defmodule CMS.Node do
  @moduledoc """
  The foundational atom of the Associative Cognitive Memory System.
  """

  @derive {Jason.Encoder, only: [:id, :head, :body, :antenna, :created_at, :last_fired]}
  defstruct [
    :id, :head, :body, :antenna, :created_at, :last_fired
  ]

  @type id :: String.t()
  @type t :: %__MODULE__{
    id: id(),
    head: CMS.NodeHead.t(),
    body: CMS.NodeBody.t(),
    antenna: CMS.NodeAntenna.t(),
    created_at: DateTime.t(),
    last_fired: DateTime.t()
  }

  @spec new(CMS.NodeHead.t(), CMS.NodeBody.t(), map()) :: {:ok, t()} | {:error, any()}
  def new(head, body, provenance_metadata) do
    # Gap 14: Derive ID from content.
    node_id = CMS.NodeFactory.derive_content_addressable_id(body, provenance_metadata)

    # Use the salience score directly to create the antenna
    # (Removed unused initial_gain variable)
    antenna = CMS.NodeAntenna.new(body.data_tail.salience_score)

    {:ok, %__MODULE__{
      id: node_id,
      head: head,
      body: body,
      antenna: antenna,
      created_at: DateTime.utc_now(),
      last_fired: DateTime.utc_now()
    }}
  end
end
