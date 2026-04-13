import requests
import json
import time
import uuid

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CMS_URL = "http://localhost:4000/api/v1/ingest"
HEADERS = {
    "Content-Type": "application/json",
    "x-agent-id": "root"
}

# ==============================================================================
# DATA: 50 CLEANED UNIQUE FACTS ON ELIXIR/PHOENIX ARCHITECTURE
# ==============================================================================

ELIXIR_ARCHITECTURE_FACTS = [
    # ----------------------------------------
    # 1-10: Core OTP and Process Management
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "The temporary restart strategy for a GenServer means it is never restarted by its Supervisor, making it suitable for transient tasks.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "OTP_Handbook", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Suitable for non-critical processes."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Dynamic Supervisor is used to manage an arbitrary number of children where processes are started and stopped programmatically.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Elixir_Forum", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Manages NodeActors population."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The via tuple mechanism in Registry provides a safe, cluster-aware method for process naming and lookup.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Registry_Docs", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Prevents global registration collisions."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The hibernate_after option allows a GenServer process to automatically swap its state to disk to reduce memory usage during inactivity.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Erlang_Optimization", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Crucial for managing millions of idle processes."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The handle_continue callback enables non-blocking initialization of lengthy tasks immediately after the init function returns.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "GenServer_Docs", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Improves supervisor boot times."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Message passing in the BEAM VM uses a copy-on-write strategy, making it efficient for sending large data structures between processes.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "BEAM_VM_Internals", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Memory is only duplicated upon modification."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The synchronous call function in GenServer blocks the caller and waits for a reply, which is useful for atomic state retrieval.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "GenServer_Best_Practices", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Used for retrieving decay criteria."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The transient restart strategy ensures processes are only restarted if they exit abnormally, not when they are shut down cleanly.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Design_Choice", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Supports the Active Forgetting mechanism."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Phoenix Channels utilize a topic, subtopic, and event structure to route real-time messages to connected clients.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Phoenix_Channels", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Manages global abnormality signal subscriptions."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The one_for_all supervisor strategy restarts all child processes if a single child process in the group fails.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "OTP_Supervisor", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Used for tightly coupled dependencies."}]
    },
    # ----------------------------------------
    # 11-20: Data & Persistence (Mnesia, ETS)
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "Mnesia tables are configured with disc copies to ensure data remains persistent on disk across node reboots.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS.EpochManager", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Essential for the epoch log index."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Vector Router uses Mnesia to map internal integer IDs from the HNSW index to external content-addressable UUIDs.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS.VectorRouter", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Bridges the gap between integer-based ML libraries and UUID systems."}]
    },
    {
        "agent_id": "root",
        "fact_text": "ETS tables provide lock-free, read-only access for the global inhibition factor to avoid bottlenecks.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Erlang_Concurrency", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Optimized for high-frequency reads."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Log Appender buffers JSONL entries in memory before flushing to disk to optimize input-output operations.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS.LogAppender", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Flushes every 50 entries or 1 second."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Temporal Query Engine uses recursive deep map merging to reconstruct historical node states from delta logs.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Chrono_Stack", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Replays partial updates over a base state."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Epoch Manager rotates log files when they reach 100 megabytes or every hour to keep files manageable.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Persistence_Config", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Dual-trigger rotation strategy."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Mnesia dirty read operations are used for high-frequency vector lookups where speed is prioritized over strict transactional consistency.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Mnesia_Optimization", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Bypasses transaction manager overhead."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The hydrate info message triggers a NodeActor to load its full state from the historical logs during a cold boot.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Cold_Boot", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Recovers state after eviction."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The FID Validator enforces strict schemas for polymorphic data payloads, such as requiring valid protocols for link types.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Data_Integrity", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Ensures data consistency during ingestion."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Vector Router employs a clean slate strategy by wiping the index directory on boot to prevent binary corruption.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "CMS_Recovery_Mechanism", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Prevents NIF crashes from bad index files."}]
    },
    # ----------------------------------------
    # 21-30: Communication and API
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "The CMS Web API enforces a strict 10 megabyte body size limit on requests to prevent resource exhaustion.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Security_Audits", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Configured via Plug Parsers."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Web Router uses a safe atom cast utility to prevent Denial of Service attacks caused by dynamic atom creation.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Elixir_Security_Best_Practice", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Whitelists allowed input strings."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Query Router uses GenStage casting to enqueue search queries into the Broadway pipeline without blocking the API response.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Elixir_Pipeline_Flow", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Enables asynchronous processing."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Bus Pipeline notifies the Query Coordinator immediately after a regional broadcast to prevent timeout errors.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "CMS_Bug_Fix_Log", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Avoids 504 gateway timeout errors."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Temporal Query Engine performs historical searches by querying the live vector index first and then reconstructing history for the results.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Query_Mechanism", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Optimization to avoid indexing history separately."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Socket Handler requires a specific token parameter to grant admin permissions for sensitive channel topics.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS.Web.SocketHandler", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Controls access to abnormality signals."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The feedback API endpoint enables anti-Hebbian learning by allowing clients to penalize specific node links.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Learning_Model", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Reduces weights of incorrect associations."}]
    },
    {
        "agent_id": "root",
        "fact_text": "HTTP DELETE requests are restricted to root or system agents to prevent unauthorized eviction of memory units.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Access_Control", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Protects graph topology."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Node Actors use the Jaro Distance string algorithm as a fallback similarity measure when vector embeddings are unavailable.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Resilience", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Prevents crashes during embedding failure."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Embedder tool delegates computation to an external Python FastAPI service to isolate the Elixir runtime from ML crashes.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "ML_Integration_Strategy", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Decouples application logic from heavy compute."}]
    },
    # ----------------------------------------
    # 31-40: Advanced Learning and Control
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "Node Actors check their ID against the incoming query trace to prevent infinite recursive loops during spreading activation.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Activation_Control", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Ensures nodes fire only once per pulse."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Decay Manager evicts nodes that are both hibernating and have a total link weight below 0.1.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "CMS_Forgetting_Model", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Preserves well-connected but dormant nodes."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Activation Engine uses a linear function to increase the inhibition factor as system congestion rises.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Regulation_Model", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Maintains system stability under load."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Node Actors apply a higher metabolic cost to activation if they are in a hibernating state to simulate cognitive effort.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Metabolic_Model", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Discourages recall of trivial, forgotten facts."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Dialectical merging in the Ingestion Engine spawns a MetaNode to explicitly document semantic conflicts between two nodes.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Conflict_Resolution", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Links conflicting nodes via contradiction edges."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Hebbian priming establishes initial semantic connections for a new node based on its top five nearest vector neighbors.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Initial_Association", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Integrates new data into the graph immediately."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Model Drift Manager verifies a node is responsive via a synchronous call before attempting to re-embed it.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "CMS_Drift_Detection", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Avoids casting to dead processes."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Semantic Region IDs are calculated by hashing the embedding vector combined with the model version to prevent collisions.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Partitioning_Logic", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Ensures version separation in the grid."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Dependency edges effectively have an infinite Time To Live, ensuring upstream nodes in a chain remain active.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Reliability_Model", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Bypasses standard decay logic."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Query Coordinator tracks only the top 50 most relevant results to minimize memory usage during high-load queries.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Efficiency_Optimization", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Prevents coordinator overload."}]
    },
    # ----------------------------------------
    # 41-50: Miscellaneous & Corner Cases
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "The Jason Encoder is extended for Nx Tensors to convert binary vector data into standard JSON lists for logging.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Serialization_Layer", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Enables serialization of tensor data."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Node Antenna gain is doubled for highly salient facts to broadcast their activation pulse further into the graph.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Antenna_Design", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Amplifies important signals."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Ingestion Engine uses a high similarity threshold of 0.98 to identify duplicate meanings before triggering conflict resolution.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Conflict_Tuning", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Prevents false positives in conflict detection."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Log Appender converts Node structs into plain maps before JSON serialization to ensure all metadata is preserved.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Serialization_Integrity", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Preserves UUID and creation timestamps."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The health check API for the embedder uses a standard HTTP GET request to verify the availability of the external ML service.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Health_Check", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Ensures vector generation is operational."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Node Actors use asynchronous casting to reinforce links in the Regional Hebbian Buffer to avoid blocking the main process.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Learning_Event", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Buffers link updates for efficiency."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Data Tail constructor automatically normalizes Access Control Lists from nil or lists into a standard map structure.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Data_Struct_Validation", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Prevents null pointer exceptions."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Query Coordinator implements a rapid inhibition check 150 milliseconds after query start to stop runaway searches.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "CMS_Performance_Tuning", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Prevents resource drain."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The abnormality detection logic flags high-scoring activations from low-trust agents as potential anomalies.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Anomaly_Detection", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Alerts operators to suspicious data."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Node Factory excludes dynamic properties like edge lists and salience scores when generating the Content-Addressable ID.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CMS_Identity_Rule", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Ensures ID stability despite neuroplasticity."}]
    }
]

# Ensure the list is exactly 50
if len(ELIXIR_ARCHITECTURE_FACTS) != 50:
    print(f"WARNING: The manual fact list has {len(ELIXIR_ARCHITECTURE_FACTS)} entries. Adjusting to 50...")
    ELIXIR_ARCHITECTURE_FACTS = ELIXIR_ARCHITECTURE_FACTS[:50]
    while len(ELIXIR_ARCHITECTURE_FACTS) < 50:
        filler_num = len(ELIXIR_ARCHITECTURE_FACTS) + 1
        ELIXIR_ARCHITECTURE_FACTS.append({
            "agent_id": "root", "fact_text": f"Filler Detail {filler_num}: Reserved fact to ensure 50 total entries.",
            "acls": {"read": ["public"], "write": ["root"]},
            "provenance": {"source": "System_Filler", "trust_score": 0.8},
            "description_payloads": [{"type": "text", "content": "Placeholder for consistency check."}]
        })

# ==============================================================================
# INJECTION EXECUTION FUNCTIONS
# ==============================================================================

def inject_node(payload, node_number, total_nodes):
    """
    Constructs and sends a single node injection request to the CMS API.
    """
    try:
        response = requests.post(CMS_URL, headers=HEADERS, data=json.dumps(payload), timeout=20)
        
        if response.status_code in [200, 201, 202]:
            response_data = response.json()
            node_id = response_data.get("node_id", "N/A")
            print(f"✅ Node {node_number}/{total_nodes}: Injected successfully. ID: {node_id[:8]}... Status: {response.status_code}")
            return True
        else:
            print(f"❌ Node {node_number}/{total_nodes}: FAILED. Status: {response.status_code}, Reason: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Node {node_number}/{total_nodes}: CRITICAL ERROR. An exception occurred: {e}")
        return False

# ==============================================================================
# MAIN EXECUTION BLOCK
# ==============================================================================

if __name__ == "__main__":
    total_nodes_to_inject = len(ELIXIR_ARCHITECTURE_FACTS)
    print(f"--- Starting batch injection of {total_nodes_to_inject} unique nodes on Elixir Architecture (Cleaned for Embedding) ---")
    
    success_count = 0
    start_time = time.time()
    
    for i, node_payload in enumerate(ELIXIR_ARCHITECTURE_FACTS):
        if inject_node(node_payload, i + 1, total_nodes_to_inject):
            success_count += 1
        time.sleep(0.05)
            
    end_time = time.time()
    
    print("\n--- Batch injection complete ---")
    print(f"Total time taken: {end_time - start_time:.2f} seconds")
    print(f"Total successful injections: {success_count}/{total_nodes_to_inject}")