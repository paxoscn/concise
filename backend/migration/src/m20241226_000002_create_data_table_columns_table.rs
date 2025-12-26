use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(DataTableColumns::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(DataTableColumns::Id)
                            .string_len(72)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::DataTableId)
                            .string_len(72)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::ColumnIndex)
                            .integer()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::Name)
                            .string_len(200)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::Desc)
                            .text()
                            .null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::DataType)
                            .string_len(100)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::Nullable)
                            .boolean()
                            .not_null()
                            .default(true),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::DefaultValue)
                            .text()
                            .null(),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::Partitioner)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(DataTableColumns::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await?;

        // 创建索引：data_table_id
        manager
            .create_index(
                Index::create()
                    .name("idx_data_table_columns_table_id")
                    .table(DataTableColumns::Table)
                    .col(DataTableColumns::DataTableId)
                    .to_owned(),
            )
            .await?;

        // 创建唯一索引：data_table_id + column_index
        manager
            .create_index(
                Index::create()
                    .name("idx_data_table_columns_table_index")
                    .table(DataTableColumns::Table)
                    .col(DataTableColumns::DataTableId)
                    .col(DataTableColumns::ColumnIndex)
                    .unique()
                    .to_owned(),
            )
            .await?;

        // 创建唯一索引：data_table_id + name
        manager
            .create_index(
                Index::create()
                    .name("idx_data_table_columns_table_name")
                    .table(DataTableColumns::Table)
                    .col(DataTableColumns::DataTableId)
                    .col(DataTableColumns::Name)
                    .unique()
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(DataTableColumns::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum DataTableColumns {
    Table,
    Id,
    DataTableId,
    ColumnIndex,
    Name,
    Desc,
    DataType,
    Nullable,
    DefaultValue,
    Partitioner,
    CreatedAt,
    UpdatedAt,
}
