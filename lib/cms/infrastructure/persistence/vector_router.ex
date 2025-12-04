defmodule CMS.VectorRouter do
  use GenServer
  require Logger

  @moduledoc """
  Manages the Hierarchical Navigable Small Worlds (HNSW) index for vector embeddings.

  CRITICAL REMEDIATION:
  1. FIX: Updated 'add' and 'query' to pass Nx.Tensor directly to HNSWLib as required by the binding.
  2. FIX: Ensures 1D vectors are correctly converted to 2D batches (Nx.new_axis).
  3. FIX: Uses safer ID generation to prevent NIF integer overflow issues.
  4. QUERY FIX: Added logic to respect the `threshold` option.
  """

  # Configuration
  @base_index_dir "priv/data/hnsw_indices"
  @dim 384
  @max_elements 100_000
  @persist_interval :timer.minutes(5)
  @persist_threshold 100
  @id_map_table :vector_id_mapping

  # Supported Models
  @supported_models ["all-MiniLM-L6-v2", "custom-bert-v1"]

  defstruct [
    :indices,           # Map: %{model_version => index_ref}
    :insertion_count,   # Map: %{model_version => count}
    :dirty_models       # MapSet: Tracks models with unpersisted changes
  ]

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_embedding(node_id, embedding, model_version) do
    GenServer.call(__MODULE__, {:add, node_id, embedding, model_version}, 30_000)
  end

  def query(query_vector, model_version, opts \\ []) do
    GenServer.call(__MODULE__, {:query, query_vector, model_version, opts}, 10_000)
  end

  def persist do
    GenServer.call(__MODULE__, :persist)
  end

  # --- Server Callbacks ---

  @impl true
  def init(_opts) do
    Logger.info("CMS.VectorRouter: Initializing with CLEAN SLATE strategy...")

    # 1. CLEAN SLATE: Remove old indices to prevent corruption loops
    File.rm_rf(@base_index_dir)
    File.mkdir_p!(@base_index_dir)

    # 2. Initialize Mnesia
    init_mnesia()

    # 3. Create fresh indices with error handling
    {initial_indices, initial_counts} =
      Enum.reduce(@supported_models, {[], []}, fn model, {indices_acc, counts_acc} ->
        case HNSWLib.Index.new(:cosine, @dim, @max_elements) do
          {:ok, index} ->
            {[{model, index} | indices_acc], [{model, 0} | counts_acc]}
          {:error, reason} ->
            Logger.error("Failed to create HNSW index for #{model}: #{inspect(reason)}")
            {indices_acc, counts_acc}
        end
      end)

    Process.send_after(self(), :periodic_persist, @persist_interval)

    {:ok, %__MODULE__{
      indices: Map.new(initial_indices),
      insertion_count: Map.new(initial_counts),
      dirty_models: MapSet.new()
    }}
  end

  @impl true
  def handle_call({:add, node_id, embedding, model_version}, _from, state) do
    case Map.fetch(state.indices, model_version) do
      {:ok, index} when not is_nil(index) ->
        try do
          # CRITICAL FIX 1: Ensure embedding is a 2D Nx.Tensor (a batch of 1 vector)
          vector_tensor =
            case Nx.rank(embedding) do
              1 -> Nx.new_axis(embedding, 0) # Convert 1D [384] to 2D [1][384]
              _ -> embedding
            end

          # CRITICAL FIX 2: Dimension Check - use Nx.shape for a 2D tensor
          tensor_dim = elem(Nx.shape(vector_tensor), 1)

          if tensor_dim != @dim do
            Logger.error("Dimension mismatch: Expected #{@dim}, got #{tensor_dim}.")
            {:reply, {:error, :dimension_mismatch}, state}
          else
            # 2. Generate ID
            # FIX 3: Use safer phash2 for NIF compatibility
            item_id = :erlang.phash2(node_id, 2_147_483_647)

            # 3. Add to HNSW (Pass the Nx.Tensor directly, as required)
            case HNSWLib.Index.add_items(index, vector_tensor, ids: [item_id]) do
              :ok ->
                :mnesia.dirty_write({@id_map_table, item_id, node_id})
                new_count = Map.get(state.insertion_count, model_version, 0) + 1
                new_dirty = MapSet.put(state.dirty_models, model_version)

                if new_count >= @persist_threshold, do: send(self(), :periodic_persist)

                {:reply, :ok, %{state | insertion_count: Map.put(state.insertion_count, model_version, new_count), dirty_models: new_dirty}}

              {:error, reason} ->
                Logger.error("HNSWLib.add_items failed: #{inspect(reason)}")
                {:reply, {:error, :add_failed}, state}
            end
          end
        rescue
          e ->
            Logger.error("VectorRouter Crash on Add: #{inspect(e)}")
            {:reply, {:error, :add_crashed}, state}
        catch
          :exit, reason ->
             Logger.error("VectorRouter NIF Crash (Exit): #{inspect(reason)}")
             {:reply, {:error, :nif_crash}, state}
        end

      _ ->
        {:reply, {:error, :unsupported_model}, state}
    end
  end

  @impl true
  def handle_call({:query, query_vector, model_version, opts}, _from, state) do
    case Map.fetch(state.indices, model_version) do
      {:ok, index} when not is_nil(index) ->
        try do
          k = Keyword.get(opts, :k, 10)
          threshold = Keyword.get(opts, :threshold, 0.0)

          # CRITICAL FIX 4: Pass the Nx.Tensor directly
          query_tensor =
            case Nx.rank(query_vector) do
              1 -> Nx.new_axis(query_vector, 0)
              _ -> query_vector
            end

          # Optimization: Check if index is empty
          current_count = Map.get(state.insertion_count, model_version, 0)

          if current_count == 0 do
             {:reply, {:ok, []}, state}
          else
            # HNSWLib.Index.knn_query expects a 2D Nx.Tensor and returns 1D Nx.Tensors
            case HNSWLib.Index.knn_query(index, query_tensor, k: k) do
              {:ok, labels_tensor, distances_tensor} ->
                # Convert Nx.Tensors to lists
                flat_labels = Nx.to_flat_list(labels_tensor)
                flat_dists = Nx.to_flat_list(distances_tensor)

                results =
                  Enum.zip(flat_labels, flat_dists)
                  # Filter results by threshold here (Assuming score is 1.0 - distance for similarity)
                  |> Enum.filter(fn {_label, dist} -> dist >= threshold end)
                  |> Enum.map(fn {int_id, score} ->
                    case :mnesia.dirty_read(@id_map_table, int_id) do
                      [{_, ^int_id, uuid}] -> {uuid, score}
                      _ -> nil
                    end
                  end)
                  |> Enum.reject(&is_nil/1)

                {:reply, {:ok, results}, state}

              {:error, msg} ->
                if is_binary(msg) and String.contains?(msg, "too small"), do: {:reply, {:ok, []}, state}, else: {:reply, {:error, msg}, state}

              nil ->
                {:reply, {:ok, []}, state}

              other ->
                Logger.error("VectorRouter: Unknown NIF return: #{inspect(other)}")
                {:reply, {:ok, []}, state}
            end
          end
        rescue
          e ->
            Logger.error("VectorRouter Query Crash: #{inspect(e)}")
            {:reply, {:ok, []}, state}
        end

      _ ->
        {:reply, {:ok, []}, state}
    end
  end

  @impl true
  def handle_call(:persist, _from, state) do
    Enum.each(state.indices, fn {model, index} -> save_to_disk(model, index) end)
    {:reply, :ok, %{state | dirty_models: MapSet.new(), insertion_count: Map.new()}}
  end

  @impl true
  def handle_info(:periodic_persist, state) do
    Enum.each(MapSet.to_list(state.dirty_models), fn model ->
      if index = Map.get(state.indices, model) do
        save_to_disk(model, index)
      end
    end)
    Process.send_after(self(), :periodic_persist, @persist_interval)
    {:noreply, %{state | dirty_models: MapSet.new(), insertion_count: Map.new()}}
  end

  # --- Internals ---

  defp init_mnesia do
    nodes = [Node.self()]
    :mnesia.create_table(@id_map_table, [
      attributes: [:int_id, :uuid],
      disc_copies: nodes,
      type: :set
    ])
    :mnesia.wait_for_tables([@id_map_table], 5000)
  end

  defp save_to_disk(model_version, index) do
    path = index_file_path(model_version)
    if index do
      HNSWLib.Index.save_index(index, path)
    end
  end

  defp index_file_path(model_version) do
    File.mkdir_p!(@base_index_dir)
    Path.join(@base_index_dir, "#{String.replace(model_version, "-", "_")}.hnsw.bin")
  end

  # Removed: to_flat_list_sanitized/1 as it is no longer needed.
end
