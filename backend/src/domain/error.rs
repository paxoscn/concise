use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Authentication error: {0}")]
    Auth(#[from] AuthError),
    
    #[error("Service error: {0}")]
    Service(#[from] ServiceError),
    
    #[error("Database error: {0}")]
    Database(#[from] sea_orm::DbErr),
    
    #[error("Executor error: {0}")]
    Executor(#[from] ExecutorError),
    
    #[error("External client error: {0}")]
    Client(#[from] ClientError),
}

#[derive(Debug, Error)]
pub enum AuthError {
    #[error("Invalid credentials")]
    InvalidCredentials,
    
    #[error("Invalid token")]
    InvalidToken,
    
    #[error("Token expired")]
    TokenExpired,
    
    #[error("JWT error: {0}")]
    JwtError(#[from] jsonwebtoken::errors::Error),
    
    #[error("Password hashing error: {0}")]
    BcryptError(#[from] bcrypt::BcryptError),
    
    #[error("Database error: {0}")]
    DatabaseError(#[from] sea_orm::DbErr),
}

#[derive(Debug, Error)]
pub enum ServiceError {
    #[error("Resource not found")]
    NotFound,
    
    #[error("Resource already exists")]
    AlreadyExists,
    
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    #[error("Unauthorized")]
    Unauthorized,
}

#[derive(Debug, Error)]
pub enum ExecutorError {
    #[error("Unsupported task type")]
    UnsupportedTaskType,
    
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
    
    #[error("Data source connection failed")]
    ConnectionFailed,
}

#[derive(Debug, Error)]
pub enum ClientError {
    #[error("HTTP request failed: {0}")]
    RequestFailed(String),
    
    #[error("Response parsing failed: {0}")]
    ParseError(String),
}
