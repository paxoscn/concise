#!/bin/bash

# 测试数据查询接口

BASE_URL="http://localhost:8080/api/v1"

echo "=== 测试数据查询接口 ==="
echo ""

# 测试 comparable_card 视图
echo "1. 测试 comparable_card 视图"
curl -X POST "${BASE_URL}/query" \
  -H "Content-Type: application/json" \
  -H "tenant_id: 1" \
  -d '{
    "view": "comparable_card",
    "params": {
      "start": "20250101",
      "end": "20250201"
    },
    "spec": {
      "xxx": "yyy"
    }
  }' | jq .

echo -e "\n"

# 测试缺少 tenant_id header
echo "2. 测试缺少 tenant_id header (应该返回错误)"
curl -X POST "${BASE_URL}/query" \
  -H "Content-Type: application/json" \
  -d '{
    "view": "comparable_card",
    "params": {
      "start": "20250101",
      "end": "20250201"
    },
    "spec": {}
  }' | jq .

echo -e "\n"

# 测试不存在的视图
echo "3. 测试不存在的视图 (应该返回错误)"
curl -X POST "${BASE_URL}/query" \
  -H "Content-Type: application/json" \
  -H "tenant_id: 1" \
  -d '{
    "view": "non_existent_view",
    "params": {},
    "spec": {}
  }' | jq .

echo -e "\n"

# 测试缺少必需参数
echo "4. 测试缺少必需参数 (应该返回错误)"
curl -X POST "${BASE_URL}/query" \
  -H "Content-Type: application/json" \
  -H "tenant_id: 1" \
  -d '{
    "view": "comparable_card",
    "params": {
      "start": "20250101"
    },
    "spec": {}
  }' | jq .

echo -e "\n"
echo "=== 测试完成 ==="
