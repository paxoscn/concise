use axum::{
    extract::{Path, Query, State},
    http::{StatusCode, HeaderMap},
    Json, Router,
    routing::{get, post, put, delete},
};
use serde::Deserialize;
use std::sync::Arc;

use crate::domain::{
    DataTableColumnService, CreateDataTableColumnRequest, UpdateDataTableColumnRequest,
    BatchCreateColumnsRequest, ServiceError,
};

#[derive(Clone)]
pub struct DataTableColumnAppState {
    pub column_service: Arc<DataTableColumnService>,
}

#[derive(Debug, Deserialize)]
pub struct ListByTableQuery {
    #[serde(default)]
    tenant_id: Option<String>,
    pub data_table_id: String,
}

// 列表查询处理函数 - 按数据表
async fn list_by_table_handler(
    State(state): State<DataTableColumnAppState>,
    headers: HeaderMap,
    Query(query): Query<ListByTableQuery>,
) -> Result<Json<Vec<crate::entities::data_table_column::Model>>, ServiceError> {
    // 可以访问headers和query
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let columns = state.column_service.list_by_table(&query.data_table_id).await?;
    Ok(Json(columns))
}

// 创建处理函数
async fn create_handler(
    State(state): State<DataTableColumnAppState>,
    headers: HeaderMap,
    Json(payload): Json<CreateDataTableColumnRequest>,
) -> Result<(StatusCode, Json<crate::entities::data_table_column::Model>), ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let column = state.column_service.create(payload).await?;
    Ok((StatusCode::CREATED, Json(column)))
}

// 批量创建处理函数
async fn batch_create_handler(
    State(state): State<DataTableColumnAppState>,
    headers: HeaderMap,
    Json(payload): Json<BatchCreateColumnsRequest>,
) -> Result<StatusCode, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    state.column_service.batch_create(payload).await?;
    Ok(StatusCode::CREATED)
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataTableColumnAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<Json<crate::entities::data_table_column::Model>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let column = state.column_service.get(id).await?;
    Ok(Json(column))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataTableColumnAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    Json(payload): Json<UpdateDataTableColumnRequest>,
) -> Result<Json<crate::entities::data_table_column::Model>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let column = state.column_service.update(id, payload).await?;
    Ok(Json(column))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataTableColumnAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<StatusCode, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    state.column_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 创建数据表列路由
pub fn create_data_table_column_routes(
    column_service: Arc<DataTableColumnService>,
) -> Router {
    let state = DataTableColumnAppState {
        column_service,
    };

    Router::new()
        .route("/", get(list_by_table_handler))
        .route("/", post(create_handler))
        .route("/batch", post(batch_create_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        .with_state(state)
}
