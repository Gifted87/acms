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
    # 1. Generate the ID (Content Addressable Hash)
    node_id = CMS.NodeFactory.derive_content_addressable_id(body, provenance_metadata)

    # 2. WRITE BACK: The ID is the checksum. Update the DataTail.
    updated_tail = %{body.data_tail | checksum: node_id}
    updated_body = %{body | data_tail: updated_tail}

    # 3. Create Antenna
    antenna = CMS.NodeAntenna.new(updated_tail.salience_score)

    {:ok, %__MODULE__{
      id: node_id,
      head: head,
      body: updated_body, # Use the updated body containing the checksum
      antenna: antenna,
      created_at: DateTime.utc_now(),
      last_fired: DateTime.utc_now()
    }}
  end
end
