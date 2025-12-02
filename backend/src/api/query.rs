use axum::{
    extract::State,
    http::HeaderMap,
    Json, Router,
    routing::post,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::sync::Arc;

use crate::domain::{QueryService, QueryError};

#[derive(Debug, Deserialize)]
pub struct QueryRequest {
    pub view: String,
    pub params: Value,
    pub spec: Value,
}

#[derive(Debug, Serialize)]
pub struct QueryResponse {
    pub data: Value,
}

#[derive(Clone)]
pub struct QueryAppState {
    pub query_service: Arc<QueryService>,
}

// curl -v http://localhost:8080/api/v1/query -H 'Content-Type: application/json' -H 'tenant_id: 1' -d '{ "view": "comparable_card", "params": { "start": "20250101", "end": "20250201" }, "spec": {} }'
async fn query_handler(
    State(state): State<QueryAppState>,
    headers: HeaderMap,
    Json(payload): Json<QueryRequest>,
) -> Result<Json<QueryResponse>, QueryError> {
    // Extract tenant_id from header
    let tenant_id = headers
        .get("tenant_id")
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| QueryError::InvalidInput("Missing tenant_id header".to_string()))?
        .to_string();

    // Execute query
    let result = state
        .query_service
        .execute_query(&tenant_id, &payload.view, payload.params, payload.spec)
        .await?;

    Ok(Json(QueryResponse { data: result }))
}

pub fn create_query_routes(query_service: Arc<QueryService>) -> Router {
    let state = QueryAppState { query_service };

    Router::new()
        .route("/query", post(query_handler))
        .with_state(state)
}
