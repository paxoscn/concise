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

// curl -v http://localhost:8080/api/v1/query -H 'Content-Type: application/json' -H 'tenant_id: 1' -d '{ "view": "comparable_card", "params": { "start": "0101", "end": "1231" }, "spec": { "sql": "SELECT CASE WHEN s.shop_name = '"''"' THEN '"'self'"' ELSE s.shop_name END merchant_name, SUM(CAST(COALESCE(s.transaction_amount, '"'0'"') AS REAL)) transaction_amount FROM dwd_rival_stats_distincted_di_1d s WHERE s.date_str BETWEEN {start} AND {end} [category_level1:AND s.category_level1 = {category_level1}] [shop_names:AND s.shop_name IN {shop_names}] GROUP BY s.shop_name" } }'
// curl -v http://localhost:8080/api/v1/query -H 'Content-Type: application/json' -H 'tenant_id: 1' -d '{ "view": "comparable_card", "params": { "start": "0101", "end": "1231", "category_level1": "家居日用" }, "spec": { "sql": "SELECT CASE WHEN s.shop_name = '"''"' THEN '"'self'"' ELSE s.shop_name END merchant_name, SUM(CAST(COALESCE(s.transaction_amount, '"'0'"') AS REAL)) transaction_amount FROM dwd_rival_stats_distincted_di_1d s WHERE s.date_str BETWEEN {start} AND {end} [category_level1:AND s.category_level1 = {category_level1}] [shop_names:AND s.shop_name IN {shop_names}] GROUP BY s.shop_name" } }'
// curl -v http://localhost:8080/api/v1/query -H 'Content-Type: application/json' -H 'tenant_id: 1' -d '{ "view": "comparable_card", "params": { "start": "0101", "end": "1231", "category_level1": "家居日用", "shop_names": [ "1", "2", "3" ] }, "spec": { "sql": "SELECT CASE WHEN s.shop_name = '"''"' THEN '"'self'"' ELSE s.shop_name END merchant_name, SUM(CAST(COALESCE(s.transaction_amount, '"'0'"') AS REAL)) transaction_amount FROM dwd_rival_stats_distincted_di_1d s WHERE s.date_str BETWEEN {start} AND {end} [category_level1:AND s.category_level1 = {category_level1}] [shop_names:AND s.shop_name IN {shop_names}] GROUP BY s.shop_name" } }'
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
