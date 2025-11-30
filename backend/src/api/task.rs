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
    AuthService, TaskService, CreateTaskRequest, 
    UpdateTaskRequest, ClientError,
};

// AppState 应用状态
#[derive(Clone)]
pub struct TaskAppState {
    pub task_service: Arc<TaskService>,
    pub auth_service: Arc<AuthService>,
}

// JWT认证中间件
async fn jwt_auth_middleware(
    State(state): State<TaskAppState>,
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
    State(state): State<TaskAppState>,
) -> Result<Json<Vec<crate::domain::Task>>, ClientError> {
    let tasks = state.task_service.list().await?;
    Ok(Json(tasks))
}

// 创建处理函数
async fn create_handler(
    State(state): State<TaskAppState>,
    Json(payload): Json<CreateTaskRequest>,
) -> Result<(StatusCode, Json<crate::domain::Task>), ClientError> {
    let task = state.task_service.create(payload).await?;
    Ok((StatusCode::CREATED, Json(task)))
}

// 详情查询处理函数
async fn get_handler(
    State(state): State<TaskAppState>,
    Path(id): Path<String>,
) -> Result<Json<crate::domain::Task>, ClientError> {
    let task = state.task_service.get(id).await?;
    Ok(Json(task))
}

// 更新处理函数
async fn update_handler(
    State(state): State<TaskAppState>,
    Path(id): Path<String>,
    Json(payload): Json<UpdateTaskRequest>,
) -> Result<Json<crate::domain::Task>, ClientError> {
    let task = state.task_service.update(id, payload).await?;
    Ok(Json(task))
}

// 删除处理函数
async fn delete_handler(
    State(state): State<TaskAppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ClientError> {
    state.task_service.delete(id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// 创建任务路由
pub fn create_task_routes(
    task_service: Arc<TaskService>,
    auth_service: Arc<AuthService>,
) -> Router {
    let state = TaskAppState {
        task_service,
        auth_service,
    };

    Router::new()
        .route("/", get(list_handler))
        .route("/", post(create_handler))
        .route("/:id", get(get_handler))
        .route("/:id", put(update_handler))
        .route("/:id", delete(delete_handler))
        .layer(middleware::from_fn_with_state(state.clone(), jwt_auth_middleware))
        .with_state(state)
}
