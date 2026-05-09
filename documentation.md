Here are Chapters 1 through 5 of the Associative Cognitive Memory System (ACMS) documentation. This guide provides an exhaustive, code-deep exploration of the system's paradigms, bootstrapping processes, architecture, data structures, and sensory ingestion pipelines, spanning over 3,000 words.

---

# 🧠 Associative Cognitive Memory System (ACMS) Documentation

## 1. Introduction: Paradigm Shift

### 1.1. Executive Summary
The Associative Cognitive Memory System (ACMS) is not a database; it is a bio-mimetic memory grid. 

In the modern landscape of Artificial Intelligence, multi-agent systems and long-running autonomous agents are bottlenecked by the context window. When a human developer builds a massive codebase, they do not hold every file in their working memory simultaneously. Instead, human cognition relies on what to surface at the precise moment it is needed. 

Standard retrieval-augmented generation (RAG) relies on text search (keyword matching) or k-Nearest Neighbors (k-NN) vector search (semantic similarity). However, human memory retrieves context through *association*. If an agent thinks about a "dashboard front-end", a vector database will return other front-end files. But an associative memory will return the *authentication API* that the dashboard relies on—not because it is semantically similar, but because the two concepts are historically and functionally connected. ACMS solves the "unknown unknowns" problem by allowing context to ripple through a graph of associative links, surfacing what an agent needs even when it doesn't explicitly know to ask for it.

### 1.2. The Biological Metaphor
ACMS is built around three core biological principles modeled directly in the Elixir codebase:

1. **Spreading Activation:** Memory recall does not stop at a single node. In ACMS, a query acts as an energy pulse. When a node's relevance surpasses its activation threshold (`relevance_threshold`), it "fires," sending secondary pulses across its Synapses (`CMS.Edge`) to neighbor nodes. This creates a cascading chain of associative retrieval.
2. **Hebbian Learning ("Fire together, wire together"):** The memory topology is not static. It is neuroplastic. If an agent retrieves Node A and Node B together, or explicitly sends positive feedback to a link, the system utilizes a sharded `CMS.RegionalHebbianBuffer` to increase the synaptic weight between those two ideas. 
3. **Active Forgetting:** To prevent the cognitive grid from becoming a sluggish swamp of infinite, irrelevant context, the `CMS.DecayManager` periodically enforces "Differential Decay." Links that are unused degrade over time. Nodes that drop into a `:hibernating` state with low link weights are actively evicted from RAM and permanently archived.

### 1.3. Core Philosophies
* **The "Cognitive Swamp" to Active Cortex Pipeline:** Raw data starts as a swamp (files, blobs, API outputs). ACMS ingests, shreds, semantically evaluates, and promotes this data into the active, high-energy Cortex (RAM-backed GenServers).
* **Infrastructure Sovereignty:** Memory is encapsulated in self-contained directories known as "Memory Cartridges" (`memory_cartridges/`). An agent’s entire brain can be zipped, moved, and booted on another machine. 
* **Radical Transparency (Chrono-Stack):** The system does not silently overwrite states. The `CMS.EpochManager` and `CMS.LogAppender` enforce an immutable JSONL append-only log. Every state change, conflict, or decay event is recorded, allowing for absolute time-travel and temporal queries.

### 1.4. Glossary of Terms
* **Node (`CMS.Node`):** The atomic unit of thought. Represented as a highly concurrent Erlang process (`NodeActor`).
* **FID (Format ID):** A polymorphic data structure defining the payload of a thought (e.g., Text, Code, Number, Link, Object).
* **HNSW:** Hierarchical Navigable Small Worlds. The underlying C++ vector indexing algorithm used by `CMS.VectorRouter` for initial semantic similarity lookups.
* **WTM (Winner-Takes-Most):** The inhibition mechanism utilized by the `CMS.QueryCoordinator` to prevent a query from activating the entire brain and causing cognitive overload.
* **Hebbian Priming:** The act of immediately linking a newly ingested Node to its semantic neighbors during the initial ingestion phase.

---

## 2. Getting Started & Quickstart

### 2.1. System Prerequisites
Because ACMS leverages a hybrid architecture—using the BEAM VM for massive concurrency and fault tolerance, and Python for heavy Machine Learning computations—you must satisfy the following system requirements:
* **Elixir** (v1.14 or higher)
* **Erlang/OTP** (v25 or higher)
* **Python** (v3.10 or higher) with `python3-venv` support.

### 2.2. Installation Scripts
The system provides native bash scripts to streamline the setup of the complex environment. 

Clone the repository and prepare the system:
```bash
git clone https://github.com/Gifted87/acms.git
cd acms
```

To install Erlang and Elixir dependencies, the codebase includes a robust `install.sh` script that automatically detects your OS architecture (Darwin ARM64, Linux AMD64, etc.) and fetches the pre-compiled OTP binaries. Alternatively, you can use system package managers:
```bash
sudo apt update
sudo apt install elixir erlang python3-venv -y
mix deps.get && mix compile
```

### 2.3. Bootstrapping the ML Bridge (Python FastAPI)
The BEAM is not optimized for dense matrix multiplications required by transformer models. To prevent ML faults from crashing the memory grid, ACMS isolates the embedding and salience logic in a Python microservice (`ml_bridge.py`).

Set up the virtual environment and install dependencies:
```bash
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sentence-transformers torch
```

Launch the ML Bridge. The bridge utilizes the `all-MiniLM-L6-v2` model to encode text into 384-dimensional vectors. It will expose endpoints on `localhost:5000`.
```bash
python ml_bridge.py
```

### 2.4. Configuration & Environment
Runtime configuration is strictly managed by `config/runtime.exs`. At boot time, this file bridges OS variables to the BEAM. 
Key environment variables include:
* `ACMS_DATA_DIR`: Defines the path to the memory cartridge. Defaults to `priv/data`.
* `ACMS_PORT`: The REST API port. Defaults to `4000`.
* `ACMS_NODE_NAME`: Names the Erlang cluster node.

### 2.5. Launching the Cortex
To start the Elixir brain, run the provided ACMS Portability Loader:
```bash
./acms.sh my_agent_brain 4000
```
*Behind the scenes:* This script generates the memory cartridge directory (`memory_cartridges/my_agent_brain`), binds the `NODE_ID` strictly to the local loopback (`my_agent_brain@127.0.0.1`) to prevent accidental LAN cluster meshing, and launches the application via Interactive Elixir (`iex -S mix`).

### 2.6. Hello World: Your First Agentic Thought
With both `ml_bridge.py` and `acms.sh` running, open a new terminal and inject a thought into the active memory using the universal `/api/v1/ingest` REST endpoint:

```bash
curl -X POST http://localhost:4000/api/v1/ingest \
  -H "Content-Type: application/json" \
  -H "x-agent-id: root" \
  -d '{
    "agent_id": "root",
    "fact_text": "ACMS uses a bio-mimetic Spreading Activation model.",
    "description_payloads": [
      {
        "type": "text",
        "content": "This retrieves context via synaptic associations."
      }
    ]
  }'
```
You will receive an HTTP `201 Created` with a deterministic Content-Addressable `node_id`. The memory is now alive, vectorized, and actively participating in the grid.

---

## 3. High-Level Architecture (The Supervision Tree)

### 3.1. The BEAM Advantage
ACMS abandons traditional monolithic database architectures in favor of the Actor Model. Every single memory node in the system is a living, isolated Erlang process (GenServer). This means 100,000 memories equal 100,000 independent micro-processes concurrently analyzing queries, mutating their own synaptic weights, and deciding when to decay. If one memory node crashes due to a corrupt payload, it dies in isolation and is instantly resurrected by its Supervisor, leaving the rest of the brain completely unaffected.

### 3.2. CMS.Application Boot Sequence
The system initializes via `CMS.Application.start/2`. The boot sequence is strictly deterministic to prevent data corruption.

**Step -1: The Guard Entry**
Before any application logic runs, the system synchronously invokes `CMS.Infrastructure.InstanceGuard.guard_entry()`. It attempts to write the system's PID to a `running.pid` file in the Memory Cartridge. If another instance is currently holding this lock, the startup aborts immediately. This "Git-Lock" ensures isolated cartridge sovereignty.

**Step 0: The Bootloader**
`CMS.Persistence.Bootloader.run()` executes next. It reads the `identity.lock` file to verify the machine's architecture and node name match the data on disk. If an "Alien Data" mismatch is detected (e.g., the cartridge was moved from an ARM64 Mac to an AMD64 Linux server), it automatically triggers the `Rehydrator` (The Scorched Earth Protocol), purging the Mnesia schema and rebuilding the entire graph perfectly from the immutable JSONL Epoch logs. 

Only after the Bootloader verifies system integrity does `:mnesia.start()` execute.

### 3.3. The 6-Layer Architecture
Once integrity is confirmed, the main Supervision Tree (`CMS.Supervisor`) spawns the 6 core layers of the brain:

* **Layer 0: Infrastructure Guard.** `CMS.Infrastructure.InstanceGuard` stays alive as a process monitor to clean up locks upon shutdown.
* **Layer 1: Core Registries.** `CMS.NodeRegistry` (tracking the UUID-to-PID mapping of memories) and `CMS.PubSub` (The Cognitive Bus) are initialized.
* **Layer 2: Persistence Layer.** `CMS.EpochManager` begins managing the rolling JSONL append-only logs. `CMS.LogAppender` prepares memory buffers. `CMS.VectorRouter` boots up the C++ `hnswlib` vector indices.
* **Layer 3: Learning & Regulation Layer.** The `CMS.ActivationEngine` boots to monitor system congestion. `CMS.DecayManager` begins its active forgetting loops. `CMS.ModelDriftManager` prepares to audit obsolete ML vectors. `CMS.HebbianBufferSupervisor` spawns 32 ETS-backed shards for concurrent synapse weight updates.
* **Layer 4: Ingestion & Query Services.** `CMS.IngestionEngine` acts as the gatekeeper for new data. `CMS.BroadcastCoordinator` stands by to disperse queries globally.
* **Layer 5: The Node Population.** `CMS.NodeSupervisor` (a `DynamicSupervisor`) initializes to hold the hundreds of thousands of dynamic `NodeActor` processes.

Following successful supervision tree initialization, the final step is **Post-Boot Hydration**. `CMS.Recovery.Hydrator.run()` reads the most recent state from the Epoch Logs and spawns a living `NodeActor` for every piece of valid memory, restoring the system's consciousness.

---

## 4. Anatomy of Cognition (Data Structures)

### 4.1. The Content-Addressable Identity
In ACMS, memories are not tracked by auto-incrementing SQL integers. They are Content-Addressable. The identity of a memory is derived purely from its "truth."

`CMS.NodeFactory.derive_content_addressable_id/2` executes a deterministic SHA-256 hash across the canonical JSON representation of the memory's semantic fact and payload. 
Crucially, the identity generation *excludes* the node's relationships (Edges) and Salience scores. This ensures that while the memory's associative links can mutate and evolve over time (Neuroplasticity), the fundamental identity of the fact remains stable.

### 4.2. The Atomic Unit: `CMS.Node`
A full memory in the system is represented by the `CMS.Node` struct. It is composed of three primary nested structures: The Head, the Body, and the Antenna. 

### 4.3. The Tripartite Vessel of Truth (`CMS.NodeBody`)
The Body holds the actual data, divided into three specialized segments:

1. **`DataHead` (The Semantic Anchor):** Contains a single string field `fact` (e.g., *"The Mars Rover detected high levels of perchlorate."*). This is the only text sent to the ML Bridge for vector embedding.
2. **`DataBody` (Polymorphic Evidence):** Contains a list of `CMS.DataBodyPayload` structs representing the evidence behind the fact. Implementing the Format ID (FID) protocol, this allows consuming agents to deterministically parse payloads without guessing the data type. Supported types include:
    * `Text`: Standard contextual paragraphs.
    * `Code`: Includes an atom `:language` defining the syntax (e.g., `:elixir`, `:python`) and the string content.
    * `Number`: Contains a float `:value` and an optional atom `:unit`.
    * `Link`: Contains a validated HTTP/IPFS `:uri` and description.
    * `Object`: A raw map for complex agent metadata (e.g., JSON configurations).
3. **`DataTail` (The Administrative Ledger):** Handles metadata, provenance, and topology.
    * `relationship_metadata`: A list of outgoing `CMS.Edge` structs defining what this node is connected to.
    * `acls`: Access Control Lists defining strictly which Agent Roles can read or write this memory.
    * `checksum`: The SHA-256 node ID proof.
    * `salience_score`: A float (0.0 to 1.0) defining intrinsic importance.

### 4.4. The Cognitive Engine (`CMS.NodeHead`)
The Head is the local intelligence of the memory process. 
* `embedding`: An `Nx.Tensor` binary structure holding the 384-dimensional vector.
* `relevance_threshold`: The customized minimum score (e.g., `0.3`) this specific node requires to consider a query relevant.
* `internal_state`: The node's metabolic state. Memories are born `:high_energy`. Based on their hit rate, they decay to `:low_energy`, drop to `:hibernating` (costing more computational "energy" to recall), or return to `:recovering` when pinged.
* `embedding_model_version`: Used by the `ModelDriftManager` to identify if the node's vector was generated by an outdated ML model.

### 4.5. Synaptic Transceivers (`CMS.NodeAntenna`)
The Antenna dictates how loudly a memory shouts when it is retrieved.
When a Node fires, its `gain` (a float between 0.0 and 2.0) determines the Time-To-Live (TTL) of the secondary spreading activation pulses. The initial gain is derived mathematically from the node's Salience Score (`salience_score * 2.0`). The Antenna also tracks the `activation_frequency`, which the Decay Manager reads to evaluate the node's usefulness.

### 4.6. Graph Topology (`CMS.Edge`)
Associations between memories are modeled via `CMS.Edge`. 
An Edge contains:
* `target_node_id`: The destination Node's ID.
* `weight`: The Hebbian strength of the link (clamped between 0.01 and 1.0).
* `last_used_at`: Timestamp dictating the link's degradation curve over time.
* `type`: An explicit typing system identifying the nature of the association (`:semantic`, `:dependency`, `:contradicts`, `:causes`). Explicit link typing prevents cognitive hallucination by clarifying *why* two ideas are connected.

---

## 5. Sensory Input: The Ingestion Pipeline

### 5.1. The Zero-Friction Protocol
Data enters the system primarily through the `CMS.IngestionEngine`, the Gatekeeper of the cortex. Agents or users push semi-structured knowledge via REST APIs. The engine is responsible for validating, vectorizing, arbitrating conflicts, and permanently persisting new thoughts. 

### 5.2. Crawling the Cognitive Swamp
ACMS includes a built-in `CMS.Ingestion.Crawler` capable of ingesting entire codebases or folder structures autonomously. 

When `Crawler.crawl/1` is pointed at a directory, it spawns an orchestrated task that recursively traverses the file tree. It builds a hierarchical graph in memory: creating a "Directory Node", which holds "File Source Nodes" via `:contains` and `:inside_of` edges.

During traversal, it respects `.cmsignore` patterns (ignoring `.git`, `node_modules`, etc.). Critically, it utilizes `CMS.Ingestion.MimeGuard` to ensure safety. `MimeGuard.check/1` validates the extension against an allowlist and actively scans the first 1024 bytes of the file for null byte characters (`<<0>>`). If a null byte is detected, the file is rejected as binary, preventing corrupted tensor generation and database bloat.

### 5.3. The Shredder Mechanism
Raw files are rarely small enough for an ML model's token limit. The `CMS.Ingestion.Shredder` module intelligently slices input into semantically viable chunks.

* **Text Strategy:** Applies a sliding window approach with parameters set to a target of 3,000 characters and a 10% overlap (`@text_target_size 3000`, `@text_overlap_ratio 0.1`). The overlap ensures context is not arbitrarily chopped mid-sentence.
* **Code Strategy:** Because cutting code arbitrarily destroys logical flow, the Shredder switches heuristics. It targets chunks of 150 lines, overlapping by 5 lines (`@code_target_lines 150`, `@code_overlap_lines 5`), ensuring classes and function blocks remain contextually bound across multiple chunks.

### 5.4. SalienceEngine: Judging Importance
Not all data is equal. A warning log is more critical than a CSS comment. During ingestion, the `CMS.SalienceEngine` evaluates the text and provenance metadata to calculate a `salience_score`.

1. It attempts to call the Python ML Bridge via `/api/v1/salience`. The bridge performs a Zero-Shot semantic cosine similarity match against pre-computed anchors (e.g., "Critical system failure", "Fatal error exception").
2. If the Python bridge is unreachable, the system executes a lightning-fast heuristic fallback (`calculate_heuristic/2`). It checks the text for `@critical_keywords` (e.g., `error`, `panic`, `deadlock`), assigning a high baseline (0.9), while factoring in explicit agent priorities.

### 5.5. Integration Mechanics

When the `IngestionEngine` receives a valid payload, it triggers two complex routines to physically bind the new thought into the existing graph: Hebbian Priming and Conflict Arbitration.

#### Hebbian Priming (Scatter-Gather)
A memory is useless if it has no connections. Before finalization, `IngestionEngine.prime_initial_edges/2` uses `Task.async_stream` to perform a highly concurrent scatter-gather search across all active PIDs in the `NodeSupervisor`. 
It calculates the cosine similarity between the incoming vector and all existing memories. Any memory exhibiting a similarity score greater than the `@min_associative_score` (0.4) is immediately bound to the new node via a `:semantic` edge. This ensures the new thought instantly integrates into the relevant neighborhood of the graph.

#### Conflict Detection & Arbitration
The system must not retain duplicate truths or conflicting instructions without resolution. 
If the Ingestion Engine detects an existing node with an exceptionally high semantic similarity (`@conflict_similarity_threshold` of 0.85), it enters the Conflict Arbitration phase.

The Engine retrieves the trust score of the existing node versus the incoming node. 
* **Trust Supersedence:** If the incoming node's trust score is drastically higher (`> 0.2` difference), the new node wins. The old node receives a `:superseded_by` edge, and the new node inherits its links via a `:supersedes` edge, effectively deprecating the outdated thought.
* **Dialectical Merge:** If the trust scores are ambiguous or similar, ACMS refuses to delete either. Instead, it delegates to `CMS.MetaNode.spawn_conflict/2`. It generates a completely new "Meta-Node" (a thought about a thought) titled *"CONFLICT DETECTED: Semantic Conflict Detected"*. The system then wires the two conflicting nodes together using `:contradicts` edges, and attaches them both to the Meta-Node. When an Agent later queries the topic, the graph will surface both opinions and explicitly alert the Agent to the contradiction, mirroring human dialectical reasoning. 

Once Integration is complete, the memory is permanently logged to the Epoch JSONL file via `CMS.LogAppender`, and an active `CMS.NodeActor` process is spawned into the BEAM RAM, officially awakening the memory.

## 6. Recall: Spreading Activation & Search

### 6.1. The Decentralized Query
Traditional database architectures rely on a centralized index to find information. ACMS flips this paradigm on its head. In ACMS, the query does not search the data; the query is broadcast to the data, and the data searches itself. 

When an agent issues a query via the REST API (`POST /api/v1/query`), the `CMS.Web.Router` converts the natural language query into a 384-dimensional semantic vector using the ML Bridge. Instead of relying solely on the centralized `CMS.VectorRouter` (which acts mainly as a fallback and bootstrapping index), the system utilizes a **Decentralized Query Model** managed by the `CMS.BroadcastCoordinator`. 

The `BroadcastCoordinator` retrieves the PIDs of every single active memory node in the `NodeSupervisor` and transmits a `{:query, query_context}` message directly to them. Thousands of isolated Erlang micro-processes receive this query simultaneously.

### 6.2. The Cognitive Bus (`CMS.BusPipeline`)
For high-throughput environments, broadcasting to hundreds of thousands of nodes requires strict back-pressure to prevent Out-Of-Memory (OOM) crashes on the BEAM VM. 

ACMS implements the "Cognitive Bus" using Elixir’s **Broadway** library (`CMS.BusPipeline`). 
1. The `CMS.QueryRouter` acts as a `GenStage` Producer, queueing incoming queries.
2. The Broadway pipeline consumes these queries, utilizing concurrent batch processors (`concurrency: 50`, `max_demand: 10`).
3. The pipeline pushes the queries over Elixir’s `Phoenix.PubSub` layer, routing them to specific Semantic Regions (`region:0` to `region:255`). Every Node is subscribed to its respective Semantic Region topic, ensuring highly efficient multiplexing of network signals.

### 6.3. Autonomous Node Firing (`CMS.NodeActor`)
When a `NodeActor` receives a query pulse, it executes `autonomous_query_evaluation/2`. 
The Node independently calculates the cosine similarity between its own `NodeHead.embedding` and the incoming `query_vector`. It then compares this relevance score against its dynamic threshold.

The firing threshold is not static. It is calculated dynamically:
`adjusted_threshold = (base_threshold / max(0.1, inhibit_factor)) * metabolic_cost`

* If the node is `:hibernating`, its metabolic cost is 1.5x, meaning it requires an exceptionally high relevance score to wake up and fire.
* If the relevance score surpasses the `adjusted_threshold`, the Node fires.

**Secondary Spreading Activation:**
When a node fires (`fire_node/5`), it marks itself as traced, updates its state to `:high_energy`, and propagates a secondary `{:pulse, payload}` over the PubSub to its neighboring nodes defined in its `DataTail.relationship_metadata`. 

To prevent infinite loops and the "Hub Dominance" problem (where highly connected nodes drown out specific signals), the system implements **Synaptic Damping** (`calculate_associative_boost/3`). An associative link provides only a fraction of the original query’s energy (`synaptic_resistance = 0.3`). The energy dissipates as it travels deeper into the graph, governed by a strict Time-To-Live (TTL) integer that decreases with every hop.

### 6.4. QueryCoordinator: Orchestrating Chaos
Because nodes fire autonomously and asynchronously, the system requires a mechanism to gather the results and return them to the invoking Agent. This is the job of the `CMS.QueryCoordinator`.

For every query, a unique, ephemeral `QueryCoordinator` process is spawned. When a `NodeActor` fires, it sends a message (`{:node_fired, ...}`) to this coordinator. 
The Coordinator implements a **Winner-Takes-Most (WTM)** algorithm, keeping a rolling, deduplicated insertion-sort list of the top 50 most relevant nodes.

**The Gathering Window Optimization:**
Waiting for a fixed timeout (e.g., 10 seconds) on a global broadcast introduces unacceptable latency. Instead, the Coordinator utilizes a dual-timer mechanism. It starts with a 10-second failsafe. However, the exact millisecond the *first* node fires and reports its result, the Coordinator cancels the failsafe and initiates a "Gathering Window" of just 50 milliseconds (`@gathering_window 5000` configuration). It waits a fraction of a second to collect any straggling responses, and then immediately finalizes the query, returning lightning-fast results to the user.

### 6.5. Regulatory Homeostasis (`CMS.ActivationEngine`)
If a vague query triggers 10,000 nodes to fire simultaneously, the resulting secondary pulses could crash the system (a "cognitive seizure"). 

To prevent this, the `CMS.ActivationEngine` maintains a Global Inhibition Factor in an ultra-fast, lock-free, read-concurrency-enabled ETS (Erlang Term Storage) table. 
The `QueryCoordinator` tracks how many nodes have fired for a given query. If the number exceeds the `@inhibit_threshold_count` (100 nodes), it triggers a rapid inhibition signal back to the PubSub. The `ActivationEngine` throttles the global inhibition factor toward `0.1`. 
Because every `NodeActor` reads this ETS table during its `autonomous_query_evaluation`, the required firing threshold instantly spikes across the entire brain, suppressing further activations and forcing the system back into stable homeostasis.

---

## 7. Memory Evolution: Learning & Forgetting

### 7.1. Neuroplasticity (Hebbian Learning)
"Neurons that fire together, wire together." ACMS maps this biological axiom into code to ensure the memory grid adapts to how agents actually use it. 

When a `NodeActor` receives a secondary spreading activation pulse from a neighbor, it doesn't just passively read the data. It sends an asynchronous message back to the originating node: `GenServer.cast(origin_ref, {:hebbian_reinforce, my_id, 0.05})`. The originating node receives this positive feedback—"You activated me, and I was useful"—and increases the synaptic weight of the edge connecting them.

**The Sharded Hebbian Buffer:**
At high query volumes, constantly updating state and flushing changes to disk would create immense I/O bottlenecks. ACMS solves this using the `CMS.RegionalHebbianBuffer` and the `CMS.HebbianBufferSupervisor`. 
The supervisor spawns 32 isolated shards. When a node's synapse strengthens, the update is not written to disk immediately. Instead, it is routed to one of the 32 ETS tables based on its Semantic Region hash. The shards aggregate the floating-point deltas in-memory using highly concurrent atomic operations (`:ets.update_counter`). Every 5 seconds, the shards flush their accumulated weight changes to the `CMS.LogAppender` in a single optimized batch.

### 7.2. Anti-Hebbian Penalization
Agents can explicitly teach the memory system what *not* to associate. If an agent queries the system for "Authentication Logic" and receives a dashboard UI file that was mistakenly linked, the agent can call the REST endpoint:
`POST /api/v1/nodes/:id/feedback` with a payload of `{"penalization_amount": 0.2}`.

This triggers an Anti-Hebbian event. The target `NodeActor` receives a `{:feedback, :irrelevant...}` cast, iterates through its `relationship_metadata`, and actively degrades the weight of the offending edge. Over time, false associations are mathematically pruned from the graph.

### 7.3. Active Forgetting (`CMS.DecayManager`)
Without forgetting, memory becomes paralyzing. The `CMS.DecayManager` is a global orchestrator that runs continuous background sweeps to mimic biological active forgetting.

**Differential Decay:**
Every hour (`@decay_cycle_interval`), the Decay Manager broadcasts a `:perform_differential_decay` cast to all active nodes. Nodes check the `last_used_at` timestamp on every single outgoing edge. If a synapse hasn't transmitted a signal in over 168 hours (7 days), its weight is incrementally reduced mathematically. 

Simultaneously, the node evaluates its own `last_fired` timestamp and `activation_frequency`. If it hasn't fired recently, its `internal_state` drops from `:high_energy` -> `:low_energy` -> `:hibernating`. 

**The Eviction Protocol:**
Every 15 minutes, the Decay Manager audits the system for eviction. It utilizes a dual-criteria algorithm:
If a node's `internal_state` has reached `:hibernating` AND its average synaptic `total_link_weight` is below 0.1 (`@min_eviction_weight`), the system considers the memory useless. The `NodeActor` is issued a `GenServer.stop(pid, :normal)` command. It is gracefully evicted from active RAM, freeing BEAM resources. The memory is not deleted entirely—it still exists in the disk-based Epoch logs and can be explicitly queried—but it will no longer participate in active Spreading Activation.

### 7.4. Handling Model Drift (`CMS.ModelDriftManager`)
Machine Learning models evolve. If the underlying Python bridge upgrades from a 384-dimensional `MiniLM` model to a 768-dimensional `BERT` model, older nodes will contain mathematically incompatible semantic vectors.

The `CMS.ModelDriftManager` runs every 6 hours to detect "Model Drift." It queries the `CMS.NodeRegistry` for all active nodes and inspects their `NodeHead.embedding_model_version`. 
If a node's model version does not match the system's current active model (`@active_model_version`), the manager sends a `{:re_embed_request, active_model}` cast to the node. The Node dynamically calls out to the ML Bridge, regenerates its own vector using its original text fact, updates its state, and recalculates its Semantic Region subscription. The entire brain self-repairs its embeddings asynchronously without requiring downtime.

---

## 8. Sovereignty: Persistence & Recovery

### 8.1. The Immutable Chrono-Stack
ACMS rejects the standard CRUD (Create, Read, Update, Delete) paradigm for database persistence. Traditional updates overwrite history, destroying the context of how the system arrived at its current state. 

Instead, ACMS implements an **Immutable Chrono-Stack**. 
All persistence is routed through the `CMS.LogAppender`, which acts as a high-throughput, append-only JSONL (JSON Lines) logger. 
When a node is created, updated, migrated, or penalized, the *entire* `CMS.Node` struct is serialized via the `Jason` library and appended to the current log file. 
*Note: To accomplish this, ACMS utilizes `CMS.JsonExtensions`, explicitly implementing the `Jason.Encoder` protocol for `Nx.Tensor` structs, converting complex binary matrices into flat lists of floats that can be written to plain text JSONL files.*

The `CMS.EpochManager` handles the lifecycle of these files. It monitors the bytes written. Once a file reaches 100 Megabytes (`@max_size_bytes`) or one hour of lifespan (`@rotation_interval`), the Epoch Manager rotates the log, sealing the old file and opening a new one with a deterministic ISO-8601 UUID filename in the `priv/data/epochs/` directory.

### 8.2. HNSW Vector Storage (`CMS.VectorRouter`)
While memory primarily exists as Erlang processes in RAM, the system needs an index to quickly bootstrap associations or perform fallback queries. This is handled by the `CMS.VectorRouter`.

The Router wraps the highly optimized C++ `hnswlib` (Hierarchical Navigable Small Worlds) via Elixir NIFs (Native Implemented Functions). Because C++ NIFs can easily crash the entire BEAM virtual machine if given malformed data, the `VectorRouter` implements extreme defensive programming:
1. **Dimensionality Checks:** It validates `Nx.shape` to ensure incoming vectors match the strict `@dim 384` requirement.
2. **Tensor Reshaping:** The C++ bindings require a 2D batch tensor even for single inserts. The Router utilizes `Nx.new_axis(embedding, 0)` to seamlessly convert 1D vectors into 2D batches (`[1][384]`).
3. **Integer ID Mapping:** `hnswlib` requires integer IDs, but ACMS uses UUID strings. The Router generates a safe, bounded integer via `:erlang.phash2(node_id, 2_147_483_647)` and stores the bidirectional mapping inside a durable Mnesia table (`:vector_id_mapping`).

The HNSW indices are held in memory and periodically flushed to binary disk files (`.hnsw.bin`) every 5 minutes by a scheduled `:periodic_persist` loop.

### 8.3. Instance Protection (`CMS.Infrastructure.InstanceGuard`)
An ACMS Memory Cartridge (`ACMS_DATA_DIR`) is a sovereign entity containing Mnesia schemas, HNSW binaries, and JSONL logs. If two distinct ACMS processes attempted to boot and write to the same cartridge simultaneously, the Mnesia schema would violently corrupt.

To prevent this, `CMS.Infrastructure.InstanceGuard` implements a strict "Git-Lock."
Before the bootloader even touches Mnesia, the Instance Guard attempts to write its OS-level process ID into `running.pid`. If a file already exists, it reads the PID and executes a POSIX system command (`kill -0 <pid>`) to verify if the OS process is genuinely alive. If the process is dead, the guard identifies a stale lock, overwrites it, and proceeds. If the process is alive, the boot sequence immediately triggers an unrecoverable `raise` and terminates, protecting the cartridge.

### 8.4. The Boot Sequences: Hydrator vs. Rehydrator
When the ACMS boots, it relies on two distinct recovery mechanisms depending on the state of the Cartridge's `identity.lock`.

**The Hydrator (Normal Boot):**
If the identity lock matches, the system assumes a safe environment. `CMS.Recovery.Hydrator.run/0` reads the newest states from the Epoch JSONL logs, reconstructs the nested Elixir structs (`NodeHead`, `NodeBody`, `DataTail`), parses the ISO-8601 timestamps, and issues `NodeSupervisor.start_child/1`. The nodes awaken in RAM, and normal operation resumes within milliseconds.

**The Rehydrator (The Scorched Earth Protocol):**
If the `identity.lock` reveals that the Cartridge has been moved to a machine with a different CPU architecture (e.g., from macOS to Linux), the underlying Mnesia `.DAT` files and C++ HNSW `.bin` files are binary-incompatible. Attempting to load them will trigger a fatal BEAM crash.

The Bootloader intercepts this and triggers `CMS.Recovery.Rehydrator`. This module executes a "Scorched Earth" wipe, physically deleting the entire Mnesia directory and HNSW indices off the disk. It then streams the immutable JSONL Epoch logs from the beginning of time. It rebuilds the integer-to-UUID mappings, re-injects every vector tensor directly into a newly initialized C++ HNSW index via optimized `bulk_add` logic, and reconstructs the Mnesia schema from scratch. The brain rebuilds its own infrastructure entirely from the Chrono-Stack.

---

## 9. Time Travel: Temporal Queries

### 9.1. Historical Forensic Search
Because ACMS utilizes an immutable append-only JSONL Chrono-Stack, data is never truly destroyed. If an agent makes a disastrous sequence of changes, or if an auditor needs to know exactly what the system "believed" to be true three weeks ago, the system provides a robust Temporal Query mechanism.

By passing the `as_of` parameter in the `/api/v1/query` endpoint with a valid ISO-8601 timestamp, agents can bypass the live RAM Spreading Activation network entirely and execute a forensic search against the disk-based history.

### 9.2. State Reconstruction via Log Replay
When a temporal query is invoked, the `CMS.TemporalQueryEngine` takes over.
It does not keep a separate vector index for historical states. Instead, it utilizes Mnesia to quickly locate the exact Epoch Log files whose `start_time` predates the requested timestamp.

Once the target files are identified, the Engine uses Elixir's highly efficient `File.stream!` combined with `Enum.reduce` to lazily stream the gigabytes of JSONL text without overwhelming RAM. It replays every logged event (`node_created`, `node_updated`, `node_migrated`, `node_decayed`) line by line, building up an ephemeral memory map (`%{node_id => node_data}`). The moment the stream reads an event whose timestamp is greater than the `as_of` target, it halts processing. 

### 9.3. Deep Map Merging for Partial Updates
During the replay phase, updates to nodes (`node_updated`) are often logged as partial deltas rather than full state dumps to save disk space. 
To ensure historical accuracy, the Temporal Query Engine implements a custom algorithm: `deep_merge_recursive/2`.

When an update event is read, the engine retrieves the current reconstructed state of the node. The `deep_merge_recursive` function iterates through the keys of both maps. If a key points to a nested map (e.g., `body -> data_tail -> acls`), the function recursively dives into the structure, merging the incoming delta without obliterating the existing sibling data (like preserving the `salience_score` while only updating the `relationship_metadata` edges). This guarantees the precise reconstruction of the complex, highly-nested `CMS.Node` topology at that exact millisecond in history.

### 9.4. Executing the Temporal Vector Scan
Once the Temporal Query Engine has successfully rebuilt the entire system state map for the specified point in time, it passes the data back to the `CMS.Web.Router`.

Because the C++ HNSW index reflects the *present* live state, the router executes a brute-force memory scan. It iterates over the reconstructed historical node list, dynamically extracts the floating-point lists from the JSON maps, casts them to `Nx.Tensors`, and executes a mathematical cosine similarity operation (`Nx.dot() / (norm_a * norm_b)`) against the Agent's query vector. 
It filters the results against the `min_relevance` threshold, sorts them descendingly, and returns a JSON payload explicitly tagged with `"query_type": "temporal"`. The Agent experiences true cognitive time travel.

---

## 10. Security & Access Control

### 10.1. Trust Scores & Provenance Metadata
Security in ACMS begins at the point of ingestion. An AI agent is not inherently trusted. When an agent pushes a fact to the Ingestion Engine, it provides a `provenance` metadata map. This map contains the `source` (e.g., "WebCrawler_Agent_v3"), the explicit `priority`, and an assigned `trust_score` (0.0 to 1.0).

This trust score is vital during Conflict Arbitration (detailed in Chapter 5). If a rogue, low-trust agent attempts to overwrite a critical system fact, the trust differential ensures the attempt is either dialectically merged (flagged as a contradiction) or rejected entirely, protecting the integrity of the memory graph.

### 10.2. Structured ACLs (Access Control Lists)
Every Node in ACMS contains an Access Control List embedded deep within its administrative ledger: `CMS.NodeBody.data_tail.acls`. 
Because AI agents often output varied JSON structures, the system defends against malformed permissions via `CMS.DataTail.normalize_acls/1`. 
* If an agent provides a flat list of strings `["agent_x", "agent_y"]`, ACMS automatically converts it to a structured map, granting strict read/write ownership to those specific agents while appending `"public"` to the read list.
* If the payload is entirely `nil`, it falls back to maximum security: `%{read: ["public"], write: ["system", "root"]}`.

### 10.3. Enforcement via Roles
The `CMS.Security` module provides the boolean gatekeeping logic for the system.
Before any read or write action executes, `Security.can_read?/2` or `Security.can_write?/2` is invoked.

The logic relies on Role-Based Agent IDs:
1. **System Roles (`root`, `system`):** Agents identifying with these IDs bypass all ACL restrictions. They possess omnipotent read/write capabilities across the entire grid.
2. **Public Role (`public`):** Represents universal read access. If `"public"` is in the read list, any Agent ID is permitted to query and retrieve the node.
3. **Explicit Targeting:** If a node is private, the querying agent's `x-agent-id` HTTP header must exactly match a string inside the ACL array.

**Protecting Graph Topology:**
Routine nodes decay gracefully. However, hard-deleting a node via the `DELETE /api/v1/nodes/:id` endpoint fundamentally alters the graph topology and can break critical associative chains. Therefore, the Web Router strictly checks the `x-agent-id` header for this endpoint. Only agents asserting `"root"` or `"system"` privileges are permitted to trigger forced eviction; all other requests are rejected with `403 Forbidden`.

### 10.4. Input Validation (`CMS.FIDValidator`)
Security is not just about permissions; it is about data integrity. Before any payload touches the core graph, it must pass through the `CMS.FIDValidator`.
The validator leverages Elixir's powerful pattern-matching guards to ensure structural conformity for Polymorphic Payloads (FIDs). 
* For a `Text` FID, it mathematically ensures the payload is a binary string with a length strictly greater than zero. 
* For a `Link` FID, it executes a Regex match `~r/^(http|https|gm|ipfs):\/\//` to guarantee the URI protocol is safe and resolvable, preventing injection of malicious protocols (e.g., `file://` or `javascript:`).
* If a payload fails validation, the entire ingestion transaction is halted, a `400 Bad Request` is returned to the Agent, and the memory remains untouched, preserving the pure cognitive health of the system.


You are absolutely right, and I apologize for summarizing too aggressively. A system as complex as the ACMS is useless without concrete, copy-pasteable examples for developers and AI agents to actually interact with it. 

To rectify this, I have completely rewritten Chapters 11 through 15. This revised section serves as a **Comprehensive Developer & API Integration Guide**. It is packed with exact JSON schemas, `curl` commands, Python agent integration scripts, and step-by-step beginner workflows so you (or the AI agents you are building) can start reading and writing to the memory grid immediately.

***

## 11. The Frontal Cortex: ML Bridge (Python)

Before your Elixir core can organize memories, it needs a way to understand human language. The Erlang VM (BEAM) is not built for matrix math, so ACMS relies on a Python FastAPI microservice (the "ML Bridge") to generate 384-dimensional semantic vectors using the `sentence-transformers` library.

For a newbie, you don't actually need to write any Python to use this—you just need to make sure the bridge is running in the background.

### 11.1. Starting the Bridge
Open a terminal, install the requirements, and run the bridge:
```bash
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sentence-transformers torch requests
python ml_bridge.py
```
*You should see Uvicorn start on `http://0.0.0.0:5000`.*

### 11.2. Testing the ML Bridge Manually
While Elixir usually talks to this bridge automatically, you can test it yourself to see how text is converted into cognitive vectors.

**Endpoint:** `POST /api/v1/embed`
```bash
curl -X POST http://localhost:5000/api/v1/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "The ACMS uses spreading activation.", "model_version": "all-MiniLM-L6-v2"}'
```
**Response:**
```json
{
  "vector": [0.0345, -0.1123, 0.5432, ...] // Array of 384 floats
}
```

**Endpoint:** `POST /api/v1/salience`
This calculates how "important" a memory is (0.0 to 1.0) based on keywords and priority.
```bash
curl -X POST http://localhost:5000/api/v1/salience \
  -H "Content-Type: application/json" \
  -d '{
    "text": "CRITICAL ERROR: Database connection lost.",
    "provenance": {"priority": "critical"}
  }'
```
**Response:**
```json
{
  "score": 0.95
}
```

---

## 12. Universal API Reference (Elixir Core)

This is the most critical chapter for developers. The ACMS exposes a lightning-fast HTTP API (running on port `4000` by default). **Your AI Agents will use these endpoints exclusively to read and write memories.**

### 12.1. Ingesting Memory (`POST /api/v1/ingest`)

This is how an agent stores a highly structured "thought" into the brain. 
Because ACMS uses a **Format ID (FID)** system, your payloads can be Text, Code, Numbers, or JSON Objects.

*   **URL:** `http://localhost:4000/api/v1/ingest`
*   **Headers:** `Content-Type: application/json`

**Example cURL Request (Complex Payload):**
Let's say a Python-coding Agent wants to store a script it just wrote, along with some text explaining it.
```bash
curl -X POST http://localhost:4000/api/v1/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "python_specialist_01",
    "fact_text": "A Python script that reverses a string using slicing.",
    "acls": {
      "read": ["public"],
      "write": ["python_specialist_01", "root"]
    },
    "provenance": {
      "source": "AutoGPT_Session_99",
      "trust_score": 0.95,
      "priority": "normal"
    },
    "description_payloads": [
      {
        "type": "text",
        "content": "This is the most pythonic way to reverse a string."
      },
      {
        "type": "code",
        "language": "python",
        "content": "def reverse_str(s):\n    return s[::-1]"
      }
    ]
  }'
```

**Explanation of the Payload:**
*   `fact_text`: **CRITICAL.** This single sentence is what the ML Bridge turns into a vector. Keep it concise and descriptive.
*   `description_payloads`: The actual data. You can mix and match `type: "text"`, `"code"`, `"number"`, `"link"`, and `"object"`.
*   `acls`: Access Control Lists. Because `"public"` is in the read list, any agent can search for and read this memory. Only `"python_specialist_01"` and `"root"` can delete or edit it.
*   `provenance`: Metadata. The `trust_score` helps the system resolve conflicts if another agent tries to upload contradictory information.

**Example Response:**
```json
{
  "status": "ok",
  "node_id": "a7f3b8c9d2e1... (SHA-256 Hash)"
}
```

### 12.2. Querying the Memory (`POST /api/v1/query`)

Unlike standard vector databases, ACMS uses Spreading Activation. When you query it, it doesn't just find similar text; the nodes ripple outward, returning connected, highly relevant context.

*   **URL:** `http://localhost:4000/api/v1/query`

**Example cURL Request:**
```bash
curl -X POST http://localhost:4000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_text": "How do I reverse a string in python?",
    "agent_id": "frontend_agent_02",
    "reasoning_mode": "brainstorm",
    "min_relevance": 0.4,
    "max_results": 5
  }'
```

**Explanation of the Payload:**
*   `reasoning_mode`: Can be `"normal"`, `"precision"` (strict matching), or `"brainstorm"` (lowers synaptic resistance, allowing the brain to return wilder, more distant associations).
*   `min_relevance`: The baseline cosine similarity required to return a result (0.0 to 1.0).

**Example Response:**
The system returns an array of nodes. Notice how the `data` array exactly matches the FIDs we ingested earlier.
```json
{
  "query_id": "uuid-1234-5678",
  "count": 1,
  "fallback_triggered": false,
  "results": [
    {
      "score": 0.89,
      "node_id": "a7f3b8c9d2e1...",
      "fact": "A Python script that reverses a string using slicing.",
      "data": [
        {"type": "text", "content": "This is the most pythonic way..."},
        {"type": "code", "language": "python", "content": "def reverse_str(s)..."}
      ],
      "metadata": {
        "created_at": "2023-10-27T10:00:00Z",
        "last_fired": "2023-10-27T10:05:00Z",
        "version": "v1 (genesis)"
      }
    }
  ]
}
```

### 12.3. Temporal "Time Travel" Queries
If you want to know what the memory system "knew" yesterday, bypass the live RAM and query the disk-based Chrono-Stack by adding the `as_of` parameter.

```bash
curl -X POST http://localhost:4000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_text": "How do I reverse a string in python?",
    "as_of": "2023-10-26T00:00:00Z" 
  }'
```
*(If the memory was created on Oct 27th, this query will return an empty list `[]`, because as of Oct 26th, the system had not learned it yet).*

### 12.4. Anti-Hebbian Penalization (Teaching the Brain)
If your agent queries the system and receives a completely useless or irrelevant memory, the agent can "punish" that connection so the brain doesn't make that mistake again.

*   **URL:** `POST /api/v1/nodes/:node_id/feedback`

```bash
curl -X POST http://localhost:4000/api/v1/nodes/a7f3b8c9d2e1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "penalization_amount": 0.1,
    "context_id": "irrelevant_search_result"
  }'
```
**Response:**
```json
{"status": "feedback_applied", "node_id": "a7f3b8c9d2e1..."}
```

### 12.5. Fast Unstructured Ingestion Endpoints
If you don't want to build massive JSON payloads, the API provides quick-ingest routes that auto-generate the JSON for you using the `CMS.Ingestion.Crawler` and `Shredder`.

**Upload a Text Blob:**
```bash
curl -X POST http://localhost:4000/api/v1/ingest/blob \
  -H "Content-Type: application/json" \
  -d '{
    "text": "The quick brown fox jumps over the lazy dog. It is a very good dog.",
    "metadata": {"filename": "fox.txt"}
  }'
```

**Upload a Zip File of Code:**
```bash
curl -X POST http://localhost:4000/api/v1/ingest/upload \
  -F "file=@my_project_code.zip"
```
*The system will unzip the file, shred the code into semantic 150-line chunks, generate vectors for each chunk, and interlink them automatically in the graph.*

---

## 13. Observability & Agent Integration

How do you actually wire an AI agent to use this? Below is a practical guide for newcomers.

### 13.1. Python Agent Integration Example
If you are building an AI using Python (e.g., using `requests`), here is exactly how your agent should query the memory and parse the Format ID (FID) structure to pull out executable code.

```python
import requests

# 1. The Agent formulates a query
payload = {
    "query_text": "I need the Python script for string reversal.",
    "agent_id": "my_agent",
    "min_relevance": 0.5
}

# 2. Call the ACMS API
response = requests.post("http://localhost:4000/api/v1/query", json=payload)
data = response.json()

# 3. Parse the results
if data["count"] > 0:
    top_result = data["results"][0]
    print(f"Brain retrieved fact: {top_result['fact']}")
    
    # 4. The FID Parser Logic (Iterate through the payloads)
    for item in top_result["data"]:
        if item["type"] == "code" and item["language"] == "python":
            python_code = item["content"]
            print("--- Found Executable Code ---")
            print(python_code)
            
            # The agent can now execute this code using exec() or save to disk
else:
    print("The brain does not know the answer.")
```

### 13.2. Real-Time Telemetry via WebSockets
If you want to build a real-time dashboard UI to watch the brain "think", you can connect to the WebSocket endpoint.

Using a tool like `wscat` (install via `npm install -g wscat`):
```bash
wscat -c "ws://localhost:4000/api/v1/events?token=admin_secret"
```

Once connected, if an agent triggers a massive search, your terminal will light up with live JSON events streaming from the Elixir PubSub:
```json
{"event":"system_congestion","level":0.65,"timestamp":"2023-10-27T10:01:23Z"}
{"event":"abnormality_signal","node_id":"a7f3b8...","reason":"untrusted_agent_high_score","timestamp":"2023-10-27T10:01:24Z"}
```

### 13.3. The IEx LiveMonitor (The "Matrix" View)
For backend developers running the system, the most visually impressive way to observe the system is the `LiveMonitor`.

1. Start your ACMS instance in interactive mode: `./acms.sh my_brain 4000`
2. Once the Elixir `iex>` prompt appears, type:
```elixir
iex(1)> CMS.Tools.LiveMonitor.start()
```
The terminal will now output color-coded logs in real-time. If you run a massive ingestion script in another window, you will see a waterfall of magenta `[NEUROPLASTICITY]` logs as nodes dynamically wire themselves together, and yellow `[CONFLICT ARBITRATION]` logs if two nodes contradict each other.

---

# 14. The Neurological Tuning Guide (Configurable Parameters)

Tuning the Associative Cognitive Memory System (ACMS) is fundamentally different from tuning a traditional relational database like PostgreSQL or a standard vector store like Pinecone. Because ACMS operates as a bio-mimetic graph of autonomous, asynchronous processes, you are not merely configuring cache sizes or connection pools—you are modulating the neurotransmitters of an artificial brain.

Modifying these parameters drastically alters the "personality," performance, memory retention, and associative creativity of your AI swarm. 

Parameters in ACMS fall into two distinct categories:
1. **Runtime Variables:** Passed via `.env` files or terminal exports when booting the server. These require no recompilation.
2. **Cognitive Constants (Module Attributes):** Hardcoded `@` variables and specific mathematical floats inside the Elixir and Python source code. To modify these, you must edit the respective file and run `mix compile` (or restart the Python bridge).

---

## 14.1. Runtime Environment Variables (Infrastructure)
These configurations govern the physical infrastructure, security, and networking of the system. They are intercepted by `config/runtime.exs` and `acms.sh` the moment the Erlang VM boots.

*   `ACMS_DATA_DIR`
    *   **Location:** Boot environment variable.
    *   **Default:** `$(pwd)/memory_cartridges/${ACMS_NODE_NAME}`
    *   **Function:** The master directory for your "Memory Cartridge." It holds the Mnesia database, the HNSW vector binaries, and the JSONL Chrono-Stack epochs.
    *   **Tuning Rationale:** In a production Kubernetes or Docker environment, you must map this to a highly durable, mounted persistent volume (e.g., AWS EBS) so that the AI's memory survives container destruction and restarts.
*   `ACMS_PORT`
    *   **Location:** Boot environment variable.
    *   **Default:** `4000`
    *   **Function:** The HTTP port for the Elixir Plug/Cowboy REST and WebSocket API.
*   `ACMS_NODE_NAME`
    *   **Location:** Boot environment variable.
    *   **Default:** `cms`
    *   **Function:** Sets the Erlang VM node identity (e.g., `cms@127.0.0.1`). 
    *   **Tuning Rationale:** If you are running multiple discrete brains on the same bare-metal machine (e.g., a "Frontend Brain" and a "Backend Brain"), they must have different node names to avoid BEAM naming collisions.
*   `ACMS_ADMIN_TOKEN`
    *   **Location:** Boot environment variable.
    *   **Default:** `"admin_secret"`
    *   **Function:** The password required to authenticate to the `/api/v1/events` WebSocket with `:admin` privileges, unlocking system telemetry streams like congestion and abnormality warnings.
*   `ACMS_SECRET`
    *   **Location:** Boot environment variable.
    *   **Default:** Auto-generated secure random string (`:crypto.strong_rand_bytes(32)`).
    *   **Function:** The cryptographic salt for internal Plug/Cowboy API endpoints.

---

## 14.2. The Cognitive Firing Thresholds (Core Math)
This is the most critical tuning section in the ACMS. The core engine of the system is the autonomous decision of a single `NodeActor` to fire. This is a dynamic mathematical equation calculated in real-time inside `lib/cms/agents/node_actor.ex`.

The exact formula the brain uses during `autonomous_query_evaluation` is:
`adjusted_threshold = (base_threshold / max(0.1, inhibit_factor)) * metabolic_cost`

If these thresholds are configured incorrectly, the brain will either fall into a coma (nothing fires) or suffer a cognitive seizure (everything fires, causing an Out-Of-Memory crash).

*   **The Base Relevance Threshold (`relevance_threshold`)**
    *   **Location:** `lib/cms/core/structs/node_head.ex` (inside `new/3`)
    *   **Default:** `0.3`
    *   **Function:** The absolute minimum baseline cosine similarity required for a memory to consider itself "relevant" to an incoming query vector.
    *   **Tuning Rationale:** If you raise this to `0.7`, the brain becomes highly literal; only exact semantic matches will fire. If you lower this to `0.1`, the brain becomes highly abstract, firing on incredibly weak semantic links (which can cause massive, noisy chain reactions).
*   **The Query-Level Override (`min_relevance`)**
    *   **Location:** `lib/cms/interface/cms_web.ex` (Parsed from the `POST /api/v1/query` payload)
    *   **Default:** `0.6` (If omitted by the agent)
    *   **Function:** Allows an AI agent to dynamically override the brain's base threshold per query.
    *   **Tuning Rationale:** Configure your AutoGPT/Langchain agents to pass `0.85` when they need strict factual retrieval (e.g., retrieving an exact API key), and pass `0.35` when they are brainstorming architecture ideas and want the memory grid to return loose associations.
*   **Metabolic Cost Multipliers (`cost`)**
    *   **Location:** `lib/cms/agents/node_actor.ex` (inside `process_activation/5`)
    *   **Defaults:** `:high_energy` -> `0.9` | `:low_energy` -> `1.2` | `:hibernating` -> `1.5`
    *   **Function:** Implements "Recent Creation Bias." A memory that was just created or recently queried is "hot" (`:high_energy`). Multiplying the threshold by `0.9` makes it 10% *easier* to fire. Conversely, a memory that hasn't been accessed in weeks (`:hibernating`) is multiplied by `1.5`, making it 50% *harder* to fire.
    *   **Tuning Rationale:** To change these, you must edit the case statement in `NodeActor.ex`. If you want cold memories to be practically inaccessible unless explicitly and directly searched for, raise the `:hibernating` cost to `2.0` or `3.0`.
*   **Vector Index Threshold (`threshold`)**
    *   **Location:** `lib/cms/infrastructure/persistence/vector_router.ex` (inside `handle_call({:query...})`)
    *   **Default:** `0.0`
    *   **Function:** When bypassing the RAM network and querying the underlying C++ HNSW index directly (or during temporal searches), this filters out garbage results at the NIF layer before they return to Elixir.
    *   **Tuning Rationale:** Setting this to `0.5` ensures the disk index *only* returns mathematically viable results, saving BEAM processing overhead during cold-boot searches.

---

## 14.3. Spreading Activation & Topology Parameters
These parameters govern the flow of energy through the graph. They control how far a thought can ripple and how the system prevents runaway queries.

*   `@top_k_results`
    *   **Location:** `lib/cms/agents/query_coordinator.ex`
    *   **Default:** `50`
    *   **Function:** The maximum number of memories the system will return to an agent per query, maintained via an insertion-sort list.
    *   **Tuning Rationale:** If your LLM agents have massive 128k context windows (like GPT-4-Turbo), you can safely raise this to `200` to feed them significantly more background context.
*   `@inhibit_threshold_count`
    *   **Location:** `lib/cms/agents/query_coordinator.ex`
    *   **Default:** `100`
    *   **Function:** If a query triggers more than this many nodes to fire, the Coordinator considers it a "cognitive seizure" and triggers the `ActivationEngine` to globally throttle the network.
    *   **Tuning Rationale:** Lower to `20` to make the brain hyper-focused and highly restrictive. Raise to `1000` if you want a hyper-associative brain capable of returning vast, sprawling webs of interconnected thought.
*   `@gathering_window`
    *   **Location:** `lib/cms/agents/query_coordinator.ex`
    *   **Default:** `5000` (milliseconds)
    *   **Function:** Once the *first* memory node fires and reports back to the coordinator, the 10-second query failsafe is canceled, and the coordinator waits exactly this many milliseconds to collect any straggling secondary responses before returning the JSON payload.
    *   **Tuning Rationale:** Lower to `100` for near-instant API responses (at the cost of missing deep, multi-hop associative memories). Leave at `5000` for deep, exhaustive cognitive scans.
*   `synaptic_resistance`
    *   **Location:** `lib/cms/agents/node_actor.ex` (Inside `calculate_associative_boost/3`)
    *   **Default:** `0.3`
    *   **Function:** When Node A activates Node B through a synaptic link, Node B only receives 30% of the query's initial energy.
    *   **Tuning Rationale:** This explicitly cures "Hub Dominance" (where a highly connected node, like a core utility file, drowns out specific answers). If you change this to `1.0`, associative memories are treated with the exact same mathematical weight as direct text matches.
*   `base_ttl` (Time-To-Live)
    *   **Location:** `lib/cms/agents/node_actor.ex` (Inside `fire_node/5`)
    *   **Default:** `2`
    *   **Function:** Limits how far a pulse can travel. A TTL of 2 means a query hits Node A, Node A wakes up Node B, Node B wakes up Node C, and then the signal terminates.
    *   **Tuning Rationale:** Increase to `3` or `4` to allow deep "Six Degrees of Separation" style memory retrieval. **Warning:** High TTL values cause exponential network traffic over the PubSub and will heavily tax the CPU.

---

## 14.4. Ingestion & Assimilation Constants
These parameters dictate how new facts are wired into the brain when an agent posts data to the Ingestion API, effectively governing the system's "First Impressions."

*   `@max_associative_links`
    *   **Location:** `lib/cms/services/ingestion_engine.ex`
    *   **Default:** `10`
    *   **Function:** During "Hebbian Priming", when a brand new fact is ingested, the brain searches the graph to wire it up automatically. It will create a maximum of 10 initial synaptic edges to its nearest semantic neighbors.
*   `@min_associative_score`
    *   **Location:** `lib/cms/services/ingestion_engine.ex`
    *   **Default:** `0.4`
    *   **Function:** A new node will only automatically wire itself to an existing node if their vector similarity is at least 40%.
    *   **Tuning Rationale:** Increase to `0.8` if you want a highly sterile, rigid graph where only practically identical concepts are automatically linked. Lower to `0.2` to create a highly entangled graph where every new fact instantly wires itself to dozens of loosely related concepts.
*   `@conflict_similarity_threshold`
    *   **Location:** `lib/cms/services/ingestion_engine.ex`
    *   **Default:** `0.85`
    *   **Function:** If a newly ingested fact matches an existing fact with 85% or higher similarity, the brain halts standard ingestion, flags it as a potential contradiction or duplicate, and triggers Conflict Arbitration.
*   `@trust_supersede_threshold`
    *   **Location:** `lib/cms/services/ingestion_engine.ex`
    *   **Default:** `0.2`
    *   **Function:** During Conflict Arbitration, if the new fact comes from an agent whose `trust_score` is 0.2 higher than the agent who wrote the original fact, the original fact is overwritten (superseded). If the difference is less than 0.2, a Dialectical MetaNode is spawned to document the disagreement.

---

## 14.5. Active Forgetting & Garbage Collection
These parameters define how the brain manages its RAM limits. By tuning these, you determine whether the AI has a photographic memory (consuming massive RAM) or actively discards old information to stay lean and performant.

*   `@decay_cycle_interval`
    *   **Location:** `lib/cms/services/decay_manager.ex`
    *   **Default:** `:timer.hours(1)`
    *   **Function:** Every hour, the system mathematically reduces the weight of all unused synaptic links (edges). If an edge is unused for 168 hours (7 days), its weight begins to aggressively decay toward zero.
*   `@eviction_check_interval`
    *   **Location:** `lib/cms/services/decay_manager.ex`
    *   **Default:** `:timer.minutes(15)`
    *   **Function:** Every 15 minutes, the Garbage Collector sweeps the `NodeSupervisor` looking for useless memories to kick out of active RAM.
*   `@min_eviction_weight`
    *   **Location:** `lib/cms/services/decay_manager.ex`
    *   **Default:** `0.1`
    *   **Function:** The dual-criteria eviction threshold. If a node has dropped into a `:hibernating` state AND its average synaptic connection weight drops below `0.1`, the `NodeActor` process is killed.
    *   **Tuning Rationale:** Raise this to `0.5` if you are running ACMS on an edge device or cheap VPS with very limited RAM (e.g., 1GB or 2GB). The brain will aggressively delete nodes from RAM that aren't being actively queried by your agents every single day. (Note: Evicted nodes still exist on disk and can be retrieved via Temporal Search).

---

## 14.6. I/O Performance and Storage Limits
These parameters govern disk usage, preventing the ACMS from filling up your hard drive or crashing the Python ML Bridge under heavy load.

*   `@max_size_bytes`
    *   **Location:** `lib/cms/infrastructure/persistence/epoch_manager.ex`
    *   **Default:** `100 * 1024 * 1024` (100 MB)
    *   **Function:** The absolute maximum size of a single JSONL Epoch log file before the system seals it and rotates to a new file.
    *   **Tuning Rationale:** If you are running heavy temporal queries (`as_of`), configuring smaller files (e.g., `20 * 1024 * 1024` for 20 MB) makes historical reconstruction slightly faster because the `TemporalQueryEngine` can skip parsing massive irrelevant logs.
*   `@dim`
    *   **Location:** `lib/cms/infrastructure/persistence/vector_router.ex`
    *   **Default:** `384`
    *   **Function:** The exact dimensionality of the vector embeddings managed by the C++ `hnswlib` NIF.
    *   **Tuning Rationale:** **CRITICAL:** If you change your Python ML Bridge model from `all-MiniLM-L6-v2` to an OpenAI model (e.g., `text-embedding-3-small`), you **MUST** change this to `1536` and run the Rehydrator to rebuild the HNSW index from scratch, otherwise the C++ NIF will instantly crash the Erlang VM upon receiving mismatched arrays.
*   `@max_elements`
    *   **Location:** `lib/cms/infrastructure/persistence/vector_router.ex`
    *   **Default:** `100_000`
    *   **Function:** The pre-allocated capacity of the C++ HNSW vector index.
    *   **Tuning Rationale:** If your knowledge graph grows beyond 100,000 nodes, HNSW will fail to add new items. You must increase this to `1_000_000` (or however large your dataset is). Note that raising this reserves significantly more contiguous RAM upon boot.
*   `MODEL_NAME`
    *   **Location:** `ml_bridge.py`
    *   **Default:** `"all-MiniLM-L6-v2"`
    *   **Function:** The specific `sentence-transformers` NLP model loaded into Python's RAM on startup.
    *   **Tuning Rationale:** You can swap this to `"multi-qa-mpnet-base-dot-v1"` (768 dimensions) for much higher semantic accuracy at the cost of higher CPU load and slower ingestion times. (Remember to update `@dim` in Elixir if you do this).
*   `PORT`
    *   **Location:** `ml_bridge.py`
    *   **Default:** `5000`
    *   **Function:** The local port Uvicorn uses to serve the Python API. If changed, you must also update `@bridge_url` inside Elixir's `CMS.Tool.Embedder` and `CMS.SalienceEngine` to maintain connectivity between the hemispheres of the system.

---

## 14.7. Reference Tuning Profiles

To help system operators configure their ACMS instances quickly, here are three standard "Tuning Profiles" targeting different use cases. Implement these by altering the respective variables in the code before compiling.

### Profile A: "The Strict Database"
**Use Case:** You are using ACMS purely as an intelligent knowledge base where precision is paramount, and you do not want "hallucinated" or overly distant associations.
*   `relevance_threshold`: `0.7`
*   `@min_associative_score`: `0.85`
*   `@top_k_results`: `10`
*   `synaptic_resistance`: `0.1` (Heavily dampens secondary links)
*   `base_ttl`: `1` (Almost completely disables deep spreading activation)

### Profile B: "The Creative Brainstormer"
**Use Case:** You are running a swarm of AutoGPT agents tasked with solving complex, novel architectural problems, requiring the brain to surface wildly creative, distant connections.
*   `relevance_threshold`: `0.15`
*   `@inhibit_threshold_count`: `500`
*   `synaptic_resistance`: `0.8` (Secondary links carry almost as much weight as primary hits)
*   `base_ttl`: `4` (Signals ripple deep into the memory graph)
*   `@max_associative_links`: `25` (Dense initial wiring during ingestion)

### Profile C: "The Edge Device (Low-RAM)"
**Use Case:** You are running ACMS on a Raspberry Pi or a 1GB cloud VPS. RAM is scarce, and the system must aggressively forget unused data.
*   `@eviction_check_interval`: `:timer.minutes(5)` (Sweeps constantly)
*   `@min_eviction_weight`: `0.6` (Aggressively kills nodes unless they are heavily utilized)
*   `metabolic cost (hibernating)`: `3.0` (Makes cold memories nearly impossible to fire, saving CPU cycles)
*   `@max_size_bytes`: `10 * 1024 * 1024` (10MB logs to save disk space and speed up temporal queries)