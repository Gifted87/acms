defmodule CMS.NodeSupervisor do
  use DynamicSupervisor
  require Logger

  @moduledoc """
  Manages the lifecycle of all CMS.NodeActor processes.

  Responsibilities:
  1. Starts NodeActors dynamically upon Ingestion or Cold Boot.
  2. Restarts transient failures.
  3. Provides lookup utilities (PID retrieval).
  """

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Spawns a new NodeActor for the given Node struct.
  """
  @spec start_child(CMS.Node.t()) :: {:ok, pid()} | {:error, any()}
  def start_child(%CMS.Node{} = node) do
    child_spec = %{
      id: node.id, # Not strictly used by DynamicSup, but good practice
      start: {CMS.NodeActor, :start_link, [node]},
      restart: :transient # Restart if crash, but not if normal shutdown (Decay)
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Retrieves the PID of a running NodeActor by its Content-Addressable ID.
  """
  @spec get_node_pid(String.t()) :: pid() | nil
  def get_node_pid(node_id) do
    case Registry.lookup(CMS.NodeRegistry, node_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Returns a list of all active Node PIDs.
  Used by DecayManager and ModelDriftManager.
  """
  def get_all_active_node_pids do
    # Get all PIDs registered in the NodeRegistry
    Registry.select(CMS.NodeRegistry, [{{:_, :"$1", :_}, [], [:"$1"]}])
  end
end
