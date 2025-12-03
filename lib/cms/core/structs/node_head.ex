defmodule CMS.NodeHead do
  @moduledoc """
  Represents the 'Head' of a CMS Node: The Local Cognitive Engine.

  Responsibilities:
  1. Holds the semantic vector embedding for similarity comparisons.
  2. Manages the 'Metabolic State' (internal_state) which acts as a firing inhibitor.
  3. Tracks the embedding model version to handle Model Drift (Gap 7).
  """

  @derive {Jason.Encoder, only: [:embedding, :embedding_model_version, :relevance_threshold, :internal_state]}
  defstruct [
    :embedding,               # Nx.Tensor: The semantic representation of DataHead.fact
    :embedding_model_version, # String: e.g., "openai_ada_002_v1", "bert_quantized_v4"
    :relevance_threshold,     # Float (0.0 - 1.0): The base confidence required to fire
    :internal_state           # Atom: :high_energy, :low_energy, :hibernating, :recovering
  ]

  @type embedding :: Nx.Tensor.t()
  @type model_version :: String.t()
  @type internal_state :: :high_energy | :low_energy | :hibernating | :recovering

  @type t :: %__MODULE__{
    embedding: embedding(),
    embedding_model_version: model_version(),
    relevance_threshold: float(),
    internal_state: internal_state()
  }

  @doc """
  Creates a new NodeHead with default metabolic energy.
  """
  @spec new(Nx.Tensor.t(), String.t(), float()) :: t()
  def new(embedding, model_version, threshold \\ 0.85) do
    %__MODULE__{
      embedding: embedding,
      embedding_model_version: model_version,
      relevance_threshold: threshold,
      internal_state: :high_energy # New nodes start with high energy (Recent Creation Bias)
    }
  end
end
