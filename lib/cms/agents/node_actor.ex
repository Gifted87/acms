defmodule CMS.NodeActor do
  use GenServer
  require Logger

  alias CMS.{Node, NodeHead, NodeBody, DataHead, DataTail, NodeAntenna, Edge}
  alias CMS.{ActivationEngine, QueryCoordinator, RegionalHebbianBuffer, LogAppender, SemanticRegion, TemporalQueryEngine}
  alias CMS.Security
  alias CMS.Tool.Embedder

  @moduledoc """
  The Atomic Unit of Cognition (The "Neuron").

  CRITICAL REMEDIATION (Fix 2 & Zombie Fix & Tuning & Pulse Crash Fix):
  1. Implements Defensive Coding: Replaces strict map access with Map.get/3.
  2. Implements Safe Math: Guards Nx.dot operations.
  3. ZOMBIE FIX: Guards against starting with nil ID or Head.
  4. HYDRATION FIX: Ensures node terminates if it cannot find data.
  5. TUNING: Implements Synaptic Damping to cure "ADHD/Hub Dominance".
  6. CRASH FIX: Fixed BadBooleanError in reinforce_link caused by strict 'and' on String IDs.
  7. HEBBIAN FIX: Implemented correct A->B reinforcement via feedback messages.
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
        # CRITICAL FIX: Custom deserialization from string-keyed map
        case deserialize_node(restored_node_map) do
          {:ok, restored_node} ->
            if is_nil(restored_node.head) do
               raise "Restored node has no head"
            end
            {:noreply, %{state | node: restored_node, hydrated?: true}}
          {:error, reason} ->
            Logger.error("NodeActor #{state.node.id}: Hydration deserialization failed: #{inspect(reason)}")
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
    # Logger.debug("NodeActor #{state.node.id}: Received primary :query. Hydrated: #{state.hydrated?}")
    if state.hydrated? do
      # NodeAntenna receives query and passes to NodeHead for autonomous evaluation
      autonomous_query_evaluation(context, state)
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
      # Logger.debug("NodeActor #{state.node.id}: Ignored pulse. Dead: #{is_dead_pulse}. Traced: #{MapSet.member?(trace, state.node.id)}")
      {:noreply, state}
    else
      Logger.debug("NodeActor #{state.node.id}: Processing pulse from #{origin_id}. TTL: #{ttl}, Boost: #{boost}")

      # --- HEBBIAN FIX START ---
      # Instead of checking for a non-existent back-link locally,
      # we send positive feedback to the Origin Node (The one that pulsed us).
      # "You activated me, so your link to me is useful. Strengthen it."
      if origin_id do
        send_hebbian_feedback(origin_id, state.node.id)
      end
      # --- HEBBIAN FIX END ---

      process_activation(:secondary, context, state, boost, ttl)
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # --- GenServer Calls (handle_call) ---

  @impl true
  def handle_call(:get_drift_info, _from, state) do
    if state.node.head do
      result = {state.node.id, state.node.head.embedding, state.node.head.embedding_model_version, state.region_id}
      {:reply, result, state}
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

  # --- HEBBIAN FIX: Handle Positive Feedback ---
  @impl true
  def handle_cast({:hebbian_reinforce, target_node_id, amount}, state) do
    # This node is the SOURCE. We received feedback that our link to `target_node_id` was useful.
    # We must find that edge and increase its weight.

    current_edges = state.node.body.data_tail.relationship_metadata

    {updated_edges, changed?} =
      Enum.map_reduce(current_edges, false, fn edge, acc ->
        if edge.target_node_id == target_node_id do
           # Boost weight, max 1.0
           new_weight = min(1.0, edge.weight + amount)

           # Log to the Sharded Buffer
           RegionalHebbianBuffer.buffer_update(state.node.id, [{target_node_id, amount}], state.region_id)

           {%{edge | weight: new_weight}, true}
        else
           {edge, acc}
        end
      end)

    if changed? do
       # Update in-memory state so the node gets smarter instantly
       updated_tail = %{state.node.body.data_tail | relationship_metadata: updated_edges}
       new_node = %{state.node | body: %{state.node.body | data_tail: updated_tail}}
       {:noreply, %{state | node: new_node}}
    else
       # If we got feedback but have no edge, it's a phantom signal (or decayed link). Ignore.
       {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:perform_differential_decay, state) do
    now = DateTime.utc_now()

    new_edges = Enum.map(state.node.body.data_tail.relationship_metadata, fn edge ->
      hours_unused = DateTime.diff(now, edge.last_used_at, :hour)
      if hours_unused > 168 do
        decay_amount = 0.001 * (hours_unused / 168.0)
        %{edge | weight: max(0.01, edge.weight - decay_amount)}
      else
        edge
      end
    end)

    days_since_fired = DateTime.diff(now, state.node.last_fired, :day)
    frequency = state.node.antenna.activation_frequency

    new_internal_state = cond do
      days_since_fired > 90 and frequency < 0.1 -> :hibernating
      days_since_fired > 30 -> :low_energy
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

  # --- Private Functions ---

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

  defp send_hebbian_feedback(origin_id, my_id) do
    # We (my_id) were activated by (origin_id).
    # We send a cast to origin_id telling it to strengthen the link to us.
    origin_ref = {:via, Registry, {CMS.NodeRegistry, origin_id}}
    GenServer.cast(origin_ref, {:hebbian_reinforce, my_id, 0.05})
  end

  # CRITICAL UPDATE: Full Deserialization without shortcuts
  defp deserialize_node(node_map) do
    try do
      # 1. Deserialize Head
      head_map = Map.get(node_map, "head")
      node_head = %NodeHead{
        embedding: Nx.tensor(Map.get(head_map, "embedding")),
        embedding_model_version: Map.get(head_map, "embedding_model_version"),
        relevance_threshold: Map.get(head_map, "relevance_threshold"),
        internal_state: String.to_atom(Map.get(head_map, "internal_state"))
      }

      # 2. Deserialize Antenna
      antenna_map = Map.get(node_map, "antenna")
      node_antenna = %NodeAntenna{
        gain: Map.get(antenna_map, "gain"),
        activation_frequency: Map.get(antenna_map, "activation_frequency"),
        signal_modulations: Map.get(antenna_map, "signal_modulations")
      }

      # 3. Deserialize Body
      body_map = Map.get(node_map, "body")

      # 3a. Reconstruct DataTail and Edges
      data_tail_map = Map.get(body_map, "data_tail")
      relationship_metadata =
        Enum.map(Map.get(data_tail_map, "relationship_metadata", []), fn edge_map ->
          %Edge{
            target_node_id: Map.get(edge_map, "target_node_id"),
            type: String.to_atom(Map.get(edge_map, "type")),
            weight: Map.get(edge_map, "weight"),
            last_used_at: parse_dt!(Map.get(edge_map, "last_used_at"))
          }
        end)

      data_tail = %DataTail{
        acls: Map.get(data_tail_map, "acls"),
        salience_score: Map.get(data_tail_map, "salience_score"),
        relationship_metadata: relationship_metadata,
        versioning_pointer: Map.get(data_tail_map, "versioning_pointer"),
        checksum: Map.get(data_tail_map, "checksum")
      }

      # 3b. Reconstruct DataHead
      data_head = %DataHead{fact: Map.get(Map.get(body_map, "data_head"), "fact")}

      # 3c. FULLY Reconstruct DataBody (Polymorphic Structs)
      raw_payloads = Map.get(body_map, "data_body", [])
      data_body_payloads = Enum.map(raw_payloads, fn payload ->
        type = Map.get(payload, "type")
        case type do
          "text" ->
            %CMS.DataBodyPayload.Text{
              type: :text,
              content: Map.get(payload, "content")
            }
          "code" ->
            %CMS.DataBodyPayload.Code{
              type: :code,
              language: String.to_atom(Map.get(payload, "language", "elixir")),
              content: Map.get(payload, "content")
            }
          "number" ->
            unit_str = Map.get(payload, "unit")
            unit = if unit_str, do: String.to_atom(unit_str), else: nil
            %CMS.DataBodyPayload.Number{
              type: :number,
              value: Map.get(payload, "value"),
              unit: unit
            }
          "link" ->
            %CMS.DataBodyPayload.Link{
              type: :link,
              uri: Map.get(payload, "uri"),
              description: Map.get(payload, "description")
            }
          "object" ->
            obj_type_str = Map.get(payload, "object_type")
            obj_type = if obj_type_str, do: String.to_atom(obj_type_str), else: nil
            %CMS.DataBodyPayload.Object{
              type: :object,
              object_type: obj_type,
              data: Map.get(payload, "data")
            }
          _ ->
            %CMS.DataBodyPayload.Text{type: :text, content: "Unknown Payload"}
        end
      end)

      # Reconstruct NodeBody
      node_body = %NodeBody{
        data_head: data_head,
        data_body: data_body_payloads,
        data_tail: data_tail
      }

      # 4. Final Node
      node = %Node{
        id: Map.get(node_map, "id"),
        head: node_head,
        body: node_body,
        antenna: node_antenna,
        created_at: parse_dt!(Map.get(node_map, "created_at")),
        last_fired: parse_dt!(Map.get(node_map, "last_fired"))
      }

      {:ok, node}
    rescue
      e ->
        Logger.error("Deserialization Error: #{inspect(e)}")
        {:error, e}
    end
  end

  defp parse_dt!(iso_str) when is_binary(iso_str) do
    case DateTime.from_iso8601(iso_str) do
      {:ok, dt, _} -> dt
      _ -> raise "Invalid ISO8601 DateTime: #{inspect(iso_str)}"
    end
  end
  defp parse_dt!(nil), do: raise "DateTime is nil"

  defp rules do
    [
      {:critical_fact_alert, fn node, _context, score ->
        score > 0.85 and String.contains?(node.body.data_head.fact, "CRITICAL")
      end},
      {:untrusted_agent_high_score, fn _node, context, score ->
        score > 0.80 and Map.get(context, :agent_trust_level, 1.0) < 0.3
      end},
      {:emergency_mode_activation, fn _node, context, _score ->
        Map.get(context, :system_mode) == :emergency
      end}
    ]
  end

  defp process_activation(type, context, state, boost, ttl) do
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
        if type == :secondary do
           Logger.info("NodeActor #{node.id} FIRED (Secondary) via Pulse. Score: #{:io_lib.format("~.4f", [total])} (Boost: #{boost})")
        end
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

    QueryCoordinator.node_fired(Map.get(context, :query_id), node.id, score, new_node)

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
      Logger.debug("NodeActor #{node.id} propagating #{type} pulse to #{length(node.body.data_tail.relationship_metadata)} neighbors. Out TTL: #{standard_out_ttl}.")

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

  # Autonomous query evaluation: NodeHead independently decides if query is relevant
  defp autonomous_query_evaluation(context, state) do
    node = state.node

    # Calculate relevance score between query and node's embedding
    relevance = calculate_relevance(node, context)

    # NodeHead applies its own relevance threshold
    threshold = node.head.relevance_threshold

    # Apply metabolic state cost factor
    cost = case node.head.internal_state do
      :high_energy -> 0.9
      :low_energy -> 1.2
      :hibernating -> 1.5
      _ -> 1.0
    end

    # Apply global inhibition factor (spreading activation damping)
    inhibit = ActivationEngine.get_global_inhibition_factor()
    adjusted_threshold = (threshold / max(0.1, inhibit)) * cost

    Logger.debug(
      "NodeActor #{node.id}: Query [#{Map.get(context, :query_id)}]. " <>
      "Relevance: #{:io_lib.format("~.4f", [relevance])}. " <>
      "Threshold (Base: #{threshold}, Adj: #{:io_lib.format("~.4f", [adjusted_threshold])}). " <>
      "Cost: #{cost}, Inhibit: #{inhibit}"
    )

    # Autonomous decision: Node fires if relevance meets threshold
    if relevance >= adjusted_threshold do
      agent_id = Map.get(context, :agent_id, "unknown")

      if Security.can_read?(agent_id, node.body.data_tail.acls) do
        Logger.info("NodeActor #{node.id} FIRED (Primary) for query [#{Map.get(context, :query_id)}]. Score: #{:io_lib.format("~.4f", [relevance])}")
        # Node fires autonomously
        fire_node(:primary, relevance, context, state, 0)
      else
        Logger.debug("NodeActor #{node.id} did not fire: Permission denied.")
        {:noreply, state}
      end
    else
      Logger.debug("NodeActor #{node.id} NO-OP: Relevance below adjusted threshold.")
      # Node decides it's not relevant - no action taken
      {:noreply, state}
    end
  end

  defp via_tuple(id), do: {:via, Registry, {CMS.NodeRegistry, id}}
end
