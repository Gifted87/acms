**The Associative Cognitive Memory System (ACMS)**

A human being can build an enormous codebase not because he remembers every line he has ever written, but because his memory knows what to surface at the right moment. When a relevant concept comes to mind, the memory fetches everything connected to it — and only that. He does not remember everything at once. He remembers what matters, when it matters.

But how does memory know what to fetch?

If it worked like a text search, thinking about *smoke* would return memories containing the word smoke — a fire outbreak, a man smoking, a burning bush. If it worked like a vector search, it would return things similar in meaning — fire, heat. But the human brain does neither. It uses a mechanism called **spreading activation**. When the brain receives the signal *smoke*, it returns *fire* — but then the memory of fire triggers *danger* and *fire extinguisher*, and the memory of the fire extinguisher triggers its location and how to use it. The brain did not remember the fire extinguisher because it is semantically similar to smoke. It remembered it because in the web of human experience, they are *connected*. This is what makes human memory intelligent — it returns not just what is similar, but what is relevant.

This is exactly how I built the ACMS to work.

---

**What the ACMS Is**

The ACMS is a human-like memory system for AI agents. It is built on three principles drawn directly from how human memory works:

**Spreading Activation** — When the memory is queried, it does not stop at the most similar result. It ripples outward through connected nodes, returning memories that are related by *association*, not just meaning. This solves what is called the unknown unknowns problem — the system surfaces what you need even when you did not know to ask for it.

**Hebbian Learning** — If two memories are repeatedly activated together, the connection between them strengthens. The ACMS does the same: memory that fires together, wires together. Over time, the memory of each agent adapts to how it is being used, just as human memory does.

**Active Forgetting** — Memories that are not accessed over time are gradually deprioritised and eventually removed from active storage — keeping the memory clean and relevant. Unlike the human brain, the ACMS does not delete permanently. Faded memories are archived, and agents can still retrieve them on explicit request.

---

**Why It Was Built**

The problem that demanded this system is clearest in multi-agent AI.

Imagine deploying 100 agents in parallel to build a large software system. Each agent handles a different part — frontend, backend, database, authentication, and so on. For the system to have cohesion, each agent must know what the others are building. The naive solution is to pass the full output of every agent to every other agent — but agents have limited context windows, and at scale this becomes impossible. Vector search is not enough either, because the file one agent needs may have no semantic similarity to its own work. A frontend agent building a dashboard does not search for *"fire extinguisher"* — but it still needs to find it.

The ACMS solves this. Each agent ingests its work into the shared memory as it progresses. When another agent queries that memory, spreading activation returns not just similar files, but *connected* ones — the ones that actually matter for that agent's task. Hundreds of agents can work in tight cohesion because they are sharing one mind.

Beyond multi-agent systems, the ACMS is also critical for any agent that needs long-term memory or deals with enormous context — whether it is an autonomous agent performing long-running tasks or a copilot that needs to store and retrieve large volumes of company data. Anywhere agents are bottlenecked by context limits, the ACMS provides a way through.

---

**Was It Successful?**

The ACMS became the base memory for the [**Autonomous Cognitive Network (ACN)**](https://github.com/Gifted87/acn) — a multi-agent system designed to build large, complex production-grade software from a single prompt, the way a human team would. The ACN orchestrates and organises large numbers of agents running in parallel, each contributing to a shared codebase.

In testing, the ACN demonstrated strong cohesion across more than 100 simultaneously running agents, generating over 200 files from scratch without manual coordination. That result would not have been possible without the associative memory layer holding the system together.

---

**Where the ACMS Is Not the Right Fit**

The system is not universally applicable. It adds unnecessary overhead for simple or short tasks that fit within a single context window. Pure semantic retrieval — such as document question-answering — does not need it. It is also not suited for tasks requiring strict linear precision, like ETL pipelines or transaction ledgers, where associative "fuzziness" is a liability rather than an asset. And in high-frequency, low-latency environments like algorithmic trading, the time spreading activation takes to ripple through the network is too costly.

The ACMS is built for complexity — for the class of problems where scale, parallelism, and the unknown unknowns problem make simpler memory systems break down.

---

**How to Use**

[![Watch the ACMS Demo](https://img.youtube.com/vi/dl1-QOE1oHg/0.jpg)](https://youtu.be/dl1-QOE1oHg)

This section provides a clear, step-by-step guide to installing the ACMS and connecting your agents to the memory network via the API. 

### 1. Installation and Setup

First, clone the repository and navigate into the project directory:

```bash
git clone https://github.com/Gifted87/acms.git
cd acms
```

Next, install the necessary dependencies for Elixir, Erlang, and Python. Run the following commands:

```bash
sudo apt update
sudo apt install elixir
sudo apt install erlang
sudo apt install python3-venv -y
```

Next, fetch the Elixir dependencies and compile the project:

```bash
mix deps.get && mix compile 
```

Set up a Python virtual environment to run the Machine Learning bridge (which handles embedding generation):

```bash
python3 -m venv venv
source venv/bin/activate
pip3 install fastapi uvicorn 
pip install sentence-transformers
```

Start the Machine Learning bridge:

```bash
python ml_bridge.py
```

Finally, in a separate terminal window, start the ACMS node, providing a name for your agent brain and a port number:

```bash
./acms.sh my_agent_brain 4000
```

### 2. Connecting Agents via the API

Agents interact with the ACMS exclusively through a RESTful API. Below are examples of how to ingest knowledge and query the memory network.

#### Example: Ingestion Task

To store a memory or fact into the system, your agent sends a `POST` request to the `/ingest` endpoint.

```bash
curl -X POST http://localhost:4000/api/v1/ingest \
  -H "Content-Type: application/json" \
  -H "x-agent-id: root" \
  -d '{
    "agent_id": "root",
    "fact_text": "ACMS uses a bio-mimetic Spreading Activation model instead of standard k-NN vector search.",
    "acls": {
      "read": ["public"],
      "write": ["root", "system"]
    },
    "provenance": {
      "source": "ACMS_Whitepaper",
      "trust_score": 0.98,
      "priority": "high"
    },
    "description_payloads": [
      {
        "type": "text",
        "content": "This allows the memory grid to retrieve context via synaptic associations rather than just semantic similarity."
      }
    ]
  }'
```

#### Example: Query Task

To retrieve context, your agent sends a `POST` request to the `/query` endpoint.

```bash
curl -X POST http://localhost:4000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_text": "How does the search mechanism work in ACMS?",
    "agent_id": "root",
    "reasoning_mode": "normal",
    "min_relevance": 0.4
  }'
```

### 3. Testing the System

To see the power of the ACMS in action, you can populate the memory with sample data and test the spreading activation retrieval.

First, ingest sample data using the provided scripts:

```bash
# Ingest 50 sample nodes containing random facts about the ACMS
python3 ingest_100_nodes.py

# Ingest 50 sample nodes containing facts about Python
python3 ingest_100_nodes2.py
```

Now, test the spreading activation mechanism using the `brainstorm` reasoning mode:

**Test 1:**
```bash
curl -X POST http://localhost:4000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{     
    "query_text": "What stops multiple threads from executing at the exact same time?",
    "agent_id": "root",
    "reasoning_mode": "brainstorm",
    "min_relevance": 0.4,
    "max_results": 10
  }'
```

**Test 2:**
```bash
curl -X POST http://localhost:4000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{     
    "query_text": "How does the system handle a process that crashes or fails?",
    "agent_id": "root",
    "reasoning_mode": "brainstorm",
    "min_relevance": 0.35,
    "max_results": 10
  }'
```

---

**Documentation**

For a deep-dive into the system architecture, component mechanics, and operational guides, please refer to the documentation.md file.

---

**License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.