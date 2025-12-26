use sea_orm::*;
use crate::entities::data_table_column::{self, Entity as DataTableColumn};

pub struct DataTableColumnRepository {
    db: DatabaseConnection,
}

impl DataTableColumnRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: data_table_column::ActiveModel) -> Result<data_table_column::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<data_table_column::Model>, DbErr> {
        DataTableColumn::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_by_table(&self, data_table_id: &str) -> Result<Vec<data_table_column::Model>, DbErr> {
        DataTableColumn::find()
            .filter(data_table_column::Column::DataTableId.eq(data_table_id))
            .order_by_asc(data_table_column::Column::ColumnIndex)
            .all(&self.db)
            .await
    }

    pub async fn update(&self, model: data_table_column::ActiveModel) -> Result<data_table_column::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        DataTableColumn::delete_by_id(id.to_string()).exec(&self.db).await
    }

    pub async fn delete_by_table(&self, data_table_id: &str) -> Result<DeleteResult, DbErr> {
        DataTableColumn::delete_many()
            .filter(data_table_column::Column::DataTableId.eq(data_table_id))
            .exec(&self.db)
            .await
    }

    pub async fn batch_create(&self, models: Vec<data_table_column::ActiveModel>) -> Result<(), DbErr> {
        if models.is_empty() {
            return Ok(());
        }
        DataTableColumn::insert_many(models).exec(&self.db).await?;
        Ok(())
    }
}
