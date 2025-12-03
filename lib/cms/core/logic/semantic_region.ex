defmodule CMS.SemanticRegion do
  @moduledoc """
  Manages Semantic Partitioning logic.

  Nodes are assigned to one of 256 regions based on their semantic embedding.
  """

  @num_regions 256

  @doc """
  Computes the region ID (0-255) for a given embedding and model version.
  """
  @spec compute_region_hash(Nx.Tensor.t(), String.t()) :: integer()
  def compute_region_hash(embedding, model_version) do
    # 1. Flatten embedding to list
    data = Nx.to_flat_list(embedding)

    # 2. Create deterministic seed string
    seed = "#{model_version}:" <> Enum.join(data, ",")

    # 3. Hash and map to region space
    # FIX: Explicitly use @num_regions
    :crypto.hash(:sha256, seed)
    |> :binary.decode_unsigned()
    |> rem(@num_regions)
  end

  @doc """
  Subscribes the current process to the relevant region topics.
  """
  def subscribe(region_id, node_id) do
    Phoenix.PubSub.subscribe(CMS.PubSub, "region:#{region_id}")
    Phoenix.PubSub.subscribe(CMS.PubSub, "node_pulse:#{node_id}")
    Phoenix.PubSub.subscribe(CMS.PubSub, "global:signals")
  end

  @doc """
  Unsubscribes from a region topic (used during Node Migration).
  """
  def unsubscribe(region_id, _node_id) do
    Phoenix.PubSub.unsubscribe(CMS.PubSub, "region:#{region_id}")
  end
end
