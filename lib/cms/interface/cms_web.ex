defmodule CMS.Web do
  @moduledoc """
  The Universal API Layer for the CMS.

  Provides a unified HTTP and WebSocket interface to the Cognitive Memory System.
  Designed to be dropped into the supervision tree with minimal configuration.

  ## Security & Performance Features
  - **Safe Atom Handling**: Whitelisted atom creation to prevent DoS.
  - **Input Validation**: Strict FID schema validation via FIDValidator.
  - **Optimized Reads**: Prefers active GenServer state over expensive disk logs.
  - **Size Limits**: Enforced 10MB body limit.
  - **WS Auth**: Basic token check for real-time streams.
  - **Resiliency**: Implements Global Fallback Broadcast if targeted search fails.

  ## Endpoints
  - POST /api/v1/ingest             -> Ingest new knowledge
  - POST /api/v1/query              -> Semantic/Temporal Search (Live or Historical)
  - GET  /api/v1/nodes/:id          -> Fetch active node state
  - POST /api/v1/nodes/:id/feedback -> Anti-Hebbian Penalization (NEW)
  - GET  /api/v1/nodes/:id/edges    -> Fetch node relationships
  - GET  /api/v1/nodes/:id/history  -> Temporal "Time Travel" fetch
  - GET  /api/v1/health/embedder    -> Check ML Bridge status
  - WS   /api/v1/events             -> Real-time signals (WebSocket)
  """
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
    def init(opts) do
      port = Keyword.get(opts, :port, 4000)

      # 1. Define routes explicitly
      ws_route = "/api/v1/events"

      # 2. Define the dispatch table
      # Plug.Cowboy will do it automatically. Passing a compiled table causes the crash.
      dispatch = [
        {:_, [
          {ws_route, CMS.Web.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {CMS.Web.Router, []}}
        ]}
      ]

      children = [
        # Pass the raw list 'dispatch' to options
        {Plug.Cowboy, scheme: :http, plug: CMS.Web.Router, options: [port: port, dispatch: dispatch]}
      ]

      Logger.info("CMS.Web API started on port #{port}")
      Supervisor.init(children, strategy: :one_for_one)
    end

  def normalize_acls(nil), do: %{read: ["public"], write: ["system", "root"]}
  def normalize_acls(list) when is_list(list), do: %{read: list ++ ["public"], write: list}
  def normalize_acls(map) when is_map(map), do: map
  def normalize_acls(_), do: %{read: ["public"], write: ["system", "root"]}
end

# ==============================================================================
# REST ROUTER
# ==============================================================================
defmodule CMS.Web.Router do
  use Plug.Router
  require Logger

  alias CMS.{IngestionEngine, QueryCoordinator, TemporalQueryEngine, NodeSupervisor}
  alias CMS.{DataBodyPayload, FIDValidator, Tool.Embedder}

  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    length: 10_000_000

  plug :match
  plug :dispatch


  defp format_public_response(score, node) do
    %{
      score: score,
      node_id: node.id,
      # 1. Extract Fact
      fact: get_in(node, [:body, :data_head, :fact]) || get_in(node, ["body", "data_head", "fact"]),
      # 2. Extract Data Body (Payloads)
      data: get_in(node, [:body, :data_body]) || get_in(node, ["body", "data_body"]),
      # 3. Clean Metadata (No Embeddings/Internal State)
      metadata: %{
        created_at: node.created_at,
        last_fired: node.last_fired,
        checksum: get_in(node, [:body, :data_tail, :checksum]) || get_in(node, ["body", "data_tail", "checksum"]),
        # Handle the nil pointer for new nodes
        version: get_in(node, [:body, :data_tail, :versioning_pointer]) || get_in(node, ["body", "data_tail", "versioning_pointer"]) || "v1 (genesis)"
      }
    }
  end

  # ----------------------------------------------------------------------------
  # 1. INGESTION API
  # ----------------------------------------------------------------------------
  post "/api/v1/ingest" do
    with {:ok, params} <- validate_params(conn.body_params, ["fact_text", "description_payloads", "agent_id"]),
         {:ok, payloads} <- parse_and_validate_payloads(params["description_payloads"]),
         acls <- CMS.Web.normalize_acls(params["acls"]) do

      request = %{
        fact_text: params["fact_text"],
        description_payloads: payloads,
        agent_id: params["agent_id"],
        acls: acls,
        provenance: params["provenance"] || %{}
      }

      case IngestionEngine.ingest(request) do
        {:ok, node_id} ->
          send_json(conn, 201, %{status: "ok", node_id: node_id})
        {:ok, :ingested_with_conflict_resolution, meta_id} ->
          send_json(conn, 202, %{status: "conflict_resolved", meta_node_id: meta_id})
        {:error, :permission_denied} ->
          send_json(conn, 403, %{error: "Permission denied"})
        {:error, reason} ->
          Logger.error("Ingestion failed: #{inspect(reason)}")
          send_json(conn, 500, %{error: "Ingestion failed", detail: inspect(reason)})
      end
    else
      {:error, {:validation, msg}} -> send_json(conn, 400, %{error: "Validation Error", detail: msg})
      {:error, missing} when is_binary(missing) -> send_json(conn, 400, %{error: "Missing fields: #{missing}"})
      _ -> send_json(conn, 400, %{error: "Invalid request format"})
    end
  end

  # ----------------------------------------------------------------------------
  # 2. QUERY API (Live & Temporal)
  # ----------------------------------------------------------------------------
  post "/api/v1/query" do
    params = conn.body_params
    query_text = params["query_text"]
    query_vec = params["query_vector"]
    agent_id = params["agent_id"] || "anonymous"

    # Feature: Pagination & Thresholds
    max_results = params["max_results"] || 50
    min_relevance = params["min_relevance"] || 0.6

    if is_nil(query_text) and is_nil(query_vec) do
      send_json(conn, 400, %{error: "Must provide query_text or query_vector"})
    else
      try do
        model = params["embedding_model"] || "all-MiniLM-L6-v2"

        final_vec =
          if query_vec do
             Nx.tensor(query_vec)
          else
             case Embedder.generate(query_text, model) do
               {:ok, tensor} -> tensor
               {:error, _} -> throw(:embedding_failed)
             end
          end

        # Feature: Validated Region Targeting
        target_regions = resolve_target_regions(params["target_regions"], final_vec, model)

        # Feature: Temporal Search (as_of)
        case params["as_of"] do
          nil ->
            # A. LIVE SPREADING ACTIVATION
            execute_live_query(conn, %{
              query_vector: final_vec,
              query_text: query_text,
              target_regions: target_regions,
              agent_id: agent_id,
              model: model,
              params: params
            })

          iso_timestamp ->
             # B. HISTORICAL FORENSIC SEARCH
             case DateTime.from_iso8601(iso_timestamp) do
               {:ok, dt, _} ->
                 execute_temporal_search(conn, final_vec, model, dt, max_results, min_relevance)
               _ ->
                 send_json(conn, 400, %{error: "Invalid as_of timestamp format"})
             end
        end

      catch
        :embedding_failed -> send_json(conn, 503, %{error: "Embedding service unavailable"})
        e ->
          Logger.error("Query Error: #{inspect(e)}")
          send_json(conn, 500, %{error: "Internal Query Error"})
      end
    end
  end

  defp resolve_target_regions(input, vector, model) when is_list(input) do
    # Validate user input: Must be list of integers 0..255
    if Enum.all?(input, fn x -> is_integer(x) and x >= 0 and x <= 255 end) do
      input
    else
      # If invalid, fall back to computed region but log warning
      Logger.warning("Invalid target_regions provided, falling back to computed.")
      [CMS.SemanticRegion.compute_region_hash(vector, model)]
    end
  end
  # Fallback: Compute region if input is nil
  defp resolve_target_regions(_, vector, model) do
    [CMS.SemanticRegion.compute_region_hash(vector, model)]
  end

  # --- CRITICAL UPDATE: Implements Decentralized Query with Broadcast to All Nodes ---
  defp execute_live_query(conn, ctx) do
    query_id = UUID.uuid4()

    # Base Context
    query_context = %{
      query_id: query_id,
      query_vector: ctx.query_vector,
      query_text: ctx.query_text,
      agent_id: ctx.agent_id,
      trace: MapSet.new(),
      embedding_model: ctx.model,
      min_relevance: ctx.params["min_relevance"] || 0.6,
      reasoning_mode: safe_atom_cast(ctx.params["reasoning_mode"], :normal, [:normal, :brainstorm, :precision]),
      system_mode: safe_atom_cast(ctx.params["system_mode"], :normal, [:normal, :emergency])
    }

    # NEW: Start a coordinator to collect responses from nodes that fire
    # Pass self() as the origin_pid so the coordinator knows where to send the ready signal and results
    {:ok, coord_pid} = QueryCoordinator.start_link(query_id, [0], self())
    ref = Process.monitor(coord_pid)

    # CRITICAL FIX: Wait for the coordinator to signal that it's ready/registered.
    # This prevents the race condition where nodes fire and try to report results
    # before the Coordinator is findable in the Registry.
    receive do
      {:coordinator_ready, ^query_id} ->
        Logger.debug("WebRouter: Coordinator #{query_id} confirmed ready. Dispatching broadcast.")
        # NEW: Broadcast query to ALL nodes using the decentralized coordinator
        CMS.BroadcastCoordinator.broadcast_query(query_context)

      {:DOWN, ^ref, :process, _pid, _reason} ->
        Logger.error("WebRouter: Coordinator crashed before ready signal.")
        # We will fall through to the result receiver which will handle the DOWN message
    after
      2000 ->
        Logger.error("WebRouter: Timed out waiting for Coordinator #{query_id} ready signal.")
    end

    # Wait for results with timeout
    results =
      receive do
        {:query_result, ^query_id, received_results} ->
          Process.demonitor(ref, [:flush])
          received_results
        {:DOWN, ^ref, :process, _pid, _reason} ->
          []
      after 10000 -> # 10 second timeout for global broadcast
          Process.demonitor(ref, [:flush])
          []
      end

    # Response Construction
    limit = ctx.params["max_results"] || 50

    # Transform tuples {score, node} to Maps %{score: s, node: n} for JSON encoding
    trimmed_results =
      results
      |> Enum.take(limit)
      |> Enum.map(fn {score, node} -> format_public_response(score, node) end)

    send_json(conn, 200, %{
      query_id: query_id,
      count: length(trimmed_results),
      results: trimmed_results,
      fallback_triggered: false # No fallback needed in new model
    })
  end

  defp execute_temporal_search(conn, vector, _model, dt, max_results, min_relevance) do
    # 1. Fetch the reconstructed history from the Engine
    case CMS.TemporalQueryEngine.get_system_state_at_time(dt) do
      {:ok, nodes} ->
        # 2. Brute-force Vector Scan in Memory
        results =
          nodes
          |> Enum.map(fn node ->
            # Extract embedding safely (it will be a list of floats from JSON)
            node_embedding = get_in(node, ["head", "embedding"])

            if node_embedding do
              # Convert list back to tensor for math
              tensor_emb = if is_list(node_embedding), do: Nx.tensor(node_embedding), else: node_embedding
              score = cosine_similarity(vector, tensor_emb)
              {score, node}
            else
              {0.0, node}
            end
          end)
          |> Enum.filter(fn {score, _} -> score >= min_relevance end)
          |> Enum.sort_by(fn {score, _} -> score end, :desc)
          |> Enum.take(max_results)
          |> Enum.map(fn {score, node} -> format_public_response(score, node) end)

        send_json(conn, 200, %{
          query_type: "temporal",
          as_of: DateTime.to_iso8601(dt),
          count: length(results),
          results: results
        })

      _ ->
        send_json(conn, 500, %{error: "Failed to reconstruct history"})
    end
  end

  defp cosine_similarity(vec_a, vec_b) do
    try do
      # Handle both Tensors and Lists
      list_a = if is_struct(vec_a, Nx.Tensor), do: Nx.to_flat_list(vec_a), else: vec_a
      list_b = if is_struct(vec_b, Nx.Tensor), do: Nx.to_flat_list(vec_b), else: vec_b

      dot_product = Enum.zip(list_a, list_b) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
      norm_a = :math.sqrt(Enum.map(list_a, &(&1 * &1)) |> Enum.sum())
      norm_b = :math.sqrt(Enum.map(list_b, &(&1 * &1)) |> Enum.sum())

      if norm_a == 0 or norm_b == 0, do: 0.0, else: dot_product / (norm_a * norm_b)
    rescue
      _ -> 0.0
    end
  end

  defp fetch_active_or_historical_node(node_id) do
    if pid = CMS.NodeSupervisor.get_node_pid(node_id) do
      try do
        GenServer.call(pid, :get_state_snapshot, 1000)
      rescue _ -> nil end
    else
      # If not active, try to fetch the LATEST known state from history
      case CMS.TemporalQueryEngine.get_node_state_at_time(node_id, DateTime.utc_now()) do
        {:ok, node} -> node
        _ -> nil
      end
    end
  end

  # ----------------------------------------------------------------------------
  # 3. NODE MANAGEMENT API
  # ----------------------------------------------------------------------------
  get "/api/v1/nodes/:id" do
    id = conn.path_params["id"]
    case fetch_active_or_historical_node(id) do
      nil -> send_json(conn, 404, %{error: "Node not found in active memory or history"})
      node -> send_json(conn, 200, node)
    end
  end

  # Feature: Anti-Hebbian Feedback
  post "/api/v1/nodes/:id/feedback" do
    id = conn.path_params["id"]
    params = conn.body_params

    # Validate Penalization Amount
    amount = params["penalization_amount"]
    context_id = params["context_id"]

    if is_number(amount) and amount > 0.0 and amount <= 1.0 do
      case NodeSupervisor.get_node_pid(id) do
        nil ->
          send_json(conn, 404, %{error: "Node not active"})
        pid ->
          # Cast the feedback to the node (Gap C remediation)
          GenServer.cast(pid, {:feedback, :irrelevant, context_id, amount})
          send_json(conn, 200, %{status: "feedback_applied", node_id: id})
      end
    else
      send_json(conn, 400, %{error: "penalization_amount must be float between 0.0 and 1.0"})
    end
  end

  get "/api/v1/nodes/:id/history" do
    id = conn.path_params["id"]
    params = fetch_query_params(conn).query_params

    case DateTime.from_iso8601(params["as_of"] || "") do
      {:ok, dt, _} ->
        case TemporalQueryEngine.get_node_state_at_time(id, dt) do
          {:ok, node} -> send_json(conn, 200, node)
          {:error, _} -> send_json(conn, 404, %{error: "No history found"})
        end
      _ ->
        send_json(conn, 400, %{error: "Invalid timestamp"})
    end
  end

  get "/api/v1/nodes/:id/edges" do
    id = conn.path_params["id"]
    case NodeSupervisor.get_node_pid(id) do
      nil ->
        case TemporalQueryEngine.get_node_state_at_time(id, DateTime.utc_now()) do
          {:ok, node} ->
            edges = get_in(node, ["body", "data_tail", "relationship_metadata"]) || []
            send_json(conn, 200, %{node_id: id, edge_count: length(edges), edges: edges})
          _ -> send_json(conn, 404, %{error: "Node not found"})
        end
      pid ->
        try do
          # Assume node actor exposes edges via call or state snapshot
          state = GenServer.call(pid, :get_state_snapshot, 5000)
          edges = get_in(state, [:body, :data_tail, :relationship_metadata]) || []
          send_json(conn, 200, %{node_id: id, edge_count: length(edges), edges: edges})
        catch
          _, _ -> send_json(conn, 503, %{error: "Node busy"})
        end
    end
  end

  delete "/api/v1/nodes/:id" do
    id = conn.path_params["id"]
    agent_id = get_req_header(conn, "x-agent-id") |> List.first()

    if agent_id in ["root", "system"] do
      case NodeSupervisor.get_node_pid(id) do
        nil -> send_json(conn, 404, %{error: "Node not active"})
        pid ->
           GenServer.stop(pid, :normal)
           CMS.LogAppender.append_node_event(id, :node_decayed, %{reason: "admin_eviction", by: agent_id})
           send_json(conn, 200, %{status: "evicted"})
      end
    else
      send_json(conn, 403, %{error: "Admin privileges required"})
    end
  end

  # ----------------------------------------------------------------------------
  # 4. SYSTEM API
  # ----------------------------------------------------------------------------
  post "/api/v1/system/:action" do
    agent_id = get_req_header(conn, "x-agent-id") |> List.first()
    if agent_id not in ["root", "system"] do
       send_json(conn, 403, %{error: "Forbidden"})
    else
      case conn.path_params["action"] do
        "rotate-epoch" ->
          CMS.EpochManager.rotate_log()
          send_json(conn, 200, %{status: "rotated"})
        "check-drift" ->
          send(CMS.ModelDriftManager, :check_for_drift)
          send_json(conn, 200, %{status: "drift_check_initiated"})
        "set-congestion" ->
          level = conn.body_params["level"]
          if is_number(level) do
            CMS.ActivationEngine.set_congestion_level(level)
            send_json(conn, 200, %{status: "congestion_set", level: level})
          else
            send_json(conn, 400, %{error: "Level must be a number"})
          end
        _ ->
          send_json(conn, 404, %{error: "Unknown action"})
      end
    end
  end

  get "/api/v1/health/embedder" do
    url = "http://localhost:5000/api/v1/health"
    case Req.get(url, receive_timeout: 1000) do
      {:ok, %{status: 200}} -> send_json(conn, 200, %{status: "ok", bridge: "connected"})
      _ -> send_json(conn, 503, %{status: "degraded", bridge: "unreachable"})
    end
  end

  match _ do
    send_json(conn, 404, %{error: "Route not found"})
  end

  # ----------------------------------------------------------------------------
  # PRIVATE HELPERS
  # ----------------------------------------------------------------------------
  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp validate_params(params, required_keys) do
    missing = Enum.filter(required_keys, fn k -> is_nil(params[k]) end)
    if Enum.empty?(missing), do: {:ok, params}, else: {:error, Enum.join(missing, ", ")}
  end

  defp parse_and_validate_payloads(list) when is_list(list) do
    results = Enum.map(list, fn item ->
      payload =
        case item["type"] do
          "text" -> %DataBodyPayload.Text{content: item["content"] || ""}
          "code" ->
            lang = safe_atom_cast(item["language"], :elixir, [:elixir, :python, :javascript, :json, :bash])
            %DataBodyPayload.Code{language: lang, content: item["content"] || ""}
          "number" ->
            unit = if item["unit"] && item["unit"] != "nil", do: safe_atom_cast(item["unit"], nil, [:meters, :seconds, :celsius, :count]), else: nil
            %DataBodyPayload.Number{value: item["value"], unit: unit}
          "link" -> %DataBodyPayload.Link{uri: item["uri"] || "", description: item["description"]}
          "object" ->
             type = safe_atom_cast(item["object_type"], :generic, [:sensor_data, :config, :metadata, :generic])
             %DataBodyPayload.Object{object_type: type, data: item["data"] || %{}}
          _ -> %DataBodyPayload.Text{content: "Unknown Payload"}
        end

      case FIDValidator.validate(payload) do
        :ok -> {:ok, payload}
        {:error, msg} -> {:error, msg}
      end
    end)

    error = Enum.find(results, fn {:error, _} -> true; _ -> false end)
    if error, do: {:error, {:validation, elem(error, 1)}}, else: {:ok, Enum.map(results, &elem(&1, 1))}
  end
  defp parse_and_validate_payloads(_), do: {:error, "Payloads must be a list"}

  defp safe_atom_cast(str, default, allowlist) when is_binary(str) do
    try do
      atom = String.to_existing_atom(str)
      if atom in allowlist, do: atom, else: default
    rescue _ -> default end
  end
  defp safe_atom_cast(_, default, _), do: default
end

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================
defmodule CMS.Web.SocketHandler do
  @behaviour :cowboy_websocket
  require Logger

  @public_topics ["global:signals"]
  @admin_topics ["global:abnormality_signal", "system_congestion"]

  def init(req, state) do
    qs = :cowboy_req.parse_qs(req)
    token = :proplists.get_value("token", qs)
    permissions = if token == "admin_secret", do: :admin, else: :public
    {:cowboy_websocket, req, Map.put(state, :permissions, permissions)}
  end

  def websocket_init(state) do
    Enum.each(@public_topics, &Phoenix.PubSub.subscribe(CMS.PubSub, &1))
    if state[:permissions] == :admin, do: Enum.each(@admin_topics, &Phoenix.PubSub.subscribe(CMS.PubSub, &1))
    {:ok, state}
  end

  def websocket_handle({:text, json}, state) do
    {:reply, {:text, "ACK: " <> json}, state}
  end
  def websocket_handle(_frame, state), do: {:ok, state}

  def websocket_info(msg, state) do
    {:reply, {:text, serialize_event(msg)}, state}
  end

  defp serialize_event({:abnormality_signal, opts}) do
    Jason.encode!(%{event: "abnormality_signal", node_id: opts[:node_id], reason: opts[:reason], timestamp: DateTime.utc_now()})
  end
  defp serialize_event({:system_congestion, level}) do
    Jason.encode!(%{event: "system_congestion", level: level, timestamp: DateTime.utc_now()})
  end
  defp serialize_event(other), do: Jason.encode!(%{event: "signal", data: inspect(other)})

end
