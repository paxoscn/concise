use std::sync::Arc;
use std::collections::HashMap;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use calamine::{Reader, open_workbook_from_rs, Xlsx};
use std::io::Cursor;
use crate::entities::{data_table, data_table_column, data_table_usage};
use crate::repository::{
    DataTableRepository, DataTableColumnRepository, DataTableUsageRepository, DataSourceRepository,
};
use super::error::ServiceError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateDataTableRequest {
    pub data_source_id: String,
    pub name: String,
    pub desc: Option<String>,
    #[serde(skip_deserializing)]
    pub tenant_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateDataTableRequest {
    pub name: Option<String>,
    pub desc: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataTableWithDetails {
    #[serde(flatten)]
    pub table: data_table::Model,
    pub columns: Vec<data_table_column::Model>,
    pub usage: Option<data_table_usage::Model>,
}

pub struct DataTableService {
    table_repo: Arc<DataTableRepository>,
    column_repo: Arc<DataTableColumnRepository>,
    usage_repo: Arc<DataTableUsageRepository>,
    data_source_repo: Arc<DataSourceRepository>,
}

impl DataTableService {
    pub fn new(
        table_repo: Arc<DataTableRepository>,
        column_repo: Arc<DataTableColumnRepository>,
        usage_repo: Arc<DataTableUsageRepository>,
        data_source_repo: Arc<DataSourceRepository>,
    ) -> Self {
        Self {
            table_repo,
            column_repo,
            usage_repo,
            data_source_repo,
        }
    }

    pub async fn create(&self, req: CreateDataTableRequest) -> Result<data_table::Model, ServiceError> {
        if req.name.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Name cannot be empty".to_string()));
        }
        if req.data_source_id.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Data source ID cannot be empty".to_string()));
        }

        let tenant_id = req.tenant_id.ok_or(ServiceError::InvalidInput("Tenant ID is required".to_string()))?;

        // Check if table with same name already exists
        if let Some(_) = self.table_repo
            .find_by_name(&tenant_id, &req.data_source_id, &req.name)
            .await
            .map_err(|_| ServiceError::InvalidInput("Failed to check existing table".to_string()))?
        {
            return Err(ServiceError::AlreadyExists);
        }

        let now = Utc::now().naive_utc();
        let id = format!("{}-{}", tenant_id, uuid::Uuid::new_v4().to_string());

        let model = data_table::ActiveModel {
            id: Set(id),
            tenant_id: Set(tenant_id),
            data_source_id: Set(req.data_source_id),
            name: Set(req.name),
            desc: Set(req.desc),
            created_at: Set(now),
            updated_at: Set(now),
        };

        self.table_repo.create(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to create data table".to_string()))
    }

    pub async fn list_by_tenant(&self, tenant_id: &str) -> Result<Vec<data_table::Model>, ServiceError> {
        self.table_repo.find_by_tenant(tenant_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to list data tables".to_string()))
    }

    pub async fn list_by_data_source(
        &self,
        tenant_id: &str,
        data_source_id: &str,
    ) -> Result<Vec<data_table::Model>, ServiceError> {
        self.table_repo.find_by_data_source(tenant_id, data_source_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to list data tables".to_string()))
    }

    pub async fn get(&self, id: String) -> Result<data_table::Model, ServiceError> {
        self.table_repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get data table".to_string()))?
            .ok_or(ServiceError::NotFound)
    }

    pub async fn get_with_details(&self, id: String) -> Result<DataTableWithDetails, ServiceError> {
        let table = self.get(id.clone()).await?;
        
        let columns = self.column_repo.find_by_table(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get columns".to_string()))?;
        
        let usage = self.usage_repo.find_by_table(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get usage".to_string()))?;

        Ok(DataTableWithDetails {
            table,
            columns,
            usage,
        })
    }

    pub async fn update(&self, id: String, req: UpdateDataTableRequest) -> Result<data_table::Model, ServiceError> {
        let existing = self.table_repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data table".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        let now = Utc::now().naive_utc();

        let model = data_table::ActiveModel {
            id: Set(existing.id),
            tenant_id: Set(existing.tenant_id),
            data_source_id: Set(existing.data_source_id),
            name: Set(req.name.unwrap_or(existing.name)),
            desc: Set(req.desc.or(existing.desc)),
            created_at: Set(existing.created_at),
            updated_at: Set(now),
        };

        self.table_repo.update(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to update data table".to_string()))
    }

    pub async fn delete(&self, id: String) -> Result<(), ServiceError> {
        let existing = self.table_repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data table".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        // Delete related columns and usage
        self.column_repo.delete_by_table(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete columns".to_string()))?;
        
        self.usage_repo.delete_by_table(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete usage".to_string()))?;

        self.table_repo.delete(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete data table".to_string()))?;

        Ok(())
    }

    pub async fn upload_data(
        &self,
        table_id: String,
        file_data: Vec<u8>,
        partition_values: HashMap<String, String>,
    ) -> Result<usize, ServiceError> {
        // 1. 获取数据表信息
        let table = self.table_repo.find_by_id(&table_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data table".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        // 2. 获取数据表的列定义
        let columns = self.column_repo.find_by_table(&table_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get columns".to_string()))?;

        if columns.is_empty() {
            return Err(ServiceError::InvalidInput("Data table has no columns defined".to_string()));
        }

        // 3. 验证分区字段
        let partition_columns: Vec<_> = columns.iter()
            .filter(|c| c.partitioner)
            .collect();

        for partition_col in &partition_columns {
            if !partition_values.contains_key(&partition_col.name) {
                return Err(ServiceError::InvalidInput(
                    format!("Missing partition value for column: {}", partition_col.name)
                ));
            }
        }

        // 4. 解析 Excel 文件
        let cursor = Cursor::new(file_data);
        let mut workbook: Xlsx<_> = open_workbook_from_rs(cursor)
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to open Excel file: {}", e)))?;

        // 获取第一个工作表
        let sheet_name = workbook.sheet_names().first()
            .ok_or(ServiceError::InvalidInput("Excel file has no sheets".to_string()))?
            .clone();

        let range = workbook.worksheet_range(&sheet_name)
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to read sheet: {}", e)))?;

        // 5. 解析表头和数据
        let mut rows = range.rows();
        let header_row = rows.next()
            .ok_or(ServiceError::InvalidInput("Excel file is empty".to_string()))?;

        // 创建列名到索引的映射
        let mut column_map: HashMap<String, usize> = HashMap::new();
        for (idx, cell) in header_row.iter().enumerate() {
            let col_name = cell.to_string().trim().to_string();
            column_map.insert(col_name, idx);
        }

        // 验证所有非分区列都在 Excel 中
        let non_partition_columns: Vec<_> = columns.iter()
            .filter(|c| !c.partitioner)
            .collect();

        for col in &non_partition_columns {
            if !column_map.contains_key(&col.name) {
                return Err(ServiceError::InvalidInput(
                    format!("Column '{}' not found in Excel file", col.name)
                ));
            }
        }

        // 6. 获取数据源连接
        let data_source = self.data_source_repo.find_by_id(&table.data_source_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find data source".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        // 解析连接配置
        let connection_config = data_source.connection_config.as_object()
            .ok_or(ServiceError::InvalidInput("Invalid connection config".to_string()))?;

        let host = connection_config.get("host")
            .and_then(|v| v.as_str())
            .ok_or(ServiceError::InvalidInput("Missing host in connection config".to_string()))?;
        let port = connection_config.get("port")
            .and_then(|v| v.as_u64())
            .unwrap_or(5432);
        let database = connection_config.get("database")
            .and_then(|v| v.as_str())
            .ok_or(ServiceError::InvalidInput("Missing database in connection config".to_string()))?;
        let username = connection_config.get("username")
            .and_then(|v| v.as_str())
            .ok_or(ServiceError::InvalidInput("Missing username in connection config".to_string()))?;
        let password = connection_config.get("password")
            .and_then(|v| v.as_str())
            .ok_or(ServiceError::InvalidInput("Missing password in connection config".to_string()))?;

        // 构建连接字符串
        let connection_string = format!(
            "postgres://{}:{}@{}:{}/{}",
            username, password, host, port, database
        );

        // 连接到目标数据库
        let target_db = Database::connect(&connection_string).await
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to connect to target database: {}", e)))?;

        // 7. 删除指定分区的现有数据
        let mut delete_conditions = Vec::new();
        for partition_col in &partition_columns {
            if let Some(value) = partition_values.get(&partition_col.name) {
                delete_conditions.push(format!("{} = '{}'", partition_col.name, value));
            }
        }

        let delete_sql = if delete_conditions.is_empty() {
            format!("DELETE FROM {}", table.name)
        } else {
            format!("DELETE FROM {} WHERE {}", table.name, delete_conditions.join(" AND "))
        };

        target_db.execute(Statement::from_string(
            DatabaseBackend::Postgres,
            delete_sql,
        )).await
            .map_err(|e| ServiceError::InvalidInput(format!("Failed to delete existing data: {}", e)))?;

        // 8. 插入新数据
        let mut rows_inserted = 0;
        
        for data_row in rows {
            let mut values = Vec::new();
            let mut col_names = Vec::new();

            // 添加非分区列的值
            for col in &non_partition_columns {
                col_names.push(col.name.clone());
                
                if let Some(&idx) = column_map.get(&col.name) {
                    if idx < data_row.len() {
                        let cell_value = &data_row[idx];
                        let value_str = self.convert_cell_value(cell_value, &col.data_type)?;
                        values.push(value_str);
                    } else {
                        values.push("NULL".to_string());
                    }
                } else {
                    values.push("NULL".to_string());
                }
            }

            // 添加分区列的值
            for partition_col in &partition_columns {
                col_names.push(partition_col.name.clone());
                if let Some(value) = partition_values.get(&partition_col.name) {
                    values.push(format!("'{}'", value));
                }
            }

            // 构建插入语句
            let insert_sql = format!(
                "INSERT INTO {} ({}) VALUES ({})",
                table.name,
                col_names.join(", "),
                values.join(", ")
            );

            target_db.execute(Statement::from_string(
                DatabaseBackend::Postgres,
                insert_sql,
            )).await
                .map_err(|e| ServiceError::InvalidInput(format!("Failed to insert data: {}", e)))?;

            rows_inserted += 1;
        }

        Ok(rows_inserted)
    }

    // 辅助函数：转换单元格值为 SQL 值
    fn convert_cell_value(&self, cell: &calamine::Data, data_type: &str) -> Result<String, ServiceError> {
        use calamine::Data;

        match cell {
            Data::Empty => Ok("NULL".to_string()),
            Data::String(s) => Ok(format!("'{}'", s.replace("'", "''"))),
            Data::Float(f) => {
                if data_type.to_lowercase().contains("int") {
                    Ok(format!("{}", *f as i64))
                } else {
                    Ok(format!("{}", f))
                }
            },
            Data::Int(i) => Ok(format!("{}", i)),
            Data::Bool(b) => Ok(format!("{}", b)),
            Data::DateTime(dt) => {
                // Excel 日期时间转换
                Ok(format!("'{}'", dt))
            },
            Data::Error(e) => Err(ServiceError::InvalidInput(
                format!("Cell contains error: {:?}", e)
            )),
            Data::DateTimeIso(dt) => Ok(format!("'{}'", dt)),
            Data::DurationIso(d) => Ok(format!("'{}'", d)),
        }
    }
}
