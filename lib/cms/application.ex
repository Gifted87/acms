defmodule CMS.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # -1. Guard Entry (The Git-Lock)
    # Critical: Ensures we own the data directory before touching any files.
    :ok = CMS.Infrastructure.InstanceGuard.guard_entry()

    # 0. Bootloader Logic (Synchronous)
    # Checks lock file. If mismatch, PURGES Mnesia/Vectors and Rehydrates from JSONL.
    # Mnesia MUST NOT be running yet, or it would have crashed on schema load.
    :ok = CMS.Persistence.Bootloader.run()
    
    # 1. Start Mnesia (Safe now, either matches current arch or is fresh)
    :mnesia.start()
  
    children = [
      # 0. Infrastructure Guard (Process Monitor for Lock Cleanup)
      CMS.Infrastructure.InstanceGuard,

      # 1. Core Registries
      {Registry, keys: :unique, name: CMS.NodeRegistry},
      {Registry, keys: :unique, name: CMS.QueryCoordinatorRegistry},

      # 2. Communication Backbone (Cognitive Bus)
      {Phoenix.PubSub, name: CMS.PubSub},

      # 3. Persistence Layer
      CMS.EpochManager,
      CMS.LogAppender,
      CMS.VectorRouter, # RESTORED: Centralized Index for K-NN

      # 4. Learning & Regulation Layer
      CMS.ActivationEngine,
      CMS.DecayManager,
      CMS.ModelDriftManager,
      CMS.HebbianBufferSupervisor,

      # 5. Ingestion & Query Services
      {Task.Supervisor, name: CMS.Ingestion.TaskSupervisor},
      CMS.IngestionEngine,
      CMS.BroadcastCoordinator,

      # 6. The Node Population
      CMS.NodeSupervisor,

      {CMS.Web, port: Application.get_env(:acn_cms, :web_port)}
    ]

    opts = [strategy: :one_for_one, name: CMS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
