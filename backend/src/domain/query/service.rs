use serde_json::Value;
use sqlx::{Pool, Postgres};
use std::collections::HashMap;
use std::sync::Arc;

use crate::domain::DataSourceService;
use super::error::QueryError;
use super::strategy::{QueryStrategy, QueryContext};

mod strategies;
use strategies::{ComparableCardStrategy};

pub struct QueryService {
    data_source_service: Arc<DataSourceService>,
    strategies: HashMap<String, Box<dyn QueryStrategy>>,
}

impl QueryService {
    pub fn new(data_source_service: Arc<DataSourceService>) -> Self {
        let mut strategies: HashMap<String, Box<dyn QueryStrategy>> = HashMap::new();
        
        // Register all strategies
        strategies.insert(
            "comparable_card".to_string(),
            Box::new(ComparableCardStrategy::new()),
        );

        Self {
            data_source_service,
            strategies,
        }
    }

    pub async fn execute_query(
        &self,
        tenant_id: &str,
        view: &str,
        params: Value,
        spec: Value,
    ) -> Result<Value, QueryError> {
        // Get the strategy for the view
        let strategy = self
            .strategies
            .get(view)
            .ok_or_else(|| QueryError::StrategyNotFound(format!("View '{}' not found", view)))?;

        // Get all data sources for the tenant
        let data_sources = self
            .data_source_service
            .list_by_tenant(tenant_id)
            .await
            .map_err(|e| QueryError::DatabaseError(format!("Failed to get data sources: {}", e)))?;

        // Create connection pools for each data source
        let mut pools: HashMap<String, Pool<Postgres>> = HashMap::new();
        
        for ds in data_sources {
            // Parse connection config
            let config = ds.connection_config.as_object()
                .ok_or_else(|| QueryError::InvalidInput("Invalid connection config".to_string()))?;

            let host = config.get("host")
                .and_then(|v| v.as_str())
                .ok_or_else(|| QueryError::InvalidInput("Missing host in connection config".to_string()))?;
            
            let port = config.get("port")
                .and_then(|v| v.as_u64())
                .unwrap_or(5432);
            
            let database = config.get("database")
                .and_then(|v| v.as_str())
                .ok_or_else(|| QueryError::InvalidInput("Missing database in connection config".to_string()))?;
            
            let username = config.get("username")
                .and_then(|v| v.as_str())
                .ok_or_else(|| QueryError::InvalidInput("Missing username in connection config".to_string()))?;
            
            let password = config.get("password")
                .and_then(|v| v.as_str())
                .ok_or_else(|| QueryError::InvalidInput("Missing password in connection config".to_string()))?;

            // Build connection string
            let connection_string = format!(
                "postgres://{}:{}@{}:{}/{}",
                username, password, host, port, database
            );

            // Create connection pool
            let pool = sqlx::postgres::PgPoolOptions::new()
                .max_connections(5)
                .connect(&connection_string)
                .await
                .map_err(|e| QueryError::DatabaseError(format!("Failed to connect to {}: {}", ds.name, e)))?;

            pools.insert(ds.name.clone(), pool);
        }

        // Create query context
        let context = QueryContext {
            data_sources: pools,
            tenant_id: tenant_id.to_string(),
            params,
            spec,
        };

        // Execute the strategy
        strategy.execute(context).await
    }
}
