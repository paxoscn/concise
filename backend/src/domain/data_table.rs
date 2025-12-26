use std::sync::Arc;
use sea_orm::*;
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::entities::{data_table, data_table_column, data_table_usage};
use crate::repository::{
    DataTableRepository, DataTableColumnRepository, DataTableUsageRepository,
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
}

impl DataTableService {
    pub fn new(
        table_repo: Arc<DataTableRepository>,
        column_repo: Arc<DataTableColumnRepository>,
        usage_repo: Arc<DataTableUsageRepository>,
    ) -> Self {
        Self {
            table_repo,
            column_repo,
            usage_repo,
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
}
