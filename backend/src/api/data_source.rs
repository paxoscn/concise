use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::Response,
    Json, Router,
    routing::{get, post, put, delete},
};
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

// 列表查询处理函数
async fn list_handler(
    State(state): State<DataSourceAppState>,
) -> Result<Json<Vec<crate::entities::data_source::Model>>, ServiceError> {
    let data_sources = state.data_source_service.list().await?;
    Ok(Json(data_sources))
}

// 创建处理函数
async fn create_handler(
    State(state): State<DataSourceAppState>,
    Json(payload): Json<CreateDataSourceRequest>,
) -> Result<(StatusCode, Json<crate::entities::data_source::Model>), ServiceError> {
    let data_source = state.data_source_service.create(payload).await?;
    Ok((StatusCode::CREATED, Json(data_source)))
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
) -> Result<Json<crate::entities::data_source::Model>, ServiceError> {
    let data_source = state.data_source_service.get(id).await?;
    Ok(Json(data_source))
}

// 更新处理函数
async fn update_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
    Json(payload): Json<UpdateDataSourceRequest>,
) -> Result<Json<crate::entities::data_source::Model>, ServiceError> {
    let data_source = state.data_source_service.update(id, payload).await?;
    Ok(Json(data_source))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<DataSourceAppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ServiceError> {
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
        .route("/", post(create_handler))
        .route("/{id}", get(get_handler))
        .route("/{id}", put(update_handler))
        .route("/{id}", delete(delete_handler))
        .layer(middleware::from_fn_with_state(state.clone(), jwt_auth_middleware))
        .with_state(state)
}
