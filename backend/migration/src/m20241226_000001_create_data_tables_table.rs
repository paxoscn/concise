use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(DataTables::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(DataTables::Id)
                            .string_len(72)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(DataTables::TenantId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTables::DataSourceId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTables::Name)
                            .string_len(200)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTables::Desc)
                            .text()
                            .null(),
                    )
                    .col(
                        ColumnDef::new(DataTables::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(DataTables::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await?;

        // 创建索引：tenant_id + data_source_id
        manager
            .create_index(
                Index::create()
                    .name("idx_data_tables_tenant_datasource")
                    .table(DataTables::Table)
                    .col(DataTables::TenantId)
                    .col(DataTables::DataSourceId)
                    .to_owned(),
            )
            .await?;

        // 创建唯一索引：tenant_id + data_source_id + name
        manager
            .create_index(
                Index::create()
                    .name("idx_data_tables_tenant_datasource_name")
                    .table(DataTables::Table)
                    .col(DataTables::TenantId)
                    .col(DataTables::DataSourceId)
                    .col(DataTables::Name)
                    .unique()
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(DataTables::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum DataTables {
    Table,
    Id,
    TenantId,
    DataSourceId,
    Name,
    Desc,
    CreatedAt,
    UpdatedAt,
}
