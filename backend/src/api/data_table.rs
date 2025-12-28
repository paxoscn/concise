use axum::{
    extract::{Path, Query, State, Multipart, DefaultBodyLimit},
    http::{StatusCode, HeaderMap},
    Extension,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::collections::HashMap;

use crate::domain::{
    DataTableService, CreateDataTableRequest, UpdateDataTableRequest,
    DataTableWithDetails, ServiceError,
};

#[derive(Clone)]
pub struct DataTableAppState {
    pub data_table_service: Arc<DataTableService>,
}

// 查询参数结构
#[derive(Debug, Deserialize)]
struct ListQueryParams {
    #[serde(default)]
    tenant_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ListByDataSourceQuery {
    #[serde(default)]
    tenant_id: Option<String>,
    pub data_source_id: String,
}

// 列表查询处理函数 - 按租户
async fn list_handler(
    State(state): State<DataTableAppState>,
    // Extension(claims): Extension<crate::domain::auth::UserClaims>,
    headers: HeaderMap,
    Query(params): Query<ListQueryParams>,
) -> Result<Json<Vec<crate::entities::data_table::Model>>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    // let tables = state.data_table_service.list_by_tenant(&claims.tenant_id).await?;
    let tables = state.data_table_service.list_by_tenant(&params.tenant_id.unwrap_or("".to_string())).await?;
    Ok(Json(tables))
}

// 列表查询处理函数 - 按数据源
// async fn list_by_data_source_handler(
//     State(state): State<DataTableAppState>,
//     // Extension(claims): Extension<crate::domain::auth::UserClaims>,
//     headers: HeaderMap,
//     Query(query): Query<ListByDataSourceQuery>,
// ) -> Result<Json<Vec<crate::entities::data_table::Model>>, ServiceError> {
//     // 可以访问headers和query
//     // 例如: let custom_header = headers.get("x-custom-header");
    
//     let tables = state.data_table_service
//         .list_by_data_source(&claims.tenant_id, &query.data_source_id)
//         .await?;
//     Ok(Json(tables))
// }

// // 创建处理函数
// async fn create_handler(
//     State(state): State<DataTableAppState>,
//     // Extension(claims): Extension<crate::domain::auth::UserClaims>,
//     headers: HeaderMap,
//     Json(mut payload): Json<CreateDataTableRequest>,
// ) -> Result<(StatusCode, Json<crate::entities::data_table::Model>), ServiceError> {
//     // 可以访问headers
//     // 例如: let custom_header = headers.get("x-custom-header");
    
//     payload.tenant_id = Some(claims.tenant_id.clone());
//     let table = state.data_table_service.create(payload).await?;
//     Ok((StatusCode::CREATED, Json(table)))
// }

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<Json<crate::entities::data_table::Model>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let table = state.data_table_service.get(id).await?;
    Ok(Json(table))
}

// 详情查询处理函数（包含列和统计信息）
async fn get_with_details_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<Json<DataTableWithDetails>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let details = state.data_table_service.get_with_details(id).await?;
    Ok(Json(details))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    Json(payload): Json<UpdateDataTableRequest>,
) -> Result<Json<crate::entities::data_table::Model>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let table = state.data_table_service.update(id, payload).await?;
    Ok(Json(table))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
) -> Result<StatusCode, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    state.data_table_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 上传响应结构
#[derive(Debug, Serialize)]
struct UploadResponse {
    message: String,
    rows_inserted: usize,
}

// 数据上传处理函数
async fn upload_data_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, ServiceError> {
    let mut file_data: Option<Vec<u8>> = None;
    let mut partition_values: HashMap<String, String> = HashMap::new();

    // 解析 multipart 表单数据
    while let Some(field) = multipart.next_field().await
        .map_err(|e| ServiceError::InvalidInput(format!("Failed to read multipart field: {}", e)))? 
    {
        let name = field.name()
            .ok_or(ServiceError::InvalidInput("Field name is missing".to_string()))?
            .to_string();

        if name == "file" {
            // 读取文件数据
            let data = field.bytes().await
                .map_err(|e| ServiceError::InvalidInput(format!("Failed to read file data: {}", e)))?;
            file_data = Some(data.to_vec());
        } else if name.starts_with("partition_") {
            // 解析分区字段，格式为 partition_<字段名>
            let field_name = name.strip_prefix("partition_")
                .ok_or(ServiceError::InvalidInput("Invalid partition field name".to_string()))?
                .to_string();
            let value = field.text().await
                .map_err(|e| ServiceError::InvalidInput(format!("Failed to read partition value: {}", e)))?;
            partition_values.insert(field_name, value);
        }
    }

    let file_data = file_data
        .ok_or(ServiceError::InvalidInput("File data is required".to_string()))?;

    // 调用服务层处理上传
    let rows_inserted = state.data_table_service
        .upload_data(id, file_data, partition_values)
        .await?;

    Ok(Json(UploadResponse {
        message: "Data uploaded successfully".to_string(),
        rows_inserted,
    }))
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
        // .route("/by-data-source", get(list_by_data_source_handler))
        // .route("/", post(create_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}/details", get(get_with_details_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        .route("/{id}/upload", post(upload_data_handler))
        // From 2MB to 50MB
        .layer(DefaultBodyLimit::max(50 * 1024 * 1024))
        .with_state(state)
}
