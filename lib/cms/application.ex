defmodule CMS.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Core Registries
      {Registry, keys: :unique, name: CMS.NodeRegistry},
      {Registry, keys: :unique, name: CMS.QueryCoordinatorRegistry},

      # 2. Communication Backbone (Cognitive Bus)
      {Phoenix.PubSub, name: CMS.PubSub},

      # 3. Persistence Layer
      CMS.EpochManager,
      CMS.LogAppender,
      CMS.VectorRouter,

      # 4. Learning & Regulation Layer
      CMS.ActivationEngine,
      CMS.DecayManager,
      CMS.ModelDriftManager,
      CMS.HebbianBufferSupervisor,

      # 5. Pipeline & Ingestion
      # REMOVED: CMS.QueryRouter (It is started by CMS.BusPipeline)
      CMS.BusPipeline,
      CMS.IngestionEngine,

      # 6. The Node Population
      CMS.NodeSupervisor
    ]

    opts = [strategy: :one_for_one, name: CMS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
