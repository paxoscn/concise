use axum::{
    body::Body,
    extract::State,
    http::{Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::sync::Arc;

use crate::domain::{AppError, AuthError, AuthService, ServiceError, ExecutorError, ClientError};

// ErrorResponse 统一错误响应结构
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}

// JWT认证中间件状态
#[derive(Clone)]
pub struct AuthMiddlewareState {
    pub auth_service: Arc<AuthService>,
}

// JWT认证中间件
pub async fn jwt_auth_middleware(
    State(state): State<AuthMiddlewareState>,
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

// 请求日志中间件
pub async fn logging_middleware(
    req: Request<Body>,
    next: Next,
) -> Response {
    let method = req.method().clone();
    let uri = req.uri().clone();
    
    log::info!("Request: {} {}", method, uri);
    
    let response = next.run(req).await;
    
    log::info!("Response: {} {} - Status: {}", method, uri, response.status());
    
    response
}

// 统一错误处理 - 将AppError转换为HTTP响应
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match self {
            AppError::Auth(auth_err) => match auth_err {
                AuthError::InvalidCredentials => (
                    StatusCode::UNAUTHORIZED,
                    "INVALID_CREDENTIALS",
                    "Invalid nickname or password",
                ),
                AuthError::InvalidToken => (
                    StatusCode::UNAUTHORIZED,
                    "INVALID_TOKEN",
                    "Invalid authentication token",
                ),
                AuthError::TokenExpired => (
                    StatusCode::UNAUTHORIZED,
                    "TOKEN_EXPIRED",
                    "Authentication token has expired",
                ),
                AuthError::JwtError(_) => (
                    StatusCode::UNAUTHORIZED,
                    "JWT_ERROR",
                    "JWT processing error",
                ),
                AuthError::BcryptError(_) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "Password verification error",
                ),
                AuthError::DatabaseError(_) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "DATABASE_ERROR",
                    "Database operation failed",
                ),
            },
            AppError::Service(ref service_err) => match service_err {
                ServiceError::NotFound => (
                    StatusCode::NOT_FOUND,
                    "NOT_FOUND",
                    "Resource not found",
                ),
                ServiceError::AlreadyExists => (
                    StatusCode::CONFLICT,
                    "ALREADY_EXISTS",
                    "Resource already exists",
                ),
                ServiceError::InvalidInput(msg) => (
                    StatusCode::UNPROCESSABLE_ENTITY,
                    "INVALID_INPUT",
                    msg.as_str(),
                ),
            },
            AppError::Database(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "DATABASE_ERROR",
                "Database operation failed",
            ),
            AppError::Executor(ref executor_err) => match executor_err {
                ExecutorError::UnsupportedTaskType => (
                    StatusCode::BAD_REQUEST,
                    "UNSUPPORTED_TASK_TYPE",
                    "Unsupported task type",
                ),
                ExecutorError::ExecutionFailed(msg) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "EXECUTION_FAILED",
                    msg.as_str(),
                ),
                ExecutorError::ConnectionFailed => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "CONNECTION_FAILED",
                    "Data source connection failed",
                ),
            },
            AppError::Client(ref client_err) => match client_err {
                ClientError::RequestFailed(msg) => (
                    StatusCode::BAD_GATEWAY,
                    "REQUEST_FAILED",
                    msg.as_str(),
                ),
                ClientError::ParseError(msg) => (
                    StatusCode::BAD_GATEWAY,
                    "PARSE_ERROR",
                    msg.as_str(),
                ),
            },
        };

        let error_response = ErrorResponse {
            code: code.to_string(),
            message: message.to_string(),
            details: None,
        };

        (status, Json(error_response)).into_response()
    }
}

// 为AuthError实现IntoResponse（向后兼容）
impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        AppError::Auth(self).into_response()
    }
}

// 为ServiceError实现IntoResponse（向后兼容）
impl IntoResponse for ServiceError {
    fn into_response(self) -> Response {
        AppError::Service(self).into_response()
    }
}

// 为ExecutorError实现IntoResponse
impl IntoResponse for ExecutorError {
    fn into_response(self) -> Response {
        AppError::Executor(self).into_response()
    }
}

// 为ClientError实现IntoResponse
impl IntoResponse for ClientError {
    fn into_response(self) -> Response {
        AppError::Client(self).into_response()
    }
}
