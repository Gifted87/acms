defmodule CMS.TemporalQueryEngine do
  @moduledoc """
  Provides querying capabilities for the immutable history of the CMS.

  Implements Gap 3: Chrono-Stack & Temporal Queries.
  It queries the Mnesia index to find relevant Epoch Logs, then streams those logs
  to reconstruct the state of a node at a specific timestamp.

  CRITICAL PATCH: Uses deep merging to correctly apply partial node updates.
  """

  require Logger
  @table_name :epoch_log_index

  @doc """
  Retrieves the full state of a Node as it existed at `target_time`.
  """
  @spec get_node_state_at_time(String.t(), DateTime.t()) :: {:ok, map()} | {:error, any()} # Returns map as full struct conversion is complex
  def get_node_state_at_time(node_id, target_time) do
    # 1. Find relevant epoch files from Mnesia
    files = find_epoch_files_before(target_time)

    if Enum.empty?(files) do
      {:error, :no_history_found}
    else
      # 2. Reconstruct State
      reconstruct_node(node_id, files, target_time)
    end
  end

  defp find_epoch_files_before(target_time) do
    matcher = :mnesia.transaction(fn ->
      # FIX: Prefixed unused 'id' with underscore
      :mnesia.foldl(fn {_tag, _id, start, _end, path}, acc ->
        if DateTime.compare(start, target_time) != :gt do
          [{start, path} | acc]
        else
          acc
        end
      end, [], @table_name)
    end)

    case matcher do
      {:atomic, result} ->
        # Sort by start_time ascending
        result
        |> Enum.sort_by(fn {start, _} -> start end, DateTime)
        |> Enum.map(fn {_, path} -> path end)
      _ -> []
    end
  end

  defp reconstruct_node(node_id, file_paths, target_time) do
    # Initialize accumulator to nil (meaning node not found yet)
    initial_state = nil

    # Reduce through files (oldest -> newest)
    final_state = Enum.reduce(file_paths, initial_state, fn path, acc_node ->
      if File.exists?(path) do
        File.stream!(path)
        |> Stream.map(&Jason.decode!/1)
        |> Enum.reduce(acc_node, fn entry, curr_node ->
          # Check if this log entry is relevant to our node and time
          if entry["entity"] == "node" and entry["id"] == node_id and Map.has_key?(entry, "data") do
            entry_ts = parse_ts(entry["timestamp"])

            if DateTime.compare(entry_ts, target_time) != :gt do
              apply_event(curr_node, entry)
            else
              curr_node # Skip events after target_time
            end
          else
            curr_node # Skip non-node or non-matching ID entries
          end
        end)
      else
        acc_node # Skip file if not found
      end
    end)

    if final_state do
      Logger.debug("TemporalQueryEngine reconstructed state for #{node_id} at #{DateTime.to_iso8601(target_time)}.")
      {:ok, final_state}
    else
      {:error, :node_not_found_at_timestamp}
    end
  end

  defp parse_ts(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> dt
      _ -> raise "Invalid timestamp format in epoch log: #{iso_string}"
    end
  end

  # --- New Function: Recursive Deep Map Merge ---
  # FIX: Removed @doc attribute for private function
  defp deep_merge_recursive(v1, v2) when is_map(v1) and is_map(v2) do
    Map.merge(v1, v2, fn _key, val1, val2 -> deep_merge_recursive(val1, val2) end)
  end
  defp deep_merge_recursive(_v1, v2), do: v2
  # ----------------------------------------------


  # Event Application Logic (The "Replay")

  # If it's a creation event, the data is the full node map.
  defp apply_event(_curr, %{"type" => "node_created", "data" => data}), do: data

  # --- LOGIC REFACTOR: Use deep merge for updates/migrations ---
  # If it's an update event, the data is either a delta or a full snapshot.
  # We use deep merge to correctly integrate the data, maintaining fields not present in 'data'.
  defp apply_event(curr, %{"type" => type, "data" => data}) when type in ["node_updated", "node_migrated"] do
    if curr != nil do
      # Deep merge the current state with the incoming update/delta map
      deep_merge_recursive(curr, data)
    else
      Logger.warning("TemporalQueryEngine encountered a #{type} event for non-existent node. Ignoring.")
      curr
    end
  end

  # Ignore other events (like hebbian updates which modify state *during* runtime)
  defp apply_event(curr, _), do: curr
end
