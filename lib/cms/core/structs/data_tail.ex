defmodule CMS.DataTail do
  @moduledoc """
  Represents the 'Tail' of a CMS Node: The Administrative Ledger.

  Responsibilities:
  1. Topology: Holds the list of Edges (relationships).
  2. Provenance: Tracks versioning pointers (Chrono Stack).
  3. Security: Holds Structured ACLs (Access Control Lists).
  4. Salience: Holds the base importance score.

  CRITICAL REMEDIATION (Fix 3):
  1. Implements Input Normalization for ACLs.
     Accepts nil, Lists, or Maps and converts them all to the standard
     %{read: [], write: []} structure to prevent crashes.
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

  @type acls_t :: %{
    read: [String.t()],    # Agent IDs or Roles that can read the node
    write: [String.t()]    # Agent IDs or Roles that can modify the node
  }

  @type t :: %__MODULE__{
    versioning_pointer: String.t() | nil,
    checksum: String.t(),
    acls: acls_t(),
    salience_score: float(),
    relationship_metadata: [Edge.t()]
  }

  @doc """
  Creates a new DataTail struct.
  Automatically normalizes ACL inputs into the required Map structure.
  """
  @spec new(float(), [Edge.t()], acls_t() | [String.t()] | nil, String.t() | nil) :: t()
  def new(salience_score, edges \\ [], acls_input \\ nil, versioning_pointer \\ nil) do
    # REMEDIATION: Normalize input ACLs to ensure Map structure
    acls = normalize_acls(acls_input)

    %__MODULE__{
      salience_score: salience_score,
      relationship_metadata: edges,
      acls: acls,
      versioning_pointer: versioning_pointer,
      checksum: "" # Checksum is calculated during NodeFactory creation
    }
  end

  # --- Internal Normalization Logic ---

  # Case 1: Nil -> Default Public Access
  defp normalize_acls(nil) do
    %{read: ["public"], write: ["system", "root"]}
  end

  # Case 2: Already a Map -> Pass through
  defp normalize_acls(%{} = map) do
    map
  end

  # Case 3: List -> Assume strict ownership (Read+Write for IDs in list, plus Public Read)
  defp normalize_acls(list) when is_list(list) do
    %{read: list ++ ["public"], write: list}
  end

  # Case 4: Invalid Input -> Fallback to Default Safe Access
  defp normalize_acls(_) do
    %{read: ["public"], write: ["system", "root"]}
  end
end
