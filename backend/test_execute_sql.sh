#!/bin/bash

# 测试执行 SQL 接口
# 使用方法: ./test_execute_sql.sh

# 设置变量
TARGET="${TARGET:-http://localhost:8080}"
TENANT_ID="${TENANT_ID:-1}"

echo "=== 测试执行 SQL 接口 ==="
echo "Target: $TARGET"
echo "Tenant ID: $TENANT_ID"
echo ""

# 1. 获取数据源列表
echo "1. 获取数据源列表..."
DATA_SOURCES=$(curl -s "$TARGET/api/v1/data-sources" \
  -H 'Content-Type: application/json' \
  -H "tenant_id: $TENANT_ID")

echo "数据源列表:"
echo "$DATA_SOURCES" | jq '.'
echo ""

# 提取第一个数据源的 ID
DATA_SOURCE_ID=$(echo "$DATA_SOURCES" | jq -r '.[0].id // empty')

if [ -z "$DATA_SOURCE_ID" ]; then
  echo "错误: 没有找到数据源"
  exit 1
fi

echo "使用数据源 ID: $DATA_SOURCE_ID"
echo ""

# 2. 执行简单的 SELECT 查询
echo "2. 执行简单的 SELECT 查询..."
curl -v "$TARGET/api/v1/data-sources/$DATA_SOURCE_ID/execute" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT * FROM data_sources LIMIT 5"
  }' | jq '.'
echo ""

# 3. 执行聚合查询
echo "3. 执行聚合查询..."
curl -v "$TARGET/api/v1/data-sources/$DATA_SOURCE_ID/execute" \
  -H 'Content-Type: application/json' \
  -d '{
    "sql": "SELECT db_type, COUNT(*) as count FROM data_sources GROUP BY db_type"
  }' | jq '.'
echo ""

# 4. 执行带 WHERE 条件的查询
echo "4. 执行带 WHERE 条件的查询..."
curl -v "$TARGET/api/v1/data-sources/$DATA_SOURCE_ID/execute" \
  -H 'Content-Type: application/json' \
  -d "{
    \"sql\": \"SELECT id, name, db_type FROM data_sources WHERE tenant_id = '$TENANT_ID'\"
  }" | jq '.'
echo ""

echo "=== 测试完成 ==="
