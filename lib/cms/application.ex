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
      # REMOVED: CMS.VectorRouter (No longer needed in decentralized model)

      # 4. Learning & Regulation Layer
      CMS.ActivationEngine,
      CMS.DecayManager,
      CMS.ModelDriftManager,
      CMS.HebbianBufferSupervisor,

      # 5. Ingestion & Query Services
      CMS.IngestionEngine,
      CMS.BroadcastCoordinator,

      # 6. The Node Population
      CMS.NodeSupervisor,

      {CMS.Web, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: CMS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
