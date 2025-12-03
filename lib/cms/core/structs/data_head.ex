defmodule CMS.DataHead do
  @moduledoc """
  Represents the 'Fact' of a CMS Node.

  This is the semantic anchor. It must be a single, declarative natural language sentence.
  The Embedder uses this string to generate the vector representation in the NodeHead.
  """

  @derive {Jason.Encoder, only: [:fact]}
  defstruct [
    :fact # String: e.g., "The Mars Rover detected high levels of perchlorate."
  ]

  @type t :: %__MODULE__{
    fact: String.t()
  }

  @spec new(String.t()) :: t()
  def new(fact) when is_binary(fact) do
    %__MODULE__{fact: fact}
  end
end
