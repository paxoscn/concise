pub use sea_orm_migration::prelude::*;

mod m20240101_000001_create_users_table;
mod m20240101_000002_create_data_sources_table;
mod m20240101_000003_create_storages_table;
mod m20241202_000001_add_tenant_id_to_data_sources;
mod m20241202_000002_add_tenant_id_to_storages;
mod m20241202_000003_add_tenant_id_to_users;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20240101_000001_create_users_table::Migration),
            Box::new(m20240101_000002_create_data_sources_table::Migration),
            Box::new(m20240101_000003_create_storages_table::Migration),
            Box::new(m20241202_000001_add_tenant_id_to_data_sources::Migration),
            Box::new(m20241202_000002_add_tenant_id_to_storages::Migration),
            Box::new(m20241202_000003_add_tenant_id_to_users::Migration),
        ]
    }
}
