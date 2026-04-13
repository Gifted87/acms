# Associative Cognitive Memory System (ACMS)

**Developed by Gift Braimah for the Autonomous Intelligence Community.**
*Licensed under the MIT License. (c) 2026 Associative Cognitive Memory Systems.*

## Executive Summary: The Sovereign Long-Term Brain for AI Agents

The **Associative Cognitive Memory System (ACMS)** is a high-concurrency, neuro-inspired knowledge orchestration grid designed specifically to serve as the **long-term associative brain** for autonomous AI agents and multi-agent systems (MAS). In the modern landscape of large language models (LLMs), a critical bottleneck exists: the finite context window. While LLMs excel at processing immediate information, they suffer from catastrophic forgetting and lack a persistent, associative medium to store and retrieve knowledge over long horizons.

ACMS solves this by moving beyond the paradigm of the "Vector Database." While a database is a passive repository of stored bytes, ACMS is an **active memory grid**. Built on the Elixir/BEAM ecosystem for massive concurrency and the Python/Transformer ecosystem for semantic depth, ACMS conceptualizes knowledge as a network of **Atomic Units of Cognition (Nodes)**. Each fact, code snippet, or observation is an independent, self-governing GenServer process—a digital neuron—capable of autonomous query evaluation, synaptic link reinforcement, and spreading activation.

The ACMS was explicitly engineered to allow AI agents to descend into the **Cognitive Swamp**—unstructured, high-entropy data environments—and distill them into a coherent, navigable cortex. It provides agents with the ability to "remember" not just strings of text, but the associations, provenance, and metabolic relevance of information, ensuring that relevant context is always available when the "spark" of a query activates the network.

---

## 1. Design Philosophy: The Memory Paradigm

### 1.1. From Vector Databases to Memory Systems
Traditional vector databases are essentially "search engines with embeddings." They operate on a k-Nearest Neighbor (k-NN) retrieval model: find the top N documents that look like the query. This is a linear, static process. 

The ACMS replaces this with an **Associative Memory** model. In a human brain, you do not "search" for a memory; you are "reminded" of it through association. A query for "Server Downtime" should not just return logs; it should activate the concept of "Power Supply," "Maintenance Schedules," and "On-call Engineers" through weighted synaptic links formed during previous operational cycles. This is the power of the ACMS: it stores the *connections* between values as a first-class citizen.

### 1.2. The Cognitive Swamp vs. The Active Cortex
Most corporate and project data exists in a state of high entropy—the "Cognitive Swamp." This environment is filled with redundant facts, conflicting documentation, and orphaned data points. ACMS acts as the filtration and crystallization engine for this swamp. Through its recursive ingestion pipeline, it extracts atomic facts and binds them into an **Active Cortex**.

In the cortex, information isn't just "there." It has a **Metabolic State**. It can be "hot" and ready for immediate recall, or "hibernating" in the deep folds of the Epoch Logs. This ecological approach to data management ensures that the AI agent's long-term brain stays lean, efficient, and focused on current operational relevance while retaining the ability to rehydrate historical truths via "Time-Travel" searches.

---

## 2. Memory Anatomy: The Anatomy of a Neuron

In the ACMS, the fundamental unit of logic is the **NodeActor**. Every node is a discrete GenServer process that manages its own state, antenna gain, and synaptic weights.

### 2.1. Deterministic Content-Addressable Identity
To ensure epistemological integrity, ACMS utilizes a strict **Content-Addressable Memory (CAM)** principle. The identity of a node is derived cryptographically using a SHA-256 hash of two components:
1.  **The Truth**: The core fact (`DataHead.fact`) and the multi-modal data payloads (`DataBody`).
2.  **The Provenance**: The source document, timestamp, agent ID, and trust score.

By hashing `Truth + Provenance`, the system ensures that the same fact from two different sources (e.g., a README and a source code comment) results in two distinct nodes that can then be linked via "Contradiction" or "Support" edges. This prevents the system from being flattened into a single, potentially incorrect "truth," preserving the diversity of context required for agentic reasoning.

### 2.2. The Metabolic Energy Model
Every neuron in the ACMS is governed by a **Metabolic State**, which acts as a firing inhibitor:
- **`:high_energy`**: Nodes that have recently been created or activated. They have a high "Antenna Gain" and act as central hubs in the current context.
- **`:low_energy`**: Nodes that have been idle. Their firing threshold increases, requiring more semantic "spark" to activate.
- **`:hibernating`**: The process has been terminated to save RAM, but its state is persisted in the Epoch Logs. Activation requires **Rehydration**.
- **`:recovering`**: A transition state where a node is warming up after rehydration.

This metabolism ensures that the agent's long-term brain doesn't suffer from "Information Overload" (ADHD). Only the most relevant nodes are kept in active memory, while the rest stay in a low-cost, persistent state.

### 2.3. The NodeAntenna and Signal Gain
Each node possesses a **NodeAntenna**, which modulates its ability to receive and transmit signals. The **Signal Gain** (typically 0.0 to 2.0) is calculated based on the node's **Salience Score**. High-salience nodes (e.g., error messages, core architectural definitions) are granted "loud" antennas, ensuring their pulses reach further through the network during spreading activation.

---

## 3. Dynamics of Cognition: Spreading Activation

Retrieval in ACMS is a physical-analogue process known as **Spreading Activation**. This is the mechanism that allows for discovery-based search.

### 3.1. The Signaling Phase
When an agent submits a query, the **QueryCoordinator** calculates the semantic vector of the query using the **ML Bridge**. This vector is then pulsed onto the **Cognitive Bus** (using Phoenix PubSub). Nodes localized in the relevant **Semantic Regions** receive the signal.

### 3.2. Firing and Pulse Propagation
A node "fires" if the incoming signal meets its **Adjusted Relevance Threshold**. The threshold is a dynamic calculation:
`Threshold = (BaseThreshold / GlobalInhibition) * MetabolicCost`

Upon firing, the node does not just return its payload to the agent; it broadcasts a **Pulse** to all nodes it is linked to. This pulse contains:
- **The Query Context**: The original query vector.
- **The Boost Score**: A fraction of the firing node's relevance.
- **The TTL (Time-To-Live)**: Prevents the signal from propagating infinitely.

### 3.3. Synaptic Damping (Hub Dominance Cure)
A common failure in graph systems is the "Hub Dominance" problem, where a few general nodes (e.g., a node for "Python") are linked to everything and thus fire for every query. ACMS cures this via **Synaptic Damping**. Every outgoing pulse is modulated by a damping factor (default 0.3). This ensures that while general concepts can "whisper" clues, they cannot drown out the specific "shouts" of relevant nodes.

---

## 4. Neuroplasticity: The Hebbian Loop

The ACMS is a **learning** brain. It evolves its structure based on how the AI agent interacts with it.

### 4.1. Hebbian Reinforcement: Wiring Together
ACMS implements a digital version of Hebb's Law: *"Nodes that fire together, wire together."* Through the **Regional Hebbian Buffer**, the system tracks which nodes frequently fire in response to the same query IDs. If Node A and Node B are co-activated, the system sends a reinforcement signal: `{:hebbian_reinforce, target_id, amount}`. This increases the weight of the synaptic link between them, making future associative jumps between them more likely.

### 4.2. Anti-Hebbian Penalization: Correcting the Brain
If an AI agent or a human reviewer marks a search result as irrelevant, the ACMS performs **Anti-Hebbian Learning**. The contributing nodes are penalized, reducing the weights of the links that led to the irrelevant result. This allows the memory system to "unlearn" harmful or noisy associations, refining the cortex over time.

### 4.3. Differential Decay: Active Forgetting
To prevent the memory grid from becoming a stagnant graveyard of outdated links, the **Decay Manager** performs **Differential Decay**. Every cycle, link weights are slightly reduced. Information that is never used eventually fades into the background, and nodes with zero link strength are eventually purged from the active cortex. This ensures that the agent's brain is always a representation of *current* and *useful* context.

---

## 5. Ingestion Ecology: Descending the Swamp

Ingestion is the process of "Genesis"—creating a brain from raw data.

### 5.1. The Crawler and Shredder
The **Crawler** recursively explores the file system or data source. It uses the **MIME Guard** to identify "truth-bearing" files (e.g., `.ex`, `.py`, `.md`) while ignoring "Cognitive Noise" (e.g., binaries, caches, `.git` folders) via the `.cmsignore` system.

Files are then passed to the **Shredder**, which canonicalizes the text into **Atomic Facts** (DataHeads). Each fact is then processed through the **Salience Engine** to determine its initial importance to the system.

### 5.2. The Orchestrator and Binding
The **Orchestrator** manages the "Binding" phase. It uses the **Vector Router** (HNSW) to find the initial neighbors for a new node. It forges the first "Seed Edges," allowing the new node to integrate into the existing associative network. This is the moment the piece of data becomes a part of the "brain."

---

## 6. Infrastructure Sovereignty: Cartridges and Recovery

ACMS is designed for absolute data sovereignty. All knowledge is stored in a **Memory Cartridge**.

### 6.1. The Instance Guard (Git-Lock)
Knowledge corruption is the highest risk in a memory system. The **Instance Guard** prevents multiple ACMS instances from writing to the same cartridge simultaneously. It uses a "Git-Lock" mechanism via a `running.pid` file. If a second instance attempts to breach the cartridge, it is hard-blocked until the lock is released or a pulse-check confirms the previous process is dead.

### 6.2. The Epoch Manager: Append-only Truth
The **Epoch Manager** is the bedrock of ACMS persistence. Every node creation, update, and link reinforcement is logged in a human-readable, append-only **JSONL Epoch Log**. This is the "Ultimate Truth." Even if the Mnesia database or the HNSW index is corrupted, the system can be reconstructed entirely from these logs.

### 6.3. Deterministic Rehydration
If a memory cartridge is moved between different physical architectures (e.g., from an x86 Linux server to an ARM Mac), Mnesia and binary indexes will fail. ACMS handles this through **Deterministic Rehydration**. The **Bootloader** detects the architectural mismatch, wipes the local binary caches, and re-reads the Epoch Logs to reconstruct the cortex in the new local format. Your AI agent's long-term memory is truly portable.

---

## 7. Practical Guide: Setting Up the Brain

### 7.1. Prerequisites
- **Elixir 1.14+** and **Erlang/OTP 25+**.
- **Python 3.10+** (for the ML Bridge).
- **Sentence-Transformers** (`all-MiniLM-L6-v2`).

### 7.2. Quick Boot
1.  **Initialize the Environment**:
    ```bash
    mix deps.get && mix compile
    ```
2.  **Start the ML Bridge**:
    The ML Bridge provides the semantic pre-frontal cortex for the system.
    ```bash
    source venv/bin/activate
    python ml_bridge.py
    ```
3.  **Launch the Memory Grid**:
    Use the `acms.sh` portability loader to start the cortex.
    ```bash
    ./acms.sh my_agent_brain 4000
    ```

### 7.3. Environment Configuration

The ACMS is configured via environment variables. For a quick start, copy the provided template and source it:

```bash
cp .env.example .env
# Edit .env with your specific keys
source .env
```

| Variable | Description | Required | Default |
| :--- | :--- | :--- | :--- |
| `ACMS_ADMIN_TOKEN` | Token for admin API access and WebSockets. | Yes | `admin_secret` |
| `ACMS_COOKIE` | Erlang distribution cookie for secure clustering. | Yes | `secure_cognitive_cookie` |
| `GEMINI_API_KEY` | Your Google Vertex AI / Gemini API Key. | Yes (for AI) | - |
| `ACMS_SECRET` | Core secret for internal encryption. | No | *Auto-generated* |
| `ACMS_DATA_DIR` | Path to the "Memory Cartridge" directory. | No | `./memory_cartridges/cms` |
| `ACMS_PORT` | The port the web server will listen on. | No | `4000` |
| `ACMS_NODE_NAME` | Name identifier for this cognitive instance. | No | `cms` |
| `GEMINI_MODEL` | Gemini model version to use. | No | `gemini-2.5-flash-lite` |
| `GEMINI_API_ENDPOINT`| API endpoint for Gemini. | No | *Google API URL* |

---

## 8. API Reference for Autonomous Agents

### POST `/api/v1/ingest`
Allows an agent to store new observations.
```json
{
  "fact_text": "Agent identified a bottleneck in the auth service.",
  "agent_id": "orchestrator_prime",
  "provenance": {"source": "log_analysis", "priority": "high"}
}
```

### POST `/api/v1/query`
The primary retrieval interface. Supports `reasoning_mode`:
- `:precision`: Narrow search, minimal pulse propagation.
- `:brainstorm`: High pulse propagation for wide association.

### POST `/api/v1/nodes/:id/feedback`
Agentic feedback loop. Use this to manually reinforce or penalize links.

---

## 9. Conclusion: The Future of Agentic Memory

The **Associative Cognitive Memory System** is more than just a storage layer; it is the cornerstone of truly autonomous AI. By providing agents with a persistent, associative, and evolving "long-term brain," we enable them to move beyond short-term prompt engineering and into the realm of complex, historical reasoning. 

ACMS is the grid upon which the next generation of multi-agent systems will build their collective intelligence. Whether you are navigating the "Cognitive Swamp" of legacy enterprise data or building a swarm of autonomous research agents, ACMS provides the resilient, neuro-inspired foundation your system needs to remember, associate, and succeed.

---
