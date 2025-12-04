defmodule CMS.NodeActor do
  use GenServer
  require Logger

  alias CMS.{Node, ActivationEngine, QueryCoordinator, RegionalHebbianBuffer, LogAppender, SemanticRegion, TemporalQueryEngine}
  alias CMS.Security
  alias CMS.Tool.Embedder

  @moduledoc """
  The Atomic Unit of Cognition (The "Neuron").

  CRITICAL REMEDIATION (Fix 2 & Zombie Fix & Tuning):
  1. Implements Defensive Coding: Replaces strict map access with Map.get/3.
  2. Implements Safe Math: Guards Nx.dot operations.
  3. ZOMBIE FIX: Guards against starting with nil ID or Head.
  4. HYDRATION FIX: Ensures node terminates if it cannot find data.
  5. TUNING: Implements Synaptic Damping to cure "ADHD/Hub Dominance".
  """

  @abnormality_topic "global:abnormality_signal"

  defstruct [:node, :region_id, :hydrated?, :hydration_retry_count]

  # --- ZOMBIE FIX: Guard against starting invalid nodes ---
  def start_link(%Node{} = node) do
    if is_nil(node.id) do
      Logger.error("NodeActor failed to start: Node ID is nil.")
      {:error, :invalid_node_id}
    else
      GenServer.start_link(__MODULE__, node, name: via_tuple(node.id))
    end
  end

  @impl true
  def init(node) do
    # --- ZOMBIE FIX: Guard against missing head/embedding ---
    if is_nil(node.head) or is_nil(node.head.embedding) do
      Logger.error("NodeActor #{node.id} failed to init: Missing head or embedding.")
      {:stop, :invalid_initial_state}
    else
      # 1. Subscribe to Semantic Region
      region_id = SemanticRegion.compute_region_hash(node.head.embedding, node.head.embedding_model_version)
      SemanticRegion.subscribe(region_id, node.id)

      # 2. Schedule State Hydration
      Process.send_after(self(), :hydrate, 10)

      {:ok, %__MODULE__{node: node, region_id: region_id, hydrated?: false, hydration_retry_count: 0}}
    end
  end

  @impl true
  # --- HYDRATION FIX: Strict checks to prevent empty "hydrated" state ---
  def handle_info(:hydrate, state) do
    case TemporalQueryEngine.get_node_state_at_time(state.node.id, DateTime.utc_now()) do
      {:ok, restored_node_map} ->
        try do
          restored_node = struct(CMS.Node, restored_node_map)

          if is_nil(restored_node.head) do
             raise "Restored node has no head"
          end

          {:noreply, %{state | node: restored_node, hydrated?: true}}
        rescue
          e ->
            Logger.error("NodeActor #{state.node.id}: Hydration struct conversion failed: #{inspect(e)}")
            retry_hydration(state)
        end

      {:error, :node_not_found_at_timestamp} ->
        if state.node.head do
          Logger.debug("NodeActor #{state.node.id}: New node, using initial state.")
          {:noreply, %{state | hydrated?: true}}
        else
          Logger.error("NodeActor #{state.node.id}: No history and invalid initial state. Terminating.")
          {:stop, :zombie_node, state}
        end

      {:error, reason} ->
        Logger.warning("NodeActor #{state.node.id}: Hydration failed with reason: #{inspect(reason)}")
        retry_hydration(state)
    end
  end

  # --- Standard Bus Handlers (handle_info) ---

  @impl true
  def handle_info({:query, context}, state) do
    if state.hydrated? do
      trace = Map.get(context, :trace, MapSet.new())

      if MapSet.member?(trace, state.node.id) do
        {:noreply, state}
      else
        process_activation(:primary, context, state, 0.0)
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:pulse, payload}, state) do
    context = Map.get(payload, :query_context, %{})
    ttl = Map.get(payload, :ttl, 0)
    trace = Map.get(payload, :trace, MapSet.new())
    boost = Map.get(payload, :boost_score, 0.0)
    origin_id = Map.get(payload, :origin_id)

    is_dead_pulse = (is_integer(ttl) and ttl <= 0)

    if is_dead_pulse or MapSet.member?(trace, state.node.id) do
      {:noreply, state}
    else
      reinforce_link(state.node, origin_id, state.region_id)
      process_activation(:secondary, context, state, boost, ttl)
    end
  end

  # --- GenServer Calls (handle_call) ---

  @impl true
  def handle_call(:get_drift_info, _from, state) do
    if state.node.head do
      result = {state.node.id, state.node.head.embedding, state.node.head.embedding_model_version, state.region_id}
      {:reply, {:ok, result}, state}
    else
      {:reply, {:error, :invalid_state}, state}
    end
  end

  @impl true
  def handle_call(:get_head_info, _from, state) do
    {:reply, state.node.head, state}
  end

  @impl true
  def handle_call(:get_decay_criteria, _from, state) do
    node = state.node
    total_link_weight = calculate_total_link_weight(node)
    {:reply, {:ok, {node.head.internal_state, total_link_weight}}, state}
  end

  @impl true
  def handle_call(:get_trust_score, _from, state) do
    trust = Map.get(state.node, :provenance, %{}) |> Map.get("trust_score", 0.5)
    {:reply, trust, state}
  end

  @impl true
  def handle_call(:get_state_snapshot, _from, state) do
    {:reply, state.node, state}
  end

  # --- GenServer Casts (handle_cast) ---

  @impl true
  def handle_cast(:perform_differential_decay, state) do
    now = DateTime.utc_now()

    new_edges = Enum.map(state.node.body.data_tail.relationship_metadata, fn edge ->
      hours_unused = DateTime.diff(now, edge.last_used_at, :hour)
      if hours_unused > 24 do
        %{edge | weight: max(0.01, edge.weight - (0.01 * (hours_unused / 24.0)))}
      else
        edge
      end
    end)

    days_since_fired = DateTime.diff(now, state.node.last_fired, :day)
    frequency = state.node.antenna.activation_frequency

    new_internal_state = cond do
      days_since_fired > 30 and frequency < 0.1 -> :hibernating
      days_since_fired > 7 -> :low_energy
      frequency > 0.5 -> :high_energy
      true -> :recovering
    end

    new_node = %{state.node |
      head: %{state.node.head | internal_state: new_internal_state},
      body: %{state.node.body | data_tail: %{state.node.body.data_tail | relationship_metadata: new_edges}}
    }

    LogAppender.append_node_event(state.node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node}}
  end

  @impl true
  def handle_cast({:add_edge, new_edge}, state) do
    current_edges = state.node.body.data_tail.relationship_metadata

    updated_edges =
      case Enum.find_index(current_edges, fn e -> e.target_node_id == new_edge.target_node_id end) do
        nil -> [new_edge | current_edges]
        idx -> List.replace_at(current_edges, idx, new_edge)
      end

    updated_tail = %{state.node.body.data_tail | relationship_metadata: updated_edges}
    new_node = %{state.node | body: %{state.node.body | data_tail: updated_tail}}

    LogAppender.append_node_event(new_node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node}}
  end

  @impl true
  def handle_cast({:update_region, new_region}, state) do
    {:noreply, %{state | region_id: new_region}}
  end

  @impl true
  def handle_cast({:feedback, :irrelevant, _context_id, penalization_amount}, state) do
    current_edges = state.node.body.data_tail.relationship_metadata

    updated_edges = Enum.map(current_edges, fn edge ->
      new_weight = max(0.01, edge.weight - penalization_amount)
      %{edge | weight: new_weight}
    end)

    updated_tail = %{state.node.body.data_tail | relationship_metadata: updated_edges}
    new_node = %{state.node | body: %{state.node.body | data_tail: updated_tail}}

    LogAppender.append_node_event(state.node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node}}
  end

  @impl true
  def handle_cast({:re_embed_request, active_model}, state) do
    case Embedder.generate(state.node.body.data_head.fact, active_model) do
      {:ok, new_embedding} ->
         new_head = %{state.node.head |
           embedding: new_embedding,
           embedding_model_version: active_model
         }
         GenServer.cast(self(), {:update_node_head, new_head})
      {:error, reason} ->
         Logger.error("NodeActor #{state.node.id}: Re-embedding failed: #{inspect(reason)}")
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_node_head, new_head}, state) do
    new_node = %{state.node | head: new_head}
    new_region = SemanticRegion.compute_region_hash(new_head.embedding, new_head.embedding_model_version)

    if new_region != state.region_id do
      SemanticRegion.unsubscribe(state.region_id, state.node.id)
      SemanticRegion.subscribe(new_region, state.node.id)
    end

    LogAppender.append_node_event(state.node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node, region_id: new_region}}
  end

  # --- Internal Logic ---

  defp retry_hydration(state) do
    current_retry = state.hydration_retry_count
    next_retry = current_retry + 1

    if next_retry <= 5 do
      delay = min(1000, 10 * :math.pow(2, next_retry) |> round)
      Process.send_after(self(), :hydrate, delay)
      {:noreply, %{state | hydration_retry_count: next_retry}}
    else
      Logger.error("NodeActor #{state.node.id}: Hydration failed after 5 attempts. Node will be terminated.")
      {:stop, :hydration_failure, state}
    end
  end

  defp rules do
    [
      {:critical_fact_alert, fn node, _context, score ->
        score > 0.95 and String.contains?(node.body.data_head.fact, "CRITICAL")
      end},
      {:untrusted_agent_high_score, fn _node, context, score ->
        score > 0.90 and Map.get(context, :agent_trust_level, 1.0) < 0.5
      end},
      {:emergency_mode_activation, fn _node, context, _score ->
        Map.get(context, :system_mode) == :emergency
      end}
    ]
  end

  defp process_activation(type, context, state, boost, ttl \\ 0) do
    node = state.node

    cost = case node.head.internal_state do
      :high_energy -> 0.9
      :low_energy -> 1.2
      :hibernating -> 1.5
      _ -> 1.0
    end

    inhibit = ActivationEngine.get_global_inhibition_factor()
    threshold = (node.head.relevance_threshold / max(0.1, inhibit)) * cost

    relevance = calculate_relevance(node, context)
    total = relevance + boost

    check_for_abnormality(node, context, total)

    if total >= threshold do
      agent_id = Map.get(context, :agent_id, "unknown")

      if Security.can_read?(agent_id, node.body.data_tail.acls) do
        fire_node(type, total, context, state, ttl)
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  defp check_for_abnormality(node, context, score) do
    Enum.each(rules(), fn {rule_name, check_fn} ->
      if check_fn.(node, context, score) do
        Phoenix.PubSub.broadcast(CMS.PubSub, @abnormality_topic, {
          :abnormality_signal,
          node_id: node.id,
          reason: rule_name,
          query_id: Map.get(context, :query_id)
        })
      end
    end)
  end

  defp fire_node(type, score, context, state, incoming_ttl) do
    node = state.node
    new_node = %{node | last_fired: DateTime.utc_now(), head: %{node.head | internal_state: :high_energy}}

    if type == :primary or score > 0.90 do
       QueryCoordinator.node_fired(Map.get(context, :query_id), node.id, score, new_node)
    end

    base_ttl =
      cond do
        type == :primary -> 2
        incoming_ttl == :infinity -> :infinity
        is_integer(incoming_ttl) -> incoming_ttl - 1
        true -> 0
      end

    standard_out_ttl =
      if base_ttl == :infinity do
        :infinity
      else
        round(base_ttl * node.antenna.gain)
      end

    if standard_out_ttl == :infinity or standard_out_ttl > 0 do
      new_trace = MapSet.put(Map.get(context, :trace, MapSet.new()), node.id)

      Enum.each(node.body.data_tail.relationship_metadata, fn edge ->
        if edge.weight > 0.1 do
          edge_specific_ttl = if edge.type == :dependency, do: :infinity, else: standard_out_ttl

          if edge_specific_ttl == :infinity or edge_specific_ttl > 0 do
            boost = calculate_associative_boost(score, edge, context)

            payload = %{
              query_context: context,
              ttl: edge_specific_ttl,
              trace: new_trace,
              origin_id: node.id,
              boost_score: boost
            }

            Phoenix.PubSub.broadcast(CMS.PubSub, "node_pulse:#{edge.target_node_id}", {:pulse, payload})
          end
        end
      end)
    end

    {:noreply, %{state | node: new_node}}
  end

  defp calculate_relevance(node, context) do
    req_model = Map.get(context, :embedding_model, node.head.embedding_model_version)

    if node.head.embedding_model_version != req_model do
      0.1
    else
      similarity(node, context)
    end
  end

  defp similarity(node, context) do
    query_vec = Map.get(context, :query_vector)

    if query_vec do
      try do
        Nx.dot(node.head.embedding, query_vec) |> Nx.to_number()
      rescue
        _ -> 0.0
      end
    else
      String.jaro_distance(
        node.body.data_head.fact,
        Map.get(context, :query_text, "")
      )
    end
  end

  # --- TUNING FIX: Synaptic Damping to cure Hub Dominance ---
  defp calculate_associative_boost(current_relevance, edge, context) do
    type_factor = case edge.type do
      :dependency -> 1.0
      :contradicts -> 0.2
      :semantic -> 0.8
      :causes -> 0.9
      _ -> 0.5
    end

    context_factor = case Map.get(context, :reasoning_mode, :normal) do
      :brainstorm -> 1.5
      :precision -> 0.8
      _ -> 1.0
    end

    # Damping Factor: 0.3
    # Ensures associative links act as "contextual whispers" (0.3x strength)
    # rather than "shouts", preventing Hub nodes from overpowering direct hits.
    synaptic_resistance = 0.3

    current_relevance * edge.weight * type_factor * context_factor * synaptic_resistance
  end

  defp calculate_total_link_weight(node) do
    if Enum.empty?(node.body.data_tail.relationship_metadata) do
      0.0
    else
      node.body.data_tail.relationship_metadata
      |> Enum.map(&(&1.weight))
      |> Enum.sum()
      |> (fn sum -> sum / length(node.body.data_tail.relationship_metadata) end).()
    end
  end

  defp reinforce_link(node, target_id, region_id) do
    if target_id and Enum.any?(node.body.data_tail.relationship_metadata, fn e -> e.target_node_id == target_id end) do
      RegionalHebbianBuffer.buffer_update(node.id, [{target_id, 0.05}], region_id)
    end
  end

  defp via_tuple(id), do: {:via, Registry, {CMS.NodeRegistry, id}}
end
