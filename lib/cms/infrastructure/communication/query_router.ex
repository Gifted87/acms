defmodule CMS.QueryRouter do
  use GenStage
  require Logger

  @moduledoc """
  The entry point for the Cognitive Bus.

  Acts as a GenStage Producer. It accepts queries and buffers them until
  the Broadway pipeline (Consumers) requests them via back-pressure.
  """

  # API

  @doc """
  Submits a query to the Cognitive Bus.
  """
  @spec broadcast_query(map(), [integer()]) :: :ok | {:error, atom()}
  def broadcast_query(query_context, target_regions) do
    # FIX: Dynamically find the producer PID associated with the Broadway pipeline
    # We cannot cast to __MODULE__ because Broadway spawns specifically named stages.
    case Broadway.producer_names(CMS.BusPipeline) do
      [producer_pid | _] ->
        GenStage.cast(producer_pid, {:broadcast, query_context, target_regions})
      [] ->
        Logger.error("CMS.QueryRouter: No active producer found for BusPipeline.")
        {:error, :bus_not_ready}
    end
  end

  # Callbacks

  @impl true
  def init(_opts) do
    # FIX: Changed argument from :ok to _opts to accept Broadway configuration
    # buffer_size: limit the queue to prevent OOM on massive overload
    {:producer, {:queue.new(), 0}, buffer_size: 10_000}
  end

  @impl true
  def handle_cast({:broadcast, context, regions}, {queue, demand}) do
    event = {context, regions}
    dispatch_events(:queue.in(event, queue), demand, [])
  end

  @impl true
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  # Dispatch Logic
  defp dispatch_events(queue, 0, events) do
    # No demand left, emit what we have and keep the rest
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, new_queue} ->
        dispatch_events(new_queue, demand - 1, [event | events])
      {:empty, _} ->
        # Queue is empty, wait for more casts
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
