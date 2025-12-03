import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import os

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# We use a standard, efficient local model.
# Dimension: 384
# CRITICAL: You must update @dim in Elixir's CMS.VectorRouter to 384.
EMBEDDING_MODEL_NAME = "all-MiniLM-L6-v2" 

# Setup FastAPI
app = FastAPI(title="ACN ML Bridge", version="2.0")

# Load Model (Global State)
print(f"Loading Embedding Model: {EMBEDDING_MODEL_NAME}...")
embedder = SentenceTransformer(EMBEDDING_MODEL_NAME)
print("Model Loaded. ML Bridge Ready.")

# ==============================================================================
# DATA MODELS
# ==============================================================================

class EmbeddingRequest(BaseModel):
    text: str
    model_version: str = "default"

class EmbeddingResponse(BaseModel):
    vector: list[float]
    dimension: int
    model_version: str

class CompletionRequest(BaseModel):
    prompt: str
    max_tokens: int = 100
    temperature: float = 0.7

class CompletionResponse(BaseModel):
    text: str
    usage: dict

# ==============================================================================
# ENDPOINTS
# ==============================================================================

@app.get("/health")
def health_check():
    """Heartbeat for the Elixir LiveWire Agent."""
    return {"status": "active", "service": "ACN ML Bridge"}

@app.post("/api/v1/embed", response_model=EmbeddingResponse)
def generate_embedding(request: EmbeddingRequest):
    """
    Generates a vector embedding for the given text.
    Used by: CMS.Tool.Embedder
    """
    try:
        # Generate embedding
        # encode() returns a numpy array, convert to list for JSON serialization
        vector = embedder.encode(request.text).tolist()
        
        return EmbeddingResponse(
            vector=vector,
            dimension=len(vector),
            model_version=EMBEDDING_MODEL_NAME
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/complete", response_model=CompletionResponse)
def generate_completion(request: CompletionRequest):
    """
    Stub for LLM Inference (Bots).
    Used by: Specialist Agents, Controller Agents.
    
    NOTE: For a full production system, connect this to:
    1. OpenAI API
    2. Local Llama.cpp / Ollama
    3. HuggingFace Transformers pipeline
    """
    # Placeholder logic for testing the architecture without a GPU
    # In a real build, replace this with your LLM inference call.
    simulated_response = f"[ACN_BOT_OUTPUT] Received prompt: '{request.prompt[:20]}...'. Reasoning logic would apply here."
    
    return CompletionResponse(
        text=simulated_response,
        usage={"prompt_tokens": len(request.prompt.split()), "completion_tokens": 10}
    )

# ==============================================================================
# RUNNER
# ==============================================================================
if __name__ == "__main__":
    # Run on port 5000 to avoid conflict with Phoenix (4000)
    uvicorn.run(app, host="0.0.0.0", port=5000)