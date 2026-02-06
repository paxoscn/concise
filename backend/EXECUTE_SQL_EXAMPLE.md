# Execute SQL API 使用示例

## 快速开始

### 前置条件

1. 确保后端服务正在运行
2. 已经创建了至少一个 PostgreSQL 数据源

### 步骤 1: 获取数据源 ID

首先，获取可用的数据源列表：

```bash
curl http://localhost:8080/api/v1/data-sources \
  -H 'Content-Type: application/json' \
  -H 'tenant_id: 1'
```

响应示例：

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "主数据库",
    "db_type": "PostgreSQL",
    "connection_config": {
      "host": "localhost",
      "port": 5432,
      "database": "mydb",
      "username": "user",
      "password": "pass"
    },
    "tenant_id": "1",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

记下 `id` 字段的值。

### 步骤 2: 执行 SQL 查询

使用获取到的数据源 ID 执行 SQL 查询：

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/550e8400-e29b-41d4-a716-446655440000/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM data_sources LIMIT 5"
  }'
```

响应示例：

```json
{
  "columns": ["id", "name", "db_type", "tenant_id", "created_at", "updated_at"],
  "rows": [
    [
      "550e8400-e29b-41d4-a716-446655440000",
      "主数据库",
      "PostgreSQL",
      "1",
      "2024-01-01 00:00:00",
      "2024-01-01 00:00:00"
    ]
  ],
  "row_count": 1
}
```

## 常见查询示例

### 1. 查询表结构

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = '\''users'\'' ORDER BY ordinal_position"
  }'
```

### 2. 统计查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT COUNT(*) as total_users, COUNT(DISTINCT email) as unique_emails FROM users"
  }'
```

### 3. 分组统计

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT DATE(created_at) as date, COUNT(*) as count FROM users WHERE created_at >= NOW() - INTERVAL '\''7 days'\'' GROUP BY DATE(created_at) ORDER BY date"
  }'
```

### 4. 多表关联查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT ds.name as data_source, dt.table_name, COUNT(dtc.id) as column_count FROM data_sources ds LEFT JOIN data_tables dt ON ds.id = dt.data_source_id LEFT JOIN data_table_columns dtc ON dt.id = dtc.data_table_id GROUP BY ds.name, dt.table_name ORDER BY ds.name, dt.table_name"
  }'
```

### 5. 条件过滤查询

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT id, name, db_type FROM data_sources WHERE tenant_id = '\''1'\'' AND db_type = '\''PostgreSQL'\'' ORDER BY created_at DESC"
  }'
```

### 6. 子查询示例

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT name, (SELECT COUNT(*) FROM data_tables WHERE data_source_id = ds.id) as table_count FROM data_sources ds WHERE tenant_id = '\''1'\''"
  }'
```

## 使用 jq 格式化输出

如果你安装了 `jq`，可以使用它来格式化 JSON 输出：

```bash
curl -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM data_sources LIMIT 5"
  }' | jq '.'
```

## 在 JavaScript/TypeScript 中使用

```typescript
interface ExecuteSqlRequest {
  sql: string;
}

interface ExecuteSqlResponse {
  columns: string[];
  rows: any[][];
  row_count: number;
}

async function executeSql(
  dataSourceId: string,
  sql: string
): Promise<ExecuteSqlResponse> {
  const response = await fetch(
    `http://localhost:8080/api/v1/data-sources/${dataSourceId}/execute`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ sql }),
    }
  );

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return await response.json();
}

// 使用示例
const result = await executeSql(
  '550e8400-e29b-41d4-a716-446655440000',
  'SELECT * FROM users LIMIT 10'
);

console.log('Columns:', result.columns);
console.log('Rows:', result.rows);
console.log('Total rows:', result.row_count);
```

## 在 Python 中使用

```python
import requests
import json

def execute_sql(data_source_id: str, sql: str) -> dict:
    url = f"http://localhost:8080/api/v1/data-sources/{data_source_id}/execute"
    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "sql": sql
    }
    
    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()
    
    return response.json()

# 使用示例
result = execute_sql(
    "550e8400-e29b-41d4-a716-446655440000",
    "SELECT * FROM users LIMIT 10"
)

print("Columns:", result["columns"])
print("Rows:", result["rows"])
print("Total rows:", result["row_count"])
```

## 错误处理示例

### Bash

```bash
response=$(curl -s -w "\n%{http_code}" \
  -X POST http://localhost:8080/api/v1/data-sources/{DATA_SOURCE_ID}/execute \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM non_existent_table"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
  echo "Success: $body"
else
  echo "Error (HTTP $http_code): $body"
fi
```

### JavaScript/TypeScript

```typescript
try {
  const result = await executeSql(
    dataSourceId,
    'SELECT * FROM non_existent_table'
  );
  console.log('Success:', result);
} catch (error) {
  console.error('Error executing SQL:', error.message);
}
```

### Python

```python
try:
    result = execute_sql(
        data_source_id,
        "SELECT * FROM non_existent_table"
    )
    print("Success:", result)
except requests.exceptions.HTTPError as e:
    print(f"Error executing SQL: {e.response.status_code} - {e.response.text}")
```

## 性能优化建议

1. **使用 LIMIT**: 对于大表查询，始终使用 LIMIT 限制返回行数
   ```sql
   SELECT * FROM large_table LIMIT 100
   ```

2. **使用索引**: 确保查询的列上有适当的索引
   ```sql
   SELECT * FROM users WHERE email = 'user@example.com'  -- email 列应该有索引
   ```

3. **避免 SELECT ***: 只选择需要的列
   ```sql
   SELECT id, name, email FROM users  -- 而不是 SELECT *
   ```

4. **使用分页**: 对于大量数据，使用 OFFSET 和 LIMIT 进行分页
   ```sql
   SELECT * FROM users ORDER BY id LIMIT 100 OFFSET 0  -- 第一页
   SELECT * FROM users ORDER BY id LIMIT 100 OFFSET 100  -- 第二页
   ```

## 安全注意事项

1. **SQL 注入**: 当前 API 不提供参数化查询，请确保在客户端进行适当的输入验证
2. **权限控制**: 建议在生产环境中添加身份验证和授权机制
3. **查询限制**: 考虑添加查询超时和资源限制
4. **审计日志**: 记录所有执行的 SQL 查询以便审计
