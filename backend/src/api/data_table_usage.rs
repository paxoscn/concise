use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde::Deserialize;
use std::sync::Arc;

use crate::domain::{
    DataTableUsageService, UpsertDataTableUsageRequest, UpdateDataTableUsageRequest,
    ServiceError,
};

#[derive(Clone)]
pub struct DataTableUsageAppState {
    pub usage_service: Arc<DataTableUsageService>,
}

#[derive(Debug, Deserialize)]
pub struct GetByTableQuery {
    pub data_table_id: String,
}

// 查询处理函数 - 按数据表
async fn get_by_table_handler(
    State(state): State<DataTableUsageAppState>,
    Query(query): Query<GetByTableQuery>,
) -> Result<Json<Option<crate::entities::data_table_usage::Model>>, ServiceError> {
    let usage = state.usage_service.get_by_table(&query.data_table_id).await?;
    Ok(Json(usage))
}

// Upsert处理函数
async fn upsert_handler(
    State(state): State<DataTableUsageAppState>,
    Json(payload): Json<UpsertDataTableUsageRequest>,
) -> Result<(StatusCode, Json<crate::entities::data_table_usage::Model>), ServiceError> {
    let usage = state.usage_service.upsert(payload).await?;
    Ok((StatusCode::OK, Json(usage)))
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataTableUsageAppState>,
    Path(id): Path<String>,
) -> Result<Json<crate::entities::data_table_usage::Model>, ServiceError> {
    let usage = state.usage_service.get(id).await?;
    Ok(Json(usage))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataTableUsageAppState>,
    Path(id): Path<String>,
    Json(payload): Json<UpdateDataTableUsageRequest>,
) -> Result<Json<crate::entities::data_table_usage::Model>, ServiceError> {
    let usage = state.usage_service.update(id, payload).await?;
    Ok(Json(usage))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataTableUsageAppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ServiceError> {
    state.usage_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 创建数据表统计路由
pub fn create_data_table_usage_routes(
    usage_service: Arc<DataTableUsageService>,
) -> Router {
    let state = DataTableUsageAppState {
        usage_service,
    };

    Router::new()
        .route("/by-table", get(get_by_table_handler))
        .route("/upsert", post(upsert_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        .with_state(state)
}
