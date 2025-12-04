defmodule CMS.ModelDriftManager do
  use GenServer
  require Logger

  @moduledoc """
  Monitors and repairs Embedding Model Drift.

  Implements Gap 7.
  Ensures that nodes using obsolete embedding models are identified
  and queued for re-embedding to maintain semantic compatibility.
  """

  # Configuration
  @check_interval :timer.hours(6)

  # Updated to match the ML Bridge default
  @active_model_version "all-MiniLM-L6-v2"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.send_after(self(), :check_for_drift, @check_interval)
    {:ok, %{active_model: @active_model_version}}
  end

  @impl true
  def handle_info(:check_for_drift, state) do
    Logger.info("ModelDriftManager: Scanning active nodes for model version mismatch...")

    # FIX: Select pids (:$1) instead of the whole tuple, and use double quotes for atom
    # Registry pattern: {{key, pid, value}, guards, [result_shape]}
    nodes_checked_count =
      Registry.select(CMS.NodeRegistry, [{{:_, :"$1", :_}, [], [:"$1"]}])
      |> Enum.map(fn pid ->
        check_node(pid, state.active_model)
      end)
      |> length()

    # FIX: Use the variable for observability
    Logger.info("ModelDriftManager: Dispatched checks for #{nodes_checked_count} nodes.")

    Process.send_after(self(), :check_for_drift, @check_interval)
    {:noreply, state}
  end

  defp check_node(pid, active_model) do
    # Asynchronously ask the node for its header info
    Task.start(fn ->
      try do
        # REMEDIATION: Defensive pattern matching to handle nil or invalid returns
        # Previously crashed if call returned nil (KeyError)
        case GenServer.call(pid, :get_head_info, 5000) do
          %CMS.NodeHead{} = node_head ->
            if node_head.embedding_model_version != active_model do
              # Trigger self-repair on the node
              GenServer.cast(pid, {:re_embed_request, active_model})
            end
          _ ->
            :noop # Got nil or unexpected format (e.g., node starting up)
        end
      catch
        :exit, _ -> :noop # Node died
        _, _ -> :noop # Timeout or other error
      end
    end)
  end
end
