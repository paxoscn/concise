use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Storages::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(Storages::Id)
                            .string_len(36)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(Storages::Name)
                            .string_len(100)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Storages::StorageType)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Storages::UploadEndpoint)
                            .string_len(255)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Storages::DownloadEndpoint)
                            .string_len(255)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Storages::AuthConfig)
                            .json()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(Storages::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(Storages::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(Storages::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum Storages {
    Table,
    Id,
    Name,
    StorageType,
    UploadEndpoint,
    DownloadEndpoint,
    AuthConfig,
    CreatedAt,
    UpdatedAt,
}
