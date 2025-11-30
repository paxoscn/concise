use axum::{
    body::Body,
    extract::State,
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::Response,
    Json, Router,
    routing::post,
};
use serde::Deserialize;
use std::sync::Arc;

use crate::domain::{
    AuthService, ExecutorEngine, ExecutorError,
    TaskMetadata, TaskType, ExecutionResult,
};

// ExecuteRequest 执行请求结构
#[derive(Debug, Deserialize)]
pub struct ExecuteRequest {
    pub task_type: TaskType,
    pub metadata: TaskMetadata,
}

// AppState 应用状态
#[derive(Clone)]
pub struct ExecutorAppState {
    pub executor_engine: Arc<ExecutorEngine>,
    pub auth_service: Arc<AuthService>,
}

// JWT认证中间件
async fn jwt_auth_middleware(
    State(state): State<ExecutorAppState>,
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

// 执行任务处理函数
async fn execute_handler(
    State(state): State<ExecutorAppState>,
    Json(payload): Json<ExecuteRequest>,
) -> Result<Json<ExecutionResult>, ExecutorError> {
    let result = state
        .executor_engine
        .execute_task(payload.task_type, payload.metadata)
        .await?;
    
    Ok(Json(result))
}

// 创建执行器路由
pub fn create_executor_routes(
    executor_engine: Arc<ExecutorEngine>,
    auth_service: Arc<AuthService>,
) -> Router {
    let state = ExecutorAppState {
        executor_engine,
        auth_service,
    };

    Router::new()
        .route("/execute", post(execute_handler))
        .layer(middleware::from_fn_with_state(state.clone(), jwt_auth_middleware))
        .with_state(state)
}
