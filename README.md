# The Associative Cognitive Memory System (ACMS)
## Part 1: Philosophy, Architecture, and The Anatomy of Synthetic Memory

### 1.0. Manifesto: From Databases to Cognition
The software industry has spent the last decade perfecting the storage of static data. We have Relational Databases (SQL) for rigid structures, NoSQL for flexibility, and recently, Vector Databases (Pinecone, Weaviate) for semantic similarity. While effective for retrieval, these systems share a fundamental flaw: they are **passive**. They are "buckets" into which we dump information, hoping to fish it out later with the exact right query. They do not think; they only hold.

The **Associative Cognitive Memory System (ACMS)** represents a paradigm shift from **Information Storage** to **Cognitive Modeling**. It is not a database; it is a synthetic nervous system. It is written primarily in **Elixir**, leveraging the **OTP Actor Model** to simulate a biological brain where every memory is not a passive row in a table, but an active, living process (a GenServer) fighting for metabolic resources.

This system answers the question: *What if RAG (Retrieval Augmented Generation) wasn't just a search engine, but a living organism that learned, forgot, and evolved?*

#### 1.1. The "Alien Organism" Architecture
To an engineer accustomed to standard CRUD applications or stateless AI pipelines, this codebase will appear alien. Standard AI architectures operate on a linear pipeline: `Input -> Process -> Output`. They are stateless. They reset every time the context window closes. They are brains in jars with no long-term continuity.

The ACMS is a **System of Systems** designed to model **Cognition**. It possesses characteristics usually reserved for biological life:
1.  **Metabolism:** Memories consume resources. If they are not accessed, they lose energy (`internal_state`) and are eventually killed (`DecayManager`).
2.  **Subjectivity:** The system does not return objective truth; it returns results based on its current state of homeostasis (`ActivationEngine`). If the system is stressed (congested), it changes how it thinks.
3.  **Neuroplasticity:** It adheres to Hebbian Theory ("Neurons that fire together, wire together"). Successful queries physically alter the topology of the graph (`RegionalHebbianBuffer`).
4.  **Dialectics:** It understands contradiction. It does not overwrite old data; it resolves conflicts through synthesis (`MetaNode`).

This is not a "Context Window Extender." This is a **Dynamic Long-Term Memory (LTM)** that operates outside the LLM's context window, curating exactly what needs to be fed into the AI based on associative relevance rather than simple keyword matching.

---

### 2.0. The Architectural Core: The Actor Model as Neural Mesh
The foundational decision of this codebase is the use of **Elixir** and the **BEAM VM**. This was not a stylistic choice, but an architectural necessity.

In a biological brain, neurons are independent units. They function in parallel, maintain their own state (electrical potential), and communicate via asynchronous chemical signals (synapses). The **Actor Model** is the only software paradigm that accurately maps to this biology.

#### 2.1. The `NodeActor`: The Atomic Unit of Cognition
In the ACMS, every single "Fact" or "Memory" is spawned as an independent process called a `CMS.NodeActor`.
*   **Location:** `cms/core/node_actor.ex`
*   **Function:** It is the "Neuron."
*   **Behavior:**
    *   It is not retrieved; it must be **activated**.
    *   It holds its own vector embedding in memory (`NodeHead`).
    *   It maintains a list of connections to other nodes (`DataTail`).
    *   It listens for signals on the "Cognitive Bus" (PubSub).

When a query enters the system, we do not perform a binary search on a B-Tree. Instead, we broadcast the query signal to the neural mesh. Each `NodeActor` autonomously evaluates the signal against its own embedding. If the signal is strong enough to overcome the node's **Relevance Threshold**, the node "fires."

#### 2.2. The Decentralized "Ghost in the Machine"
This architecture is decentralized. There is no central "Brain" class that iterates over a list of nodes. Emergent intelligence arises from the interaction of thousands (or millions) of `NodeActor` processes.

*   **Evidence:** `CMS.BroadcastCoordinator` and `CMS.QueryCoordinator`.
*   **Mechanism:** The `BroadcastCoordinator` sends a pulse to the ether. The `NodeActors` catch it. The `QueryCoordinator` sits back and waits for nodes to shout "I'm relevant!" It is a **Scatter-Gather** mechanism that mimics the wave-propagation of neural activity.

---

### 3.0. The Anatomy of a Memory: The Tripartite Node Structure
To facilitate this complex behavior, a "Node" in the ACMS is not a simple JSON blob. It is a highly structured entity composed of three distinct parts, mirroring the anatomy of a biological cell (Nucleus, Cytoplasm/Membrane, and Receptors).

The definition is found in `cms/core/structs/node.ex`. A Node is composed of the **Head**, the **Body**, and the **Antenna**.

#### 3.1. The NodeHead (`cms/core/structs/node_head.ex`)
The **Head** represents the "Cognitive Engine" of the node. It contains the data required for the node to interact with the embedding space and manage its own energy. It is the "Brain of the Cell."

*   **`embedding` (Nx.Tensor):** The high-dimensional vector representation of the fact. This is the "soul" of the node, used for cosine similarity calculations. It is kept in memory as an `Nx` tensor for ultra-fast, hardware-accelerated math operations.
*   **`embedding_model_version` (String):** Tracks which AI model (e.g., "all-MiniLM-L6-v2") created the embedding. This is critical for the **Model Drift** system (`CMS.ModelDriftManager`), which monitors for nodes using obsolete models and queues them for "re-imagining."
*   **`internal_state` (Atom):** The metabolic clock. This state determines how "expensive" it is to fire this node.
    *   `:high_energy`: The node is active, young, or frequently visited. It has a low firing threshold (easy to activate).
    *   `:low_energy`: The node is aging. It requires a stronger query signal to wake up.
    *   `:hibernating`: The node is near death. It is invisible to standard queries and is a candidate for garbage collection (`CMS.DecayManager`).
*   **`relevance_threshold` (Float):** The "Synaptic Gap." The minimum similarity score required for this node to fire. This is not static; it is modulated by the `Antenna` and the `ActivationEngine`.

#### 3.2. The NodeBody (`cms/core/structs/node_body.ex`)
The **Body** is the "Vessel of Truth." It holds the actual information the system is remembering, along with the metadata that defines its relationships and security. The Body is further subdivided into three crucial components:

1.  **`DataHead` (`data_head.ex`): The Semantic Anchor.**
    *   Must be a single, declarative natural language sentence (e.g., *"The Mars Rover detected high levels of perchlorate."*).
    *   This is the text that generates the embedding found in the `NodeHead`. It serves as the human-readable summary of the memory.

2.  **`DataBody` (`data_body.ex`): The Polymorphic Payload.**
    *   Unlike the Head, this part is not embedded. It is the "Evidence" or the "Detail."
    *   It utilizes a **Format ID (FID)** system to store diverse data types safely. This allows the memory to store raw data without confusing the embedding model.
    *   **FID Types:**
        *   `Text`: Detailed descriptions or prose.
        *   `Code`: Executable snippets (Elixir, Python) that "Specialist Agents" can compile and run.
        *   `Number`: Structured data for regression/math agents.
        *   `Link`: Pointers to external resources (IPFS, Web).
    *   **Validation:** The `CMS.FIDValidator` ensures that ingestion requests adhere to strict schema rules, preventing "memory corruption."

3.  **`DataTail` (`data_tail.ex`): The Administrative Ledger.**
    *   Crucially located *inside* the Body, the Tail manages the node's topology and provenance. It defines "where this node fits" in the universe.
    *   **`relationship_metadata` (List of `Edge`):** The Connectome.
        *   This is the list of outgoing connections.
        *   **The Edge Struct (`edge.ex`):**
            *   `type`: Explicit typing (Gap B remediation). Links can be `:semantic` (similar), `:dependency` (requires), `:contradicts` (dialectical), or `:causes` (logic). This allows for **Causal Reasoning** chains.
            *   `weight`: A float (0.0 - 1.0) representing the strength of the association. This weight changes dynamically via **Hebbian Learning**.
            *   `last_used_at`: Used by the `DecayManager` to prune dead links ("Active Forgetting").
    *   **`acls` (Map):** Access Control Lists. The system implements granular security. A memory can be private to a specific Agent ID.
    *   **`salience_score`:** The base importance of the node, calculated at ingestion.
    *   **`checksum`:** The content-addressable hash of the Head and Body.

#### 3.3. The NodeAntenna (`cms/core/structs/node_antenna.ex`)
The **Antenna** represents the "Synaptic Transceiver" of the node. It is the interface between the Node and the outside world (the PubSub bus).

While the `Head` contains the logic for *evaluation*, the `Antenna` determines the **sensitivity** of the node to incoming signals.

*   **`gain` (Float):** A multiplier applied to incoming signals.
    *   High Salience nodes (Critical Errors, Security Alerts) are initialized with High Gain (~2.0).
    *   This means even a weak query signal will trigger them. They are "loud" memories.
    *   Low Salience nodes (Debug logs) have Low Gain (~0.5). You must query for them explicitly and accurately to find them.
*   **`activation_frequency` (Float):** A rolling metric of how often this node fires.
    *   This feeds into the metabolic logic. High frequency keeps the `NodeHead` in `:high_energy` state.
    *   If frequency drops, the Antenna signals the Head to downgrade to `:low_energy`.
*   **`signal_modulations` (Map):** Real-time overrides.
    *   Allows the system to temporarily boost or suppress specific nodes based on global states (e.g., "Emergency Mode" boosts all security-related antennas).

---

### 4.0. Ingestion: The Gatekeeper of Reality
In a standard RAG system, ingestion is a simple ETL pipeline: Text -> Vector -> DB. In the ACMS, ingestion is a **Cognitive Process** involving arbitration, conflict detection, and trust evaluation. This is handled by the `CMS.IngestionEngine` (`cms/services/ingestion_engine.ex`).

#### 4.1. The Zero-Friction Ingestion Protocol
The system is designed to ingest "Atomic Thoughts." You do not ingest a document; you ingest a Fact.

1.  **Validation:** The payload is checked against `FIDValidator`.
2.  **Embedding:** The `CMS.Tool.Embedder` bridges to Python to generate the vector.
3.  **Salience Calculation:** The `CMS.SalienceEngine` determines how "important" this new fact is.
    *   It uses a fallback mechanism: It tries a Machine Learning classifier first. If the ML bridge is down, it falls back to heuristics (keyword scanning for "critical", "error", etc.).
    *   High salience results in a high initial **Antenna Gain**, making the memory "loud" and easily retrievable.

#### 4.2. Conflict Detection & Trust-Based Arbitration
This is one of the most sophisticated features of the ACMS, distinguishing it from RAG. The system solves **Cognitive Dissonance**.

When a new node is ingested, the system performs a **Scatter-Gather** check (`check_for_conflict/1` in `IngestionEngine`) to see if a semantically identical node already exists.

If a conflict is found (e.g., New Fact: *"Sky is Green"* vs. Old Fact: *"Sky is Blue"*), the system invokes **Trust-Based Arbitration**:

1.  **Supersedence:**
    *   If the New Node comes from a source with a significantly higher `trust_score` (defined in Provenance) than the Old Node, the Old Node is marked as `:superseded`.
    *   An edge is created: `Old --[superseded_by]--> New`.
    *   This preserves history while updating truth.

2.  **Dialectical Merge:**
    *   If the trust scores are similar, the system acknowledges ambiguity.
    *   It spawns a **MetaNode** (`CMS.MetaNode`). This is a special node that represents the conflict itself.
    *   **Structure:** `Thesis (Old) <--> Synthesis (MetaNode) <--> Antithesis (New)`.
    *   This allows the system to answer queries like *"Is the sky blue?"* with *"There is a conflict in the data: Source A says Blue, Source B says Green."*

#### 4.3. Automated Association (Hebbian Priming)
Upon ingestion, a node should not be an island. The `IngestionEngine` performs **Hebbian Priming**.
*   It immediately queries the existing graph for similar nodes.
*   It creates initial `:semantic` edges to the top matches.
*   This ensures that new knowledge is immediately integrated into the "Latent Space" of the brain.

---

### 5.0. Content Addressability and Identity
The ACMS enforces **Content-Addressable Memory (CAM)** principles via the `CMS.NodeFactory` (`cms/core/logic/node_factory.ex`).

In a standard DB, IDs are auto-incrementing integers or random UUIDs. In ACMS, the ID of a node is a **SHA-256 hash** of its content (Truth + Provenance).

*   **Logic:** `hash(DataHead + DataBody + Provenance)`.
*   **Implication:** If two agents independently discover the same fact, they will generate the same ID. This automatically handles de-duplication at the identity level.
*   **Exclusion:** Note that `DataTail` (Edges, Salience) is *excluded* from the hash. A node's relationships change over time (neuroplasticity), but its Identity (the fact it represents) remains constant.

---

### 6.0. The Persistence Layer: Chrono-Stack and Vectors
While the system runs in RAM (active memory), it requires persistence. The ACMS uses a dual-persistence strategy detailed in `cms/infrastructure/persistence`.

#### 6.1. The Epoch Log (`CMS.EpochManager` & `CMS.LogAppender`)
*   **Philosophy:** History is immutable.
*   **Mechanism:** All events (Creation, Updates, Decay, Hebbian Weights) are appended to a JSONL file called an **Epoch Log**.
*   **Chrono-Stack:** By replaying these logs up to a specific timestamp, the `CMS.TemporalQueryEngine` can reconstruct the state of the brain as it existed at any point in the past. This provides "Time Travel" capabilities for debugging hallucination or auditing reasoning chains.

#### 6.2. The Vector Router (`CMS.VectorRouter`)
*   **Role:** The spatial index.
*   **Technology:** Wraps `HNSWLib` (Hierarchical Navigable Small Worlds) via Elixir NIFs.
*   **Function:** While `NodeActors` handle associative lookups, we need an entry point. The `VectorRouter` allows us to turn a raw text query into a set of entry-point Node IDs based on approximate nearest neighbor (ANN) search.
*   **Remediation:** The codebase includes critical fixes for dimensionality mismatches (handling 1D vs 2D tensors) and NIF safety (using `phash2` for ID generation).

---

### 7.0. Summary of Part 1
We have established the physical body of the ACMS. We have a decentralized mesh of `NodeActors` (Neurons), connected by weighted `Edges` (Synapses) stored in their `DataTail`, tuned by `NodeAntennas`, and validated by strict `FID` protocols.

This structure solves the **Static Context Problem** of standard RAG. Instead of retrieving documents based on keywords, we have created a system that creates distinct, addressable, and interconnected memories.

Here is **Part 2** of the ACMS README. This section focuses on the runtime dynamics—the "Physiology" of the system—detailing how the static structures defined in Part 1 come alive to think, learn, and regulate themselves.

***

# The Associative Cognitive Memory System (ACMS)
## Part 2: System Dynamics, Spreading Activation, and Homeostasis

### 8.0. Introduction: From Structure to Physiology
In Part 1, we defined the **Anatomy** of the ACMS: the `NodeActor` (Neuron), the `Edge` (Synapse), and the `NodeAntenna` (Receptor). These structures provide the *potential* for intelligence, but they are inert without a mechanism to drive them.

Part 2 describes the **Physiology** of the system. It explains the runtime dynamics that occur when a query enters the cognitive mesh. We will explore how the system implements **Spreading Activation** (the "Train of Thought"), how it regulates its own activity through **Homeostasis** (Global Inhibition), and how it physically alters its own structure over time through **Neuroplasticity** (Hebbian Learning).

This is not a description of data retrieval; it is a description of a **Cognitive Event**.

---

### 9.0. The Activation Cycle: The Physics of "Thinking"
In a standard Vector Database, a query is a geometric operation: "Find the nearest points in high-dimensional space." In the ACMS, a query is a **Signal Propagation Event**. It follows a biological model where activation starts at a specific locus and spreads through the network based on synaptic weights and signal strength.

The lifecycle of a "Thought" in this system follows four distinct phases, orchestrated by the `CMS.BroadcastCoordinator` and the `CMS.QueryCoordinator`.

#### 9.1. Phase 1: The Broadcast (Signal Injection)
The process begins when the `CMS.Web` interface receives a query. Instead of looking up an index, it initiates a decentralized broadcast.

1.  **The Coordinator:** A `CMS.QueryCoordinator` process is spawned (`cms/agents/query_coordinator.ex`). Its job is to manage the lifecycle of this specific thought, ensuring it doesn't persist forever or cause a system crash.
2.  **The Broadcast:** The `CMS.BroadcastCoordinator` (`cms/infrastructure/communication/broadcast_coordinator.ex`) takes the query vector and transmits it to the **Cognitive Bus** (Phoenix PubSub).
3.  **The Target:** Unlike centralized systems, the query is sent to *every active* `NodeActor` in the targeted Semantic Regions. This is the "Ghost in the Machine" principle—there is no central brain deciding what is relevant. The memories themselves must decide.

#### 9.2. Phase 2: Autonomous Evaluation (Primary Activation)
Every `NodeActor` listens to the bus. When a query signal arrives, the node wakes up and performs **Autonomous Query Evaluation** (`node_actor.ex` -> `autonomous_query_evaluation/2`).

This is a critical divergence from standard search. The node does not just compare vectors; it runs a complex internal calculation to determine if it "cares" about the signal.

**The Decision Formula:**
The node calculates a local Relevance Score (Cosine Similarity). However, simply having a high similarity score is *not* enough to fire. The node compares this score against a dynamically adjusted threshold:

$$
\text{Threshold}_{adjusted} = \frac{\text{BaseThreshold}}{\max(0.1, \text{InhibitionFactor})} \times \text{MetabolicCost}
$$

*   **BaseThreshold:** The intrinsic confidence required (stored in `NodeHead`).
*   **InhibitionFactor:** A global variable from the `ActivationEngine` (see Section 10.0). If the system is stressed (0.1), the threshold skyrockets, silencing all but the most relevant nodes.
*   **MetabolicCost:** Derived from `internal_state`.
    *   `:high_energy` nodes (cost 0.9) differ slightly in favor of firing.
    *   `:hibernating` nodes (cost 1.5) are groggy; they refuse to wake up for anything less than a perfect match.

**The Outcome:**
If `Relevance >= Threshold`, the node **Fires**. It emits a "Primary Activation" event back to the `QueryCoordinator` and transitions its internal state to `:high_energy`.

#### 9.3. Phase 3: Spreading Activation (The Pulse)
This is where "Retrieval" becomes "Reasoning." A standard database stops at Phase 2. The ACMS continues.

When a node fires, it does not just report its data; it checks its **Antenna Gain**. If the signal is strong enough, the node becomes a transmitter. It iterates through its `DataTail.relationship_metadata` (Edges) and sends a secondary **Pulse** to its neighbors.

*   **The Mechanism:** `NodeActor.fire_node/5`.
*   **The Payload:** The pulse contains the original query context, but with a **Boosted Score**.
*   **The Trace:** To prevent infinite loops (A -> B -> A), the pulse carries a `MapSet` trace of all visited nodes. A node will not fire if it is already in the trace.
*   **TTL (Time To Live):** The pulse has a decay counter (e.g., 2 hops). This limits the "depth" of the thought, preventing the entire brain from lighting up at once.

#### 9.4. Phase 4: Associative Resonance (Secondary Activation)
A neighbor receiving a Pulse (`handle_info({:pulse...})`) undergoes **Secondary Activation**.

It does *not* match the query vector against its own embedding. Instead, it asks: *"My neighbor fired. Do I trust them enough to fire too?"*

**The Associative Boost Calculation:**
The strength of the pulse is modulated by the specific **Edge Type** connecting the nodes (`calculate_associative_boost/3` in `node_actor.ex`):

*   `:dependency` (Strong): "I cannot exist without the activator." (1.0x strength).
*   `:causes` (Logic): "The activator caused me." (0.9x strength).
*   `:semantic` (Weak): "We are somewhat related." (0.8x strength).
*   `:contradicts` (Damping): "I disagree with the activator." (0.2x strength).

**Synaptic Damping:**
The code implements a "Synaptic Resistance" factor (0.3). This prevents **Hub Dominance**. Without this, a "Hub Node" (like a node representing the concept "The") would fire constantly, activating the entire graph. The damping ensures that associative links act as "contextual whispers" rather than shouting matches.

**The Result:**
If the boosted signal overcomes the neighbor's threshold, it fires too. This brings context into the result set that has *zero vector similarity* to the original query but is causally related.

---

### 10.0. Homeostasis: The Activation Engine
Biological brains are prone to **Epileptic Seizures**—uncontrolled feedback loops where every neuron fires simultaneously. In a software cognitive system, this manifests as a "Cognitive Explosion," where a broad query (e.g., "Tell me everything") activates 100% of the nodes, crashing the CPU and filling the context window with noise.

The ACMS solves this via the `CMS.ActivationEngine` (`cms/services/activation_engine.ex`), implementing **Global Inhibition**.

#### 10.1. The Inhibition Factor
The `ActivationEngine` monitors the "Congestion Level" of the system.
*   **Idle System:** Congestion 0.0 -> Inhibition Factor 1.0 (Full Sensitivity).
*   **Stressed System:** Congestion 1.0 -> Inhibition Factor 0.1 (Max Inhibition).

This factor is stored in a public **ETS (Erlang Term Storage)** table (`:cms_global_inhibition_factor_ets`) for ultra-fast, lock-free concurrent reads by millions of NodeActors.

#### 10.2. Negative Feedback Loop
This creates a control loop:
1.  A broad query causes massive activation.
2.  The `QueryCoordinator` detects the surge (>100 nodes fired).
3.  It signals the `ActivationEngine` to raise congestion.
4.  The Inhibition Factor drops.
5.  Node thresholds rise (`Base / Inhibition`).
6.  Fewer nodes fire in the next millisecond.
7.  The seizure is quelled.

This implies the ACMS has "moods." In a high-stress environment, it becomes skeptical and taciturn (only responding to high-confidence matches). In a low-stress environment, it becomes creative and associative (exploring weak links).

---

### 11.0. The Cognitive Bus: Infrastructure & Coordination
The "Nervous System" connecting these components is built on `Phoenix.PubSub` and `Broadway`.

#### 11.1. The BusPipeline (`cms/infrastructure/communication/bus_pipeline.ex`)
Why not just use direct function calls? Because of **Back-Pressure**.
If 10,000 queries arrive instantly, spawning 10,000 broadcasts would crash the VM.

The `BusPipeline` acts as a shock absorber.
*   **Producer:** `CMS.QueryRouter`. Buffers incoming requests.
*   **Consumer:** `BusPipeline` (Broadway). Consumes requests at a controlled rate (`concurrency: 50`).
*   **Batching:** Queries are batched before broadcasting.

This architecture ensures that the system degrades gracefully under load rather than failing catastrophically.

#### 11.2. The Query Coordinator: Winner-Takes-Most
The `CMS.QueryCoordinator` (`cms/agents/query_coordinator.ex`) is responsible for collecting the thoughts of the network. It implements a critical optimization called the **Gathering Window**.

*   **The Problem:** In a decentralized system, you don't know *when* the last node will finish thinking. Waiting for a fixed timeout (e.g., 5 seconds) makes the system slow.
*   **The Solution:**
    1.  The Coordinator waits for the *first* result to arrive.
    2.  Once the first node fires, it starts a short timer (`@gathering_window = 50ms`).
    3.  It assumes that the most relevant nodes (Direct Hits) will fire almost simultaneously.
    4.  After 50ms, it closes the window and returns the results.
    5.  Late arrivals are ignored.

This effectively implements a **Winner-Takes-Most (WTM)** mechanism. We don't want *all* answers; we want the strongest answers, fast.

---

### 12.0. Neuroplasticity: Hebbian Learning
A static database is dead. The ACMS learns. The principle is **Hebbian Theory**: *"Neurons that fire together, wire together."*

If Node A fires, and its pulse causes Node B to fire, and the resulting set of information is deemed "useful" (e.g., accessed by the user), the bond between A and B must be strengthened.

#### 12.1. The Feedback Loop
The implementation is found in `NodeActor.handle_info({:pulse...})` and `handle_cast({:hebbian_reinforce...})`.

1.  **Stimulus:** Node A pulses Node B.
2.  **Activation:** Node B fires.
3.  **Feedback:** Node B immediately sends a cast *back* to Node A: *"You activated me. Strengthen our link."*
4.  **Reinforcement:** Node A finds the `Edge` pointing to Node B in its `DataTail` and increments the `weight`.

#### 12.2. The Regional Hebbian Buffer (`cms/learning/regional_hebbian_buffer.ex`)
Constantly writing these tiny weight updates to disk (the Epoch Log) would destroy I/O performance. The ACMS uses a **Sharded Write-Behind Buffer**.

*   **Sharding:** There are 32 `RegionalHebbianBuffer` processes (`cms/learning/hebbian_buffer_supervisor.ex`).
*   **Aggregation:** Updates are routed to a shard based on the Semantic Region ID. The buffer aggregates updates in memory (ETS).
    *   `{"NodeA", "NodeB"} += 0.05`
    *   `{"NodeA", "NodeB"} += 0.01`
    *   Result: `+0.06`
*   **Flushing:** Every few seconds (or when the buffer is full), the aggregated weights are flushed to the `LogAppender` in a single batch operation.

This allows the system to support "High-Velocity Learning"—it can adjust its own topology thousands of times per second without touching the disk.

---

### 13.0. Active Forgetting: The Decay Manager
A brain that remembers everything eventually becomes useless—it gets clogged with noise. Forgetting is as important as learning.

The `CMS.DecayManager` (`cms/services/decay_manager.ex`) runs in the background, enforcing **Evolutionary Pressure** on memories.

#### 13.1. Differential Decay
It's not just about deleting nodes; it's about degrading connections.
*   **Edges:** Every `Edge` has a `last_used_at` timestamp.
*   **The Cycle:** Periodically, the Decay Manager instructs nodes to scan their edges.
*   **The Rot:** If an edge hasn't been traversed in 1 week, its weight is reduced (`weight - 0.001`).
*   **The Break:** If weight drops below 0.01, the edge is severed. The association is forgotten.

#### 13.2. Metabolic Eviction (The Zombie Cleanup)
Nodes themselves act like living cells.
*   If a node is rarely activated (`activation_frequency` low), its `internal_state` drops to `:low_energy`, then `:hibernating`.
*   The `DecayManager` runs an **Eviction Check**.
*   **Criteria:** If a node is `:hibernating` **AND** its total link strength to the rest of the network is weak (`< 0.1`), it is considered "Socially Isolated" and "Metabolically Dead."
*   **Action:** The process is terminated (`GenServer.stop`). The memory is erased from active RAM (though it remains in the immutable Epoch Log history).

This ensures the ACMS RAM usage stays efficient, populated only by relevant, active knowledge.

---

### 14.0. Model Drift: Keeping the Ghost in Sync
A unique challenge of Long-Term Memory in AI is that the "Brain" (the Embedding Model) changes. OpenAI releases `text-embedding-3-small`, rendering `text-embedding-ada-002` vectors obsolete. A standard vector DB requires a massive, blocking re-indexing job.

The ACMS handles this continuously via the `CMS.ModelDriftManager` (`cms/services/model_drift_manager.ex`).

1.  **Scanning:** It periodically polls nodes for their `embedding_model_version`.
2.  **Detection:** If a node says "I was embedded with `bert-v1`" but the system is running `all-MiniLM-L6-v2`, it is flagged.
3.  **Self-Repair:** The manager sends a cast to the node: `{:re_embed_request, "all-MiniLM-L6-v2"}`.
4.  **Action:** The node autonomously calls the `Embedder`, generates a new vector, and updates its own Head. It then unsubscribes from its old `SemanticRegion` and subscribes to the new one.

The system essentially "heals" itself, migrating its memories to the new latent space one by one without downtime.

---

### 15.0. Summary of Part 2
In Part 2, we have seen how the ACMS functions as a dynamic system.
*   **Thinking** is modeled as **Spreading Activation** with energy costs.
*   **Stability** is maintained via **Global Inhibition**.
*   **Learning** is physical rewiring via **Hebbian Buffers**.
*   **Efficiency** is enforced via **Metabolic Decay**.

The system is not just storing data; it is *experiencing* it.

Here is **Part 3** of the ACMS README. This final section bridges the gap between the theoretical architecture and practical reality. It covers the **Interface**, the **Operational Tools**, the **Temporal "Time Travel" Engine**, and the specific steps required to boot the system.

***

# The Associative Cognitive Memory System (ACMS)
## Part 3: Interface, Tools, Forensics, and Operations

### 16.0. Introduction: Interfacing with the Synthetic Mind
In Parts 1 and 2, we established the ACMS as a self-regulating, biologically inspired neural mesh. However, a brain in a jar is useless without sensory inputs (Ingestion) and motor outputs (Querying).

Part 3 details the **Universal Interface Layer** (`CMS.Web`), the **Observability Tools** (`LiveMonitor`), and the **Forensic Capabilities** (`TemporalQueryEngine`) that allow operators to interact with, visualize, and debug the cognitive processes of the system.

Unlike standard RAG pipelines which are "Black Boxes" (Input $\rightarrow$ Magic $\rightarrow$ Output), the ACMS provides "Glass Box" observability. You can watch the thoughts form in real-time.

---

### 17.0. The Universal Interface Layer (`CMS.Web`)
The system exposes its nervous system to the outside world via `CMS.Web` (`cms/interface/cms_web.ex`). This is a Supervisor that manages the HTTP (Cowboy/Plug) and WebSocket endpoints.

It is designed with **Defensive coding** principles:
*   **Size Limits:** Enforces a 10MB body limit to prevent memory overflow attacks.
*   **Atom Safety:** Uses `safe_atom_cast` to prevent "Atom Exhaustion" DoS attacks when parsing JSON payloads.
*   **Validation:** All inputs pass through the `CMS.FIDValidator` before touching the core logic.

#### 17.1. The REST API Endpoints
The API is not just for retrieval; it is for **Cognitive Manipulation**.

**1. Ingestion (`POST /api/v1/ingest`)**
*   **Purpose:** The only way to introduce new facts into the Mind.
*   **Logic:** Triggers the `IngestionEngine`.
*   **Return Codes:**
    *   `201 Created`: The node was accepted and spawned.
    *   `202 Accepted`: A **Conflict** was detected. The system performed a Dialectical Merge and spawned a `MetaNode` instead. This is a critical signal to the client that "Your truth is contested."

**2. Semantic & Temporal Query (`POST /api/v1/query`)**
*   **Purpose:** Initiates Spreading Activation.
*   **Dual-Mode:**
    *   **Live Mode:** If `as_of` is null, it broadcasts a query to the active mesh. Results are returned via the `QueryCoordinator`'s "Winner-Takes-Most" algorithm.
    *   **Time Travel Mode:** If `as_of` is a timestamp (ISO8601), it bypasses the active mesh and invokes the `TemporalQueryEngine` to perform forensic reconstruction (see Section 19.0).

**3. Anti-Hebbian Feedback (`POST /api/v1/nodes/:id/feedback`)**
*   **Purpose:** Reinforcement Learning.
*   **Mechanism:** If the AI produces a bad answer based on a specific node, the operator sends a "Penalization."
*   **Effect:** The `NodeActor` receives the cast `{:feedback, :irrelevant, ...}`. It reduces the weights of its connections. If a connection drops below 0.01, it is severed. This effectively "trains" the brain to stop associating those two concepts.

#### 17.2. The Subconscious Stream (WebSockets)
**Endpoint:** `ws://localhost:4000/api/v1/events`
*   **Handler:** `CMS.Web.SocketHandler`.
*   **Purpose:** Real-time telemetry.
*   **Signals:**
    *   `global:signals`: Broadcasts general events like Hebbian updates.
    *   `system_congestion`: Streams the current Inhibition Factor (0.0 - 1.0).
    *   `abnormality_signal`: Streams high-priority "pulses" (e.g., Critical Fact Activation).

This allows frontend dashboards to visualize the "Brain Activity" similar to an fMRI scan.

---

### 18.0. Ingestion in Practice: Polymorphic Payloads
To use the ACMS effectively, one must understand **Format IDs (FIDs)**. The system does not just store text; it stores typed data structures defined in `CMS.DataBodyPayload`.

#### 18.1. The JSON Structure
When POSTing to `/ingest`, the payload looks like this:

```json
{
  "agent_id": "ingestion_agent_01",
  "fact_text": "The Elixir NodeActor process uses 15% less RAM than the Python equivalent.",
  "provenance": {
    "source": "benchmarks_v2.pdf",
    "page": 42,
    "trust_score": 0.95
  },
  "description_payloads": [
    {
      "type": "text",
      "content": "Detailed memory usage logs show a steady state of 20MB vs 150MB."
    },
    {
      "type": "code",
      "language": "elixir",
      "content": "Process.info(self(), :memory)"
    },
    {
      "type": "number",
      "value": 15.5,
      "unit": "percent"
    }
  ],
  "acls": ["research_team"]
}
```

#### 18.2. Lifecycle of this Request
1.  **Validation:** `FIDValidator` confirms that the "code" payload actually has a language atom, and the "number" payload has a valid value.
2.  **Identity:** `NodeFactory` hashes the `fact_text` + `description_payloads` + `provenance` to generate the ID.
3.  **Arbitration:** `IngestionEngine` checks if we already know this fact.
4.  **Priming:** The system scans the network for related concepts (e.g., "Elixir," "Performance," "Python"). It creates initial edges.
5.  **Spawn:** A `NodeActor` spins up. It is now alive.

---

### 19.0. Temporal Forensics: The Chrono-Stack
One of the most dangerous aspects of LLMs is **Silent Hallucination**. You ask a question, get an answer, and you don't know *why* the AI said that. Worse, if the AI changes its mind tomorrow, you can't prove what it believed yesterday.

The ACMS solves this via the **Chrono-Stack**, managed by the `CMS.TemporalQueryEngine` (`cms/core/logic/temporal_query_engine.ex`).

#### 19.1. The Immutable History
The `CMS.EpochManager` (`cms/infrastructure/persistence/epoch_manager.ex`) ensures that nothing is ever overwritten.
*   **Rotation:** Logs are rotated every hour or every 100MB.
*   **Indexing:** Mnesia tracks the start/end time of every log file.

#### 19.2. State Reconstruction
When you query with `"as_of": "2023-10-27T10:00:00Z"`, the system performs a **Replay**:
1.  It queries Mnesia to find all Epoch Logs created *before* that timestamp.
2.  It streams the logs from disk (`File.stream!`).
3.  It replays every event (`node_created`, `node_updated`, `hebbian_update`) into an in-memory map.
    *   **Deep Merge:** It uses a recursive deep merge strategy to apply partial updates correctly.
    *   **Filtering:** It stops processing exactly at the target timestamp.
4.  **Vector Scan:** Since the past state is not in the live Vector Index, the engine performs a brute-force cosine similarity scan on the reconstructed memory snapshot.

**Result:** You get the exact state of the Knowledge Graph as it existed in the past. You can prove *why* the system made a decision, even if the nodes involved have since decayed or been superseded.

---

### 20.0. Tools: Visualizing the Matrix
Debugging a decentralized mesh of thousands of processes is impossible with standard log files. You need visualization.

#### 20.1. The Live Monitor (`CMS.Tools.LiveMonitor`)
Located in `cms/tools/live_monitor.ex` (and the `New Text Document.txt` remediation), this tool turns the IEx console into a Matrix-style dashboard.

**Usage:**
```elixir
iex> CMS.Tools.LiveMonitor.start()
```

**The Color Code:**
*   **`@magenta` (Neuroplasticity):** Fires when `RegionalHebbianBuffer` flushes. Shows the brain physically rewiring itself.
    *   *Example:* `[NEUROPLASTICITY] Node 8f2a... strengthened links to 14 neighbors.`
*   **`@yellow` (Conflict):** Fires when `IngestionEngine` arbitrates truth.
    *   *Example:* `[CONFLICT ARBITRATION] Node A SUPERSEDED Node B (Trust Dominance).`
*   **`@cyan` (Pulses):** Fires when a `NodeActor` triggers a high-level abnormality signal (e.g., "Emergency Mode").
*   **`@red` / `@blue` (Homeostasis):** Shows the `ActivationEngine` fighting congestion.
    *   *Example:* `[SYSTEM HOMEOSTASIS] Congestion Level: 0.8. Inhibition Factor modulated.`

This tool allows the operator to "feel" the health of the system. If the screen is scrolling too fast with Red/Blue messages, the brain is having a seizure (Cognitive Explosion). If it is silent, the brain is dormant.

---

### 21.0. The ML Bridge: Integrating Python
While Elixir handles the high-concurrency nervous system, it lacks the raw matrix-multiplication libraries for state-of-the-art Transformer models. The ACMS uses a **Microservice Bridge**.

*   **Elixir Side:** `CMS.Tool.Embedder` (`cms/tools/embedder.ex`). Uses `Req` to POST JSON to localhost.
*   **Python Side:** `ml_bridge.py` (Implied). A FastAPI service running `sentence-transformers`.
*   **Protocol:** JSON over HTTP.
    *   **Request:** `{"text": "...", "model_version": "all-MiniLM-L6-v2"}`
    *   **Response:** `{"vector": [0.12, -0.45, ...], "dimensions": 384}`


---

### 22.0. Operational Guide: Getting Started

#### 22.1. Prerequisites
1.  **Elixir 1.14+ / Erlang OTP 25+**: The runtime environment.
2.  **Python 3.9+**: For the ML Bridge.
3.  **Dependencies**:
    *   `phoenix_pubsub`: The Cognitive Bus.
    *   `broadway`: The Back-pressure pipeline.
    *   `hnswlib`: Vector indexing (NIF).
    *   `nx`: Numerical Elixir (Tensors).
    *   `req`: HTTP Client.

#### 22.2. Installation & Boot
1.  **Start the ML Bridge (Terminal 1):**
    ```bash
    pip install fastapi uvicorn sentence-transformers
    python ml_bridge.py # Assumed present
    # Output: Listening on port 5000
    ```

2.  **Start the ACMS (Terminal 2):**
    ```bash
    mix deps.get
    iex -S mix
    ```
    *   This boots `CMS.Application`.
    *   Supervisors start: `NodeRegistry`, `PubSub`, `EpochManager`, `VectorRouter`, `IngestionEngine`.

3.  **Activate Visualization:**
    ```elixir
    iex> CMS.Tools.LiveMonitor.start()
    ```

4.  **Ingest Knowledge:**
    ```bash
    curl -X POST http://localhost:4000/api/v1/ingest \
      -H "Content-Type: application/json" \
      -d '{ "agent_id": "user", "fact_text": "ACMS uses Elixir for concurrency.", "description_payloads": [{"type": "text", "content": "..."}] }'
    ```
    *   *Watch the LiveMonitor:* You should see Green (Ingestion) and then Magenta (Hebbian Priming) as it links "ACMS" to "Elixir."

5.  **Query:**
    ```bash
    curl -X POST http://localhost:4000/api/v1/query \
      -H "Content-Type: application/json" \
      -d '{ "query_text": "How does the system handle concurrency?" }'
    ```
    *   *Watch the LiveMonitor:* You will see the Broadcast, the Spreading Activation (Cyan), and the eventual result.

---

### 23.0. Limitations and The Grand Challenge
The ACMS represents a massive leap forward in Agentic Memory, but it is not without limitations.

#### 23.1. The "Gestalt" Problem
Graph memories are excellent for facts (`A -> B`), logic, and code. They are terrible for **Narrative**.
If you atomize a novel into 10,000 nodes, you lose the "vibe," the prose style, and the emotional arc. The ACMS is a left-brain system. It needs a right-brain counterpart (perhaps a standard RAG document store) to handle "gestalt" information.

#### 23.2. The Ingestion Bottleneck
The system is only as good as its decomposition.
*   **Garbage In, Garbage Out:** If you ingest a 50-page PDF as a single node, the embedding will be muddy, and the `Antenna` will be confused.
*   **The Challenge:** You need a highly sophisticated "Ingestion Agent" (likely an LLM) to read documents and break them down into atomic, declarative sentences (`DataHead`) before feeding them to the ACMS. The ACMS cannot digest raw data files directly; it needs "pre-chewed" cognitive atoms.

#### 23.3. Cold Start
A new ACMS is dumb. It has no edges. The **Hebbian Priming** helps, but the system truly shines only after it has been used for a few days. The topology needs time to "settle" based on user query patterns. This requires patience from the operator.

---

### 24.0. Final Conclusion
The **Associative Cognitive Memory System** is a blueprint for Synthetic Sentience.

It demonstrates that **Memory is not Storage; Memory is Process.**
*   By moving from passive rows to active Actors...
*   By moving from keyword search to spreading activation...
*   By moving from overwrite-updates to dialectical merges...

...we create a system that does not just "retrieve" information, but **reconstructs context** dynamically. It evolves. It forgets what doesn't matter. It learns from what does.

This codebase is not just a tool; it is an argument that the future of AI is not just bigger Context Windows, but **Agentic Long-Term Memory** that sits outside the model, guiding it like a conscience.
