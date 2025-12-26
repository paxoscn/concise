use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::data_table_column;
use crate::repository::DataTableColumnRepository;
use super::error::ServiceError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateDataTableColumnRequest {
    pub data_table_id: String,
    pub column_index: i32,
    pub name: String,
    pub desc: Option<String>,
    pub data_type: String,
    #[serde(default = "default_true")]
    pub nullable: bool,
    pub default_value: Option<String>,
    #[serde(default)]
    pub partitioner: bool,
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateDataTableColumnRequest {
    pub name: Option<String>,
    pub desc: Option<String>,
    pub data_type: Option<String>,
    pub nullable: Option<bool>,
    pub default_value: Option<String>,
    pub partitioner: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchCreateColumnsRequest {
    pub data_table_id: String,
    pub columns: Vec<ColumnInfo>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColumnInfo {
    pub column_index: i32,
    pub name: String,
    pub desc: Option<String>,
    pub data_type: String,
    #[serde(default = "default_true")]
    pub nullable: bool,
    pub default_value: Option<String>,
    #[serde(default)]
    pub partitioner: bool,
}

pub struct DataTableColumnService {
    repo: Arc<DataTableColumnRepository>,
}

impl DataTableColumnService {
    pub fn new(repo: Arc<DataTableColumnRepository>) -> Self {
        Self { repo }
    }

    pub async fn create(&self, req: CreateDataTableColumnRequest) -> Result<data_table_column::Model, ServiceError> {
        if req.name.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Name cannot be empty".to_string()));
        }
        if req.data_type.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Data type cannot be empty".to_string()));
        }

        let now = Utc::now().naive_utc();
        let id = format!("{}-{}", req.data_table_id, uuid::Uuid::new_v4().to_string());

        let model = data_table_column::ActiveModel {
            id: Set(id),
            data_table_id: Set(req.data_table_id),
            column_index: Set(req.column_index),
            name: Set(req.name),
            desc: Set(req.desc),
            data_type: Set(req.data_type),
            nullable: Set(req.nullable),
            default_value: Set(req.default_value),
            partitioner: Set(req.partitioner),
            created_at: Set(now),
            updated_at: Set(now),
        };

        self.repo.create(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to create column".to_string()))
    }

    pub async fn batch_create(&self, req: BatchCreateColumnsRequest) -> Result<(), ServiceError> {
        if req.columns.is_empty() {
            return Ok(());
        }

        let now = Utc::now().naive_utc();
        let models: Vec<data_table_column::ActiveModel> = req.columns
            .into_iter()
            .map(|col| {
                let id = format!("{}-{}", req.data_table_id, uuid::Uuid::new_v4().to_string());
                data_table_column::ActiveModel {
                    id: Set(id),
                    data_table_id: Set(req.data_table_id.clone()),
                    column_index: Set(col.column_index),
                    name: Set(col.name),
                    desc: Set(col.desc),
                    data_type: Set(col.data_type),
                    nullable: Set(col.nullable),
                    default_value: Set(col.default_value),
                    partitioner: Set(col.partitioner),
                    created_at: Set(now),
                    updated_at: Set(now),
                }
            })
            .collect();

        self.repo.batch_create(models).await
            .map_err(|_| ServiceError::InvalidInput("Failed to batch create columns".to_string()))
    }

    pub async fn list_by_table(&self, data_table_id: &str) -> Result<Vec<data_table_column::Model>, ServiceError> {
        self.repo.find_by_table(data_table_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to list columns".to_string()))
    }

    pub async fn get(&self, id: String) -> Result<data_table_column::Model, ServiceError> {
        self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get column".to_string()))?
            .ok_or(ServiceError::NotFound)
    }

    pub async fn update(&self, id: String, req: UpdateDataTableColumnRequest) -> Result<data_table_column::Model, ServiceError> {
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find column".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        let now = Utc::now().naive_utc();

        let model = data_table_column::ActiveModel {
            id: Set(existing.id),
            data_table_id: Set(existing.data_table_id),
            column_index: Set(existing.column_index),
            name: Set(req.name.unwrap_or(existing.name)),
            desc: Set(req.desc.or(existing.desc)),
            data_type: Set(req.data_type.unwrap_or(existing.data_type)),
            nullable: Set(req.nullable.unwrap_or(existing.nullable)),
            default_value: Set(req.default_value.or(existing.default_value)),
            partitioner: Set(req.partitioner.unwrap_or(existing.partitioner)),
            created_at: Set(existing.created_at),
            updated_at: Set(now),
        };

        self.repo.update(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to update column".to_string()))
    }

    pub async fn delete(&self, id: String) -> Result<(), ServiceError> {
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find column".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        self.repo.delete(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete column".to_string()))?;

        Ok(())
    }
}
