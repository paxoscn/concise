# 设计文档

## 概述

数据湖仓系统采用前后端分离架构，后端使用Rust + Axum + SeaORM + MySQL实现单实例服务，前端使用现代Web技术栈实现管理界面。系统核心功能包括用户认证、资源管理（数据源和存储）、任务执行引擎。

## 架构

### 整体架构

```
┌─────────────┐
│   Frontend  │
│   (Web UI)  │
└──────┬──────┘
       │ HTTP/REST
       ▼
┌─────────────────────────────────────┐
│         Backend (Rust)              │
│  ┌─────────────────────────────┐   │
│  │     API Layer (Axum)        │   │
│  └────────────┬────────────────┘   │
│               │                     │
│  ┌────────────▼────────────────┐   │
│  │     Domain Layer            │   │
│  │  ┌──────────────────────┐   │   │
│  │  │  Auth Service        │   │   │
│  │  │  DataSource Service  │   │   │
│  │  │  Storage Service     │   │   │
│  │  │  Task Service        │   │   │
│  │  │  Executor Engine     │   │   │
│  │  └──────────────────────┘   │   │
│  └────────────┬────────────────┘   │
│               │                     │
│  ┌────────────▼────────────────┐   │
│  │  Data Access Layer (SeaORM) │   │
│  └────────────┬────────────────┘   │
└───────────────┼─────────────────────┘
                │
       ┌────────┴────────┐
       ▼                 ▼
  ┌─────────┐      ┌──────────────┐
  │  MySQL  │      │ External Task│
  │Database │      │   Center     │
  └─────────┘      └──────────────┘
```

### 后端分层架构

1. **API Layer**: 处理HTTP请求、路由、中间件
2. **Domain Layer**: 业务逻辑、服务编排
3. **Data Access Layer**: 数据库操作、实体映射

## 组件和接口

### 1. API Layer

#### 路由结构

```
/api/v1
├── /auth
│   └── POST /login          # 用户登录
├── /data-sources
│   ├── GET    /             # 列表查询
│   ├── POST   /             # 创建
│   ├── GET    /{id}          # 详情查询
│   ├── PUT    /{id}          # 更新
│   └── DELETE /{id}          # 删除
├── /storages
│   ├── GET    /             # 列表查询
│   ├── POST   /             # 创建
│   ├── GET    /{id}          # 详情查询
│   ├── PUT    /{id}          # 更新
│   └── DELETE /{id}          # 删除
├── /tasks
│   ├── GET    /             # 列表查询（代理到任务中心）
│   ├── POST   /             # 创建（代理到任务中心）
│   ├── GET    /{id}          # 详情查询（代理到任务中心）
│   ├── PUT    /{id}          # 更新（代理到任务中心）
│   └── DELETE /{id}          # 删除（代理到任务中心）
└── /executor
    └── POST /execute        # 执行任务
```

#### 中间件

- **CORS**: 跨域资源共享
- **Logging**: 请求日志记录
- **Authentication**: JWT令牌验证
- **Error Handling**: 统一错误处理

### 2. Domain Layer

#### Auth Service

```rust
pub struct AuthService {
    user_repo: Arc<UserRepository>,
    jwt_secret: String,
}

impl AuthService {
    pub async fn login(&self, nickname: String, password: String) 
        -> Result<AuthToken, AuthError>;
    
    pub async fn verify_token(&self, token: &str) 
        -> Result<UserClaims, AuthError>;
}
```

#### DataSource Service

```rust
pub struct DataSourceService {
    repo: Arc<DataSourceRepository>,
}

impl DataSourceService {
    pub async fn create(&self, req: CreateDataSourceRequest) 
        -> Result<DataSource, ServiceError>;
    
    pub async fn list(&self) -> Result<Vec<DataSource>, ServiceError>;
    
    pub async fn get(&self, id: Uuid) 
        -> Result<DataSource, ServiceError>;
    
    pub async fn update(&self, id: Uuid, req: UpdateDataSourceRequest) 
        -> Result<DataSource, ServiceError>;
    
    pub async fn delete(&self, id: Uuid) -> Result<(), ServiceError>;
}
```

#### Storage Service

```rust
pub struct StorageService {
    repo: Arc<StorageRepository>,
}

impl StorageService {
    pub async fn create(&self, req: CreateStorageRequest) 
        -> Result<Storage, ServiceError>;
    
    pub async fn list(&self) -> Result<Vec<Storage>, ServiceError>;
    
    pub async fn get(&self, id: Uuid) 
        -> Result<Storage, ServiceError>;
    
    pub async fn update(&self, id: Uuid, req: UpdateStorageRequest) 
        -> Result<Storage, ServiceError>;
    
    pub async fn delete(&self, id: Uuid) -> Result<(), ServiceError>;
}
```

#### Task Service

```rust
pub struct TaskService {
    task_center_client: Arc<TaskCenterClient>,
}

impl TaskService {
    pub async fn list(&self) -> Result<Vec<Task>, ServiceError>;
    
    pub async fn create(&self, req: CreateTaskRequest) 
        -> Result<Task, ServiceError>;
    
    pub async fn get(&self, id: String) 
        -> Result<Task, ServiceError>;
    
    pub async fn update(&self, id: String, req: UpdateTaskRequest) 
        -> Result<Task, ServiceError>;
    
    pub async fn delete(&self, id: String) -> Result<(), ServiceError>;
}
```

#### Executor Engine

```rust
pub struct ExecutorEngine {
    data_source_service: Arc<DataSourceService>,
    storage_service: Arc<StorageService>,
    task_service: Arc<TaskService>,
}

pub struct ExecutorContext {
    pub data_sources: Vec<DataSource>,
    pub storages: Vec<Storage>,
}

#[async_trait]
pub trait Executor: Send + Sync {
    async fn execute(
        &self, 
        metadata: TaskMetadata, 
        context: ExecutorContext
    ) -> Result<ExecutionResult, ExecutorError>;
}

pub struct SqlExecutor;
pub struct ExcelExecutor;

impl ExecutorEngine {
    pub async fn execute_task(
        &self,
        task_type: TaskType,
        metadata: TaskMetadata,
    ) -> Result<ExecutionResult, ExecutorError>;
    
    fn get_executor(&self, task_type: &TaskType) -> Box<dyn Executor>;
    
    async fn trigger_next_actions(
        &self,
        metadata: &TaskMetadata,
        result: &ExecutionResult,
    ) -> Result<(), ExecutorError>;
}
```

### 后端依赖

#### Web framework
axum = { version = "0.8.5", features = ["multipart"] }
tokio = { version = "1.0", features = ["full"] }
tower = "0.5"
tower-http = { version = "0.6", features = ["cors", "trace", "fs"] }
http = "1.0"
#### Database and ORM
sea-orm = { version = "1.1.17", features = ["sqlx-mysql", "runtime-tokio-rustls", "macros", "debug-print"] }
sea-orm-migration = "1.1.17"
#### Redis
redis = { version = "0.21", features = ["tokio-comp"] }
#### Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
#### UUID and time
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
url = "2.4"
#### Error handling
thiserror = "1.0"
#### Async traits
async-trait = "0.1"
futures = "0.3"
#### HTTP client
reqwest = { version = "0.11", default_features = false, features = ["json", "stream", "rustls-tls"] }
bytes = "1.0"
#### Configuration
config = "0.13"
#### Logging
log = "0.4"
tklog = "0.3.0"
#### Authentication
bcrypt = "0.15"
jsonwebtoken = "9.3"

### 3. Data Access Layer

#### 实体定义

```rust
// User Entity
#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "users")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub nickname: String,
    pub password_hash: String,
    pub created_at: DateTime,
    pub updated_at: DateTime,
}

// DataSource Entity
#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "data_sources")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub name: String,
    pub db_type: String,
    pub connection_config: Json, // 存储连接属性
    pub created_at: DateTime,
    pub updated_at: DateTime,
}

// Storage Entity
#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "storages")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub name: String,
    pub storage_type: String,
    pub upload_endpoint: String,
    pub download_endpoint: String,
    pub auth_config: Json, // 存储认证信息
    pub created_at: DateTime,
    pub updated_at: DateTime,
}
```

#### Repository Pattern

```rust
pub struct UserRepository {
    db: DatabaseConnection,
}

pub struct DataSourceRepository {
    db: DatabaseConnection,
}

pub struct StorageRepository {
    db: DatabaseConnection,
}
```

### 4. External Integration

#### Task Center Client

```rust
pub struct TaskCenterClient {
    client: reqwest::Client,
    base_url: String,
}

impl TaskCenterClient {
    pub async fn list_tasks(&self) -> Result<Vec<Task>, ClientError>;
    pub async fn create_task(&self, req: CreateTaskRequest) 
        -> Result<Task, ClientError>;
    pub async fn get_task(&self, id: &str) 
        -> Result<Task, ClientError>;
    pub async fn update_task(&self, id: &str, req: UpdateTaskRequest) 
        -> Result<Task, ClientError>;
    pub async fn delete_task(&self, id: &str) 
        -> Result<(), ClientError>;
}
```

## 数据模型

### 数据库表结构

#### users 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 主键，UUID |
| nickname | VARCHAR(100) | 昵称，唯一 |
| password_hash | VARCHAR(255) | bcrypt加密的密码 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

#### data_sources 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 主键，UUID |
| name | VARCHAR(100) | 数据源名称 |
| db_type | VARCHAR(50) | 数据库类型（MySQL, PostgreSQL等） |
| connection_config | JSON | 连接配置（host, port, database, username, password等） |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

#### storages 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 主键，UUID |
| name | VARCHAR(100) | 存储名称 |
| storage_type | VARCHAR(50) | 存储类型（S3, OSS, MinIO等） |
| upload_endpoint | VARCHAR(255) | 上传域名 |
| download_endpoint | VARCHAR(255) | 下载域名 |
| auth_config | JSON | 认证信息（access_key, secret_key等） |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### API 数据模型

#### 认证相关

```rust
pub struct LoginRequest {
    pub nickname: String,
    pub password: String,
}

pub struct AuthToken {
    pub token: String,
    pub expires_at: DateTime<Utc>,
}

pub struct UserClaims {
    pub user_id: Uuid,
    pub nickname: String,
    pub exp: i64,
}
```

#### 任务相关

```rust
pub struct TaskMetadata {
    pub task_id: String,
    pub dependencies: Vec<String>, // 依赖的任务ID
    pub next_actions: Vec<NextAction>,
    pub config: serde_json::Value,
}

pub struct NextAction {
    pub action_type: String,
    pub target_task_id: String,
    pub condition: Option<String>,
}

pub enum TaskType {
    Sql,
    Excel,
}

pub struct ExecutionResult {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
}
```

## 错误处理

### 错误类型层次

```rust
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Authentication error: {0}")]
    Auth(#[from] AuthError),
    
    #[error("Service error: {0}")]
    Service(#[from] ServiceError),
    
    #[error("Database error: {0}")]
    Database(#[from] sea_orm::DbErr),
    
    #[error("Executor error: {0}")]
    Executor(#[from] ExecutorError),
    
    #[error("External client error: {0}")]
    Client(#[from] ClientError),
}

#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    #[error("Invalid credentials")]
    InvalidCredentials,
    
    #[error("Invalid token")]
    InvalidToken,
    
    #[error("Token expired")]
    TokenExpired,
}

#[derive(Debug, thiserror::Error)]
pub enum ServiceError {
    #[error("Resource not found")]
    NotFound,
    
    #[error("Resource already exists")]
    AlreadyExists,
    
    #[error("Invalid input: {0}")]
    InvalidInput(String),
}

#[derive(Debug, thiserror::Error)]
pub enum ExecutorError {
    #[error("Unsupported task type")]
    UnsupportedTaskType,
    
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
    
    #[error("Data source connection failed")]
    ConnectionFailed,
}
```

### HTTP 错误响应

```rust
pub struct ErrorResponse {
    pub code: String,
    pub message: String,
    pub details: Option<serde_json::Value>,
}

// 错误码映射
// 401: 认证失败
// 403: 权限不足
// 404: 资源不存在
// 409: 资源冲突
// 422: 输入验证失败
// 500: 服务器内部错误
```

## 测试策略

### 单元测试

- Domain Layer服务逻辑测试
- Repository CRUD操作测试
- Executor执行逻辑测试
- 工具函数测试

### 集成测试

- API端点测试（使用测试数据库）
- 数据库迁移测试
- 外部服务集成测试（使用mock）

### 测试工具

- `cargo test`: 运行测试
- `sqlx-cli`: 数据库迁移测试
- `mockall`: Mock外部依赖

## 前端设计

### 技术栈建议

- **框架**: React / Vue 3
- **UI库**: Ant Design / Element Plus（支持中文）
- **状态管理**: Redux / Pinia
- **HTTP客户端**: Axios
- **路由**: React Router / Vue Router

### 页面结构

```
/
├── /login                    # 登录页（苹果风格）
├── /dashboard                # 首页仪表盘
├── /data-sources             # 数据源管理
│   ├── /list                 # 列表页
│   ├── /create               # 创建页
│   └── /edit/{id}             # 编辑页
├── /storages                 # 数据存储管理
│   ├── /list                 # 列表页
│   ├── /create               # 创建页
│   └── /edit/{id}             # 编辑页
└── /tasks                    # 任务管理
    ├── /list                 # 列表页
    ├── /create               # 创建页
    └── /edit/{id}             # 编辑页
```

### 登录页设计要点

- 简洁的苹果风格设计
- 居中的登录表单
- 圆角输入框和按钮
- 柔和的配色方案
- 响应式布局

### 管理页面功能

- 表格展示资源列表
- 搜索和筛选功能
- 创建、编辑、删除操作
- 表单验证
- 操作确认对话框

## 配置管理

### 配置文件结构

```toml
# config/default.toml
[server]
host = "0.0.0.0"
port = 8080

[database]
url = "mysql://user:password@localhost:3306/lakehouse"
max_connections = 10

[jwt]
secret = "your-secret-key"
expiration_hours = 24

[task_center]
base_url = "http://task-center:8081"
timeout_seconds = 30

[logging]
level = "info"
```

### 环境变量覆盖

- `DATABASE_URL`: 数据库连接字符串
- `JWT_SECRET`: JWT密钥
- `TASK_CENTER_URL`: 任务中心地址
- `SERVER_PORT`: 服务端口

## 部署架构

### 单实例部署

```
┌─────────────────────────────────┐
│         Nginx (反向代理)         │
│  ┌──────────┐   ┌────────────┐  │
│  │ Frontend │   │  Backend   │  │
│  │  Static  │   │   :8080    │  │
│  └──────────┘   └────────────┘  │
└─────────────────────────────────┘
         │
         ▼
    ┌─────────┐
    │  MySQL  │
    └─────────┘
```

### Docker 部署

- Backend: Rust多阶段构建镜像
- Frontend: Nginx静态文件服务
- MySQL: 官方镜像
- Docker Compose编排

## 安全考虑

1. **密码安全**: 使用bcrypt加密存储
2. **JWT安全**: 设置合理的过期时间，使用强密钥
3. **SQL注入防护**: 使用SeaORM参数化查询
4. **CORS配置**: 限制允许的源
5. **敏感信息**: 数据库连接信息和认证信息加密存储
6. **HTTPS**: 生产环境强制使用HTTPS
7. **输入验证**: 所有API输入进行验证
