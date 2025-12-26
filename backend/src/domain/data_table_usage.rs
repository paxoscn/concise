use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::data_table_usage;
use crate::repository::DataTableUsageRepository;
use super::error::ServiceError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpsertDataTableUsageRequest {
    pub data_table_id: String,
    pub row_count: i64,
    pub partition_count: i32,
    pub storage_size: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateDataTableUsageRequest {
    pub row_count: Option<i64>,
    pub partition_count: Option<i32>,
    pub storage_size: Option<i64>,
}

pub struct DataTableUsageService {
    repo: Arc<DataTableUsageRepository>,
}

impl DataTableUsageService {
    pub fn new(repo: Arc<DataTableUsageRepository>) -> Self {
        Self { repo }
    }

    pub async fn upsert(&self, req: UpsertDataTableUsageRequest) -> Result<data_table_usage::Model, ServiceError> {
        let now = Utc::now().naive_utc();
        let id = format!("{}-usage", req.data_table_id);

        let model = data_table_usage::ActiveModel {
            id: Set(id),
            data_table_id: Set(req.data_table_id),
            row_count: Set(req.row_count),
            partition_count: Set(req.partition_count),
            storage_size: Set(req.storage_size),
            created_at: Set(now),
            updated_at: Set(now),
        };

        self.repo.upsert(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to upsert usage".to_string()))
    }

    pub async fn get_by_table(&self, data_table_id: &str) -> Result<Option<data_table_usage::Model>, ServiceError> {
        self.repo.find_by_table(data_table_id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get usage".to_string()))
    }

    pub async fn get(&self, id: String) -> Result<data_table_usage::Model, ServiceError> {
        self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get usage".to_string()))?
            .ok_or(ServiceError::NotFound)
    }

    pub async fn update(&self, id: String, req: UpdateDataTableUsageRequest) -> Result<data_table_usage::Model, ServiceError> {
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find usage".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        let now = Utc::now().naive_utc();

        let model = data_table_usage::ActiveModel {
            id: Set(existing.id),
            data_table_id: Set(existing.data_table_id),
            row_count: Set(req.row_count.unwrap_or(existing.row_count)),
            partition_count: Set(req.partition_count.unwrap_or(existing.partition_count)),
            storage_size: Set(req.storage_size.unwrap_or(existing.storage_size)),
            created_at: Set(existing.created_at),
            updated_at: Set(now),
        };

        self.repo.update(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to update usage".to_string()))
    }

    pub async fn delete(&self, id: String) -> Result<(), ServiceError> {
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find usage".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        self.repo.delete(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete usage".to_string()))?;

        Ok(())
    }
}
