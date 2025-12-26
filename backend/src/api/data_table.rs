use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Extension,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde::Deserialize;
use std::sync::Arc;

use crate::domain::{
    DataTableService, CreateDataTableRequest, UpdateDataTableRequest,
    DataTableWithDetails, ServiceError,
};

#[derive(Clone)]
pub struct DataTableAppState {
    pub data_table_service: Arc<DataTableService>,
}

#[derive(Debug, Deserialize)]
pub struct ListByDataSourceQuery {
    pub data_source_id: String,
}

// 列表查询处理函数 - 按租户
async fn list_handler(
    State(state): State<DataTableAppState>,
    Extension(claims): Extension<crate::domain::auth::UserClaims>,
) -> Result<Json<Vec<crate::entities::data_table::Model>>, ServiceError> {
    let tables = state.data_table_service.list_by_tenant(&claims.tenant_id).await?;
    Ok(Json(tables))
}

// 列表查询处理函数 - 按数据源
async fn list_by_data_source_handler(
    State(state): State<DataTableAppState>,
    Extension(claims): Extension<crate::domain::auth::UserClaims>,
    Query(query): Query<ListByDataSourceQuery>,
) -> Result<Json<Vec<crate::entities::data_table::Model>>, ServiceError> {
    let tables = state.data_table_service
        .list_by_data_source(&claims.tenant_id, &query.data_source_id)
        .await?;
    Ok(Json(tables))
}

// 创建处理函数
async fn create_handler(
    State(state): State<DataTableAppState>,
    Extension(claims): Extension<crate::domain::auth::UserClaims>,
    Json(mut payload): Json<CreateDataTableRequest>,
) -> Result<(StatusCode, Json<crate::entities::data_table::Model>), ServiceError> {
    payload.tenant_id = Some(claims.tenant_id.clone());
    let table = state.data_table_service.create(payload).await?;
    Ok((StatusCode::CREATED, Json(table)))
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
) -> Result<Json<crate::entities::data_table::Model>, ServiceError> {
    let table = state.data_table_service.get(id).await?;
    Ok(Json(table))
}

// 详情查询处理函数（包含列和统计信息）
async fn get_with_details_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
) -> Result<Json<DataTableWithDetails>, ServiceError> {
    let details = state.data_table_service.get_with_details(id).await?;
    Ok(Json(details))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    Json(payload): Json<UpdateDataTableRequest>,
) -> Result<Json<crate::entities::data_table::Model>, ServiceError> {
    let table = state.data_table_service.update(id, payload).await?;
    Ok(Json(table))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ServiceError> {
    state.data_table_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 创建数据表路由
pub fn create_data_table_routes(
    data_table_service: Arc<DataTableService>,
) -> Router {
    let state = DataTableAppState {
        data_table_service,
    };

    Router::new()
        .route("/", get(list_handler))
        .route("/by-data-source", get(list_by_data_source_handler))
        .route("/", post(create_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}/details", get(get_with_details_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        .with_state(state)
}
