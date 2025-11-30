use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::storage;
use crate::repository::storage::StorageRepository;
use super::error::ServiceError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateStorageRequest {
    pub name: String,
    pub storage_type: String,
    pub upload_endpoint: String,
    pub download_endpoint: String,
    pub auth_config: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateStorageRequest {
    pub name: Option<String>,
    pub storage_type: Option<String>,
    pub upload_endpoint: Option<String>,
    pub download_endpoint: Option<String>,
    pub auth_config: Option<serde_json::Value>,
}

pub struct StorageService {
    repo: Arc<StorageRepository>,
}

impl StorageService {
    pub fn new(repo: Arc<StorageRepository>) -> Self {
        Self { repo }
    }

    pub async fn create(&self, req: CreateStorageRequest) -> Result<storage::Model, ServiceError> {
        // Validate input
        if req.name.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Name cannot be empty".to_string()));
        }
        if req.storage_type.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Storage type cannot be empty".to_string()));
        }
        if req.upload_endpoint.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Upload endpoint cannot be empty".to_string()));
        }
        if req.download_endpoint.trim().is_empty() {
            return Err(ServiceError::InvalidInput("Download endpoint cannot be empty".to_string()));
        }

        let now = Utc::now().naive_utc();
        let id = uuid::Uuid::new_v4().to_string();

        let model = storage::ActiveModel {
            id: Set(id),
            name: Set(req.name),
            storage_type: Set(req.storage_type),
            upload_endpoint: Set(req.upload_endpoint),
            download_endpoint: Set(req.download_endpoint),
            auth_config: Set(req.auth_config),
            created_at: Set(now),
            updated_at: Set(now),
        };

        self.repo.create(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to create storage".to_string()))
    }

    pub async fn list(&self) -> Result<Vec<storage::Model>, ServiceError> {
        self.repo.find_all().await
            .map_err(|_| ServiceError::InvalidInput("Failed to list storages".to_string()))
    }

    pub async fn get(&self, id: String) -> Result<storage::Model, ServiceError> {
        self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to get storage".to_string()))?
            .ok_or(ServiceError::NotFound)
    }

    pub async fn update(&self, id: String, req: UpdateStorageRequest) -> Result<storage::Model, ServiceError> {
        // First check if the storage exists
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find storage".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        let now = Utc::now().naive_utc();

        let model = storage::ActiveModel {
            id: Set(existing.id),
            name: Set(req.name.unwrap_or(existing.name)),
            storage_type: Set(req.storage_type.unwrap_or(existing.storage_type)),
            upload_endpoint: Set(req.upload_endpoint.unwrap_or(existing.upload_endpoint)),
            download_endpoint: Set(req.download_endpoint.unwrap_or(existing.download_endpoint)),
            auth_config: Set(req.auth_config.unwrap_or(existing.auth_config)),
            created_at: Set(existing.created_at),
            updated_at: Set(now),
        };

        self.repo.update(model).await
            .map_err(|_| ServiceError::InvalidInput("Failed to update storage".to_string()))
    }

    pub async fn delete(&self, id: String) -> Result<(), ServiceError> {
        // First check if the storage exists
        let existing = self.repo.find_by_id(&id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to find storage".to_string()))?
            .ok_or(ServiceError::NotFound)?;

        self.repo.delete(&existing.id).await
            .map_err(|_| ServiceError::InvalidInput("Failed to delete storage".to_string()))?;

        Ok(())
    }
}
