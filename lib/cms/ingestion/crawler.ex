defmodule CMS.Ingestion.Crawler do
  @moduledoc """
  Handles the physical traversal of directories and files, orchestrating the creation
  of the graph hierarchy (Directory -> File Source -> Chunks).
  """

  alias CMS.Ingestion.MimeGuard
  alias CMS.IngestionEngine
  alias CMS.Edge
  alias CMS.NodeSupervisor
  require Logger
  
  @default_ignores [".git", "_build", "deps", ".elixir_ls", "node_modules", ".DS_Store", "priv/data"]

  @doc """
  Traverses a directory at the given path and ingests its structure and content.
  Returns {:ok, root_node_id} on success.
  """
  def crawl(path) do
    cond do
      File.dir?(path) ->
        Logger.info("Crawler: Starting directory traversal at #{path}")
        traverse_dir(path, nil, path, @default_ignores)

      File.exists?(path) ->
        Logger.info("Crawler: Starting single-file ingestion for #{path}")
        ingest_file(path, nil)

      true ->
        Logger.error("Crawler: Path does not exist or is not accessible: #{path}")
        {:error, :not_found}
    end
  end

  defp traverse_dir(path, parent_id, root_path, inherited_patterns) do
    dir_name = Path.basename(path)
    
    # 1. Ingest Directory Node
    case ingest_directory(path, dir_name, parent_id) do
      {:ok, dir_id} ->
        # 2. List contents
        case File.ls(path) do
          {:ok, files} ->
            active_patterns = load_local_patterns(path, inherited_patterns)
            
            files
            |> Enum.reject(fn file -> 
               full_path = Path.join(path, file)
               should_ignore?(file, full_path, root_path, active_patterns)
            end)
            |> Enum.each(fn file ->
              full_path = Path.join(path, file)
              if File.dir?(full_path) do
                 traverse_dir(full_path, dir_id, root_path, active_patterns)
              else
                 ingest_file(full_path, dir_id)
              end
            end)
            {:ok, dir_id}
          {:error, reason} ->
            Logger.error("Failed to list directory #{path}: #{inspect(reason)}")
            {:error, reason}
        end
        
      error -> 
        Logger.error("Failed to ingest directory #{path}: #{inspect(error)}")
        error
    end
  end

  defp ingest_directory(path, name, parent_id) do
    description_payloads = [
      %CMS.DataBodyPayload.Object{
        type: :object, 
        object_type: :directory, 
        data: %{path: path, name: name}
      }
    ]
    
    fact_text = "Directory: #{name}"
    
    provenance = %{source: "CMS.Ingestion.Crawler", type: "directory", path: path}
    
    request = %{
      description_payloads: description_payloads,
      fact_text: fact_text,
      agent_id: "system",
      acls: %{read: ["public"], write: ["system", "root"]},
      provenance: provenance
    }

    case IngestionEngine.ingest(request) do
      {:ok, node_id} ->
        link_parent_child(parent_id, node_id)
        {:ok, node_id}
      {:ok, :ingested_with_conflict_resolution, node_id} ->
        link_parent_child(parent_id, node_id)
        {:ok, node_id}
      err -> err
    end
  end
  
  defp ingest_file(path, parent_id) do
    with :ok <- MimeGuard.check(path),
         {:ok, content} <- File.read(path) do

         Logger.info("Processing file: #{path}")

         filename = Path.basename(path)
         
          # 1. Ingest Source Node with full content
          payloads = [
            %CMS.DataBodyPayload.Text{
              type: :text,
              content: content
            },
            %CMS.DataBodyPayload.Object{
              type: :object,
              object_type: :file_source,
              data: %{filename: filename, path: path, size: byte_size(content)}
            }
          ]
         
         provenance = %{source: "CMS.Ingestion.Crawler", type: "file_source", path: path}
         
         request = %{
            description_payloads: payloads,
            fact_text: "File Source: #{filename}",
            agent_id: "system",
            acls: %{read: ["public"], write: ["system", "root"]},
            provenance: provenance
         }
         
         case IngestionEngine.ingest(request) do
            {:ok, source_id} -> handle_file_ingestion_success(source_id, parent_id, path, content)
            {:ok, :ingested_with_conflict_resolution, source_id} -> handle_file_ingestion_success(source_id, parent_id, path, content)
            _ -> :ignore # Failed to ingest source
         end
    else
      {:error, reason} -> 
        Logger.debug("Skipping file #{path}: #{inspect(reason)}")
        :ignore
    end
  end
  
  defp handle_file_ingestion_success(source_id, parent_id, _path, _content) do
    link_parent_child(parent_id, source_id)
    # File content is now stored directly in the file source node
    # No shredding or chunk creation needed
    :ok
  end


  defp link_parent_child(nil, _child_id), do: :ok
  defp link_parent_child(parent_id, child_id) do
    add_edge(parent_id, child_id, :contains, 1.0)
    add_edge(child_id, parent_id, :inside_of, 1.0)
  end

  defp add_edge(source_id, target_id, type, weight) do
    edge = Edge.new(target_id, type, weight)
    
    case NodeSupervisor.get_node_pid(source_id) do
      nil -> 
        # If node not active (e.g. IngestionEngine created it but didn't start it? It says it spawns...)
        # IngestionEngine does `NodeSupervisor.start_child(node)`.
        # Just in case, we might need to wait or it might be a race condition.
        # Retry once?
        :timer.sleep(50)
        if pid = NodeSupervisor.get_node_pid(source_id) do
           GenServer.cast(pid, {:add_edge, edge})
        else
           Logger.warning("Failed to add edge #{type} from #{source_id} to #{target_id}: Node not active")
        end
      pid ->
        GenServer.cast(pid, {:add_edge, edge})
    end
  end

  defp load_local_patterns(path, inherited_patterns) do
    ignore_file = Path.join(path, ".cmsignore")
    patterns = if File.exists?(ignore_file) do
      Logger.debug("Loading local patterns from #{ignore_file}")
      File.read!(ignore_file)
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    else
      []
    end
    
    all = Enum.uniq(inherited_patterns ++ patterns)
    Logger.debug("Total active patterns for #{path}: #{inspect(all)}")
    all
  end

  defp should_ignore?(name, full_path, root_path, patterns) do
    rel_path = Path.relative_to(full_path, root_path)
    
    res = Enum.any?(patterns, fn pattern ->
      clean_pattern = String.trim_trailing(pattern, "/")
      
      # Match 1: Basename match (e.g. "venv" matches venv/...)
      # Match 2: Relative path match (e.g. "priv/data" matches priv/data/...)
      name == clean_pattern or rel_path == clean_pattern
    end)
    
    if res do
      Logger.debug("IGNORE: #{rel_path} matched a pattern")
    end
    
    res
  end
end
