use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::data_source;
use crate::repository::data_source::DataSourceRepository;
use super::error::ServiceError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateDataSourceRequest {
    pub name: String,
    pub db_type: String,
    pub connection_config: serde_json::Value,
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

        let now = Utc::now().naive_utc();
        let id = uuid::Uuid::new_v4().to_string();

        let model = data_source::ActiveModel {
            id: Set(id),
            name: Set(req.name),
            db_type: Set(req.db_type),
            connection_config: Set(req.connection_config),
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
}
