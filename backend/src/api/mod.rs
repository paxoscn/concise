// API层：处理HTTP请求、路由和中间件

pub mod auth;
pub mod data_source;
pub mod storage;
pub mod task;
pub mod executor;
pub mod middleware;

pub use auth::create_auth_routes;
pub use data_source::create_data_source_routes;
pub use storage::create_storage_routes;
pub use task::create_task_routes;
pub use executor::create_executor_routes;
pub use middleware::{ErrorResponse, jwt_auth_middleware, logging_middleware, AuthMiddlewareState};
