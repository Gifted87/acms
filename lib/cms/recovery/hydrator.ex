defmodule CMS.Recovery.Hydrator do
  require Logger
  alias CMS.Node
  alias CMS.NodeHead
  alias CMS.NodeBody
  alias CMS.DataHead
  alias CMS.DataTail
  alias CMS.Edge
  alias CMS.NodeAntenna
  alias CMS.NodeSupervisor

  @moduledoc """
  Responsible for "Hydrating" (loading) existing nodes from Epoch Logs into active RAM processes.
  This prevents "Amnesia" after a system restart.
  """

  @epoch_dir "priv/data/epochs"

  @doc """
  Main entry point for hydration. Scans epoch logs and spawns node processes.
  """
  def run do
    Logger.info("HYDRATOR: Beginning Boot Hydration Protocol...")
    
    File.mkdir_p!(@epoch_dir)
    
    files = 
      File.ls!(@epoch_dir)
      |> Enum.filter(&String.ends_with?(&1, ".jsonl"))
      |> Enum.sort()
      |> Enum.map(&Path.join(@epoch_dir, &1))

    if files == [] do
      Logger.info("HYDRATOR: No epoch logs found. Skipping hydration.")
    else
      Logger.info("HYDRATOR: Found #{length(files)} files. Loading nodes...")
      
      nodes_map = load_nodes_from_logs(files)
      
      Logger.info("HYDRATOR: Loaded #{map_size(nodes_map)} nodes from disk. Spawning processes...")
      
      spawn_nodes(nodes_map)
      
      count = Registry.count(CMS.NodeRegistry)
      Logger.info("HYDRATOR: Hydration Complete. Total Active Nodes: #{count}")
    end
    
    :ok
  end

  defp load_nodes_from_logs(files) do
    Enum.reduce(files, %{}, fn path, acc_sys ->
      File.stream!(path)
      |> Stream.map(fn line -> 
        case Jason.decode(line) do
          {:ok, data} -> data
          {:error, _} -> nil
        end
      end)
      |> Enum.reduce(acc_sys, fn 
           %{"entity" => "node", "type" => type, "data" => d}, acc 
             when type in ["node_created", "node_updated"] -> 
               Map.put(acc, d["id"], d)
           _, acc -> acc
         end)
    end)
  end

  defp spawn_nodes(nodes_map) do
    Enum.each(nodes_map, fn {id, node_map} ->
      try do
        node = reconstruct_node(node_map)
        case NodeSupervisor.start_child(node) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> 
            Logger.error("HYDRATOR: Failed to start node #{id}: #{inspect(reason)}")
        end
      rescue
        e -> 
          Logger.error("HYDRATOR: Error reconstructing node #{id}: #{inspect(e)}")
      end
    end)
  end

  defp reconstruct_node(node_map) do
    id = node_map["id"]
    head_map = node_map["head"]
    body_map = node_map["body"]
    tail_map = body_map["data_tail"]
    
    # Reconstruct Head
    emb_raw = head_map["embedding"]
    tensor = 
      if is_map(emb_raw) and Map.has_key?(emb_raw, "data") do
        Nx.tensor(emb_raw["data"])
      else
        Nx.tensor(emb_raw)
      end

    node_head = %NodeHead{
      embedding: tensor,
      embedding_model_version: head_map["embedding_model_version"],
      relevance_threshold: head_map["relevance_threshold"],
      internal_state: String.to_atom(head_map["internal_state"] || "high_energy")
    }

    # Reconstruct Tail & Edges
    edges = Enum.map(tail_map["relationship_metadata"] || [], fn e ->
      %Edge{
        target_node_id: e["target_node_id"],
        type: String.to_atom(e["type"]),
        weight: e["weight"] || 1.0,
        last_used_at: parse_datetime(e["last_used_at"])
      }
    end)

    node_tail = %DataTail{
      salience_score: tail_map["salience_score"] || 1.0,
      relationship_metadata: edges,
      checksum: tail_map["checksum"] || id,
      acls: tail_map["acls"] || %{}
    }

    # Reconstruct Body
    node_body = %NodeBody{
      data_head: %DataHead{fact: body_map["data_head"]["fact"]},
      data_body: body_map["data_body"] || [],
      data_tail: node_tail
    }

    # Reconstruct Antenna
    antenna_map = node_map["antenna"] || %{}
    node_antenna = %NodeAntenna{
      gain: antenna_map["gain"] || 1.0,
      activation_frequency: antenna_map["activation_frequency"] || 1.0,
      signal_modulations: antenna_map["signal_modulations"] || %{}
    }

    %Node{
      id: id,
      head: node_head,
      body: node_body,
      antenna: node_antenna,
      created_at: parse_datetime(node_map["created_at"]),
      last_fired: parse_datetime(node_map["last_fired"])
    }
  end

  defp parse_datetime(nil), do: DateTime.utc_now()
  defp parse_datetime(string) when is_binary(string) do
    case DateTime.from_iso8601(string) do
      {:ok, dt, _offset} -> dt
      _ -> DateTime.utc_now()
    end
  end
  defp parse_datetime(%{"calendar" => _, "day" => _, "hour" => _} = _map) do
    # Handle cases where Jason might have encoded it as a map if not careful, 
    # though usually it's ISO8601.
    DateTime.utc_now() 
  end
  defp parse_datetime(_), do: DateTime.utc_now()
end
