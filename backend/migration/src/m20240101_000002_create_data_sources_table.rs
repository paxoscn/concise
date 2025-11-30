use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(DataSources::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(DataSources::Id)
                            .string_len(36)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(DataSources::Name)
                            .string_len(100)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataSources::DbType)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataSources::ConnectionConfig)
                            .json()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataSources::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(DataSources::UpdatedAt)
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
            .drop_table(Table::drop().table(DataSources::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum DataSources {
    Table,
    Id,
    Name,
    DbType,
    ConnectionConfig,
    CreatedAt,
    UpdatedAt,
}
