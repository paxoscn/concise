# 数据上传示例

## 示例 1: 销售数据上传

### 数据表定义

```json
{
  "id": "sales-table-001",
  "name": "sales_data",
  "columns": [
    {
      "name": "week",
      "data_type": "VARCHAR",
      "partitioner": true
    },
    {
      "name": "region",
      "data_type": "VARCHAR",
      "partitioner": true
    },
    {
      "name": "product_id",
      "data_type": "VARCHAR",
      "partitioner": false
    },
    {
      "name": "product_name",
      "data_type": "VARCHAR",
      "partitioner": false
    },
    {
      "name": "sales_amount",
      "data_type": "DECIMAL",
      "partitioner": false
    },
    {
      "name": "quantity",
      "data_type": "INTEGER",
      "partitioner": false
    }
  ]
}
```

### Excel 文件内容 (sales_2024w01_north.xlsx)

| product_id | product_name | sales_amount | quantity |
|------------|--------------|--------------|----------|
| P001 | 笔记本电脑 | 15000.00 | 3 |
| P002 | 鼠标 | 150.00 | 50 |
| P003 | 键盘 | 300.00 | 30 |
| P004 | 显示器 | 8000.00 | 10 |

### 上传命令

```bash
# 使用 curl
curl -X POST http://localhost:8080/api/v1/data-tables/sales-table-001/upload \
  -F "file=@sales_2024w01_north.xlsx" \
  -F "partition_week=2024-W01" \
  -F "partition_region=north"

# 使用测试脚本
./test_upload_data.sh sales-table-001 sales_2024w01_north.xlsx week=2024-W01 region=north
```

### 预期结果

```json
{
  "message": "Data uploaded successfully",
  "rows_inserted": 4
}
```

## 示例 2: 库存数据上传（无分区）

### 数据表定义

```json
{
  "id": "inventory-table-001",
  "name": "inventory",
  "columns": [
    {
      "name": "sku",
      "data_type": "VARCHAR",
      "partitioner": false
    },
    {
      "name": "warehouse",
      "data_type": "VARCHAR",
      "partitioner": false
    },
    {
      "name": "stock_quantity",
      "data_type": "INTEGER",
      "partitioner": false
    },
    {
      "name": "last_updated",
      "data_type": "TIMESTAMP",
      "partitioner": false
    }
  ]
}
```

### Excel 文件内容 (inventory.xlsx)

| sku | warehouse | stock_quantity | last_updated |
|-----|-----------|----------------|--------------|
| SKU001 | WH-A | 100 | 2024-01-15 10:30:00 |
| SKU002 | WH-A | 250 | 2024-01-15 10:30:00 |
| SKU003 | WH-B | 75 | 2024-01-15 10:30:00 |

### 上传命令

```bash
# 无分区字段，直接上传
curl -X POST http://localhost:8080/api/v1/data-tables/inventory-table-001/upload \
  -F "file=@inventory.xlsx"

# 使用测试脚本
./test_upload_data.sh inventory-table-001 inventory.xlsx
```

### 预期结果

```json
{
  "message": "Data uploaded successfully",
  "rows_inserted": 3
}
```

## 示例 3: 多分区字段

### 数据表定义

```json
{
  "id": "metrics-table-001",
  "name": "performance_metrics",
  "columns": [
    {
      "name": "year",
      "data_type": "INTEGER",
      "partitioner": true
    },
    {
      "name": "month",
      "data_type": "INTEGER",
      "partitioner": true
    },
    {
      "name": "department",
      "data_type": "VARCHAR",
      "partitioner": true
    },
    {
      "name": "metric_name",
      "data_type": "VARCHAR",
      "partitioner": false
    },
    {
      "name": "metric_value",
      "data_type": "DECIMAL",
      "partitioner": false
    }
  ]
}
```

### Excel 文件内容 (metrics_202401_sales.xlsx)

| metric_name | metric_value |
|-------------|--------------|
| revenue | 1500000.00 |
| orders | 3500 |
| avg_order_value | 428.57 |
| customer_satisfaction | 4.5 |

### 上传命令

```bash
# 三个分区字段
curl -X POST http://localhost:8080/api/v1/data-tables/metrics-table-001/upload \
  -F "file=@metrics_202401_sales.xlsx" \
  -F "partition_year=2024" \
  -F "partition_month=1" \
  -F "partition_department=sales"

# 使用测试脚本
./test_upload_data.sh metrics-table-001 metrics_202401_sales.xlsx \
  year=2024 month=1 department=sales
```

### 预期结果

```json
{
  "message": "Data uploaded successfully",
  "rows_inserted": 4
}
```

## 常见问题

### Q1: Excel 列顺序必须和数据表定义一致吗？

**A**: 不需要。系统会根据列名自动匹配，Excel 中的列可以是任意顺序。

### Q2: Excel 中可以有额外的列吗？

**A**: 可以。系统只会读取数据表定义中的列，额外的列会被忽略。

### Q3: 如果 Excel 中缺少某个非分区列会怎样？

**A**: 系统会返回错误，提示缺少必需的列。所有非分区列都必须在 Excel 中存在。

### Q4: 空单元格会如何处理？

**A**: 空单元格会被转换为 SQL 的 NULL 值。

### Q5: 如何更新特定分区的数据？

**A**: 上传时指定相同的分区字段值，系统会先删除该分区的所有数据，然后插入新数据。

### Q6: 可以同时上传多个分区吗？

**A**: 不可以。每次上传只能针对一个分区。如果需要上传多个分区，需要多次调用 API。

### Q7: 上传大文件时有什么限制？

**A**: 建议单次上传不超过 10,000 行。对于更大的数据集，建议分批上传。

## 完整测试流程

### 1. 创建数据表

```bash
curl -X POST http://localhost:8080/api/v1/data-tables \
  -H "Content-Type: application/json" \
  -d '{
    "data_source_id": "ds-001",
    "name": "test_table",
    "desc": "测试表"
  }'
```

### 2. 定义列结构

```bash
# 添加分区列
curl -X POST http://localhost:8080/api/v1/data-table-columns \
  -H "Content-Type: application/json" \
  -d '{
    "data_table_id": "test-table-001",
    "column_index": 0,
    "name": "date",
    "data_type": "DATE",
    "partitioner": true
  }'

# 添加数据列
curl -X POST http://localhost:8080/api/v1/data-table-columns \
  -H "Content-Type: application/json" \
  -d '{
    "data_table_id": "test-table-001",
    "column_index": 1,
    "name": "value",
    "data_type": "DECIMAL",
    "partitioner": false
  }'
```

### 3. 准备 Excel 文件

创建 `test_data.xlsx`，内容如下：

| value |
|-------|
| 100.5 |
| 200.3 |
| 150.7 |

### 4. 上传数据

```bash
./test_upload_data.sh test-table-001 test_data.xlsx date=2024-01-15
```

### 5. 验证数据

连接到目标数据库，查询数据：

```sql
SELECT * FROM test_table WHERE date = '2024-01-15';
```

预期结果：

| date | value |
|------|-------|
| 2024-01-15 | 100.5 |
| 2024-01-15 | 200.3 |
| 2024-01-15 | 150.7 |
