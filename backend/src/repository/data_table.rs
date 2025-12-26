use sea_orm::*;
use crate::entities::data_table::{self, Entity as DataTable};

pub struct DataTableRepository {
    db: DatabaseConnection,
}

impl DataTableRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: data_table::ActiveModel) -> Result<data_table::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<data_table::Model>, DbErr> {
        DataTable::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_all(&self) -> Result<Vec<data_table::Model>, DbErr> {
        DataTable::find().all(&self.db).await
    }

    pub async fn update(&self, model: data_table::ActiveModel) -> Result<data_table::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        DataTable::delete_by_id(id.to_string()).exec(&self.db).await
    }

    pub async fn find_by_tenant(&self, tenant_id: &str) -> Result<Vec<data_table::Model>, DbErr> {
        DataTable::find()
            .filter(data_table::Column::TenantId.eq(tenant_id))
            .all(&self.db)
            .await
    }

    pub async fn find_by_data_source(
        &self,
        tenant_id: &str,
        data_source_id: &str,
    ) -> Result<Vec<data_table::Model>, DbErr> {
        DataTable::find()
            .filter(data_table::Column::TenantId.eq(tenant_id))
            .filter(data_table::Column::DataSourceId.eq(data_source_id))
            .all(&self.db)
            .await
    }

    pub async fn find_by_name(
        &self,
        tenant_id: &str,
        data_source_id: &str,
        name: &str,
    ) -> Result<Option<data_table::Model>, DbErr> {
        DataTable::find()
            .filter(data_table::Column::TenantId.eq(tenant_id))
            .filter(data_table::Column::DataSourceId.eq(data_source_id))
            .filter(data_table::Column::Name.eq(name))
            .one(&self.db)
            .await
    }
}
