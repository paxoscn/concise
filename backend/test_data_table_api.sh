#!/bin/bash

# 数据表 API 测试脚本
# 使用方法: ./test_data_table_api.sh

set -e

# 配置
BASE_URL="${BASE_URL:-http://localhost:8080}"
API_BASE="$BASE_URL/api/v1"

echo "=========================================="
echo "数据表 API 测试"
echo "=========================================="
echo "Base URL: $BASE_URL"
echo ""

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_api() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local headers=$5
    
    echo -e "${YELLOW}测试: $name${NC}"
    echo "请求: $method $endpoint"
    
    if [ -n "$data" ]; then
        echo "数据: $data"
    fi
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "$API_BASE$endpoint" $headers)
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            $headers \
            -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            $headers \
            -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE$endpoint" $headers)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ 成功 (HTTP $http_code)${NC}"
        if [ -n "$body" ]; then
            echo "$body" | jq '.' 2>/dev/null || echo "$body"
        fi
    else
        echo -e "${RED}✗ 失败 (HTTP $http_code)${NC}"
        echo "$body"
    fi
    echo ""
    
    # 返回响应体供后续使用
    echo "$body"
}

# 1. 登录获取 token（如果需要）
echo "=========================================="
echo "1. 认证测试"
echo "=========================================="
echo ""

# 注意：这里假设你已经有了认证系统
# 如果没有，可以跳过这一步，直接使用 tenant_id header
TOKEN=""
# TOKEN=$(test_api "登录" "POST" "/auth/login" \
#     '{"username":"admin","password":"password"}' | jq -r '.token')

if [ -n "$TOKEN" ]; then
    AUTH_HEADER="-H \"Authorization: Bearer $TOKEN\""
    echo "Token: $TOKEN"
else
    AUTH_HEADER=""
    echo "跳过认证（使用 tenant_id header）"
fi
echo ""

# 2. 创建数据表
echo "=========================================="
echo "2. 数据表测试"
echo "=========================================="
echo ""

# 假设已有数据源 ID
DATA_SOURCE_ID="test-datasource-id"

TABLE_RESPONSE=$(test_api "创建数据表" "POST" "/data-tables" \
    "{
        \"data_source_id\": \"$DATA_SOURCE_ID\",
        \"name\": \"test_orders_$(date +%s)\",
        \"desc\": \"测试订单表\"
    }" \
    "-H \"tenant_id: test-tenant\"")

TABLE_ID=$(echo "$TABLE_RESPONSE" | jq -r '.id' 2>/dev/null || echo "")

if [ -z "$TABLE_ID" ] || [ "$TABLE_ID" = "null" ]; then
    echo -e "${RED}创建数据表失败，无法继续测试${NC}"
    exit 1
fi

echo "数据表 ID: $TABLE_ID"
echo ""

# 3. 查询数据表列表
test_api "查询数据表列表（按租户）" "GET" "/data-tables" \
    "" \
    "-H \"tenant_id: test-tenant\"" > /dev/null

test_api "查询数据表列表（按数据源）" "GET" "/data-tables/by-data-source?data_source_id=$DATA_SOURCE_ID" \
    "" \
    "-H \"tenant_id: test-tenant\"" > /dev/null

# 4. 查询数据表详情
test_api "查询数据表详情" "GET" "/data-tables/$TABLE_ID" \
    "" \
    "-H \"tenant_id: test-tenant\"" > /dev/null

# 5. 批量创建字段
echo "=========================================="
echo "3. 数据表字段测试"
echo "=========================================="
echo ""

test_api "批量创建字段" "POST" "/data-table-columns/batch" \
    "{
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
            },
            {
                \"column_index\": 2,
                \"name\": \"order_date\",
                \"desc\": \"订单日期\",
                \"data_type\": \"date\",
                \"nullable\": false,
                \"partitioner\": true
            },
            {
                \"column_index\": 3,
                \"name\": \"amount\",
                \"desc\": \"订单金额\",
                \"data_type\": \"decimal(10,2)\",
                \"nullable\": false,
                \"default_value\": \"0.00\",
                \"partitioner\": false
            }
        ]
    }" > /dev/null

# 6. 查询字段列表
COLUMNS_RESPONSE=$(test_api "查询字段列表" "GET" "/data-table-columns?data_table_id=$TABLE_ID")

COLUMN_ID=$(echo "$COLUMNS_RESPONSE" | jq -r '.[0].id' 2>/dev/null || echo "")

if [ -n "$COLUMN_ID" ] && [ "$COLUMN_ID" != "null" ]; then
    # 7. 查询字段详情
    test_api "查询字段详情" "GET" "/data-table-columns/$COLUMN_ID" > /dev/null
    
    # 8. 更新字段
    test_api "更新字段" "PUT" "/data-table-columns/$COLUMN_ID" \
        "{
            \"desc\": \"订单唯一标识（更新）\"
        }" > /dev/null
fi

# 9. 创建统计信息
echo "=========================================="
echo "4. 数据表统计测试"
echo "=========================================="
echo ""

test_api "Upsert 统计信息" "POST" "/data-table-usages/upsert" \
    "{
        \"data_table_id\": \"$TABLE_ID\",
        \"row_count\": 1000000,
        \"partition_count\": 10,
        \"storage_size\": 52428800
    }" > /dev/null

# 10. 查询统计信息
USAGE_RESPONSE=$(test_api "查询统计信息（按数据表）" "GET" "/data-table-usages/by-table?data_table_id=$TABLE_ID")

USAGE_ID=$(echo "$USAGE_RESPONSE" | jq -r '.id' 2>/dev/null || echo "")

if [ -n "$USAGE_ID" ] && [ "$USAGE_ID" != "null" ]; then
    # 11. 更新统计信息
    test_api "更新统计信息" "PUT" "/data-table-usages/$USAGE_ID" \
        "{
            \"row_count\": 1500000,
            \"storage_size\": 78643200
        }" > /dev/null
fi

# 12. 查询完整信息
echo "=========================================="
echo "5. 查询完整信息"
echo "=========================================="
echo ""

test_api "查询数据表完整信息（包含字段和统计）" "GET" "/data-tables/$TABLE_ID/details" \
    "" \
    "-H \"tenant_id: test-tenant\"" > /dev/null

# 13. 清理测试数据（可选）
echo "=========================================="
echo "6. 清理测试数据"
echo "=========================================="
echo ""

read -p "是否删除测试数据？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -n "$COLUMN_ID" ] && [ "$COLUMN_ID" != "null" ]; then
        test_api "删除字段" "DELETE" "/data-table-columns/$COLUMN_ID" > /dev/null
    fi
    
    if [ -n "$USAGE_ID" ] && [ "$USAGE_ID" != "null" ]; then
        test_api "删除统计信息" "DELETE" "/data-table-usages/$USAGE_ID" > /dev/null
    fi
    
    test_api "删除数据表" "DELETE" "/data-tables/$TABLE_ID" \
        "" \
        "-H \"tenant_id: test-tenant\"" > /dev/null
    
    echo -e "${GREEN}测试数据已清理${NC}"
else
    echo "保留测试数据"
    echo "数据表 ID: $TABLE_ID"
fi

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
