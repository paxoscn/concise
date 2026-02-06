# Execute SQL API - 快速参考

## 一行命令测试

```bash
# 1. 获取数据源 ID
DATA_SOURCE_ID=$(curl -s http://localhost:8080/api/v1/data-sources -H 'tenant_id: 1' | jq -r '.[0].id')

# 2. 执行 SQL 查询
curl -X POST "http://localhost:8080/api/v1/data-sources/$DATA_SOURCE_ID/execute" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT * FROM data_sources LIMIT 5"}' | jq '.'
```

## 基本用法

```bash
POST /api/v1/data-sources/{id}/execute
Content-Type: application/json

{
  "sql": "SELECT * FROM table_name LIMIT 10"
}
```

## 响应格式

```json
{
  "columns": ["col1", "col2", "col3"],
  "rows": [
    ["value1", "value2", "value3"],
    ["value4", "value5", "value6"]
  ],
  "row_count": 2
}
```

## 常用查询

### 查看所有表

```bash
curl -X POST "http://localhost:8080/api/v1/data-sources/{id}/execute" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT tablename FROM pg_tables WHERE schemaname = '\''public'\''"}'
```

### 查看表结构

```bash
curl -X POST "http://localhost:8080/api/v1/data-sources/{id}/execute" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '\''users'\''"}'
```

### 统计查询

```bash
curl -X POST "http://localhost:8080/api/v1/data-sources/{id}/execute" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT COUNT(*) as total FROM users"}'
```

### 分组统计

```bash
curl -X POST "http://localhost:8080/api/v1/data-sources/{id}/execute" \
  -H 'Content-Type: application/json' \
  -d '{"sql": "SELECT status, COUNT(*) as count FROM orders GROUP BY status"}'
```

## 使用测试脚本

```bash
cd backend
./test_execute_sql.sh
```

## 支持的数据库

- ✅ PostgreSQL
- ❌ MySQL (暂不支持)
- ❌ SQLite (暂不支持)

## 注意事项

1. 仅支持 PostgreSQL 数据库
2. 所有返回值都是字符串类型
3. 建议使用 LIMIT 限制返回行数
4. 注意 SQL 注入风险

## 完整文档

- [API 文档](./EXECUTE_SQL_API.md)
- [使用示例](./EXECUTE_SQL_EXAMPLE.md)
- [功能总结](./EXECUTE_SQL_FEATURE.md)
