defmodule CMS.MetaNode do
  @moduledoc """
  Factory for creating Meta-Nodes (nodes about nodes).
  """

  # FIX: Removed unused Edge alias
  alias CMS.Node

  @spec spawn_conflict(String.t(), map()) :: {:ok, CMS.Node.t()}
  def spawn_conflict(description, context_data) do
    head_text = "CONFLICT DETECTED: #{description}"
    data_head = CMS.DataHead.new(head_text)

    payload = %CMS.DataBodyPayload.Object{type: :object, object_type: :conflict_context, data: context_data}
    data_tail = CMS.DataTail.new(1.0, [], ["system", "root"])
    body = CMS.NodeBody.new(data_head, [payload], data_tail)

    {:ok, embedding} = CMS.Tool.Embedder.generate(head_text, "all-MiniLM-L6-v2")
    head = CMS.NodeHead.new(embedding, "all-MiniLM-L6-v2", 0.95)

    provenance = %{source: "CMS.IngestionEngine", method: "dialectical_merge"}
    Node.new(head, body, provenance)
  end
end
