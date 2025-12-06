use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Views::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(Views::Id)
                            .string_len(72)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(Views::TenantId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Views::ViewCode)
                            .string_len(100)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Views::ViewType)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Views::ViewSql)
                            .text()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Views::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(Views::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await?;

        // 创建唯一索引：tenant_id + view_code
        manager
            .create_index(
                Index::create()
                    .name("idx_views_tenant_view_code")
                    .table(Views::Table)
                    .col(Views::TenantId)
                    .col(Views::ViewCode)
                    .unique()
                    .to_owned(),
            )
            .await?;

        // 创建索引：tenant_id + view_type
        manager
            .create_index(
                Index::create()
                    .name("idx_views_tenant_view_type")
                    .table(Views::Table)
                    .col(Views::TenantId)
                    .col(Views::ViewType)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(Views::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum Views {
    Table,
    Id,
    TenantId,
    ViewCode,
    ViewType,
    ViewSql,
    CreatedAt,
    UpdatedAt,
}
