#!/bin/bash

# Configuration
BASE_URL="http://localhost:4000/api/v1"
ADMIN_HEADER="x-agent-id: root"
CONTENT_TYPE="Content-Type: application/json"

echo "========================================================"
echo "STARTING COMPREHENSIVE CMS API TEST (ROOT PERMISSIONS)"
echo "========================================================"

# 1. HEALTH CHECK
# Tests connection to Elixir API and Python Bridge
echo -e "\n[1] Testing Health Check..."
curl -s -X GET "$BASE_URL/health/embedder" | jq .

# 2. INGESTION (Root Agent)
# Ingests a complex node with mixed FID payloads
echo -e "\n[2] Ingesting New Knowledge..."
INGEST_RESPONSE=$(curl -s -X POST "$BASE_URL/ingest" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{
    "fact_text": "The implementation of the CMS API layer was completed successfully.",
    "agent_id": "root",
    "acls": ["public", "root"],
    "provenance": {
        "source": "integration_test_script",
        "priority": "critical"
    },
    "description_payloads": [
      {
        "type": "text", 
        "content": "API Layer verification test."
      },
      {
        "type": "code",
        "language": "bash",
        "content": "curl -X GET /health"
      },
      {
        "type": "number",
        "value": 100,
        "unit": "percent"
      }
    ]
  }')

echo "Response: $INGEST_RESPONSE"
# Extract Node ID for future tests
NODE_ID=$(echo $INGEST_RESPONSE | jq -r '.node_id')

if [ "$NODE_ID" == "null" ]; then
  echo "Error: Ingestion failed. Exiting."
  exit 1
fi
echo "-> Captured Node ID: $NODE_ID"

# 3. LIVE SEMANTIC QUERY
# Tests vector search, spreading activation, and pagination
echo -e "\n[3] Testing Live Semantic Query..."
curl -s -X POST "$BASE_URL/query" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{
    "query_text": "status of CMS API implementation",
    "agent_id": "root",
    "min_relevance": 0.1,
    "max_results": 5,
    "reasoning_mode": "precision",
    "target_regions": null
  }' | jq .

# 4. FETCH ACTIVE NODE STATE
# Tests direct retrieval via Supervisor or Temporal backup
echo -e "\n[4] Fetching Active Node State ($NODE_ID)..."
curl -s -X GET "$BASE_URL/nodes/$NODE_ID" \
  -H "$ADMIN_HEADER" | jq .

# 5. FETCH NODE EDGES
# Tests relationship metadata retrieval
echo -e "\n[5] Fetching Node Edges..."
curl -s -X GET "$BASE_URL/nodes/$NODE_ID/edges" \
  -H "$ADMIN_HEADER" | jq .

# 6. ANTI-HEBBIAN FEEDBACK
# Tests the new feedback endpoint to penalize connections
echo -e "\n[6] Applying Anti-Hebbian Feedback (Penalization)..."
curl -s -X POST "$BASE_URL/nodes/$NODE_ID/feedback" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{
    "context_id": "test_context_001",
    "penalization_amount": 0.5
  ' | jq .

# 7. TEMPORAL (HISTORICAL) QUERY
# Tests the "Time Travel" search capabilities using current time
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo -e "\n[7] Testing Temporal Forensic Search (As Of: $CURRENT_TIME)..."
curl -s -X POST "$BASE_URL/query" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d "{
    "query_text": "CMS API status",
    "as_of": \"$CURRENT_TIME\",
    "max_results": 5
  }" | jq .

# 8. FETCH NODE HISTORY
# Tests fetching a specific node's state at a timestamp
echo -e "\n[8] Fetching Node History..."
curl -s -X GET "$BASE_URL/nodes/$NODE_ID/history?as_of=$CURRENT_TIME" \
  -H "$ADMIN_HEADER" | jq .

# 9. SYSTEM: SET CONGESTION (Admin Only)
# Tests setting global inhibition levels
echo -e "\n[9] [ADMIN] Setting System Congestion..."
curl -s -X POST "$BASE_URL/system/set-congestion" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{
    "level": 0.75
  }' | jq .

# 10. SYSTEM: CHECK DRIFT (Admin Only)
# Manually triggers model drift detection scan
echo -e "\n[10] [ADMIN] Triggering Model Drift Check..."
curl -s -X POST "$BASE_URL/system/check-drift" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{}' | jq .

# 11. SYSTEM: ROTATE EPOCH (Admin Only)
# Forces a log rotation to disk
echo -e "\n[11] [ADMIN] Rotating Epoch Logs..."
curl -s -X POST "$BASE_URL/system/rotate-epoch" \
  -H "$CONTENT_TYPE" \
  -H "$ADMIN_HEADER" \
  -d '{}' | jq .

# 12. DELETE NODE (Admin Only)
# Evicts the node created in step 2
echo -e "\n[12] [ADMIN] Evicting/Deleting Node..."
curl -s -X DELETE "$BASE_URL/nodes/$NODE_ID" \
  -H "$ADMIN_HEADER" | jq .

echo -e "\n========================================================"
echo "TEST COMPLETE"
echo "========================================================"