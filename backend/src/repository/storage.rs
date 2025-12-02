use sea_orm::*;
use crate::entities::storage::{self, Entity as Storage};

pub struct StorageRepository {
    db: DatabaseConnection,
}

impl StorageRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: storage::ActiveModel) -> Result<storage::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<storage::Model>, DbErr> {
        Storage::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_all(&self) -> Result<Vec<storage::Model>, DbErr> {
        Storage::find().all(&self.db).await
    }

    pub async fn update(&self, model: storage::ActiveModel) -> Result<storage::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        Storage::delete_by_id(id.to_string()).exec(&self.db).await
    }

    pub async fn find_by_tenant(&self, tenant_id: &str) -> Result<Vec<storage::Model>, DbErr> {
        Storage::find()
            .filter(storage::Column::TenantId.eq(tenant_id))
            .all(&self.db)
            .await
    }
}
