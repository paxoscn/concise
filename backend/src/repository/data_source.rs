use sea_orm::*;
use crate::entities::data_source::{self, Entity as DataSource};

pub struct DataSourceRepository {
    db: DatabaseConnection,
}

impl DataSourceRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: data_source::ActiveModel) -> Result<data_source::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<data_source::Model>, DbErr> {
        DataSource::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_all(&self) -> Result<Vec<data_source::Model>, DbErr> {
        DataSource::find().all(&self.db).await
    }

    pub async fn update(&self, model: data_source::ActiveModel) -> Result<data_source::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        DataSource::delete_by_id(id.to_string()).exec(&self.db).await
    }
}
