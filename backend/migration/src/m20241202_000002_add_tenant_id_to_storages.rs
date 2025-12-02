use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .alter_table(
                Table::alter()
                    .table(Storages::Table)
                    .add_column(
                        ColumnDef::new(Storages::TenantId)
                            .string_len(36)
                            .not_null()
                            .default(""),
                    )
                    .to_owned(),
            )
            .await?;

        // 创建索引以提高查询性能
        manager
            .create_index(
                Index::create()
                    .name("idx_storages_tenant_id")
                    .table(Storages::Table)
                    .col(Storages::TenantId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_index(
                Index::drop()
                    .name("idx_storages_tenant_id")
                    .table(Storages::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(Storages::Table)
                    .drop_column(Storages::TenantId)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum Storages {
    Table,
    TenantId,
}
