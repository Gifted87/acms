defmodule CMS.NodeBody do
  @moduledoc """
  Represents the 'Body' of a CMS Node: The Tripartite Vessel of Truth.

  Contains:
  1. DataHead: The semantic anchor (Natural Language Fact).
  2. DataBody: The structured payload (Polymorphic Evidence).
  3. DataTail: The administrative ledger (Relationships & Provenance).
  """

  @derive {Jason.Encoder, only: [:data_head, :data_body, :data_tail]}
  defstruct [
    :data_head, # %CMS.DataHead{}
    :data_body, # List of %CMS.DataBodyPayload{}
    :data_tail  # %CMS.DataTail{}
  ]

  @type t :: %__MODULE__{
    data_head: any(), # Type defined in next step
    data_body: list(any()), # Type defined in next step
    data_tail: any()  # Type defined in next step
  }

  @spec new(any(), list(any()), any()) :: t()
  def new(head, body_payloads, tail) do
    %__MODULE__{
      data_head: head,
      data_body: body_payloads,
      data_tail: tail
    }
  end
end
