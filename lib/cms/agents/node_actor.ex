defmodule CMS.NodeActor do
  use GenServer
  require Logger

  # FIX: Cleaned up aliases and ensured they are used
  alias CMS.{Node, ActivationEngine, QueryCoordinator, RegionalHebbianBuffer, LogAppender, SemanticRegion, TemporalQueryEngine}
  alias CMS.Edge
  alias CMS.Security
  alias CMS.Tool.Embedder

  @moduledoc """
  The Atomic Unit of Cognition (The "Neuron").

  Implements:
  - Fix 2: State Hydration (Crash Amnesia Fix).
  - Gap 11.4: Node Migration.
  - Section 7.2: Hebbian & Anti-Hebbian Learning.
  - Section 8.2: Model Drift Handling.
  """

  @abnormality_topic "global:abnormality_signal"

  defstruct [:node, :region_id, :hydrated?]

  def start_link(%Node{} = node) do
    GenServer.start_link(__MODULE__, node, name: via_tuple(node.id))
  end

  @impl true
  def init(node) do
    # 1. Subscribe to Semantic Region
    region_id = SemanticRegion.compute_region_hash(node.head.embedding, node.head.embedding_model_version)
    SemanticRegion.subscribe(region_id, node.id)

    # 2. FIX 2: Schedule State Hydration
    Process.send_after(self(), :hydrate, 10)

    {:ok, %__MODULE__{node: node, region_id: region_id, hydrated?: false}}
  end

  # --- FIX 2: Hydration Logic ---
  @impl true
  def handle_info(:hydrate, state) do
    Logger.debug("NodeActor #{state.node.id}: Attempting hydration from Temporal History...")

    case TemporalQueryEngine.get_node_state_at_time(state.node.id, DateTime.utc_now()) do
      {:ok, restored_node_map} ->
        # Simplified merge logic assuming struct compatibility
        restored_node = struct(CMS.Node, restored_node_map)

        Logger.info("NodeActor #{state.node.id}: Hydrated successfully.")
        {:noreply, %{state | node: restored_node, hydrated?: true}}

      {:error, _reason} ->
        Logger.debug("NodeActor #{state.node.id}: No history found. Starting fresh.")
        {:noreply, %{state | hydrated?: true}}
    end
  end

  # --- Standard Bus Handlers ---

  @impl true
  def handle_info({:query, context}, state) do
    if state.hydrated? do
      if MapSet.member?(context.trace, state.node.id) do
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
    %{query_context: context, ttl: ttl, trace: trace, boost_score: boost, origin_id: origin_id} = payload

    # GAP 9 FIX: Handle :infinity atom explicitly
    is_dead_pulse = (is_integer(ttl) and ttl <= 0)

    if is_dead_pulse or MapSet.member?(trace, state.node.id) do
      {:noreply, state}
    else
      reinforce_link(state.node, origin_id, state.region_id)
      process_activation(:secondary, context, state, boost, ttl)
    end
  end

  # --- GenServer Calls ---

  @impl true
  def handle_call(:get_drift_info, _from, state) do
    result = {state.node.id, state.node.head.embedding, state.node.head.embedding_model_version, state.region_id}
    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_head_info, _from, state) do
    {:reply, state.node.head, state}
  end

  @impl true
  def handle_call(:get_decay_criteria, _from, state) do
    node = state.node
    total_link_weight = calculate_total_link_weight(node)
    {:reply, {node.head.internal_state, total_link_weight}, state}
  end

  @impl true
  def handle_call(:get_trust_score, _from, state) do
    trust = Map.get(state.node, :provenance, %{}) |> Map.get("trust_score", 0.5)
    {:reply, trust, state}
  end

  # --- GenServer Casts (Expanded for Completeness) ---

  @impl true
  def handle_cast(:perform_differential_decay, state) do
    now = DateTime.utc_now()

    # 1. Decay Edges
    new_edges = Enum.map(state.node.body.data_tail.relationship_metadata, fn edge ->
      hours_unused = DateTime.diff(now, edge.last_used_at, :hour)
      if hours_unused > 24 do
        %{edge | weight: max(0.01, edge.weight - (0.01 * (hours_unused / 24.0)))}
      else
        edge
      end
    end)

    # 2. Update Metabolic State
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

  # --- NEW: Anti-Hebbian Penalization (Gap C) ---
  @impl true
  def handle_cast({:feedback, :irrelevant, _context_id, penalization_amount}, state) do
    # Penalize recent links. For simplicity, we reduce all active link weights.
    current_edges = state.node.body.data_tail.relationship_metadata

    updated_edges = Enum.map(current_edges, fn edge ->
      # Reduce weight, clamping at 0.01
      new_weight = max(0.01, edge.weight - penalization_amount)
      %{edge | weight: new_weight}
    end)

    updated_tail = %{state.node.body.data_tail | relationship_metadata: updated_edges}
    new_node = %{state.node | body: %{state.node.body | data_tail: updated_tail}}

    LogAppender.append_node_event(state.node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node}}
  end

  # --- NEW: Model Drift Repair (Gap 7) ---
  @impl true
  def handle_cast({:re_embed_request, active_model}, state) do
    Logger.info("NodeActor #{state.node.id}: Re-embedding self to model #{active_model}...")

    # 1. Generate new embedding
    case Embedder.generate(state.node.body.data_head.fact, active_model) do
      {:ok, new_embedding} ->
         new_head = %{state.node.head |
           embedding: new_embedding,
           embedding_model_version: active_model
         }

         # 2. Trigger self-update via cast
         GenServer.cast(self(), {:update_node_head, new_head})

      {:error, reason} ->
         Logger.error("NodeActor #{state.node.id}: Re-embedding failed: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_node_head, new_head}, state) do
    new_node = %{state.node | head: new_head}

    # Recalculate region since embedding changed
    new_region = SemanticRegion.compute_region_hash(new_head.embedding, new_head.embedding_model_version)

    # Update Subscription if region changed
    if new_region != state.region_id do
      SemanticRegion.unsubscribe(state.region_id, state.node.id)
      SemanticRegion.subscribe(new_region, state.node.id)
    end

    LogAppender.append_node_event(state.node.id, :node_updated, new_node)
    {:noreply, %{state | node: new_node, region_id: new_region}}
  end

  # --- Internal Logic ---

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
      # FIX: Restored Security Check using alias Security
      if Security.can_read?(context.agent_id, node.body.data_tail.acls) do
        fire_node(type, total, context, state, ttl)
      else
        Logger.debug("Node #{node.id} suppressed. Agent #{context.agent_id} denied by ACLs.")
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  defp check_for_abnormality(node, context, score) do
    Enum.each(rules(), fn {rule_name, check_fn} ->
      if check_fn.(node, context, score) do
        Logger.error("Node #{node.id} triggered Abnormality Signal (Rule: #{rule_name}).")
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
    # 1. Update last_fired and internal state
    new_node = %{node | last_fired: DateTime.utc_now(), head: %{node.head | internal_state: :high_energy}}

    # 2. Reply to Coordinator
    if type == :primary or score > 0.90, do: QueryCoordinator.node_fired(context.query_id, node.id, score, new_node)

    # 3. Broadcast Pulse (Spreading Activation)
    # GAP 9 FIX: Calculate base_ttl handling :infinity for dependencies
    base_ttl =
      cond do
        type == :primary -> 2
        incoming_ttl == :infinity -> :infinity
        true -> incoming_ttl - 1
      end

    # Calculate the standard decay TTL based on antenna gain
    standard_out_ttl =
      if base_ttl == :infinity do
        :infinity
      else
        round(base_ttl * node.antenna.gain)
      end

    # Check if we should propagate at all (either infinite or > 0)
    if standard_out_ttl == :infinity or standard_out_ttl > 0 do
      new_trace = MapSet.put(context.trace, node.id)

      Enum.each(node.body.data_tail.relationship_metadata, fn edge ->
        # Filter weak links
        if edge.weight > 0.1 do
          # GAP 9 FIX: Override TTL for dependency links
          edge_specific_ttl =
            if edge.type == :dependency do
              :infinity
            else
              standard_out_ttl
            end

          # Only broadcast if this specific edge has life
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
    if node.head.embedding_model_version != context.embedding_model do
      # Penalize model drift heavily
      0.1
    else
      similarity(node, context)
    end
  end

  defp similarity(node, context) do
    if context.query_vector do
      try do
        # FIX: Used alias Embedder
        Nx.dot(node.head.embedding, context.query_vector) |> Nx.to_number()
      rescue _ -> 0.0 end
    else
      String.jaro_distance(node.body.data_head.fact, context.query_text)
    end
  end

  @spec calculate_associative_boost(float(), Edge.t(), map()) :: float()
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

    current_relevance * edge.weight * type_factor * context_factor
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
    if Enum.any?(node.body.data_tail.relationship_metadata, fn e -> e.target_node_id == target_id end) do
      RegionalHebbianBuffer.buffer_update(node.id, [{target_id, 0.05}], region_id)
    end
  end

  defp via_tuple(id), do: {:via, Registry, {CMS.NodeRegistry, id}}
end
