mod api;
mod domain;
mod entities;
mod repository;
mod config;

use std::sync::Arc;
use axum::{Router, middleware};
use tower_http::cors::{CorsLayer, Any};
use tower_http::trace::TraceLayer;
use sea_orm::Database;

use config::AppConfig;
use repository::{UserRepository, DataSourceRepository, StorageRepository, ViewRepository};
use domain::{
    AuthService, DataSourceService, StorageService, 
    TaskService, TaskCenterClient, ExecutorEngine, QueryService,
};
use api::{
    create_auth_routes, create_data_source_routes, create_storage_routes,
    create_task_routes, create_executor_routes, create_query_routes, logging_middleware,
};
use migration::{Migrator, MigratorTrait};

#[tokio::main]
async fn main() {
    // Initialize logger
    tklog::ASYNC_LOG.set_console(true);
    tklog::ASYNC_LOG.set_level(tklog::LEVEL::Info);
    
    log::info!("Starting Data Lakehouse Backend...");

    // Load configuration
    let app_config = AppConfig::load()
        .expect("Failed to load configuration");

    log::info!("Configuration loaded successfully");
    log::info!("Server will start on {}:{}", app_config.server.host, app_config.server.port);

    // Initialize database connection
    log::info!("Connecting to database...");
    let db_url = app_config.database.url.clone();
    
    let db1 = Database::connect(&db_url)
        .await
        .expect("Failed to connect to database");
    
    log::info!("Database connected successfully");

    // Run database migrations
    log::info!("Running database migrations...");
    Migrator::up(&db1, None)
        .await
        .expect("Failed to run database migrations");
    log::info!("Database migrations completed successfully");

    // Create additional database connections for repositories
    let db2 = Database::connect(&db_url)
        .await
        .expect("Failed to connect to database");
    let db3 = Database::connect(&db_url)
        .await
        .expect("Failed to connect to database");
    let db4 = Database::connect(&db_url)
        .await
        .expect("Failed to connect to database");

    // Initialize repositories
    let user_repo = Arc::new(UserRepository::new(db1));
    let data_source_repo = Arc::new(DataSourceRepository::new(db2));
    let storage_repo = Arc::new(StorageRepository::new(db3));
    let view_repo = Arc::new(ViewRepository::new(db4));

    // Initialize services
    let auth_service = Arc::new(AuthService::new(
        user_repo,
        app_config.jwt.secret.clone(),
        app_config.jwt.expiration_hours,
    ));

    let data_source_service = Arc::new(DataSourceService::new(data_source_repo));
    let storage_service = Arc::new(StorageService::new(storage_repo));

    let task_center_client = Arc::new(TaskCenterClient::new(
        app_config.task_center.base_url.clone()
    ));
    let task_service = Arc::new(TaskService::new(task_center_client));

    let executor_engine = Arc::new(ExecutorEngine::new(
        data_source_service.clone(),
        storage_service.clone(),
        task_service.clone(),
    ));

    let query_service = Arc::new(QueryService::new(data_source_service.clone(), view_repo));

    // Build application routes
    let app = Router::new()
        // Auth routes (no JWT protection)
        .nest("/api/v1/auth", create_auth_routes(auth_service.clone()))
        // Data source routes (with JWT protection)
        .nest("/api/v1/data-sources", create_data_source_routes(
            data_source_service.clone(),
            auth_service.clone(),
        ))
        // Storage routes (with JWT protection)
        .nest("/api/v1/storages", create_storage_routes(
            storage_service.clone(),
            auth_service.clone(),
        ))
        // Task routes (with JWT protection)
        .nest("/api/v1/tasks", create_task_routes(
            task_service.clone(),
            auth_service.clone(),
        ))
        // Executor routes (with JWT protection)
        .nest("/api/v1/executor", create_executor_routes(
            executor_engine,
            auth_service.clone(),
        ))
        // Query routes (no JWT protection, uses tenant_id header)
        .nest("/api/v1", create_query_routes(query_service))
        // Add global middleware
        .layer(middleware::from_fn(logging_middleware))
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any)
        )
        .layer(TraceLayer::new_for_http());

    // Build server address
    let addr = format!("{}:{}", app_config.server.host, app_config.server.port);
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("Failed to bind to address");

    log::info!("Server listening on http://{}", addr);

    // Start server with graceful shutdown
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("Server error");

    log::info!("Server shutdown complete");
}

/// Graceful shutdown signal handler
async fn shutdown_signal() {
    use tokio::signal;

    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {
            log::info!("Received Ctrl+C signal, shutting down...");
        },
        _ = terminate => {
            log::info!("Received terminate signal, shutting down...");
        },
    }
}
