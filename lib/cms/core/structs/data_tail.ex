defmodule CMS.DataTail do
  @moduledoc """
  Represents the 'Tail' of a CMS Node: The Administrative Ledger.

  Responsibilities:
  1. Topology: Holds the list of Edges (relationships).
  2. Provenance: Tracks versioning pointers (Chrono Stack).
  3. Security: Holds **Structured ACLs** (Access Control Lists).
  4. Salience: Holds the base importance score (used to initialize Antenna Gain).

  CRITICAL UPDATE (Gap 11/12): ACLs are now a structured map for role-based security.
  """

  alias CMS.Edge

  @derive {Jason.Encoder, only: [:versioning_pointer, :checksum, :acls, :salience_score, :relationship_metadata]}
  defstruct [
    :versioning_pointer,    # String: URI/Ref to previous state (e.g., "gm://node/v1")
    :checksum,              # String: SHA3-256 hash of {DataHead + DataBody}
    :acls,                  # Map: %{read: [String.t()], write: [String.t()]}
    :salience_score,        # Float 0.0 - 1.0: Intrinsic importance
    :relationship_metadata  # List[%CMS.Edge{}]: The outgoing connections
  ]

  # --- TYPE REFACTOR: Updated ACLs to a map ---
  @type acls_t :: %{
    read: [String.t()],    # Agent IDs or Roles that can read the node (e.g., "public", "system")
    write: [String.t()]   # Agent IDs or Roles that can modify the node
  }

  @type t :: %__MODULE__{
    versioning_pointer: String.t() | nil,
    checksum: String.t(),
    acls: acls_t(),
    salience_score: float(),
    relationship_metadata: [CMS.Edge.t()]
  }

  # --- STRUCT UPDATE: New constructor uses structured default ACLs ---
  @doc """
  Creates a new DataTail struct.
  """
  @spec new(float(), [CMS.Edge.t()], acls_t() | [String.t()] | nil, String.t() | nil) :: t()
  def new(salience_score, edges \\ [], acls_input \\ nil, versioning_pointer \\ nil) do
    # Normalize the input ACLs. If a simple list is provided, default it to both read/write roles.
    acls = case acls_input do
      nil ->
        %{read: ["public"], write: ["system", "root"]}
      %{} = map ->
        map
      list when is_list(list) ->
        # Assume if a list of IDs is provided, they have full control
        %{read: list ++ ["public"], write: list}
    end

    %__MODULE__{
      salience_score: salience_score,
      relationship_metadata: edges,
      acls: acls,
      versioning_pointer: versioning_pointer,
      checksum: "" # Checksum is calculated during NodeFactory creation (Step 5)
    }
  end
end
