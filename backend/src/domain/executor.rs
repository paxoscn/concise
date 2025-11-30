use std::sync::Arc;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use crate::entities::{data_source, storage};
use super::error::ExecutorError;
use super::data_source::DataSourceService;
use super::storage::StorageService;
use super::task::TaskService;

// Task metadata structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskMetadata {
    pub task_id: String,
    #[serde(default)]
    pub dependencies: Vec<String>,
    #[serde(default)]
    pub next_actions: Vec<NextAction>,
    pub config: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NextAction {
    pub action_type: String,
    pub target_task_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub condition: Option<String>,
}

// Task type enum
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TaskType {
    Sql,
    Excel,
}

// Executor context containing all available resources
#[derive(Debug, Clone)]
pub struct ExecutorContext {
    pub data_sources: Vec<data_source::Model>,
    pub storages: Vec<storage::Model>,
}

// Execution result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionResult {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
}

// Executor trait - all executors must implement this
#[async_trait]
pub trait Executor: Send + Sync {
    async fn execute(
        &self,
        metadata: TaskMetadata,
        context: ExecutorContext,
    ) -> Result<ExecutionResult, ExecutorError>;
}

// ExecutorEngine - main engine for task execution
pub struct ExecutorEngine {
    data_source_service: Arc<DataSourceService>,
    storage_service: Arc<StorageService>,
    task_service: Arc<TaskService>,
}

impl ExecutorEngine {
    pub fn new(
        data_source_service: Arc<DataSourceService>,
        storage_service: Arc<StorageService>,
        task_service: Arc<TaskService>,
    ) -> Self {
        Self {
            data_source_service,
            storage_service,
            task_service,
        }
    }

    /// Execute a task based on its type and metadata
    pub async fn execute_task(
        &self,
        task_type: TaskType,
        metadata: TaskMetadata,
    ) -> Result<ExecutionResult, ExecutorError> {
        // Build executor context by fetching all data sources and storages
        let context = self.build_context().await?;

        // Get the appropriate executor for the task type
        let executor = self.get_executor(&task_type);

        // Execute the task
        let result = executor.execute(metadata.clone(), context).await?;

        // If execution was successful, trigger next actions
        if result.success {
            self.trigger_next_actions(&metadata, &result).await?;
        }

        Ok(result)
    }

    /// Build execution context by fetching all available resources
    async fn build_context(&self) -> Result<ExecutorContext, ExecutorError> {
        let data_sources = self.data_source_service
            .list()
            .await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to fetch data sources: {}", e)))?;

        let storages = self.storage_service
            .list()
            .await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to fetch storages: {}", e)))?;

        Ok(ExecutorContext {
            data_sources,
            storages,
        })
    }

    /// Get the appropriate executor based on task type
    fn get_executor(&self, task_type: &TaskType) -> Box<dyn Executor> {
        match task_type {
            TaskType::Sql => Box::new(SqlExecutor),
            TaskType::Excel => Box::new(ExcelExecutor),
        }
    }

    /// Trigger next actions based on task metadata
    async fn trigger_next_actions(
        &self,
        metadata: &TaskMetadata,
        _result: &ExecutionResult,
    ) -> Result<(), ExecutorError> {
        for action in &metadata.next_actions {
            // For now, we'll just log the action
            // In a real implementation, this would trigger the next task
            log::info!(
                "Triggering next action: {} for task {}",
                action.action_type,
                action.target_task_id
            );

            // TODO: Implement actual task triggering logic
            // This could involve:
            // 1. Checking conditions
            // 2. Calling task service to update task status
            // 3. Triggering task execution
        }

        Ok(())
    }
}

// SQL Executor - executes SQL statements against data sources
pub struct SqlExecutor;

#[async_trait]
impl Executor for SqlExecutor {
    async fn execute(
        &self,
        metadata: TaskMetadata,
        context: ExecutorContext,
    ) -> Result<ExecutionResult, ExecutorError> {
        // Extract SQL configuration from metadata
        let sql_statement = metadata.config
            .get("sql")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'sql' in config".to_string()))?;

        let data_source_id = metadata.config
            .get("data_source_id")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'data_source_id' in config".to_string()))?;

        // Find the data source
        let data_source = context.data_sources
            .iter()
            .find(|ds| ds.id == data_source_id)
            .ok_or_else(|| ExecutorError::ExecutionFailed(format!("Data source {} not found", data_source_id)))?;

        // Execute SQL based on database type
        match data_source.db_type.as_str() {
            "mysql" | "MySQL" => {
                self.execute_mysql(sql_statement, &data_source.connection_config).await
            }
            "postgresql" | "PostgreSQL" => {
                self.execute_postgresql(sql_statement, &data_source.connection_config).await
            }
            _ => Err(ExecutorError::ExecutionFailed(
                format!("Unsupported database type: {}", data_source.db_type)
            )),
        }
    }
}

impl SqlExecutor {
    /// Execute SQL statement on MySQL database
    async fn execute_mysql(
        &self,
        sql: &str,
        connection_config: &serde_json::Value,
    ) -> Result<ExecutionResult, ExecutorError> {
        use sea_orm::{Database, Statement, ConnectionTrait};

        // Build connection string from config
        let connection_string = self.build_mysql_connection_string(connection_config)?;

        // Connect to database
        let db = Database::connect(&connection_string)
            .await
            .map_err(|_| ExecutorError::ConnectionFailed)?;

        // Execute the SQL statement
        let result = db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::MySql,
            sql.to_string(),
        ))
        .await
        .map_err(|e| ExecutorError::ExecutionFailed(format!("SQL execution failed: {}", e)))?;

        // Close connection
        db.close().await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to close connection: {}", e)))?;

        Ok(ExecutionResult {
            success: true,
            message: format!("SQL executed successfully. Rows affected: {}", result.rows_affected()),
            data: Some(serde_json::json!({
                "rows_affected": result.rows_affected(),
            })),
        })
    }

    /// Execute SQL statement on PostgreSQL database
    async fn execute_postgresql(
        &self,
        sql: &str,
        connection_config: &serde_json::Value,
    ) -> Result<ExecutionResult, ExecutorError> {
        use sea_orm::{Database, Statement, ConnectionTrait};

        // Build connection string from config
        let connection_string = self.build_postgresql_connection_string(connection_config)?;

        // Connect to database
        let db = Database::connect(&connection_string)
            .await
            .map_err(|_| ExecutorError::ConnectionFailed)?;

        // Execute the SQL statement
        let result = db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Postgres,
            sql.to_string(),
        ))
        .await
        .map_err(|e| ExecutorError::ExecutionFailed(format!("SQL execution failed: {}", e)))?;

        // Close connection
        db.close().await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to close connection: {}", e)))?;

        Ok(ExecutionResult {
            success: true,
            message: format!("SQL executed successfully. Rows affected: {}", result.rows_affected()),
            data: Some(serde_json::json!({
                "rows_affected": result.rows_affected(),
            })),
        })
    }

    /// Build MySQL connection string from config
    fn build_mysql_connection_string(
        &self,
        config: &serde_json::Value,
    ) -> Result<String, ExecutorError> {
        let host = config.get("host")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'host' in connection config".to_string()))?;

        let port = config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(3306);

        let database = config.get("database")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'database' in connection config".to_string()))?;

        let username = config.get("username")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'username' in connection config".to_string()))?;

        let password = config.get("password")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        Ok(format!(
            "mysql://{}:{}@{}:{}/{}",
            username, password, host, port, database
        ))
    }

    /// Build PostgreSQL connection string from config
    fn build_postgresql_connection_string(
        &self,
        config: &serde_json::Value,
    ) -> Result<String, ExecutorError> {
        let host = config.get("host")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'host' in connection config".to_string()))?;

        let port = config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(5432);

        let database = config.get("database")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'database' in connection config".to_string()))?;

        let username = config.get("username")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'username' in connection config".to_string()))?;

        let password = config.get("password")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        Ok(format!(
            "postgresql://{}:{}@{}:{}/{}",
            username, password, host, port, database
        ))
    }
}

// Excel Executor - imports Excel files into database tables
pub struct ExcelExecutor;

#[async_trait]
impl Executor for ExcelExecutor {
    async fn execute(
        &self,
        metadata: TaskMetadata,
        context: ExecutorContext,
    ) -> Result<ExecutionResult, ExecutorError> {
        // Extract Excel configuration from metadata
        let file_path = metadata.config
            .get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'file_path' in config".to_string()))?;

        let data_source_id = metadata.config
            .get("data_source_id")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'data_source_id' in config".to_string()))?;

        let storage_id = metadata.config
            .get("storage_id")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'storage_id' in config".to_string()))?;

        // Find the data source
        let data_source = context.data_sources
            .iter()
            .find(|ds| ds.id == data_source_id)
            .ok_or_else(|| ExecutorError::ExecutionFailed(format!("Data source {} not found", data_source_id)))?;

        // Find the storage
        let storage = context.storages
            .iter()
            .find(|s| s.id == storage_id)
            .ok_or_else(|| ExecutorError::ExecutionFailed(format!("Storage {} not found", storage_id)))?;

        // Download Excel file from storage
        let excel_data = self.download_file(file_path, storage).await?;

        // Parse Excel file
        let sheets_data = self.parse_excel(&excel_data)?;

        // Import data into database
        let rows_imported = self.import_to_database(sheets_data, data_source).await?;

        Ok(ExecutionResult {
            success: true,
            message: format!("Excel file imported successfully. Total rows: {}", rows_imported),
            data: Some(serde_json::json!({
                "rows_imported": rows_imported,
            })),
        })
    }
}

impl ExcelExecutor {
    /// Download file from storage
    async fn download_file(
        &self,
        file_path: &str,
        storage: &storage::Model,
    ) -> Result<Vec<u8>, ExecutorError> {
        // Build download URL
        let download_url = format!("{}/{}", storage.download_endpoint, file_path);

        // Create HTTP client
        let client = reqwest::Client::new();

        // Get authentication headers if needed
        let mut request = client.get(&download_url);

        // Add authentication if configured
        if let Some(access_key) = storage.auth_config.get("access_key").and_then(|v| v.as_str()) {
            if let Some(_secret_key) = storage.auth_config.get("secret_key").and_then(|v| v.as_str()) {
                // Simple bearer token auth (adjust based on actual storage auth mechanism)
                request = request.header("Authorization", format!("Bearer {}", access_key));
            }
        }

        // Download file
        let response = request
            .send()
            .await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to download file: {}", e)))?;

        if !response.status().is_success() {
            return Err(ExecutorError::ExecutionFailed(
                format!("Download failed with status: {}", response.status())
            ));
        }

        let bytes = response
            .bytes()
            .await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to read file bytes: {}", e)))?;

        Ok(bytes.to_vec())
    }

    /// Parse Excel file and extract all sheets
    fn parse_excel(&self, data: &[u8]) -> Result<Vec<SheetData>, ExecutorError> {
        use calamine::{Reader, Xlsx, open_workbook_from_rs};
        use std::io::Cursor;

        let cursor = Cursor::new(data);
        let mut workbook: Xlsx<_> = open_workbook_from_rs(cursor)
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to open Excel file: {}", e)))?;

        let mut sheets = Vec::new();

        for sheet_name in workbook.sheet_names().to_vec() {
            if let Ok(range) = workbook.worksheet_range(&sheet_name) {
                let mut rows = Vec::new();
                let mut headers = Vec::new();

                for (idx, row) in range.rows().enumerate() {
                    if idx == 0 {
                        // First row is headers
                        headers = row.iter()
                            .map(|cell| cell.to_string())
                            .collect();
                    } else {
                        // Data rows
                        let row_data: Vec<String> = row.iter()
                            .map(|cell| cell.to_string())
                            .collect();
                        rows.push(row_data);
                    }
                }

                sheets.push(SheetData {
                    name: sheet_name,
                    headers,
                    rows,
                });
            }
        }

        Ok(sheets)
    }

    /// Import sheets data into database
    async fn import_to_database(
        &self,
        sheets: Vec<SheetData>,
        data_source: &data_source::Model,
    ) -> Result<usize, ExecutorError> {
        use sea_orm::Database;

        // Build connection string
        let connection_string = match data_source.db_type.as_str() {
            "mysql" | "MySQL" => self.build_mysql_connection_string(&data_source.connection_config)?,
            "postgresql" | "PostgreSQL" => self.build_postgresql_connection_string(&data_source.connection_config)?,
            _ => return Err(ExecutorError::ExecutionFailed(
                format!("Unsupported database type: {}", data_source.db_type)
            )),
        };

        // Connect to database
        let db = Database::connect(&connection_string)
            .await
            .map_err(|_| ExecutorError::ConnectionFailed)?;

        let mut total_rows = 0;

        for sheet in sheets {
            // Create or update table
            self.create_table(&db, &sheet, &data_source.db_type).await?;

            // Insert data
            let rows_inserted = self.insert_data(&db, &sheet, &data_source.db_type).await?;
            total_rows += rows_inserted;
        }

        // Close connection
        db.close().await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to close connection: {}", e)))?;

        Ok(total_rows)
    }

    /// Create table for sheet data
    async fn create_table(
        &self,
        db: &sea_orm::DatabaseConnection,
        sheet: &SheetData,
        db_type: &str,
    ) -> Result<(), ExecutorError> {
        use sea_orm::{Statement, ConnectionTrait};

        // Sanitize table name
        let table_name = sheet.name.replace(" ", "_").to_lowercase();

        // Build CREATE TABLE statement
        let columns: Vec<String> = sheet.headers.iter()
            .map(|h| {
                let col_name = h.replace(" ", "_").to_lowercase();
                format!("`{}` TEXT", col_name)
            })
            .collect();

        let create_sql = format!(
            "CREATE TABLE IF NOT EXISTS `{}` (id INT AUTO_INCREMENT PRIMARY KEY, {})",
            table_name,
            columns.join(", ")
        );

        let backend = match db_type {
            "mysql" | "MySQL" => sea_orm::DatabaseBackend::MySql,
            "postgresql" | "PostgreSQL" => sea_orm::DatabaseBackend::Postgres,
            _ => return Err(ExecutorError::ExecutionFailed("Unsupported database type".to_string())),
        };

        db.execute(Statement::from_string(backend, create_sql))
            .await
            .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to create table: {}", e)))?;

        Ok(())
    }

    /// Insert data rows into table
    async fn insert_data(
        &self,
        db: &sea_orm::DatabaseConnection,
        sheet: &SheetData,
        db_type: &str,
    ) -> Result<usize, ExecutorError> {
        use sea_orm::{Statement, ConnectionTrait};

        if sheet.rows.is_empty() {
            return Ok(0);
        }

        let table_name = sheet.name.replace(" ", "_").to_lowercase();
        let column_names: Vec<String> = sheet.headers.iter()
            .map(|h| format!("`{}`", h.replace(" ", "_").to_lowercase()))
            .collect();

        let backend = match db_type {
            "mysql" | "MySQL" => sea_orm::DatabaseBackend::MySql,
            "postgresql" | "PostgreSQL" => sea_orm::DatabaseBackend::Postgres,
            _ => return Err(ExecutorError::ExecutionFailed("Unsupported database type".to_string())),
        };

        let mut total_inserted = 0;

        // Insert in batches of 100 rows
        for chunk in sheet.rows.chunks(100) {
            let values: Vec<String> = chunk.iter()
                .map(|row| {
                    let escaped_values: Vec<String> = row.iter()
                        .map(|v| format!("'{}'", v.replace("'", "''")))
                        .collect();
                    format!("({})", escaped_values.join(", "))
                })
                .collect();

            let insert_sql = format!(
                "INSERT INTO `{}` ({}) VALUES {}",
                table_name,
                column_names.join(", "),
                values.join(", ")
            );

            let result = db.execute(Statement::from_string(backend, insert_sql))
                .await
                .map_err(|e| ExecutorError::ExecutionFailed(format!("Failed to insert data: {}", e)))?;

            total_inserted += result.rows_affected() as usize;
        }

        Ok(total_inserted)
    }

    /// Build MySQL connection string (reused from SqlExecutor logic)
    fn build_mysql_connection_string(
        &self,
        config: &serde_json::Value,
    ) -> Result<String, ExecutorError> {
        let host = config.get("host")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'host' in connection config".to_string()))?;

        let port = config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(3306);

        let database = config.get("database")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'database' in connection config".to_string()))?;

        let username = config.get("username")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'username' in connection config".to_string()))?;

        let password = config.get("password")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        Ok(format!(
            "mysql://{}:{}@{}:{}/{}",
            username, password, host, port, database
        ))
    }

    /// Build PostgreSQL connection string (reused from SqlExecutor logic)
    fn build_postgresql_connection_string(
        &self,
        config: &serde_json::Value,
    ) -> Result<String, ExecutorError> {
        let host = config.get("host")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'host' in connection config".to_string()))?;

        let port = config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(5432);

        let database = config.get("database")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'database' in connection config".to_string()))?;

        let username = config.get("username")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ExecutorError::ExecutionFailed("Missing 'username' in connection config".to_string()))?;

        let password = config.get("password")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        Ok(format!(
            "postgresql://{}:{}@{}:{}/{}",
            username, password, host, port, database
        ))
    }
}

// Helper struct for sheet data
#[derive(Debug, Clone)]
struct SheetData {
    name: String,
    headers: Vec<String>,
    rows: Vec<Vec<String>>,
}
