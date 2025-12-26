// API层：处理HTTP请求、路由和中间件

pub mod auth;
pub mod data_source;
pub mod storage;
pub mod task;
pub mod executor;
pub mod query;
pub mod middleware;
pub mod data_table;
pub mod data_table_column;
pub mod data_table_usage;

pub use auth::create_auth_routes;
pub use data_source::create_data_source_routes;
pub use storage::create_storage_routes;
pub use task::create_task_routes;
pub use executor::create_executor_routes;
pub use query::create_query_routes;
pub use middleware::logging_middleware;
pub use data_table::create_data_table_routes;
pub use data_table_column::create_data_table_column_routes;
pub use data_table_usage::create_data_table_usage_routes;
