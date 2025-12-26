use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(DataTableUsages::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(DataTableUsages::Id)
                            .string_len(72)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::DataTableId)
                            .string_len(72)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::RowCount)
                            .big_integer()
                            .not_null()
                            .default(0),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::PartitionCount)
                            .integer()
                            .not_null()
                            .default(0),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::StorageSize)
                            .big_integer()
                            .not_null()
                            .default(0),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(DataTableUsages::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await?;

        // 创建唯一索引：data_table_id（一个表只有一条统计记录）
        manager
            .create_index(
                Index::create()
                    .name("idx_data_table_usages_table_id")
                    .table(DataTableUsages::Table)
                    .col(DataTableUsages::DataTableId)
                    .unique()
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(DataTableUsages::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum DataTableUsages {
    Table,
    Id,
    DataTableId,
    RowCount,
    PartitionCount,
    StorageSize,
    CreatedAt,
    UpdatedAt,
}
