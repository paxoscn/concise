# Data Lakehouse Backend

数据湖仓系统后端服务，使用 Rust + Axum + SeaORM + PostgreSQL 实现。

## 技术栈

- **Web框架**: Axum 0.8
- **异步运行时**: Tokio
- **ORM**: SeaORM 1.1
- **数据库**: PostgreSQL
- **认证**: JWT + bcrypt

## 项目结构

```
backend/
├── src/
│   ├── api/           # API层：路由和处理器
│   ├── domain/        # 领域层：业务逻辑和服务
│   ├── repository/    # 数据访问层：Repository实现
│   ├── entities/      # 数据库实体模型
│   └── main.rs        # 应用入口
├── migration/         # 数据库迁移脚本
├── config/            # 配置文件
│   └── default.toml   # 默认配置
└── Cargo.toml         # 依赖配置
```

## 快速开始

### 前置要求

- Rust 1.70+
- PostgreSQL 14+
- Cargo

### 安装依赖

```bash
cargo build
```

### 配置数据库

1. 创建数据库：
```sql
CREATE DATABASE lakehouse;
```

2. 更新配置文件 `config/default.toml` 中的数据库连接信息

### 运行迁移

```bash
# 待实现
```

### 启动服务

```bash
cargo run
```

服务将在 `http://localhost:8080` 启动。

## API文档

### 认证
- `POST /api/v1/auth/login` - 用户登录

### 数据源管理
- `GET /api/v1/data-sources` - 查询数据源列表
- `POST /api/v1/data-sources` - 创建数据源
- `GET /api/v1/data-sources/{id}` - 查询数据源详情
- `PUT /api/v1/data-sources/{id}` - 更新数据源
- `DELETE /api/v1/data-sources/{id}` - 删除数据源

### 数据存储管理
- `GET /api/v1/storages` - 查询存储列表
- `POST /api/v1/storages` - 创建存储
- `GET /api/v1/storages/{id}` - 查询存储详情
- `PUT /api/v1/storages/{id}` - 更新存储
- `DELETE /api/v1/storages/{id}` - 删除存储

### 任务管理
- `GET /api/v1/tasks` - 查询任务列表
- `POST /api/v1/tasks` - 创建任务
- `GET /api/v1/tasks/{id}` - 查询任务详情
- `PUT /api/v1/tasks/{id}` - 更新任务
- `DELETE /api/v1/tasks/{id}` - 删除任务

### 任务执行
- `POST /api/v1/executor/execute` - 执行任务

## 开发

### 运行测试

```bash
cargo test
```

### 代码格式化

```bash
cargo fmt
```

### 代码检查

```bash
cargo clippy
```

## 环境变量

可以通过环境变量覆盖配置文件中的设置：

- `DATABASE_URL` - 数据库连接字符串
- `JWT_SECRET` - JWT密钥
- `TASK_CENTER_URL` - 任务中心地址
- `SERVER_PORT` - 服务端口

## 许可证

MIT
