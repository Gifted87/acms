defmodule CMS.QueryCoordinator do
  use GenServer
  require Logger

  alias CMS.LogAppender # Added LogAppender alias for failure reporting

  @moduledoc """
  Orchestrates the lifecycle of a single query.

  Implements Gap 1: Global Inhibition / Winner-Takes-Most (WTM).

  It collects results from responding NodeActors. If too many nodes fire ("Cognitive Overload"),
  it broadcasts an :inhibit signal to prune the search tree.
  """

  # Configuration
  @top_k_results 50             # Only care about top 50 relevant nodes
  @inhibit_threshold_count 100  # If >100 nodes fire, trigger inhibition
  @query_timeout 5_000          # Max time to wait for results
  @inhibit_check_delay 150      # Check for explosion 150ms after start

  # State
  defstruct [
    :query_id,
    :origin_pid,
    :target_regions,
    :fired_nodes,    # Map: %{node_id => {relevance, node_data}}
    :top_k_list,     # List: [{relevance, node_id}, ...] sorted desc
    :active_regions, # MapSet of regions pending completion
    :inhibited?      # Boolean
  ]

  # API
  # ... (start_link, node_fired, region_complete remain unchanged)

  @doc """
  Starts a coordinator for a specific query.
  """
  def start_link(query_id, target_regions, origin_pid) do
    GenServer.start_link(__MODULE__, {query_id, target_regions, origin_pid}, name: via_tuple(query_id))
  end

  @doc """
  Called by a NodeActor when it decides to fire.
  """
  def node_fired(query_id, node_id, relevance, node_data) do
    case Registry.lookup(CMS.QueryCoordinatorRegistry, query_id) do
      [{pid, _}] -> GenServer.cast(pid, {:node_fired, node_id, relevance, node_data})
      [] -> :ok # Coordinator died or timed out, ignore
    end
  end

  @doc """
  Called by the BusPipeline when a region has finished processing the initial broadcast.
  """
  def region_complete(query_id, region_id) do
    case Registry.lookup(CMS.QueryCoordinatorRegistry, query_id) do
      [{pid, _}] -> GenServer.cast(pid, {:region_complete, region_id})
      [] -> :ok
    end
  end

  # Callbacks

  @impl true
  def init({query_id, target_regions, origin_pid}) do
    # Fail-safe timeout
    Process.send_after(self(), :timeout, @query_timeout)

    # Rapid inhibition check
    Process.send_after(self(), :check_inhibition, @inhibit_check_delay)

    {:ok, %__MODULE__{
      query_id: query_id,
      origin_pid: origin_pid,
      target_regions: target_regions,
      active_regions: MapSet.new(target_regions),
      fired_nodes: %{},
      top_k_list: [],
      inhibited?: false
    }}
  end

  @impl true
  def handle_cast({:node_fired, node_id, relevance, node_data}, state) do
    # 1. Store Result
    new_fired = Map.put(state.fired_nodes, node_id, {relevance, node_data})

    # 2. Update Top-K (Insertion Sort / limited list)
    new_top_k = update_top_k(state.top_k_list, {relevance, node_id})

    # 3. Check Immediate Overload
    if not state.inhibited? and map_size(new_fired) > @inhibit_threshold_count do
      trigger_inhibition(state.query_id, state.active_regions)
      # CRITICAL PATCH: Log overload failure
      report_query_failure(state, :cognitive_overload)
      {:noreply, %{state | fired_nodes: new_fired, top_k_list: new_top_k, inhibited?: true}}
    else
      {:noreply, %{state | fired_nodes: new_fired, top_k_list: new_top_k}}
    end
  end

  @impl true
  def handle_cast({:region_complete, region_id}, state) do
    new_active = MapSet.delete(state.active_regions, region_id)

    if MapSet.size(new_active) == 0 do
      finalize_query(state)
      {:stop, :normal, state}
    else
      {:noreply, %{state | active_regions: new_active}}
    end
  end

  @impl true
  def handle_info(:check_inhibition, state) do
    # If we have a lot of results early on, prune the rest of the search.
    if not state.inhibited? and map_size(state.fired_nodes) > (@inhibit_threshold_count / 2) do
      Logger.debug("Coordinator #{state.query_id}: Fast inhibition triggered.")
      trigger_inhibition(state.query_id, state.active_regions)
      # CRITICAL PATCH: Log fast overload warning
      report_query_failure(state, :rapid_inhibition)
      {:noreply, %{state | inhibited?: true}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    # CRITICAL PATCH: Report explicit failure and finish with partial results
    Logger.warning("Coordinator #{state.query_id} timed out.")
    report_query_failure(state, :timeout)
    finalize_query(state)
    {:stop, :normal, state}
  end

  # Internals

  defp trigger_inhibition(query_id, active_regions) do
    # Broadcast :inhibit to all active regions via PubSub
    Enum.each(active_regions, fn region_id ->
      Phoenix.PubSub.broadcast(CMS.PubSub, "region:#{region_id}", {:inhibit, query_id})
    end)
  end

  defp report_query_failure(state, reason) do
    LogAppender.append_system_event(:query_failure, %{
      query_id: state.query_id,
      reason: reason,
      origin_pid: state.origin_pid,
      fired_node_count: map_size(state.fired_nodes),
      active_regions: MapSet.to_list(state.active_regions)
    })
  end

  defp finalize_query(state) do
    # Map top_k IDs back to full data
    results =
      state.top_k_list
      |> Enum.map(fn {_score, id} -> Map.get(state.fired_nodes, id) end)
      |> Enum.reject(&is_nil/1) # Safety check

    # Send back to requestor
    send(state.origin_pid, {:query_result, state.query_id, results})
  end

  defp update_top_k(list, new_entry) do
    [new_entry | list]
    |> Enum.sort_by(fn {score, _} -> score end, :desc)
    |> Enum.take(@top_k_results)
  end

  defp via_tuple(query_id) do
    {:via, Registry, {CMS.QueryCoordinatorRegistry, query_id}}
  end
end
