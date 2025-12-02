use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .alter_table(
                Table::alter()
                    .table(DataSources::Table)
                    .add_column(
                        ColumnDef::new(DataSources::TenantId)
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
                    .name("idx_data_sources_tenant_id")
                    .table(DataSources::Table)
                    .col(DataSources::TenantId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_index(
                Index::drop()
                    .name("idx_data_sources_tenant_id")
                    .table(DataSources::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(DataSources::Table)
                    .drop_column(DataSources::TenantId)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum DataSources {
    Table,
    TenantId,
}
