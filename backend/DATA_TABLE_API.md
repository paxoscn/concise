# 数据表 API 文档

本文档描述了数据表相关的 REST API 接口。

## 基础信息

- **Base URL**: `http://localhost:8080/api/v1`
- **认证方式**: 
  - 数据表接口需要 JWT 认证（通过 `Authorization: Bearer <token>` 头）
  - 数据表字段和统计接口暂不需要认证

## 1. 数据表 (Data Tables)

### 1.1 创建数据表

**请求**
```http
POST /data-tables
Authorization: Bearer <token>
Content-Type: application/json

{
  "data_source_id": "ds-uuid",
  "name": "user_orders",
  "desc": "用户订单表"
}
```

**响应**
```json
{
  "id": "tenant-id-uuid",
  "tenant_id": "tenant-uuid",
  "data_source_id": "ds-uuid",
  "name": "user_orders",
  "desc": "用户订单表",
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 1.2 查询数据表列表（按租户）

**请求**
```http
GET /data-tables
Authorization: Bearer <token>
```

**响应**
```json
[
  {
    "id": "tenant-id-uuid",
    "tenant_id": "tenant-uuid",
    "data_source_id": "ds-uuid",
    "name": "user_orders",
    "desc": "用户订单表",
    "created_at": "2024-12-26T10:00:00",
    "updated_at": "2024-12-26T10:00:00"
  }
]
```

### 1.3 查询数据表列表（按数据源）

**请求**
```http
GET /data-tables/by-data-source?data_source_id=ds-uuid
Authorization: Bearer <token>
```

**响应**
```json
[
  {
    "id": "tenant-id-uuid",
    "tenant_id": "tenant-uuid",
    "data_source_id": "ds-uuid",
    "name": "user_orders",
    "desc": "用户订单表",
    "created_at": "2024-12-26T10:00:00",
    "updated_at": "2024-12-26T10:00:00"
  }
]
```

### 1.4 查询数据表详情

**请求**
```http
GET /data-tables/{id}
Authorization: Bearer <token>
```

**响应**
```json
{
  "id": "tenant-id-uuid",
  "tenant_id": "tenant-uuid",
  "data_source_id": "ds-uuid",
  "name": "user_orders",
  "desc": "用户订单表",
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 1.5 查询数据表详情（包含字段和统计）

**请求**
```http
GET /data-tables/{id}/details
Authorization: Bearer <token>
```

**响应**
```json
{
  "id": "tenant-id-uuid",
  "tenant_id": "tenant-uuid",
  "data_source_id": "ds-uuid",
  "name": "user_orders",
  "desc": "用户订单表",
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00",
  "columns": [
    {
      "id": "tenant-id-uuid-col-uuid",
      "data_table_id": "tenant-id-uuid",
      "column_index": 0,
      "name": "order_id",
      "desc": "订单ID",
      "data_type": "bigint",
      "nullable": false,
      "default_value": null,
      "partitioner": false,
      "created_at": "2024-12-26T10:00:00",
      "updated_at": "2024-12-26T10:00:00"
    }
  ],
  "usage": {
    "id": "tenant-id-uuid-usage",
    "data_table_id": "tenant-id-uuid",
    "row_count": 1000000,
    "partition_count": 10,
    "storage_size": 52428800,
    "created_at": "2024-12-26T10:00:00",
    "updated_at": "2024-12-26T10:00:00"
  }
}
```

### 1.6 更新数据表

**请求**
```http
PUT /data-tables/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "user_orders_v2",
  "desc": "用户订单表（更新版）"
}
```

**响应**
```json
{
  "id": "tenant-id-uuid",
  "tenant_id": "tenant-uuid",
  "data_source_id": "ds-uuid",
  "name": "user_orders_v2",
  "desc": "用户订单表（更新版）",
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:05:00"
}
```

### 1.7 删除数据表

**请求**
```http
DELETE /data-tables/{id}
Authorization: Bearer <token>
```

**响应**
```
Status: 204 No Content
```

**注意**: 删除数据表会级联删除其所有字段和统计信息。

---

## 2. 数据表字段 (Data Table Columns)

### 2.1 创建字段

**请求**
```http
POST /data-table-columns
Content-Type: application/json

{
  "data_table_id": "tenant-id-uuid",
  "column_index": 0,
  "name": "order_id",
  "desc": "订单ID",
  "data_type": "bigint",
  "nullable": false,
  "default_value": null,
  "partitioner": false
}
```

**响应**
```json
{
  "id": "tenant-id-uuid-col-uuid",
  "data_table_id": "tenant-id-uuid",
  "column_index": 0,
  "name": "order_id",
  "desc": "订单ID",
  "data_type": "bigint",
  "nullable": false,
  "default_value": null,
  "partitioner": false,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 2.2 批量创建字段

**请求**
```http
POST /data-table-columns/batch
Content-Type: application/json

{
  "data_table_id": "tenant-id-uuid",
  "columns": [
    {
      "column_index": 0,
      "name": "order_id",
      "desc": "订单ID",
      "data_type": "bigint",
      "nullable": false,
      "default_value": null,
      "partitioner": false
    },
    {
      "column_index": 1,
      "name": "user_id",
      "desc": "用户ID",
      "data_type": "bigint",
      "nullable": false,
      "default_value": null,
      "partitioner": false
    },
    {
      "column_index": 2,
      "name": "order_date",
      "desc": "订单日期",
      "data_type": "date",
      "nullable": false,
      "default_value": null,
      "partitioner": true
    }
  ]
}
```

**响应**
```
Status: 201 Created
```

### 2.3 查询字段列表（按数据表）

**请求**
```http
GET /data-table-columns?data_table_id=tenant-id-uuid
```

**响应**
```json
[
  {
    "id": "tenant-id-uuid-col-uuid",
    "data_table_id": "tenant-id-uuid",
    "column_index": 0,
    "name": "order_id",
    "desc": "订单ID",
    "data_type": "bigint",
    "nullable": false,
    "default_value": null,
    "partitioner": false,
    "created_at": "2024-12-26T10:00:00",
    "updated_at": "2024-12-26T10:00:00"
  }
]
```

### 2.4 查询字段详情

**请求**
```http
GET /data-table-columns/{id}
```

**响应**
```json
{
  "id": "tenant-id-uuid-col-uuid",
  "data_table_id": "tenant-id-uuid",
  "column_index": 0,
  "name": "order_id",
  "desc": "订单ID",
  "data_type": "bigint",
  "nullable": false,
  "default_value": null,
  "partitioner": false,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 2.5 更新字段

**请求**
```http
PUT /data-table-columns/{id}
Content-Type: application/json

{
  "desc": "订单唯一标识",
  "nullable": false
}
```

**响应**
```json
{
  "id": "tenant-id-uuid-col-uuid",
  "data_table_id": "tenant-id-uuid",
  "column_index": 0,
  "name": "order_id",
  "desc": "订单唯一标识",
  "data_type": "bigint",
  "nullable": false,
  "default_value": null,
  "partitioner": false,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:05:00"
}
```

### 2.6 删除字段

**请求**
```http
DELETE /data-table-columns/{id}
```

**响应**
```
Status: 204 No Content
```

---

## 3. 数据表统计 (Data Table Usages)

### 3.1 Upsert 统计信息

**请求**
```http
POST /data-table-usages/upsert
Content-Type: application/json

{
  "data_table_id": "tenant-id-uuid",
  "row_count": 1000000,
  "partition_count": 10,
  "storage_size": 52428800
}
```

**响应**
```json
{
  "id": "tenant-id-uuid-usage",
  "data_table_id": "tenant-id-uuid",
  "row_count": 1000000,
  "partition_count": 10,
  "storage_size": 52428800,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 3.2 查询统计信息（按数据表）

**请求**
```http
GET /data-table-usages/by-table?data_table_id=tenant-id-uuid
```

**响应**
```json
{
  "id": "tenant-id-uuid-usage",
  "data_table_id": "tenant-id-uuid",
  "row_count": 1000000,
  "partition_count": 10,
  "storage_size": 52428800,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 3.3 查询统计详情

**请求**
```http
GET /data-table-usages/{id}
```

**响应**
```json
{
  "id": "tenant-id-uuid-usage",
  "data_table_id": "tenant-id-uuid",
  "row_count": 1000000,
  "partition_count": 10,
  "storage_size": 52428800,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:00:00"
}
```

### 3.4 更新统计信息

**请求**
```http
PUT /data-table-usages/{id}
Content-Type: application/json

{
  "row_count": 1500000,
  "storage_size": 78643200
}
```

**响应**
```json
{
  "id": "tenant-id-uuid-usage",
  "data_table_id": "tenant-id-uuid",
  "row_count": 1500000,
  "partition_count": 10,
  "storage_size": 78643200,
  "created_at": "2024-12-26T10:00:00",
  "updated_at": "2024-12-26T10:05:00"
}
```

### 3.5 删除统计信息

**请求**
```http
DELETE /data-table-usages/{id}
```

**响应**
```
Status: 204 No Content
```

---

## 错误响应

所有接口在出错时返回统一的错误格式：

```json
{
  "error": "错误描述信息"
}
```

常见的 HTTP 状态码：
- `200 OK` - 请求成功
- `201 Created` - 创建成功
- `204 No Content` - 删除成功
- `400 Bad Request` - 请求参数错误
- `401 Unauthorized` - 未授权
- `404 Not Found` - 资源不存在
- `409 Conflict` - 资源已存在
- `500 Internal Server Error` - 服务器内部错误

---

## 使用示例

### 完整流程示例

```bash
# 1. 登录获取 token
TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"password"}' | jq -r '.token')

# 2. 创建数据表
TABLE_ID=$(curl -X POST http://localhost:8080/api/v1/data-tables \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "data_source_id": "ds-uuid",
    "name": "user_orders",
    "desc": "用户订单表"
  }' | jq -r '.id')

# 3. 批量创建字段
curl -X POST http://localhost:8080/api/v1/data-table-columns/batch \
  -H 'Content-Type: application/json' \
  -d "{
    \"data_table_id\": \"$TABLE_ID\",
    \"columns\": [
      {
        \"column_index\": 0,
        \"name\": \"order_id\",
        \"desc\": \"订单ID\",
        \"data_type\": \"bigint\",
        \"nullable\": false,
        \"partitioner\": false
      },
      {
        \"column_index\": 1,
        \"name\": \"user_id\",
        \"desc\": \"用户ID\",
        \"data_type\": \"bigint\",
        \"nullable\": false,
        \"partitioner\": false
      }
    ]
  }"

# 4. 创建统计信息
curl -X POST http://localhost:8080/api/v1/data-table-usages/upsert \
  -H 'Content-Type: application/json' \
  -d "{
    \"data_table_id\": \"$TABLE_ID\",
    \"row_count\": 1000000,
    \"partition_count\": 10,
    \"storage_size\": 52428800
  }"

# 5. 查询完整信息
curl -X GET "http://localhost:8080/api/v1/data-tables/$TABLE_ID/details" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 注意事项

1. **租户隔离**: 数据表接口会自动从 JWT token 中提取 `tenant_id`，确保数据隔离。

2. **唯一性约束**: 
   - 同一租户下，同一数据源中的表名必须唯一
   - 同一数据表中，字段序号和字段名必须唯一

3. **级联删除**: 删除数据表会自动删除其所有字段和统计信息。

4. **字段顺序**: `column_index` 从 0 开始，建议按顺序创建字段。

5. **统计信息**: 使用 `upsert` 接口可以自动创建或更新统计信息，无需判断是否存在。

6. **存储大小**: `storage_size` 单位为字节（Byte）。
