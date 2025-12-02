use async_trait::async_trait;
use serde_json::Value;
use sqlx::{Pool, Postgres};
use std::collections::HashMap;

use super::error::QueryError;

/// QueryContext contains all the information needed for a query strategy
pub struct QueryContext {
    /// Map of data source name to database connection pool
    pub data_sources: HashMap<String, Pool<Postgres>>,
    /// Tenant ID
    pub tenant_id: String,
    /// Query parameters
    pub params: Value,
    /// Query specification
    pub spec: Value,
}

/// QueryStrategy trait that all query strategies must implement
#[async_trait]
pub trait QueryStrategy: Send + Sync {
    /// Execute the query strategy and return the result
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError>;
}
