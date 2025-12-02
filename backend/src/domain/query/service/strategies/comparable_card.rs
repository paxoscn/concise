use async_trait::async_trait;
use serde_json::{json, Value};
use sqlx::Row;

use crate::domain::query::{QueryStrategy, QueryContext, QueryError};

pub struct ComparableCardStrategy;

impl ComparableCardStrategy {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl QueryStrategy for ComparableCardStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // Extract parameters
        let start = context.params.get("start")
            .and_then(|v| v.as_str())
            .ok_or_else(|| QueryError::InvalidInput("Missing 'start' parameter".to_string()))?;
        
        let end = context.params.get("end")
            .and_then(|v| v.as_str())
            .ok_or_else(|| QueryError::InvalidInput("Missing 'end' parameter".to_string()))?;

        // Example: Get the first available data source
        let (ds_name, pool) = context.data_sources.iter().next()
            .ok_or_else(|| QueryError::DatabaseError("No data sources available".to_string()))?;

        // Example query - replace with your actual logic
        // 
        // Alternative: Use context.build_query() if spec.sql is provided:
        let built = context.build_query()?;
        println!("sql = {}", &built.sql);
        // let mut query = sqlx::query(&built.sql);
        // for param_name in &built.param_names {
        //     query = context.bind_param(query, param_name)?;
        // }
        // let row = query.fetch_one(pool).await
        //     .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;
        
        let query = r#"
            SELECT 
                COUNT(*) as total_count,
                $1 as start_date,
                $2 as end_date,
                $3 as tenant_id
        "#;

        let row = sqlx::query(query)
            .bind(start)
            .bind(end)
            .bind(&context.tenant_id)
            .fetch_one(pool)
            .await
            .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;

        let total_count: i64 = row.try_get("total_count")
            .map_err(|e| QueryError::ExecutionError(format!("Failed to get total_count: {}", e)))?;

        // Build response
        let result = json!({
            "view": "comparable_card",
            "tenant_id": context.tenant_id,
            "data_source": ds_name,
            "params": {
                "start": start,
                "end": end,
            },
            "spec": context.spec,
            "result": {
                "total_count": total_count,
            }
        });

        Ok(result)
    }
}
