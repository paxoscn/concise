# Execute SQL API

## 概述

这个 API 允许你通过指定的数据源 ID 执行任意 SQL 查询，并返回查询结果。

## 端点

```
POST /api/v1/data-sources/{id}/execute
```

## 请求参数

### 路径参数

- `id` (string, required): 数据源的唯一标识符

### 请求体

```json
{
  "sql": "SELECT * FROM table_name LIMIT 10"
}
```

- `sql` (string, required): 要执行的 SQL 查询语句

## 响应

### 成功响应 (200 OK)

```json
{
  "columns": ["id", "name", "db_type", "created_at"],
  "rows": [
    ["1", "主数据库", "PostgreSQL", "2024-01-01 00:00:00"],
    ["2", "备份数据库", "PostgreSQL", "2024-01-02 00:00:00"]
  ],
  "row_count": 2
}
```

响应字段说明：

- `columns` (array of strings): 查询结果的列名列表
- `rows` (array of arrays): 查询结果的数据行，每行是一个值数组
- `row_count` (integer): 返回的行数

### 错误响应

#### 404 Not Found - 数据源不存在

```json
{
  "error": "Not found"
}
```

#### 400 Bad Request - SQL 执行失败

```json
{
  "error": "Failed to execute SQL: syntax error at or near \"SELEC\""
}
```

#### 400 Bad Request - 不支持的数据库类型

```json
{
  "error": "Unsupported database type: MySQL. Only PostgreSQL is supported."
}
```

## 使用示例

### 1. 简单查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/123e4567-e89b-12d3-a456-426614174000/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM users LIMIT 10"
  }'
```

### 2. 聚合查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/123e4567-e89b-12d3-a456-426614174000/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT status, COUNT(*) as count FROM orders GROUP BY status"
  }'
```

### 3. 带条件的查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/123e4567-e89b-12d3-a456-426614174000/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT id, name, email FROM users WHERE created_at > '\''2024-01-01'\'' ORDER BY created_at DESC"
  }'
```

### 4. JOIN 查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/123e4567-e89b-12d3-a456-426614174000/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT u.name, o.order_id, o.total FROM users u JOIN orders o ON u.id = o.user_id WHERE o.status = '\''completed'\''"
  }'
```

## 注意事项

1. **数据库支持**: 当前版本仅支持 PostgreSQL 数据库
2. **权限**: 执行的 SQL 查询将使用数据源配置中的数据库用户权限
3. **安全性**: 
   - 请确保只允许受信任的用户访问此 API
   - 建议在生产环境中添加 SQL 注入防护
   - 考虑限制可执行的 SQL 语句类型（例如只允许 SELECT）
4. **性能**: 
   - 对于大量数据的查询，建议添加 LIMIT 子句
   - 复杂查询可能会影响数据库性能
5. **数据类型**: 当前所有返回值都转换为字符串类型，未来版本可能会保留原始数据类型

## 错误处理

API 会返回以下类型的错误：

- **连接错误**: 无法连接到数据源
- **SQL 语法错误**: SQL 语句语法不正确
- **权限错误**: 数据库用户没有执行该查询的权限
- **超时错误**: 查询执行时间过长

## 测试脚本

项目提供了一个测试脚本 `test_execute_sql.sh`，可以快速测试此 API：

```bash
cd backend
./test_execute_sql.sh
```

你也可以指定自定义的服务器地址和租户 ID：

```bash
TARGET=http://localhost:8080 TENANT_ID=1 ./test_execute_sql.sh
```
