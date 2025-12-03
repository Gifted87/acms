# ACN Standard Associative Cognitive Memory System (CMS)
## Technical Reference Manual & Implementation Guide (Version 2.0)

**Version:** 2.0 (Stable/Architectural)
**Language:** Elixir 1.14+ (OTP 25+)
**Frameworks:** Phoenix PubSub, Broadway, HNSWLib, Mnesia, ETS
**Status:** Architecturally Complete / Vetting Compliant

---

## 1. Executive Summary & System Philosophy

The Associative Cognitive Memory System (CMS) is the foundational "neocortex" of the Autonomous Cognitive Network (ACN). Unlike traditional CRUD databases that store passive rows of data, the CMS is a **Distributed Actor System** where every unit of knowledge (a "Node") is an autonomous, living process capable of independent decision-making, self-regulation, and active association.

This documentation details the implementation of the CMS Version 2.0 architecture. This version specifically addresses the "16 Critical Gaps" identified in previous architectural audits, introducing robust mechanisms for global inhibition, conflict detection, temporal auditability, and bio-mimetic neuroplasticity.

### 1.1 Core Design Principles
1.  **The Actor Model as Cognition:** Every "fact" or "concept" is an isolated Elixir GenServer (`CMS.NodeActor`). This provides fault isolation and massive concurrency.
2.  **Radical Transparency:** Every state change is appended to an immutable Epoch Log. The system can be rewound to any point in time (`CMS.TemporalQueryEngine`).
3.  **Content-Addressability:** A node's ID is a cryptographic hash of its content. If the content changes, the identity changes. This enforces truth integrity.
4.  **Bio-Mimicry:** The system implements metabolic energy, Hebbian learning (neurons that fire together, wire together), and active forgetting (decay).

---

## 2. High-Level Architecture & Supervision Tree

The system is designed as a hierarchical supervision tree (`CMS.Application`), ensuring fault tolerance and orderly startup/shutdown sequences.

### 2.1 The Supervision Strategy (`CMS.Application`)
The application startup sequence is strictly ordered to handle dependencies between the "Nervous System" (PubSub), "Long-Term Memory" (Persistence), and "Active Cognition" (Nodes).

1.  **Registries:** `CMS.NodeRegistry` and `CMS.QueryCoordinatorRegistry` provide unique process naming and lookup capabilities via `Registry.via_tuple/2`.
2.  **Communication Backbone:** `Phoenix.PubSub` is started early to allow components to subscribe to topics immediately upon boot.
3.  **Persistence Layer:** `CMS.EpochManager` (Logs), `CMS.LogAppender`, and `CMS.VectorRouter` (HNSW Indices) are initialized to ensure data can be written and retrieved before any nodes go online.
4.  **Regulation Layer:** `CMS.ActivationEngine` (Global Inhibition) and `CMS.DecayManager` start here to enforce system-wide physics.
5.  **Ingestion & Pipeline:** `CMS.BusPipeline` (Broadway) and `CMS.IngestionEngine` are started to accept external input.
6.  **Node Population:** Finally, `CMS.NodeSupervisor` (DynamicSupervisor) starts, ready to spawn thousands of `CMS.NodeActor` processes.

### 2.2 Semantic Region Partitioning
To prevent broadcast storms in a massive network, the CMS partitions the "Cognitive Bus" into 256 Semantic Regions.

*   **Logic:** `CMS.SemanticRegion.compute_region_hash/2` takes a vector embedding and a model version string. It flattens the vector, seeds it with the model version, hashes it (SHA-256), and takes the modulo 256.
*   **Routing:** A `NodeActor` only subscribes to PubSub topics relevant to its semantic neighborhood (`"region:123"`). This ensures that a query about "Astrophysics" does not wake up nodes related to "Culinary Arts," mimicking the specialized regions of a biological brain.

---

## 3. The Cognitive Atom: Data Structures

The fundamental unit of the CMS is the **Node**, defined in `CMS.Node`. It is a tripartite structure designed to balance linguistic precision, structured data, and graph topology.

### 3.1 The Head (`CMS.NodeHead`)
The "Head" represents the decision-making engine of the node.
*   **Embedding:** A high-dimensional tensor (`Nx.Tensor`) representing the semantic meaning of the node.
*   **Model Version:** Explicitly tracked (e.g., `"all-MiniLM-L6-v2"`) to handle **Model Drift (Gap 7)**. A node knows which AI model generated its understanding of the world.
*   **Metabolic State:** An atom (`:high_energy`, `:low_energy`, `:hibernating`) that acts as a firing inhibitor. A low-energy node requires a stronger stimulus to activate (Gap 13).

### 3.2 The Body (`CMS.NodeBody`)
The "Body" is the vessel of truth. It is divided into:
*   **DataHead:** A single natural language sentence (The "Fact").
*   **DataBody:** A polymorphic list of evidence.
    *   **FID System (Gap 12):** The system uses Format IDs (`CMS.DataBodyPayload`) to distinguish between types of data.
        *   `%Text{}`: Descriptive prose.
        *   `%Code{}`: Executable snippets (tagged with language).
        *   `%Number{}`: Raw sensor data or metrics.
        *   `%Link{}`: URI pointers to external resources.
        *   `%Object{}`: Serialized JSON maps.
    *   **Validation:** `CMS.FIDValidator` ensures strict schema compliance before ingestion.

### 3.3 The Tail (`CMS.DataTail`)
The "Tail" is the administrative ledger.
*   **Relationship Metadata:** A list of `CMS.Edge` structs.
*   **Structured ACLs (Gap 11):** Access Control Lists are maps `%{read: [...], write: [...]}` ensuring granular security.
*   **Salience Score:** A float (0.0-1.0) determining the node's intrinsic importance to the network.

### 3.4 The Antenna (`CMS.NodeAntenna`)
The "Antenna" handles signal modulation **(Gap 10)**.
*   **Gain:** A continuous float (0.0 - 2.0).
*   **Function:** Instead of a binary "shout/whisper," the antenna scales the Time-To-Live (TTL) of outgoing signals. A high-gain antenna allows a pulse to travel further through the network graph.

---

## 4. The Zero-Friction Ingestion Protocol

The `CMS.IngestionEngine` is the gatekeeper of the system. It orchestrates a complex, multi-step process to ensure that new knowledge is validated, secured, and integrated without corruption.

### 4.1 Automated Association (Hebbian Priming)
Upon ingestion, a new node is not isolated. The engine performs **Hebbian Priming**:
1.  It generates an embedding for the new fact.
2.  It queries the `CMS.VectorRouter` for the top 5 nearest semantic neighbors.
3.  It automatically creates `CMS.Edge` structs of type `:semantic` linking the new node to these existing nodes.
*Result:* New knowledge is immediately "wired" into the existing cognitive context.

### 4.2 Conflict Detection & Trust Arbitration (Gap 4)
The system actively prevents duplication and contradiction.
1.  **Vector Scan:** Before insertion, the engine queries the Vector Index with a high threshold (0.98 similarity).
2.  **Conflict Identification:** If a node exists with >98% similarity but a different ID, a conflict is declared.
3.  **Trust-Based Arbitration:** The system compares the `trust_score` (from Provenance) of the new node vs. the existing node.
    *   **Supersedence:** If the new node is significantly more trusted (>0.2 diff), it **supersedes** the old node. The old node receives a `:superseded_by` edge, and the new node receives a `:supersedes` edge.
    *   **Dialectical Merge:** If trust is equal or ambiguous, a **Meta-Node** is spawned. This Meta-Node represents the "Conflict" itself. Both the new and old nodes are linked to the Meta-Node via `:contradicts` edges. This preserves both viewpoints for higher-level reasoning agents to resolve later.

---

## 5. The Cognitive Bus & Back-Pressure

The implementation of the communication bus addresses **Gap 8 (System Stability)** by preventing "Thundering Herd" scenarios.

### 5.1 The Pipeline Topology
The system moves away from raw PubSub broadcasts for queries, utilizing the **Broadway** library.
1.  **Producer (`CMS.QueryRouter`):** Acts as a `GenStage` producer. It buffers incoming queries in a queue.
2.  **Consumer (`CMS.BusPipeline`):** This Broadway module requests events from the producer based on demand. It limits concurrency (e.g., 50 concurrent broadcasts).
3.  **Back-Pressure:** If the system is under load, the Broadway pipeline stops requesting new events. The `QueryRouter` buffer fills up, eventually rejecting new queries rather than crashing the node network.

### 5.2 Broadcast Execution
When `CMS.BusPipeline` processes a message, it extracts the `target_regions` and performs a targeted `Phoenix.PubSub.broadcast` only to those specific topics (e.g., `"region:42"`). This minimizes message serialization overhead and CPU usage on nodes that are semantically irrelevant to the query.

---

## 6. The Active Node Lifecycle (`CMS.NodeActor`)

The `CMS.NodeActor` is the most complex component, implementing the behavior of a single "neuron."

### 6.1 State Hydration (Crash Recovery)
To address the "Amnesia" problem (Gap 2), the `init/1` function of the NodeActor does not just start empty. It schedules a `:hydrate` message.
*   **Logic:** The node calls `CMS.TemporalQueryEngine.get_node_state_at_time/2` for `DateTime.utc_now()`.
*   **Result:** If the node process crashed and restarted, it pulls its last known state from the immutable Epoch Logs, restoring its edges, energy level, and memory.

### 6.2 Spreading Activation & Pulse Logic
The core cognitive mechanic is **Spreading Activation**.
1.  **Incoming Pulse:** A node receives a `{:pulse, payload}` message.
2.  **Cycle Detection (Gap 2):** The payload contains a `trace` (MapSet of visited IDs). If the node's own ID is in the trace, it drops the message immediately to prevent infinite loops.
3.  **Relevance Calculation:** The node calculates its relevance to the query context using Cosine Similarity (`Nx.dot`) and Jaro-Winkler string distance.
4.  **Thresholding:** The `relevance` is compared against a dynamic threshold.
    *   **Metabolic Cost (Gap 13):** If `internal_state` is `:low_energy`, the threshold is multiplied by 1.2. The node is "tired" and refuses to fire for weak signals.
    *   **Global Inhibition (Gap 16):** The threshold is divided by the `CMS.ActivationEngine` global factor. If the system is congested, the factor drops (e.g., 0.5), effectively doubling the required relevance to fire.
5.  **Firing:** If `relevance > threshold`, the node:
    *   Reports to the `CMS.QueryCoordinator`.
    *   Broadcasts a secondary pulse to its neighbors via its **Antenna**.
    *   **Dependency Propagation (Gap 9):** If an edge type is `:dependency`, the TTL is overridden to `:infinity`, ensuring causal chains are fully traced regardless of distance.

### 6.3 Anti-Hebbian Penalization (Gap C)
Nodes can learn from negative feedback.
*   **Trigger:** `handle_cast({:feedback, :irrelevant, ...})`.
*   **Action:** The node identifies links that were active during the flagged context and penalizes their weight (e.g., `weight - 0.1`).
*   **Result:** Over time, irrelevant associations wither away, while useful ones are reinforced via standard Hebbian learning.

---

## 7. Global Regulation & Inhibition

The system implements a "Winner-Takes-Most" mechanism (Gap 1) to prevent Cognitive Overload (Epilepsy).

### 7.1 The Query Coordinator (`CMS.QueryCoordinator`)
Every query spawns a dedicated Coordinator process.
*   **Monitoring:** It tracks how many nodes have fired in response to the query.
*   **Inhibition Trigger:** If `fired_nodes` exceeds `@inhibit_threshold_count` (100), it assumes the query is too broad.
*   **Action:** It broadcasts a high-priority `{:inhibit, query_id}` signal to the target regions.
*   **Effect:** Nodes receiving this signal immediately abort processing for that specific query ID.

### 7.2 The Activation Engine (`CMS.ActivationEngine`)
This module manages system-wide physics.
*   **Congestion Monitoring:** It listens for system stats (CPU, RAM usage).
*   **ETS Table:** It maintains a cached float `@factor` in an ETS table (`:cms_global_inhibition_factor_ets`).
*   **Optimization:** `NodeActor`s read from this ETS table (a microsecond operation) rather than making GenServer calls, ensuring that the inhibition check does not become a bottleneck itself.

---

## 8. Persistence & Memory Layer

The CMS uses a hybrid persistence strategy combining Vector Search, Append-Only Logs, and Mnesia.

### 8.1 Vector Router (HNSW)
The `CMS.VectorRouter` wraps the `HNSWLib` NIF (Native Implemented Function) for high-performance Approximate Nearest Neighbor search.
*   **Multi-Model Support (Gap 7):** The router maintains a Map of indices, keyed by `model_version`. This ensures that embeddings from "OpenAI-Ada-002" are never compared against "BERT-v1" embeddings, which would result in mathematical nonsense.
*   **Persistence:** Indices are flushed to disk (`.hnsw.bin`) every 5 minutes or after 100 insertions.

### 8.2 Immutable History (Epoch Logs)
Data is never overwritten, only appended.
*   **Format:** JSONL (JSON Lines).
*   **Rotation:** `CMS.EpochManager` rotates files hourly or when they hit 100MB.
*   **Mnesia Index:** A local Mnesia database maps time ranges to file paths (e.g., `Start: 12:00, End: 13:00 -> /data/epoch_88.jsonl`).

### 8.3 Temporal Query Engine (Gap 3)
This module provides "Time Travel" for data.
*   **Function:** `get_node_state_at_time(node_id, timestamp)`.
*   **Mechanism:**
    1.  Queries Mnesia to find the relevant Epoch Logs.
    2.  Streams the logs from oldest to newest.
    3.  Replays `node_created` and `node_updated` events.
    4.  Stops replay when the timestamp is reached.
    5.  **Deep Merge:** It uses a recursive deep merge strategy to apply partial updates (deltas) correctly to the reconstructed state.

---

## 9. Learning & Neuroplasticity

Learning in CMS Version 2.0 is continuous and asynchronous.

### 9.1 Sharded Hebbian Buffers (Gap 5)
Link weights change frequently (every time a node fires). Writing to disk for every fire is impossible.
*   **Sharding:** `CMS.HebbianBufferSupervisor` starts 32 `CMS.RegionalHebbianBuffer` processes.
*   **Routing:** Updates are routed to a shard based on the node's region ID.
*   **Aggregation:** Each shard uses a private ETS table to accumulate weight deltas (`+0.05`, `-0.01`).
*   **Flushing:** Every 5 seconds, the buffer is drained, aggregated, and written to the `LogAppender` as a single batch operation.

### 9.2 Model Drift Management
Machine Learning models evolve. The `CMS.ModelDriftManager` (Gap 7) ensures the CMS keeps up.
*   **Drift Check:** Periodically scans active nodes to check if their `embedding_model_version` matches the system's `@active_model`.
*   **Remediation:** If a mismatch is found, it triggers a background `Task`. The task calls `CMS.Tool.Embedder` to generate a fresh embedding for the node's text using the new model.
*   **Audit:** The update is logged as a `node_updated` event, preserving the history that the node once "thought" in an older embedding space.

---

## 10. Node Migration & Topology Repair

As a node's embedding changes (due to Model Drift remediation or manual editing), its semantic coordinates change.
*   **Problem:** A node might technically belong to Region 5, but currently resides in Region 2. Queries to Region 5 will miss it.
*   **Solution (Gap 11):** `CMS.NodeDriftManager` calculates the correct region hash.
*   **Migration:** If `current_region != correct_region`:
    1.  Unsubscribes the node from the old PubSub topic.
    2.  Subscribes it to the new topic.
    3.  Logs a `node_migrated` event.
    4.  Updates the internal state of the `NodeActor`.

---

## 11. Security & Access Control

The system implements "Defense in Depth."

### 11.1 Structured ACLs
The `CMS.DataTail` contains an `acls` map:
```elixir
%{
  read: ["public", "agent_007"],
  write: ["root", "system_admin"]
}
```

### 11.2 Enforcement Points
1.  **Ingestion:** `CMS.IngestionEngine` checks `Security.can_write?` before accepting a new node.
2.  **Query Processing:** `CMS.NodeActor` checks `Security.can_read?` inside the spreading activation loop. Even if a node is highly relevant (high vector similarity), it **will not fire** if the querying agent lacks read permissions.

---

## 12. Codebase Directory Structure

```text
/cms
  ├── application.ex             # Application entry point & Supervision tree
  ├── cms.ex                     # Main interface
  ├── /core
  │   ├── node.ex                # Main Node Struct
  │   ├── /structs
  │   │   ├── node_head.ex       # Embedding & State
  │   │   ├── node_body.ex       # Payload container
  │   │   ├── node_antenna.ex    # Signal modulation
  │   │   ├── data_head.ex       # Fact string
  │   │   ├── data_tail.ex       # Metadata & ACLs
  │   │   ├── edge.ex            # Graph links
  │   │   └── data_body_payload.ex # Polymorphic FIDs
  │   └── /logic
  │       ├── node_factory.ex    # ID Generation (CAM)
  │       ├── fid_validator.ex   # Ingestion Validation
  │       ├── fid_parser.ex      # Consumption Parsing
  │       ├── salience_engine.ex # Importance Calculation
  │       └── semantic_region.ex # Partitioning Logic
  ├── /agents
  │   ├── node_actor.ex          # The "Neuron" (GenServer)
  │   ├── ingestion_engine.ex    # Entry Point (GenServer)
  │   ├── query_coordinator.ex   # WTM Orchestrator
  │   └── meta_node.ex           # Conflict Resolution Factory
  ├── /services
  │   ├── node_supervisor.ex     # Dynamic Supervisor
  │   ├── activation_engine.ex   # Global Inhibition
  │   ├── decay_manager.ex       # Active Forgetting
  │   ├── node_drift_manager.ex  # Topology Repair
  │   └── security.ex            # ACL Logic
  ├── /infrastructure
  │   ├── /communication
  │   │   ├── bus_pipeline.ex    # Broadway Pipeline
  │   │   └── query_router.ex    # GenStage Producer
  │   └── /persistence
  │       ├── vector_router.ex   # HNSW Manager
  │       ├── epoch_manager.ex   # Log Rotation
  │       ├── log_appender.ex    # High-throughput Logger
  │       └── temporal_query_engine.ex # Time Travel
  ├── /learning
  │   ├── regional_hebbian_buffer.ex # Sharded Learning
  │   ├── hebbian_buffer_supervisor.ex # Learning Supervisor
  │   └── model_drift_manager.ex # Embedding Updates
  └── /tools
      └── embedder.ex            # ML Bridge Client
```

---

## 13. Operational Considerations

### 13.1 Deployment Requirements
*   **Erlang/OTP:** Version 25+ is required for the latest GenServer optimizations.
*   **Disk I/O:** The `priv/data` directory must be mounted on high-IOPS storage (SSD) to support HNSW paging and Epoch Log appending.
*   **ML Bridge:** A companion Python/FastAPI service must be running at `http://localhost:5000` to handle embedding generation (`CMS.Tool.Embedder`).

### 13.2 Monitoring & Telemetry
Key metrics to monitor via Telemetry/Phoenix Dashboard:
*   **`CMS.BusPipeline` Queue Length:** Indicates ingestion back-pressure.
*   **`hebbian_buffer` Flush Sizes:** Indicates learning rate.
*   **ETS Inhibition Factor:** Monitor `:cms_global_inhibition_factor_ets` to see if the system is throttling itself due to congestion.
*   **Node Count:** Total active processes under `CMS.NodeSupervisor`.

---

## 14. Conclusion

The CMS Version 2.0 codebase represents a significant leap forward in cognitive architecture. By strictly adhering to the "16 Gaps" remediation plan, it delivers a system that is not only "smart" (via embeddings and associations) but also **stable** (via inhibition and back-pressure), **auditable** (via temporal logs), and **resilient** (via hydration and drift management).

This documentation serves as the primary reference for the initial build and future maintenance of the Autonomous Cognitive Network's memory substrate.
