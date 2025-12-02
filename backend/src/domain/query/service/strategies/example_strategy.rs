use async_trait::async_trait;
use serde_json::{json, Value};

use crate::domain::query::{QueryStrategy, QueryContext, QueryError};

/// Example strategy - copy this file to create new strategies
pub struct ExampleStrategy;

impl ExampleStrategy {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl QueryStrategy for ExampleStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // 1. Extract and validate parameters from context.params
        let param1 = context.params.get("param1")
            .and_then(|v| v.as_str())
            .ok_or_else(|| QueryError::InvalidInput("Missing 'param1' parameter".to_string()))?;

        // 2. Extract spec fields from context.spec
        let spec_field = context.spec.get("field")
            .and_then(|v| v.as_str())
            .unwrap_or("default_value");

        // 3. Access data sources
        // You can iterate through all data sources or get a specific one
        for (ds_name, pool) in &context.data_sources {
            log::info!("Available data source: {}", ds_name);
            
            // Example query
            let _result = sqlx::query("SELECT 1")
                .fetch_one(pool)
                .await
                .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;
        }

        // 4. Build and return response
        let result = json!({
            "view": "example",
            "tenant_id": context.tenant_id,
            "params": {
                "param1": param1,
            },
            "spec": {
                "field": spec_field,
            },
            "result": {
                "message": "Example strategy executed successfully"
            }
        });

        Ok(result)
    }
}
