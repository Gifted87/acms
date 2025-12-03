defmodule CMS.VectorRouter do
  use GenServer
  require Logger

  @moduledoc """
  Manages the Hierarchical Navigable Small Worlds (HNSW) index for vector embeddings.

  CRITICAL PATCH (Gap 7): Now manages a map of HNSW indices, one for each
  embedding model version, preventing cross-model interference.
  """

  # Configuration
  @base_index_dir "priv/data/hnsw_indices" # New base directory for multiple indices
  @dim 384
  @max_elements 100_000
  @persist_interval :timer.minutes(5)
  @persist_threshold 100

  # Placeholder for configurable supported models
  @supported_models ["all-MiniLM-L6-v2", "custom-bert-v1"]

  # --- STRUCT UPDATE ---
  defstruct [
    :indices,           # Map: %{model_version => index_ref}
    :insertion_count,   # Map: %{model_version => count}
    :dirty_models       # MapSet: Tracks models with unpersisted changes
  ]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_embedding(node_id, embedding, model_version) do
    GenServer.call(__MODULE__, {:add, node_id, embedding, model_version})
  end

  @doc """
  Queries the HNSW index for approximate nearest neighbors.
  Options: :k (default 10), :threshold (min similarity score, default 0.0)
  """
  @spec query(Nx.Tensor.t(), String.t(), Keyword.t()) :: {:ok, list({String.t(), float()})} | {:error, any()}
  def query(query_vector, model_version, opts \\ []) do
    GenServer.call(__MODULE__, {:query, query_vector, model_version, opts})
  end

  def persist do
    GenServer.call(__MODULE__, :persist)
  end

  # --- New Helper: Determines the file path for a model's index ---
  defp index_file_path(model_version) do
    File.mkdir_p!(@base_index_dir)
    Path.join(@base_index_dir, "#{String.replace(model_version, "-", "_")}.hnsw.bin")
  end

  # Server Callbacks

  @impl true
  # --- FUNCTION REFACTOR: init/1 to load/create multiple indices ---
  def init(_opts) do
    Logger.info("CMS.VectorRouter: Initializing multi-model HNSW indices.")
    Process.send_after(self(), :periodic_persist, @persist_interval)

    {initial_indices, initial_counts} =
      Enum.map(@supported_models, fn model ->
        case load_index(model) do
          {:ok, index} ->
            Logger.info("HNSW index for '#{model}' loaded from disk.")
            {model, index}
          {:error, :not_found} ->
            Logger.info("Creating new HNSW index for '#{model}'.")
            {:ok, index} = HNSWLib.Index.new(:cosine, @dim, @max_elements)
            {model, index}
          {:error, reason} ->
            Logger.error("Failed to load index for '#{model}': #{inspect(reason)}. Creating new one.")
            {:ok, index} = HNSWLib.Index.new(:cosine, @dim, @max_elements)
            {model, index}
        end
        |> then(fn {m, i} -> {m, i} end)
        |> then(fn {m, i} -> {{m, i}, {m, 0}} end)
      end)
      |> Enum.unzip()

    {:ok, %__MODULE__{
      indices: Map.new(initial_indices),
      insertion_count: Map.new(initial_counts),
      dirty_models: MapSet.new()
    }}
  end

  @impl true
  # --- LOGIC REFACTOR: handle_call({:add, ...}) now uses the correct index ---
  def handle_call({:add, node_id, embedding, model_version}, _from, state) do
    case Map.fetch(state.indices, model_version) do
      {:ok, index} ->
        # HNSWLib expects %Nx.Tensor{}
        item_id = :erlang.phash2(node_id)
        case HNSWLib.Index.add_items(index, embedding, ids: [item_id]) do
          :ok ->
            new_count = Map.get(state.insertion_count, model_version, 0) + 1
            new_dirty_models = MapSet.put(state.dirty_models, model_version)

            if new_count >= @persist_threshold, do: send(self(), :periodic_persist)

            {:reply, :ok, %{state |
              insertion_count: Map.put(state.insertion_count, model_version, new_count),
              dirty_models: new_dirty_models
            }}
          error ->
            {:reply, error, state}
        end

      :error ->
        Logger.warning("VectorRouter: Attempt to add node with unsupported model: #{model_version}")
        {:reply, {:error, :unsupported_model_version}, state}
    end
  end

  @impl true
  # --- LOGIC & ERROR HANDLING REFACTOR: handle_call({:query, ...}) now uses the correct index ---
  def handle_call({:query, query_vector, model_version, opts}, _from, state) do
    case Map.fetch(state.indices, model_version) do
      {:ok, index} ->
        k = Keyword.get(opts, :k, 10)
        threshold = Keyword.get(opts, :threshold, 0.0)

        case HNSWLib.Index.knn_query(index, query_vector, k: k) do
          {:ok, labels, distances} ->
            results =
              Enum.zip(labels, distances)
              |> Enum.filter(fn {_label, score} -> score >= threshold end)
            {:reply, {:ok, results}, state}

          {:error, msg} ->
            # Catch empty index error from the C++ library
            if is_binary(msg) and String.contains?(msg, "too small") do
              {:reply, {:ok, []}, state}
            else
              Logger.error("HNSW Query Failed for model #{model_version}: #{msg}")
              {:reply, {:error, msg}, state}
            end

          error ->
            {:reply, error, state}
        end

      :error ->
        # --- ERROR HANDLING: Return {:ok, []} on unsupported/missing model ---
        Logger.warning("Query received for unsupported/missing model: #{model_version}. Returning empty results.")
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
    # Only persist models that have changes
    Enum.each(MapSet.to_list(state.dirty_models), fn model ->
      if index = Map.get(state.indices, model) do
        save_to_disk(model, index)
      end
    end)
    {:noreply, %{state | dirty_models: MapSet.new(), insertion_count: Map.new()}}
  end

  defp load_index(model_version) do
    path = index_file_path(model_version)
    if File.exists?(path) do
      HNSWLib.Index.load_index(:cosine, @dim, path)
    else
      {:error, :not_found}
    end
  end

  defp save_to_disk(model_version, index) do
    path = index_file_path(model_version)
    Logger.debug("Persisting HNSW index for model '#{model_version}' to #{path}...")
    HNSWLib.Index.save_index(index, path)
  end
end
