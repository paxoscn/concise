# MySQL 到 PostgreSQL 迁移指南

本文档记录了将数据湖仓系统从 MySQL 迁移到 PostgreSQL 的所有更改。

## 主要变更

### 1. Docker Compose 配置 (docker-compose.yml)

- 将 MySQL 8.0 容器替换为 PostgreSQL 16
- 更新环境变量：
  - `MYSQL_*` → `POSTGRES_*`
- 更新端口：3306 → 5432
- 更新健康检查命令：`mysqladmin ping` → `pg_isready`
- 更新数据卷名称：`mysql_data` → `postgres_data`
- 更新 DATABASE_URL 环境变量

### 2. 后端配置 (backend/config/default.toml)

- 数据库连接字符串从 `mysql://` 改为 `postgres://`
- 端口从 3306 改为 5432

### 3. Rust 依赖 (backend/Cargo.toml)

- SeaORM 特性从 `sqlx-mysql` 改为 `sqlx-postgres`

### 4. 数据库迁移 (backend/migration/Cargo.toml)

- SeaORM 特性从 `sqlx-mysql` 改为 `sqlx-postgres`

### 5. 数据库初始化脚本

#### init-db/01-init-schema.sql

MySQL 语法 → PostgreSQL 语法：

- 移除 `USE lakehouse;` 语句
- 移除 `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
- 将 `INDEX` 改为独立的 `CREATE INDEX` 语句
- 将 `ON UPDATE CURRENT_TIMESTAMP` 改为触发器实现
- 将 `JSON` 类型改为 `JSONB`
- 创建 `update_updated_at_column()` 函数和触发器

#### init-db/02-seed-data.sql

- 移除 `USE lakehouse;` 语句
- 将 `ON DUPLICATE KEY UPDATE` 改为 `ON CONFLICT DO NOTHING`
- 将 `JSON_OBJECT()` 改为 `jsonb_build_object()`

### 6. 后端代码

#### backend/src/domain/auth.rs

- 测试代码中的 `MockDatabase::new(DatabaseBackend::MySql)` 改为 `DatabaseBackend::Postgres`

#### backend/src/domain/executor.rs

- CREATE TABLE 语句适配 PostgreSQL 语法：
  - MySQL: `` `column` TEXT `` 和 `AUTO_INCREMENT`
  - PostgreSQL: `"column" TEXT` 和 `SERIAL`
- INSERT 语句的标识符引用：
  - MySQL: 反引号 `` ` ``
  - PostgreSQL: 双引号 `"`

### 7. 文档更新

- **backend/README.md**: 更新技术栈说明和前置要求
- **DEPLOYMENT.md**: 更新所有 MySQL 相关的说明、命令和配置示例
- **init-db/README.md**: 更新容器说明

## 迁移步骤

### 1. 停止现有服务

```bash
docker-compose down -v
```

### 2. 更新代码

所有代码已更新完成，无需手动修改。

### 3. 重新构建并启动服务

```bash
# 重新构建镜像
docker-compose build

# 启动服务
docker-compose up -d
```

### 4. 验证服务

```bash
# 检查服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 检查 PostgreSQL 健康状态
docker-compose exec postgres pg_isready -U lakehouse_user

# 测试后端 API
curl http://localhost:8080/health
```

## 数据迁移（如果需要）

如果你有现有的 MySQL 数据需要迁移到 PostgreSQL：

### 方法 1: 使用 pgloader

```bash
# 安装 pgloader
brew install pgloader  # macOS
# 或
apt-get install pgloader  # Ubuntu/Debian

# 执行迁移
pgloader mysql://lakehouse_user:lakehouse_pass@localhost:3306/lakehouse \
         postgresql://lakehouse_user:lakehouse_pass@localhost:5432/lakehouse
```

### 方法 2: 手动导出导入

```bash
# 1. 从 MySQL 导出数据
mysqldump -u lakehouse_user -p lakehouse > mysql_dump.sql

# 2. 转换 SQL 语法（需要手动调整）
# - 修改数据类型
# - 修改自增列语法
# - 修改 JSON 函数

# 3. 导入到 PostgreSQL
psql -U lakehouse_user -d lakehouse < converted_dump.sql
```

## 兼容性说明

### 保持的功能

- 所有 API 端点保持不变
- 数据模型结构保持不变
- 业务逻辑保持不变
- 前端代码无需修改

### 语法差异

| 功能 | MySQL | PostgreSQL |
|------|-------|------------|
| 自增主键 | `AUTO_INCREMENT` | `SERIAL` |
| JSON 类型 | `JSON` | `JSONB` |
| 标识符引用 | 反引号 `` ` `` | 双引号 `"` |
| 更新时间戳 | `ON UPDATE CURRENT_TIMESTAMP` | 触发器 |
| 冲突处理 | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT` |
| JSON 函数 | `JSON_OBJECT()` | `jsonb_build_object()` |

## 性能优化建议

### PostgreSQL 配置优化

在 `docker-compose.yml` 中添加：

```yaml
services:
  postgres:
    command: 
      - -c
      - max_connections=200
      - -c
      - shared_buffers=1GB
      - -c
      - effective_cache_size=3GB
      - -c
      - maintenance_work_mem=256MB
      - -c
      - checkpoint_completion_target=0.9
      - -c
      - wal_buffers=16MB
      - -c
      - default_statistics_target=100
```

### 索引优化

PostgreSQL 支持更多索引类型：

```sql
-- GIN 索引用于 JSONB
CREATE INDEX idx_data_sources_config ON data_sources USING GIN (connection_config);

-- 部分索引
CREATE INDEX idx_active_users ON users(id) WHERE created_at > NOW() - INTERVAL '30 days';
```

## 故障排查

### 连接问题

```bash
# 检查 PostgreSQL 是否运行
docker-compose exec postgres pg_isready

# 查看 PostgreSQL 日志
docker-compose logs postgres

# 测试连接
docker-compose exec postgres psql -U lakehouse_user -d lakehouse -c "SELECT version();"
```

### 权限问题

```sql
-- 授予所有权限
GRANT ALL PRIVILEGES ON DATABASE lakehouse TO lakehouse_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lakehouse_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lakehouse_user;
```

## 回滚方案

如果需要回滚到 MySQL：

1. 停止服务：`docker-compose down -v`
2. 恢复原始配置文件（使用 git）
3. 重新启动：`docker-compose up -d`

## 参考资源

- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [SeaORM PostgreSQL 支持](https://www.sea-ql.org/SeaORM/docs/install-and-config/database-and-async-runtime/)
- [MySQL 到 PostgreSQL 迁移指南](https://wiki.postgresql.org/wiki/Converting_from_other_Databases_to_PostgreSQL)
