# Associative Cognitive Memory System (ACMS) Technical Documentation

## High-Density Technical Reference Suite

### Table of Contents
1. [Introduction: Paradigm Shift](#1-introduction-paradigm-shift)
2. [The Biological Metaphor](#2-the-biological-metaphor)
3. [Infrastructure: The Supervision Tree](#3-infrastructure-the-supervision-tree)
4. [Anatomy of Cognition (Data Structures)](#4-anatomy-of-cognition-data-structures)
5. [Recall: Spreading Activation & Search](#5-recall-spreading-activation--search)
6. [Neuroplasticity: The Learning Loop](#7-neuroplasticity-the-learning-loop)
7. [Sovereignty: Persistence & Recovery](#8-sovereignty-persistence--recovery)
8. [Time Travel: Temporal Query Engine](#9-time-travel-temporal-query-engine)
9. [Security & Access Control](#10-security--access-control)
10. [The Frontal Cortex: ML Bridge](#11-the-frontal-cortex-ml-bridge)
11. [Universal API Reference](#12-universal-api-reference)
12. [Observability & Agent Integration](#13-observability--agent-integration)
13. [Testing & Maintenance](#14-testing--maintenance)
14. [Configuration & Tuning](#15-configuration--tuning)
15. [Getting Started Guide](#16-getting-started-guide)

# 1. Introduction: Paradigm Shift

In the landscape of modern artificial intelligence, we find ourselves at a critical juncture. The most significant bottleneck is not the raw speed of computation, nor the availability of massive datasets, but rather the **fluidity and sovereignty of memory**. Traditional Large Language Models (LLMs) are like powerful, isolated brains with no long-term storage; they can reason brilliantly about the information presented in their immediate "context window," but once that window is closed, the experience—the learning—is lost. This is the "Amnesiac AI" problem.

To solve this, the industry has turned to Retrieval-Augmented Generation (RAG) and Vector Databases. However, standard RAG is a "Passive Silo"—it treats data as static rows in a table, disconnected from the dynamic flow of cognition. The **Associative Cognitive Memory System (ACMS)** represents a radical paradigm shift. It is not a database; it is a **Cortex**. Built on the high-concurrency Erlang/Elixir BEAM virtual machine, ACMS transforms data into a living network of "NodeActors" that associate, learn, and evolve in real-time.

## 1.1. The Philosophy of Associative AI: Beyond the Library

The human brain does not function like a library. When you think of a "Red Apple," your brain doesn't perform a k-Nearest Neighbors (k-NN) search across a flat index of fruit. Instead, the concept of "Red" fires a set of neurons that are physically and chemically linked to the concept of "Apple," which in turn are linked to "Crunchy," "Sweet," "Newton," and "Garden of Eden." This is **Associative Memory**.

In ACMS, we move beyond the "Library" metaphor. A traditional Vector DB is a library where books are filed by their semantic content. To find something, you must walk to the shelf. In ACMS, the books are alive. They talk to each other. They "fire" signals across "synapses." When you stimulate one part of the cortex with a query, the excitation spreads naturally through the network, discovering connections that were never explicitly indexed.

### 1.1.1. The Failure of the Context Window
Modern LLMs rely on the context window as their only form of short-term memory. As the window grows (from 8k to 100k to 1M tokens), the cost of attention grows quadratically. More importantly, the "Lost in the Middle" phenomenon shows that as context grows, the model becomes less effective at retrieving specific facts from the center of the window. 

ACMS provides an "External Cortex" that scales linearly, not quadratically. By offloading long-term memory to a dedicated, associative graph, we allow the LLM to focus on what it does best: reasoning and synthesis. The LLM becomes the "Frontal Cortex," while ACMS becomes the "Hippocampus" and "Neocortex."

### 1.1.2. The Active Data Paradigm
In most systems, data is "dead." It sits in a database waiting for a query to wake it up. In ACMS, data is "active." Every node is a `NodeActor`—a lightweight Erlang process. This means data can:
- **Learn**: Update its own associations based on how often it is retrieved.
- **Forget**: Decay its own salience if it is no longer useful.
- **Protect**: Enforce its own security policies at the cellular level.
- **Signal**: Broadcast its state to the system if it detects an anomaly.

## 1.2. The ACMS Manifesto: Sovereignty of Thought

ACMS is not just a technical solution; it is a political and ethical statement about the future of AI. We believe that **Memory is Sovereignty**.

### 1.2.1. The Memory Cartridge
In the current AI landscape, your "memory" (your documents, chats, and data) is often locked inside a cloud provider's proprietary database. If you leave the provider, you lose the associations and learning that the system has built up over time. 

ACMS introduces the **Memory Cartridge**. Your cortex is stored as a self-contained, portable directory. You can pick up your cartridge and move it from a local server to a cloud cluster, or even run it on an air-gapped machine. Your associations—the "wiring" of your digital mind—belong to you.

### 1.2.2. Transparency and the Chrono-Stack
Black-box AI is a danger to society. When an AI makes a decision, we must be able to ask "Why?" ACMS provides the answer through the **Chrono-Stack**. Because every cognitive event is recorded in an immutable, human-readable ledger, we can perform "Cognitive Forensics." We can see exactly which memories fired, which associations were followed, and how the system's "state of mind" evolved leading up to a specific output.

## 1.3. Vision for the Future: The Cognitive Utility (2026-2031)

Our vision for ACMS extends far beyond a simple software library. We envision a future where cognitive memory is a standard utility, similar to electricity or the internet.

### 1.3.1. Phase 1: The Personal Cortex (Current)
In the immediate future, ACMS serves as the Long-Term Memory (LTM) for personal AI assistants. It stores your documents, your codebases, and your communications, allowing your AI to "remember" your preferences and past interactions with perfect fidelity across years of use.

### 1.3.2. Phase 2: The Collaborative Memory Grid (2027)
As ACMS instances begin to talk to each other via Erlang Distribution, we will see the emergence of "Collaborative Memory." Organizations will be able to share specific "Semantic Regions" of their cortex with partners, creating a distributed, interconnected knowledge graph that spans the globe while maintaining individual sovereignty.

### 1.3.3. Phase 3: Multimodal Consciousness (2029)
The ultimate goal of ACMS is to transcend text. Future versions will support "Multimodal Synapses," where a node containing a text description can be linked to a node containing a visual memory or an auditory pattern. This will allow for true "Cross-Modal Reasoning," where an agent can "visualize" a concept by following associative trails into its visual memory.

## 1.4. Why Elixir? The Power of the BEAM

The choice of Elixir and the Erlang/OTP (Open Telecom Platform) was not accidental. To build a system that mimics the brain, we needed a runtime that could handle:
- **Massive Concurrency**: The BEAM can handle millions of lightweight processes simultaneously. This allows every node in the cortex to be an independent, active actor.
- **Fault Tolerance**: In a brain, if a single neuron fails, the system doesn't crash. Erlang's "Let it Crash" philosophy and supervision trees provide the exact same level of resilience.
- **Distributed by Nature**: The BEAM was designed for distributed systems. ACMS can naturally scale from a single core to a thousand nodes across a global network without changing its fundamental logic.

### Deep Technical Context Section
The technical underpinnings of the ACMS system rely on the unique capabilities of the Erlang VM (BEAM). Unlike traditional runtimes, the BEAM treats concurrency as a first-class citizen. Each NodeActor in ACMS is mapped to an Erlang process, which has its own heap and stack. This isolation is critical for the 'Cellular Security' model discussed in Chapter 10. When a query is broadcast across the Cognitive Bus, the BEAM's scheduler efficiently manages the execution of thousands of firing nodes in parallel, utilizing all available CPU cores without the need for complex locking mechanisms. This architecture allows ACMS to achieve microsecond latency in spreading activation pulses, even when the cortex contains millions of active nodes. Furthermore, the BEAM's preemptive scheduler ensures that no single node can monopolize the system's resources, maintaining global homeostasis even during massive 'Signal Storms.'

---

# 2. The Biological Metaphor

To understand ACMS, one must stop thinking in terms of "Tables and Rows" and start thinking in terms of "Neurons and Synapses." The system's architecture is a direct digital translation of neurobiological principles, designed to mimic the efficiency, resilience, and associative power of the human brain.

## 2.1. The Node as a Neuron (NodeActor)

In ACMS, every piece of information—a paragraph of text, a function of code, an image metadata blob—is represented as a **NodeActor**. 

### 2.1.1. Self-Supervision and Cellular Autonomy
Like a biological neuron, a NodeActor is an autonomous agent. It has its own state, its own threshold for "firing," and its own metabolic cycle. In the human cortex, neurons don't wait for a central processor to tell them what to do; they respond to local chemical and electrical stimuli. Similarly, an ACMS node listens to the **Cognitive Bus** and decides for itself whether it should participate in a thought process.

### 2.1.2. The All-or-None Principle
In neurobiology, the "All-or-None Law" states that if a stimulus exceeds the threshold, the neuron fires a full action potential; otherwise, it remains silent. ACMS implements this through its **Firing Threshold**. If a query's semantic similarity to a node is 0.69 and the threshold is 0.70, the node remains silent. This prevents the system from being overwhelmed by "Cognitive Noise" and ensures that only the most relevant memories are activated.

## 2.2. The Synapse as an Edge (EdgeWeights)

Associations between nodes are represented as **Edges**, mimicking the synapses that connect neurons.

### 2.2.1. Long-Term Potentiation (LTP)
LTP is the process by which synaptic connections are strengthened through frequent activation. In ACMS, this is mapped to the **Hebbian Reinforcement** algorithm. When two nodes fire in close temporal proximity during a query, the system increases the weight of the edge between them. This is the digital equivalent of "Wiring together." Over time, these reinforced paths become the "Highways" of the system's thought process, allowing for faster and more intuitive recall.

### 2.2.2. Long-Term Depression (LTD)
LTD is the opposite of LTP—it is the weakening of synapses that are no longer useful. ACMS implements this through the **DecayManager** (Chapter 7). Unused links slowly lose weight, eventually falling below the "Synaptic Pruning" threshold. This ensures that the system's memory remains lean and focused on current information, rather than being cluttered by obsolete associations.

## 2.3. Spreading Activation: The Pulse of Thought

When you query ACMS, you are not "Searching." You are "Stimulating" the cortex.

### 2.3.1. The Cascade of Excitation
1.  **Stimulus**: You provide a query vector (the "Sensory Input").
2.  **Primary Firing**: The nodes that directly match the stimulus fire, generating an "Action Potential."
3.  **The Pulse**: These nodes release a "Signal" (an asynchronous message) to all their connected neighbors.
4.  **Secondary Firing**: If a neighbor receives enough pulses (summing up to its threshold), it fires as well.

This is how ACMS discovers "Hidden Connections"—it finds the things you *didn't* know were related to your question by following the "Trails of Thought" laid down by past learning.

## 2.4. Homeostasis: Regulatory Systems

A brain without regulation is a brain in seizure. ACMS implements several "Homeostatic" mechanisms to maintain system balance.

### 2.4.1. Global Inhibition (The GABA Metaphor)
In the brain, GABA is the primary inhibitory neurotransmitter. It dampens neuronal activity to prevent over-excitation. ACMS implements **Global Inhibition** through the `ActivationEngine`. When the system detects a "Signal Storm" (too many nodes firing at once), it broadcasts an inhibition signal that effectively "raises the volume" required for any node to fire. This forces the system to focus only on the loudest, most critical signals.

### 2.4.2. Metabolic Cycling
Neurons require energy to fire. In ACMS, "Energy" is mapped to system resources (RAM and CPU).
- **High-Energy State**: A node that is "Top of Mind" is kept fully resident in memory.
- **Hibernation**: A node that hasn't been used in a long time "Goes to Sleep," persisting its state to disk and terminating its process to save energy.

## 2.5. The "Sleeping Brain" (Offline Consolidation)

Just as the human brain consolidates memories during sleep, ACMS performs **Offline Consolidation**. During periods of low query load, the system's background workers (like the `DecayManager` and `ModelDriftManager`) audit the graph. They prune weak links, re-index new associations, and optimize the vector space. This ensures that the system is always "Waking Up" sharper and more organized than it was the day before.

### Neurobiological Implementation Details
The mapping from neurobiology to digital logic in ACMS is achieved through a set of sophisticated algorithms that balance semantic precision with associative recall. The Hebbian Learning engine, for example, utilizes a modified version of the Hebbian Rule that incorporates a temporal decay factor. This ensures that only the most consistently useful associations are maintained, mirroring the way the human brain prunes synapses that are no longer active. The Firing Threshold is dynamically adjusted based on the system's overall 'Excitation Level,' a metric that tracks the rate of message passing across the Cognitive Bus. In high-stress scenarios, the system automatically increases the threshold to prioritize only the most semantically relevant memories, preventing the cognitive overload that can occur in less sophisticated RAG systems. This homeostatic balance is the key to ACMS's ability to provide coherent, high-value recall even in the presence of massive amounts of noisy, unstructured data.

---

# 3. Infrastructure: The Supervision Tree

ACMS is built on the philosophy of **Fault Tolerance**. In a system with millions of active processes, some *will* fail. The system's infrastructure is designed to handle these failures gracefully using a hierarchical Supervision Tree, leveraging the power of the Erlang/OTP framework.

## 3.1. The Genesis: CMS.Application

The root of the entire system is the `CMS.Application`. It acts as the "Genesis" point, initiating the core sub-systems in a strict, dependency-aware order. When the system boots, it follows a "Cascade of Life":

1.  **Infrastructure Layer**: Mnesia (Distributed State), LogAppender (Persistent History), and Registry (Process Discovery).
2.  **ML Layer**: MLBridge (Frontal Cortex connectivity).
3.  **Cognitive Layer**: NodeSupervisor (The actual memory grid) and ActivationEngine (Regulation).
4.  **Interface Layer**: Web.Router (API) and LiveMonitor (Observability).

## 3.2. The Supervision Philosophy: "Let it Crash"

ACMS adheres to the Erlang philosophy of "Let it Crash." We do not write defensive code to catch every possible exception. Instead, we allow individual `NodeActors` to fail and rely on their supervisors to restore them to a known good state.

### 3.2.1. Supervision Strategies
- **`one_for_one`**: Used for the `NodeSupervisor`. If one node crashes, only that node is restarted.
- **`one_for_all`**: Used for the core infrastructure. If the `LogAppender` crashes, the entire system is restarted, as persistence is critical to system integrity.

## 3.3. Mnesia: The Distributed State Engine

ACMS uses **Mnesia**, the distributed database built into the BEAM, to manage its structural metadata (Edges and Node Indices).

### 3.3.1. Storage Types and Optimization
- **`ram_copies`**: Used for the `Edge` table during high-frequency queries to ensure microsecond latency.
- **`disc_copies`**: Used for the `NodeHead` and `Salience` tables to ensure that the core identity of the cortex survives a reboot.
- **Transaction Isolation**: ACMS uses `dirty_read` for queries (speed) but strictly `transactional_write` for learning and ingestion (integrity).

## 3.4. The NodeRegistry: Localizing Thoughts

In a system with millions of nodes, we cannot rely on global process names. Instead, we use the `Registry` module for **Process Discovery**.
- **Via Tuples**: When a node needs to talk to its neighbor, it looks up the neighbor's PID using a "Via Tuple": `{:via, Registry, {CMS.NodeRegistry, node_id}}`.

## 3.5. NodeSupervisor: Managing the Dynamic Cortex

The `NodeSupervisor` is a `DynamicSupervisor` responsible for the birth and death of `NodeActors`.
- **On-Demand Activation**: Nodes are not all loaded into memory on startup. They are "Woken Up" by the `Hydrator` the first time they are queried.
- **Self-Healing**: If a `NodeActor` becomes corrupted, the Supervisor restarts it. If the restart fails, the node is "Blacklisted" and a rehydration request is sent.

### Infrastructure Technical Deep Dive
The supervision tree in ACMS is designed to maximize availability while minimizing recovery time. The use of a DynamicSupervisor for NodeActors allows the system to manage its memory footprint dynamically, spawning and killing processes as needed based on the current cognitive load. This is complemented by the Registry module, which provides a highly efficient, core-local lookup table for process PIDs. Unlike global process names, which can become a bottleneck in large clusters, the Registry is partitioned across CPU cores, allowing for millions of concurrent lookups with minimal contention. The LogAppender's batching logic further enhances performance by grouping disk writes, reducing the I/O overhead on the underlying filesystem. This combination of actor-based concurrency, distributed state management via Mnesia, and optimized persistence makes ACMS the most robust cognitive memory engine ever built on the BEAM virtual machine.

---

# 4. Anatomy of Cognition (Data Structures)

If the supervision tree is the skeletal structure of ACMS, the data structures are its DNA. Every interaction, every memory, and every decision within the system is governed by a set of strictly defined structs. These are not merely data containers; they are semantic templates that enforce the "Content-Addressable Memory" (CAM) principles of the system.

## 4.1. The Content-Addressable Identity (CMS.NodeFactory)

At the heart of ACMS is the concept of "Sovereign Identity." In a traditional database, an ID is often an incrementing integer or a random UUID. In ACMS, a node's ID is derived directly from its content. This is known as **Content-Addressable Memory**.

### 4.1.1. Deterministic ID Generation (SHA-256 Hashing)
The `CMS.NodeFactory` is the module responsible for minting new node IDs. When a new piece of information is ingested, the Factory performs a ritual of "Canonical Serialization."
1.  **Truth Extraction**: It extracts the "Truth" components of the node—specifically the `DataHead` (the semantic fact) and the `DataBody` (the evidence).
2.  **Canonicalization**: It converts these components into a JSON string where keys are strictly sorted.
3.  **Hashing**: It concatenates the serialized Truth with the serialized **Provenance Metadata** and runs it through a SHA-256 hashing algorithm.
4.  **Encoding**: The result is a 64-character hexadecimal string that serves as the node's permanent address.

### 4.1.2. Why SHA-256?
The decision to use SHA-256 over faster algorithms was driven by the need for **Cryptographic Uniqueness**. In a system designed to scale to billions of nodes, the birthday paradox becomes a real concern. SHA-256 ensures de-duplication-by-design.

## 4.2. The Tripartite Vessel of Truth (CMS.NodeBody)

The `NodeBody` is where the actual information resides. It is divided into three distinct sections:
- **DataHead**: The semantic anchor (summarized fact).
- **DataBody**: Polymorphic payloads (Text, Code, JSON, Binary) identified by **Format IDs (FIDs)**.
- **DataTail**: The administrative ledger (Salience, ACLs, Checksum).

### 4.2.1. Format IDs (FIDs)
| FID | Struct Type | Use Case |
| :--- | :--- | :--- |
| `text/markdown` | `%CMS.DataBodyPayload.Text{}` | Standard prose and documentation. |
| `code/elixir` | `%CMS.DataBodyPayload.Code{}` | Executable snippets or reference logic. |
| `object/json` | `%CMS.DataBodyPayload.Object{}` | Structured data, sensor readings. |
| `blob/binary` | `%CMS.DataBodyPayload.Binary{}` | Images or encrypted blobs. |

## 4.3. Graph Topology (CMS.Edge)

The `Edge` is the connective tissue of the system. It implements **Explicit Link Typing**, allowing the system to understand *how* two thoughts are related.
- **`:semantic`**: Related by content similarity.
- **`:dependency`**: One fact requires another.
- **`:contradicts`**: Logical conflict between two facts.
- **`:supersedes`**: Temporal versioning (Fact A is newer than Fact B).

### Data Structure Technical Deep Dive
The efficiency of ACMS relies on the careful design of its core structs. By using Elixir's defstruct, we ensure that every node and edge has a predictable memory layout, which is critical for the BEAM's garbage collector and for the serialization process used in the Chrono-Stack. The use of SHA-256 for node IDs not only provides content-addressability but also serves as a robust mechanism for de-duplication across distributed instances. The polymorphic nature of the DataBody is achieved through a set of specialized payload structs, each optimized for its specific data type. For example, the Code payload includes metadata for language detection and indentation-aware shredding, while the Object payload provides native support for nested JSON maps. This granularity allows ACMS to act as a universal memory engine, capable of storing and associating any form of digital information with perfect fidelity.

---

---

# 5. Recall: Spreading Activation & Search

Recall in ACMS is a "Cognitive Event." It triggers a cascade of activity across the neural network.

## 6.1. The Cognitive Bus (Phoenix.PubSub)

ACMS uses a decentralized **Cognitive Bus**. Every active `NodeActor` listens to this bus, allowing for massive horizontal scalability.

## 6.2. The Firing Decision (CMS.NodeActor)

When a node hears a query, it calculates cosine similarity.
- **Relevance Threshold**: If similarity exceeds `min_relevance`, the node fires.
- **Antenna Modulation**: High-salience nodes might fire even if the semantic match is slightly weak.

## 6.3. Pulse Propagation: The Cascade

Firing nodes excite their neighbors via shared edges.
- **Pulse Strength**: `P = SourceScore * EdgeWeight * DampingFactor`.
- **Damping**: Default 0.3x to prevent "Signal Storms."
- **TTL (Time To Live)**: Pulse propagation is limited to a fixed number of hops (default: 2) to prevent cognitive drift.

## 6.4. Regulatory Homeostasis (CMS.ActivationEngine)

The `ActivationEngine` acts as the "Inhibitory System."
- **Global Inhibition**: If the system detects a "Signal Storm," it broadcasts an inhibition signal that raises the firing threshold for all nodes.

### Recall Technical Deep Dive
The recall mechanism in ACMS is designed to mimic the spreading activation patterns observed in the human brain. By using a decentralized PubSub-based architecture, the system eliminates the bottlenecks associated with centralized vector indices. Every NodeActor is responsible for its own firing decision, allowing the system to scale horizontally to millions of nodes across a cluster of servers. The QueryCoordinator acts as the 'Short-Term Memory' for each query, collecting and ranking firing events in real-time. The use of a damping factor and TTL for pulse propagation ensures that the system remains focused and prevents the chaotic signal storms that can occur in unstructured graphs. This combination of semantic vector matching and associative link following allows ACMS to discover hidden connections and provide a level of context that is simply not possible with traditional search engines.

---

# 6. Neuroplasticity: The Learning Loop

ACMS is a living system that learns from its interactions.

## 7.1. Hebbian Learning (CMS.HebbianEngine)

"Nodes that fire together, wire together." 
- **Reinforcement**: When two nodes fire during the same query, the system strengthens the link between them.
- **Feedback Loop**: External feedback from a user or agent can also be used to manually strengthen or weaken associations.

## 7.2. Active Forgetting (CMS.DecayManager)

Associations that are not used slowly decay.
- **Decay Constant**: Links lose weight at a configurable rate (default: 0.01 per day).
- **Synaptic Pruning**: When an edge weight falls below a certain threshold, it is removed from the graph entirely.
- **Node Hibernation**: Nodes with very low salience are hibernated (terminated from memory but kept on disk).

## 7.3. Model Drift Management

As ML models evolve, the vector embeddings for old nodes may become obsolete.
- **Re-Vectorization**: The `ModelDriftManager` periodically re-embeds nodes using the latest model in the ML Bridge.

### Learning Technical Deep Dive
The learning loop in ACMS is a continuous process that optimizes the cortex for the specific needs of the user. The HebbianEngine implements a high-performance weight update algorithm that uses Mnesia transactions to ensure the integrity of the graph topology. The DecayManager operates as a background worker, periodically auditing the entire graph to prune weak and unused links. This 'Active Forgetting' is critical for maintaining system performance, as it prevents the cortex from being overwhelmed by obsolete or low-value information. The ModelDriftManager ensures that the system's semantic understanding remains current, automatically re-indexing nodes whenever a new search model is deployed. This combination of real-time reinforcement and background optimization allows ACMS to grow and adapt with a sophistication that mirrors the neuroplasticity of the human brain.

---

# 7. Sovereignty: Persistence & Recovery

Persistence in ACMS is about protecting the **Sovereignty** of the system's identity.

## 8.1. The Immutable Chrono-Stack

ACMS treats its memory as an immutable "Chrono-Stack"—a chronological ledger of every cognitive event.
- **JSONL Format**: Primary Epoch logs use JSON Lines for readability, parsability, and resilience.
- **Event-Sourced**: Every change is appended to the stack, ensuring a perfect audit trail.

## 8.2. LogAppender: High-Throughput Persistence

The `LogAppender` GenServer batches writes to disk.
- **Backpressure**: It flushes the buffer to the current Epoch file every 100ms or when the buffer reaches 1,000 events.
- **InstanceGuard**: Uses a PID lock file to prevent two instances from writing to the same "Memory Cartridge."

## 8.3. Recovery: Cognitive Rehydration

The `Hydrator` reconstructs the system's state from the Chrono-Stack.
1.  **Scanning**: Sorts Epoch logs chronologically.
2.  **Streaming**: Replays every event through the system.
3.  **State Reconstruction**: Re-spawns `NodeActors` and re-establishes edges.
4.  **Vector Index Rebuild**: Re-indexes all nodes into the HNSW graph.

### Persistence Technical Deep Dive
The persistence layer in ACMS is designed to ensure maximum sovereignty and portability for the user's data. By using an immutable, event-sourced Chrono-Stack, we guarantee that the system's state can be fully reconstructed from a portable Memory Cartridge, independent of any external database provider. The LogAppender's batching logic and backpressure mechanisms ensure that the system can handle massive event rates without sacrificing write integrity. The InstanceGuard provides a critical safety layer, preventing data corruption that could occur if two instances attempted to mount the same cartridge simultaneously. This robust storage architecture makes ACMS the ideal solution for sovereign AI applications that require long-term, verifiable memory across heterogeneous hardware environments.

---

# 8. Time Travel: Temporal Query Engine

ACMS can reconstruct its state at any point in its history using the `TemporalQueryEngine`.

## 9.1. The "As-Of" Protocol

A user can send an `as_of` timestamp with any query.
- **The Replay Algorithm**: The system creates a virtual "Sandbox Cortex" and replays the Chrono-Stack up to the requested timestamp.
- **Historical Search**: The query is performed against this historical snapshot.

## 9.2. Deep Merge: Recursive Reconstruction

State in ACMS is often nested.
- **Recursive Merge**: The engine uses a `deep_merge_recursive` utility to accurately apply partial updates to complex node bodies during replay.

## 9.3. Cognitive Forensics

Temporal queries allow for auditing of AI decision-making by revealing exactly what "Facts" the system had access to at any given moment.

### Temporal Query Technical Deep Dive
The Temporal Query Engine is one of the most unique features of ACMS, providing a level of explainability and auditability that is simply not possible with traditional vector databases. By replaying the immutable Chrono-Stack, the engine can recreate the exact 'state of mind' of the system at any point in time. This is achieved through a high-performance replay mechanism that leverages the speed of the BEAM's pattern matching and recursion. The deep_merge_recursive utility ensures that nested state updates are correctly applied, allowing the system to track the evolution of complex configuration objects or semantic associations over time. This 'Time Travel' capability is essential for debugging cognitive drift, auditing AI behavior, and ensuring long-term alignment with the user's goals.

---

# 9. Security & Access Control

ACMS implements a **Cellular Security Model**.

## 10.1. Decentralized ACL Enforcement

Every `NodeActor` is responsible for its own security.
- **Access Checks**: Before firing or returning content, a node checks the requester's identity against its internal `DataTail.acls` map.
- **Granular Permissions**: Supports `read`, `write`, `delete`, and `admin` permissions.

## 10.2. Provenance & Chain of Trust

Every event is tagged with **Provenance Metadata**.
- **Signatures**: Includes agent ID, IP address, and optional cryptographic signatures.
- **Trust Scoring**: Salience can be adjusted based on the trustworthiness of the source.

## 10.3. Real-Time Abnormality Signaling

Nodes broadcast a "Pain Signal" on the Cognitive Bus if they detect unauthorized access attempts or unexpected state changes.

### Security Technical Deep Dive
The cellular security model in ACMS treats every piece of information as a sovereign entity. By decentralizing security enforcement at the node level, we eliminate the 'Single Point of Failure' inherent in centralized ACL systems. Every NodeActor acts as its own gatekeeper, validating every query against its internal permission set. This architecture is ideally suited for multi-tenant or multi-agent environments where different entities may have different levels of access to the shared cortex. The use of provenance metadata ensures that every change is traceable back to its source, providing a perfect chain of trust for the system's knowledge. The abnormality signaling mechanism provides real-time observability into security events, allowing for immediate intervention if the system's integrity is compromised.

---

# 10. The Frontal Cortex: ML Bridge

The heavy lifting of semantic understanding is handled by the **ML Bridge** (Python/FastAPI/PyTorch).

## 11.1. Transformer Pipelines

- **Models**: Default use of `sentence-transformers/all-MiniLM-L6-v2`.
- **Hardware Acceleration**: Automatic CUDA/MPS detection for GPU acceleration.
- **Batching**: Support for high-throughput batched vectorization.

## 11.2. Cognitive Salience Mathematics

- **Anchor Vectors**: Text is compared against "Semantic Anchors" to calculate salience.
- **Distance Calculation**: Uses Cosine Similarity for distance measurement.

### ML Bridge Technical Deep Dive
The ML Bridge serves as the primary interface between the Elixir-based cognitive orchestration and the Python-based machine learning ecosystem. By using FastAPI, we achieve high-performance asynchronous connectivity between the two runtimes. The bridge's transformer pipelines are optimized for the specific requirements of associative memory, prioritizing fast vector generation and accurate semantic similarity scoring. The use of hardware acceleration (CUDA/MPS) ensures that the system can handle massive ingestion and recall loads with microsecond latency. The cognitive salience mathematics provide a robust way to filter and rank incoming information, ensuring that only the most relevant facts are integrated into the cortex. This hybrid architecture allows ACMS to leverage the best-in-class tools from both the Elixir and Python ecosystems, resulting in a cognitive memory engine that is both fast and semantically aware.

---

# 11. Universal API Reference

ACMS exposes a unified interface via HTTP/REST and WebSockets. All requests must include the `x-agent-id` header for provenance and security tracking.

## 11.1. Ingestion Protocol

### 11.1.1. Sovereign Ingestion
`POST /api/v1/ingest`

The primary method for populating the cortex. This endpoint accepts a fully structured payload, allowing the caller to define the fact, its evidential payloads, and its cellular security policies.

**Request Body:**
```json
{
  "fact_text": "The ACMS is a sovereign cognitive memory system.",
  "agent_id": "root",
  "description_payloads": [
    {
      "type": "text",
      "content": "Detailed evidence for the fact."
    }
  ],
  "acls": ["public"]
}
```

**Example Curl:**
```bash
curl -X POST http://localhost:4000/api/v1/ingest \
     -H "Content-Type: application/json" \
     -H "x-agent-id: root" \
     -d '{
       "fact_text": "Digital Organisms learn through association.",
       "agent_id": "genesis_machine",
       "description_payloads": [{"type": "text", "content": "Evidence block."}]
     }'
```

## 11.2. Query & Cognitive Search

`POST /api/v1/query`

The primary interface for stimulating the cortex. Supports semantic search, associative pulses, and temporal rehydration.

**Request Parameters:**
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `query_text` | String | Required* | The natural language query. |
| `min_relevance` | Float | 0.6 | Similarity threshold (0.0 to 1.0). |
| `max_results` | Integer | 50 | Maximum nodes to return. |
| `as_of` | String | `null` | ISO8601 timestamp for temporal search. |
| `reasoning_mode` | String | `normal` | `normal`, `brainstorm` (high pulse), `precision` (low pulse). |

**Example Search:**
```bash
curl -X POST http://localhost:4000/api/v1/query \
     -H "Content-Type: application/json" \
     -d '{
       "query_text": "Who built the ACMS?",
       "min_relevance": 0.7,
       "max_results": 5
     }'
```

**Temporal "Time Travel" Example:**
```bash
curl -X POST http://localhost:4000/api/v1/query \
     -H "Content-Type: application/json" \
     -d '{
       "query_text": "System state",
       "as_of": "2024-12-01T12:00:00Z"
     }'
```

## 11.3. Node Interaction & Feedback

### 11.3.1. Fetch Node State
`GET /api/v1/nodes/:id`

### 11.3.2. Anti-Hebbian Feedback (Penalization)
`POST /api/v1/nodes/:id/feedback`

Used to manually weaken associations if a node is deemed irrelevant to a specific context.

**Example Request:**
```json
{
  "penalization_amount": 0.2,
  "context_id": "query_abc_123"
}
```

## 11.4. Real-Time Signals (WebSockets)

`WS /api/v1/events?token=YOUR_ADMIN_TOKEN`

**Standard Signal Schema:**
```json
{
  "event": "signal",
  "data": {
    "node_id": "sha256...",
    "action": "fired",
    "score": 0.89,
    "timestamp": "..."
  }
}
```

### API Technical Deep Dive
The Universal API Reference provides everything needed for an external agent or application to interact with the ACMS cortex. The RESTful endpoints are designed for high-performance ingestion and query coordination, while the WebSocket interface provides real-time observability into the system's internal state. Every API call is validated through the security mechanisms discussed in Chapter 10, ensuring that only authorized entities can interact with the memory. The use of JSON for all message payloads ensures compatibility across all modern programming languages. For high-throughput applications, the WebSocket interface is particularly powerful, allowing for a tight feedback loop between the system's learning and the external environment.

---

# 12. Observability & Agent Integration

## 12.1. LiveMonitor (Watching the Brain)

The `CMS.Tools.LiveMonitor` provides a real-time console view of the system.
- **Color Coding**: Green (Creation), Blue (Direct Hit), Cyan (Pulse), Red (Inhibition).
- **Trace Paths**: Visualizing the spread of activation through the graph.

## 12.2. Agent Patterns (MAG)

ACMS is designed for **Memory-Augmented Generation (MAG)**.
- **Rich Context**: Agents use the associative graph to build contexts that exceed the limits of traditional RAG.
- **Obsidian Integration**: Exporting cognitive traces to Obsidian for human review.

### Observability Technical Deep Dive
The observability suite in ACMS provides a transparent view into the inner workings of the digital mind. By subscribing to the 'global:signals' topic, the LiveMonitor tool can visualize the real-time spread of activation across the cortex, allowing developers to see exactly how associations are being followed during a query. This level of transparency is critical for debugging complex cognitive behaviors and ensuring that the system is learning the right things. The agent integration patterns (MAG) provide a blueprint for how to use ACMS to enhance the reasoning capabilities of LLMs. By providing a rich, associative context that goes far beyond simple semantic search, MAG allows agents to perform deeper analysis and maintain better long-term consistency in their outputs. The Obsidian integration further bridges the gap between human and machine cognition, allowing users to interact with and review the system's associations in a familiar, human-friendly format.

---

# 13. Testing & Maintenance

## 13.1. TDD with ExUnit

ACMS is built with test-driven development.
- **Unit Tests**: Verifying individual components like `MimeGuard` and `NodeFactory`.
- **Integration Tests**: End-to-end ingestion and query flows.

## 13.2. Chaos Engineering

Testing system resilience by killing processes and verifying recovery via the `Hydrator`.

## 13.3. Performance Benchmarking

Measuring latency and throughput for spreading activation at scale.

## 13.4. Roadmap: The Path Forward

- **Distributed Cortex**: Cluster-wide memory grids.
- **Multimodal Synapses**: Linking text to images and audio.
- **Autonomous Dreaming**: Offline consolidation and pruning cycles.

### Testing and Maintenance Technical Deep Dive
The testing and maintenance protocols for ACMS ensure that the system remains stable and reliable as it grows to millions of nodes. By leveraging Elixir's built-in ExUnit framework, we maintain a robust suite of unit and integration tests that verify the correctness of every core component. The chaos engineering experiments involve deliberately terminating NodeActor processes and ensuring that the Hydrator can perfectly reconstruct their state from the immutable Chrono-Stack. Performance benchmarking is a continuous process, measuring the latency of spreading activation pulses and the throughput of the ingestion pipeline across different hardware configurations. The roadmap for ACMS focuses on scaling the system to distributed clusters and expanding its semantic range to multimodal data. This rigorous approach to quality assurance and forward-looking architecture ensures that ACMS remains the gold standard for sovereign, associative cognitive memory systems.

---

# 14. Configuration & Tuning

ACMS is highly configurable via environment variables and the `config/` directory.

## 14.1. Core Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `ACMS_PORT` | `4000` | HTTP/WS API Port. |
| `ACMS_ADMIN_TOKEN` | `admin_secret` | Token for admin APIs and WebSocket auth. |
| `ACMS_DATA_DIR` | `./memory_cartridges` | Location of the Chrono-Stack and Mnesia logs. |
| `GEMINI_API_KEY` | `null` | Required for semantic embedding and reasoning. |
| `ACMS_COOKIE` | `secure_cookie` | Erlang distribution cookie for clustering. |

## 14.2. Cognitive Thresholds

These values are typically set in `config/config.exs` or via system API calls.

- **`min_relevance` (0.6)**: The minimum semantic similarity required for a node to "fire."
- **`pulse_damping` (0.3)**: The reduction in energy as a signal passes through a synapse.
- **`max_hops` (2)**: Maximum distance a signal can travel from the primary firing node.
- **`inhibition_threshold` (1000)**: Number of concurrent firings before Global Inhibition (GABA) is triggered.

## 14.3. Persistence Tuning

- **`flush_interval_ms` (100)**: How often the `LogAppender` writes to disk.
- **`batch_size` (1000)**: Number of events collected before a forced flush.

---

# 15. Getting Started Guide

## 15.1. Prerequisites
- **Erlang/OTP 26+** and **Elixir 1.15+**.
- **Python 3.10+** (for the ML Bridge).
- **PostgreSQL/Mnesia** (Mnesia is built-in).

## 15.2. Installation

1. **Clone and Install Dependencies**:
   ```bash
   git clone https://github.com/GiftBraimah/acms.git
   cd acms
   mix deps.get
   ```

2. **Setup the ML Bridge**:
   ```bash
   pip install -r requirements.txt
   python3 ml_bridge.py
   ```

3. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your GEMINI_API_KEY
   source .env
   ```

4. **Boot the Genesis Machine**:
   ```bash
   mix phx.server
   ```

## 15.3. Your First Ingestion

Populate the cortex with its first memory using the `/api/v1/ingest` endpoint:
```bash
curl -X POST http://localhost:4000/api/v1/ingest \
     -H "Content-Type: application/json" \
     -H "x-agent-id: admin" \
     -d '{
       "fact_text": "ACMS is now active.",
       "agent_id": "system",
       "description_payloads": [{"type": "text", "content": "Initialization complete."}]
     }'
```

## 15.4. Verifying the System
Open the `LiveMonitor` to watch the system's "State of Mind":
```bash
# In an IEx session
iex -S mix
iex> CMS.Tools.LiveMonitor.start()
```

---

**Documentation Complete. Authority Established.**
