use sea_orm::*;
use crate::entities::view::{self, Entity as View};

pub struct ViewRepository {
    db: DatabaseConnection,
}

impl ViewRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn find_by_code_and_tenant(
        &self,
        view_code: &str,
        tenant_id: &str,
    ) -> Result<Option<view::Model>, DbErr> {
        View::find()
            .filter(view::Column::ViewCode.eq(view_code))
            .filter(view::Column::TenantId.eq(tenant_id))
            .one(&self.db)
            .await
    }

    pub async fn find_by_tenant(&self, tenant_id: &str) -> Result<Vec<view::Model>, DbErr> {
        View::find()
            .filter(view::Column::TenantId.eq(tenant_id))
            .all(&self.db)
            .await
    }
}
