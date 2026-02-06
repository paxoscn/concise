use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::data_source;
use crate::repository::data_source::DataSourceRepository;
use super::error::ServiceError;
use sqlx::{Row, Column};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateDataSourceRequest {
    pub name: String,
    pub db_type: String,
    pub connection_config: serde_json::Value,
    #[serde(skip_deserializing)]
    pub tenant_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateDataSourceRequest {
    pub name: Option<String>,
    pub db_type: Option<String>,
    pub connection_config: Option<serde_json::Value>,
}

pub struct DataSourceService {
    repo: Arc<DataSourceRepository>,
}

impl DataSourceService {
    pub fn new(repo: Arc<DataSourceRepository>) -> Self {
        Self { repo }
    }

    pub async fn create(&self, req: CreateDataSourceRequest) -> Result<data_source::Model, ServiceError> {
        // Validate input
        if req.name.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Name cannot be empty".to_string()));
        }
        if req.db_type.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Database type cannot be empty".to_string()));
        }

        let tenant_id = req.tenant_id.ok_or(ServiceError::InvalidInput("Tenant ID is required".to_string()))?;

        let now = Utc::now().naive_utc();
        let id = uuid::Uuid::new_v4().to_string();

        let model = data_source::ActiveModel {
            id: Set(id),
            name: Set(req.name),
            db_type: Set(req.db_type),
            connection_config: Set(req.connection_config),
            tenant_id: Set(tenant_id),
            created_at: Set(now),
            updated_at: Set(now),
        };

        self.repo.create(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to create data source".to_string()))
    }

    pub async fn list(&self) -> Result<Vec<data_source::Model>, ServiceError> {
        self.repo.find_all().await
            .map_err(|_| ServiceError::InvalidInput("Failed to list data sources".to_string()))
    }

    pub async fn list_by_tenant(&self, tenant_id: &str) -> Result<Vec<data_source::Model>, ServiceError> {
        self.repo.find_by_tenant(tenant_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to list data sources".to_string()))
    }

    pub async fn get(&self, id: String) -> Result<data_source::Model, ServiceError> {
        self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get data source".to_string()))?
            .ok_or(ServiceError::NotFound)
    }

    pub async fn update(&self, id: String, req: UpdateDataSourceRequest) -> Result<data_source::Model, ServiceError> {
        // First check if the data source exists
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data source".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        let now = Utc::now().naive_utc();

        let model = data_source::ActiveModel {
            id: Set(existing.id),
            name: Set(req.name.unwrap_or(existing.name)),
            db_type: Set(req.db_type.unwrap_or(existing.db_type)),
            connection_config: Set(req.connection_config.unwrap_or(existing.connection_config)),
            tenant_id: Set(existing.tenant_id),
            created_at: Set(existing.created_at),
            updated_at: Set(now),
        };

        self.repo.update(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to update data source".to_string()))
    }

    pub async fn delete(&self, id: String) -> Result<(), ServiceError> {
        // First check if the data source exists
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data source".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        self.repo.delete(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete data source".to_string()))?;

        Ok(())
    }

    pub async fn execute_sql(&self, id: &str, sql: &str) -> Result<SqlExecutionResult, ServiceError> {
        // Get the data source
        let data_source = self.repo.find_by_id(id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data source".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        // Execute SQL based on database type
        match data_source.db_type.as_str() {
            "postgresql" | "PostgreSQL" => {
                self.execute_postgresql_query(sql, &data_source.connection_config).await
            }
            _ => Err(ServiceError::InvalidInput(
                format!("Unsupported database type: {}. Only PostgreSQL is supported.", data_source.db_type)
            )),
        }
    }

    async fn execute_postgresql_query(
        &self,
        sql: &str,
        connection_config: &serde_json::Value,
    ) -> Result<SqlExecutionResult, ServiceError> {
        // Parse connection config
        let config = connection_config.as_object()
            .ok_or_else(|| ServiceError::InvalidInput("Invalid connection config".to_string()))?;

        let host = config.get("host")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ServiceError::InvalidInput("Missing host in connection config".to_string()))?;
        
        let port = config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(5432);
        
        let database = config.get("database")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ServiceError::InvalidInput("Missing database in connection config".to_string()))?;
        
        let username = config.get("username")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ServiceError::InvalidInput("Missing username in connection config".to_string()))?;
        
        let password = config.get("password")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ServiceError::InvalidInput("Missing password in connection config".to_string()))?;

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
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to connect to database: {}", e)))?;

        // Execute query
        let rows = sqlx::query(sql)
            .fetch_all(&pool)
            .await
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to execute SQL: {}", e)))?;

        // Extract column names and data
        let mut columns = Vec::new();
        let mut result_rows = Vec::new();

        if let Some(first_row) = rows.first() {
            for column in first_row.columns() {
                columns.push(column.name().to_string());
            }
        }

        for row in rows {
            let mut result_row = Vec::new();
            for (i, _column) in columns.iter().enumerate() {
                let value: Option<String> = row.try_get(i).ok();
                result_row.push(match value {
                    Some(v) => Value::String(v),
                    None => Value::Null,
                });
            }
            result_rows.push(result_row);
        }

        let row_count = result_rows.len();

        pool.close().await;

        Ok(SqlExecutionResult {
            columns,
            rows: result_rows,
            row_count,
        })
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct SqlExecutionResult {
    pub columns: Vec<String>,
    pub rows: Vec<Vec<Value>>,
    pub row_count: usize,
}
