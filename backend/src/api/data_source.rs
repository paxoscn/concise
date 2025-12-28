use axum::{
    body::Body,
    extract::{Path, Query, State},
    http::{Request, StatusCode, HeaderMap},
    middleware::{self, Next},
    response::Response,
    Extension,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde::Deserialize;
use std::sync::Arc;

use crate::domain::{
    AuthService, DataSourceService, CreateDataSourceRequest, 
    UpdateDataSourceRequest, ServiceError,
};

// AppState 应用状态
#[derive(Clone)]
pub struct DataSourceAppState {
    pub data_source_service: Arc<DataSourceService>,
    pub auth_service: Arc<AuthService>,
}

// JWT认证中间件
async fn jwt_auth_middleware(
    State(state): State<DataSourceAppState>,
    mut req: Request<Body>,
    next: Next,
) -> Result<Response, StatusCode> {
    // 从请求头中获取Authorization
    let auth_header = req
        .headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // 检查Bearer token格式
    if !auth_header.starts_with("Bearer ") {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let token = &auth_header[7..]; // 移除"Bearer "前缀

    // 验证token
    let claims = state
        .auth_service
        .verify_token(token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // 将用户信息存入请求扩展中
    req.extensions_mut().insert(claims);

    Ok(next.run(req).await)
}

// 查询参数结构
#[derive(Debug, Deserialize)]
struct ListQueryParams {
    #[serde(default)]
    tenant_id: Option<String>,
    #[serde(default)]
    page: Option<u64>,
    #[serde(default)]
    page_size: Option<u64>,
}

/*
curl -v "$TARGET/api/v1/data-sources" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1'
*/
// 列表查询处理函数
async fn list_handler(
    State(state): State<DataSourceAppState>,
    // Extension(claims): Extension<crate::domain::auth::UserClaims>,
    headers: HeaderMap,
    Query(params): Query<ListQueryParams>,
) -> Result<Json<Vec<crate::entities::data_source::Model>>, ServiceError> {
    // 可以访问headers和params
    // 例如: let custom_header = headers.get("x-custom-header");
    // 例如: let page = params.page.unwrap_or(1);
    
    // let data_sources = state.data_source_service.list_by_tenant(&claims.tenant_id).await?;
    let data_sources = state.data_source_service.list_by_tenant(&params.tenant_id.unwrap_or("".to_string())).await?;
    Ok(Json(data_sources))
}

// 创建处理函数
// async fn create_handler(
//     State(state): State<DataSourceAppState>,
//     // Extension(claims): Extension<crate::domain::auth::UserClaims>,
//     headers: HeaderMap,
//     Json(mut payload): Json<CreateDataSourceRequest>,
// ) -> Result<(StatusCode, Json<crate::entities::data_source::Model>), ServiceError> {
//     // 可以访问headers
//     // 例如: let custom_header = headers.get("x-custom-header");
    
//     payload.tenant_id = Some(claims.tenant_id.clone());
//     let data_source = state.data_source_service.create(payload).await?;
//     Ok((StatusCode::CREATED, Json(data_source)))
// }

// 详情查询参数结构
#[derive(Debug, Deserialize)]
struct GetQueryParams {
    #[serde(default)]
    include_metadata: Option<bool>,
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    Query(params): Query<GetQueryParams>,
) -> Result<Json<crate::entities::data_source::Model>, ServiceError> {
    // 可以访问headers和params
    // 例如: let custom_header = headers.get("x-custom-header");
    // 例如: let include_metadata = params.include_metadata.unwrap_or(false);
    
    let data_source = state.data_source_service.get(id).await?;
    Ok(Json(data_source))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    Json(payload): Json<UpdateDataSourceRequest>,
) -> Result<Json<crate::entities::data_source::Model>, ServiceError> {
    // 可以访问headers
    // 例如: let custom_header = headers.get("x-custom-header");
    
    let data_source = state.data_source_service.update(id, payload).await?;
    Ok(Json(data_source))
}

// 删除查询参数结构
#[derive(Debug, Deserialize)]
struct DeleteQueryParams {
    #[serde(default)]
    force: Option<bool>,
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    Query(params): Query<DeleteQueryParams>,
) -> Result<StatusCode, ServiceError> {
    // 可以访问headers和params
    // 例如: let custom_header = headers.get("x-custom-header");
    // 例如: let force = params.force.unwrap_or(false);
    
    state.data_source_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 创建数据源路由
pub fn create_data_source_routes(
    data_source_service: Arc<DataSourceService>,
    auth_service: Arc<AuthService>,
) -> Router {
    let state = DataSourceAppState {
        data_source_service,
        auth_service,
    };

    Router::new()
        .route("/", get(list_handler))
        // .route("/", post(create_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        // .layer(middleware::from_fn_with_state(state.clone(), jwt_auth_middleware))
        .with_state(state)
}
