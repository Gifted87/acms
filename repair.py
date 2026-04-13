import os
import re

# Configuration
FILE_PATH = "lib/cms/interface/cms_web.ex"

# The new robust implementation
NEW_CODE_BLOCK = r"""  get "/api/v1/graph/snapshot" do
    limit = 200
    
    # 1. Try fetching Active Memory (RAM/Processes)
    active_pids = CMS.NodeSupervisor.get_all_active_node_pids()
    
    nodes = 
      if Enum.empty?(active_pids) do
        # 2. Fallback: Cold Boot / Long-Term Memory (Disk)
        case CMS.TemporalQueryEngine.get_system_state_at_time(DateTime.utc_now()) do
          {:ok, historical_nodes} -> 
            historical_nodes
            |> Enum.take(limit)
            |> Enum.map(fn node -> 
              %{
                id: node["id"],
                label: String.slice(get_in(node, ["body", "data_head", "fact"]) || "Unknown", 0, 30) <> "..",
                group: get_in(node, ["head", "internal_state"]) || "hibernating",
                edges: get_in(node, ["body", "data_tail", "relationship_metadata"]) || []
              }
            end)
          _ -> []
        end
      else
        # 3. Active Memory Exists
        active_pids
        |> Enum.take(limit)
        |> Enum.map(fn pid -> 
          try do
             # Increased timeout to 2000ms
             GenServer.call(pid, :get_state_snapshot, 2000)
          catch _, _ -> nil end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.map(fn node -> 
           %{
             id: node.id,
             label: String.slice(node.body.data_head.fact, 0, 30) <> "..",
             group: node.head.internal_state,
             edges: node.body.data_tail.relationship_metadata
           }
        end)
      end

    send_json(conn, 200, %{count: length(nodes), nodes: nodes})
  end"""

def apply_patch():
    if not os.path.exists(FILE_PATH):
        print(f"❌ Error: File not found at {FILE_PATH}")
        return

    with open(FILE_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to capture the existing endpoint block.
    # It looks for: get "/api/v1/graph/snapshot" do ... (anything) ... send_json(...) end
    # Using re.DOTALL so (.) matches newlines
    pattern = r'get "/api/v1/graph/snapshot" do.*?send_json\(conn, 200, %{count: length\(nodes\), nodes: nodes}\)\s+end'
    
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        print("✅ Found existing graph snapshot endpoint.")
        new_content = re.sub(pattern, NEW_CODE_BLOCK, content, count=1, flags=re.DOTALL)
        
        with open(FILE_PATH, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print("🚀 Patch applied successfully!")
        print("   - Added Disk Fallback (Cold Boot Support)")
        print("   - Increased Timeout to 2000ms")
        print("\nPlease restart your Elixir server: ./acms.sh or mix phx.server")
    else:
        print("⚠️  Warning: Could not find the specific code block to replace.")
        print("   The file might have already been modified.")

if __name__ == "__main__":
    apply_patch()