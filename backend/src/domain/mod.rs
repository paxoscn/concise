// 领域层：业务逻辑和服务

pub mod auth;
pub mod data_source;
pub mod storage;
pub mod task;
pub mod executor;
pub mod query;
pub mod error;

pub use auth::AuthService;
pub use data_source::{DataSourceService, CreateDataSourceRequest, UpdateDataSourceRequest};
pub use storage::{StorageService, CreateStorageRequest, UpdateStorageRequest};
pub use task::{TaskCenterClient, TaskService, Task, CreateTaskRequest, UpdateTaskRequest};
pub use executor::{
    ExecutorEngine, ExecutionResult, 
    TaskMetadata, TaskType
};
pub use query::{QueryService, QueryError};
pub use error::{AppError, AuthError, ServiceError, ExecutorError, ClientError};
