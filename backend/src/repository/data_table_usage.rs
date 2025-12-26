use sea_orm::*;
use crate::entities::data_table_usage::{self, Entity as DataTableUsage};

pub struct DataTableUsageRepository {
    db: DatabaseConnection,
}

impl DataTableUsageRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: data_table_usage::ActiveModel) -> Result<data_table_usage::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<data_table_usage::Model>, DbErr> {
        DataTableUsage::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_by_table(&self, data_table_id: &str) -> Result<Option<data_table_usage::Model>, DbErr> {
        DataTableUsage::find()
            .filter(data_table_usage::Column::DataTableId.eq(data_table_id))
            .one(&self.db)
            .await
    }

    pub async fn update(&self, model: data_table_usage::ActiveModel) -> Result<data_table_usage::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        DataTableUsage::delete_by_id(id.to_string()).exec(&self.db).await
    }

    pub async fn delete_by_table(&self, data_table_id: &str) -> Result<DeleteResult, DbErr> {
        DataTableUsage::delete_many()
            .filter(data_table_usage::Column::DataTableId.eq(data_table_id))
            .exec(&self.db)
            .await
    }

    pub async fn upsert(&self, model: data_table_usage::ActiveModel) -> Result<data_table_usage::Model, DbErr> {
        // Try to find existing record
        let data_table_id = match &model.data_table_id {
            Set(id) => id.clone(),
            _ => return Err(DbErr::Custom("data_table_id is required".to_string())),
        };

        if let Some(existing) = self.find_by_table(&data_table_id).await? {
            // Update existing record
            let mut update_model = model;
            update_model.id = Set(existing.id);
            update_model.update(&self.db).await
        } else {
            // Insert new record
            model.insert(&self.db).await
        }
    }
}
