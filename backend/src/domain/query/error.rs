use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum QueryError {
    #[error("Invalid input: {0}")]
    InvalidInput(String),

    #[error("Strategy not found: {0}")]
    StrategyNotFound(String),

    #[error("Database error: {0}")]
    DatabaseError(String),

    #[error("Query execution error: {0}")]
    ExecutionError(String),

    #[error("Internal error: {0}")]
    InternalError(String),
}

impl IntoResponse for QueryError {
    fn into_response(self) -> Response {
        let (status, error_message) = match self {
            QueryError::InvalidInput(msg) => (StatusCode::BAD_REQUEST, msg),
            QueryError::StrategyNotFound(msg) => (StatusCode::NOT_FOUND, msg),
            QueryError::DatabaseError(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
            QueryError::ExecutionError(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
            QueryError::InternalError(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
        };

        let body = Json(json!({
            "error": error_message,
        }));

        (status, body).into_response()
    }
}
