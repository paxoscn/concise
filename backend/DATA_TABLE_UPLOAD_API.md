# 数据表上传 API 文档

## 概述

数据表上传 API 允许用户通过 Excel 文件上传数据到指定的数据表中。上传的数据会覆盖指定分区的现有数据。

## API 端点

### 上传数据到数据表

**端点**: `POST /api/v1/data-tables/{id}/upload`

**描述**: 上传 Excel 文件数据到指定的数据表，支持分区覆盖。

#### 请求参数

**路径参数**:
- `id` (string, required): 数据表 ID

**表单数据** (multipart/form-data):
- `file` (file, required): Excel 文件 (.xlsx 格式)
- `partition_<字段名>` (string, optional): 分区字段的值，格式为 `partition_字段名=字段值`

#### 请求示例

##### 使用 curl

```bash
# 不带分区字段
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@data.xlsx"

# 带单个分区字段
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@data.xlsx" \
  -F "partition_week=2024-W01"

# 带多个分区字段
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@data.xlsx" \
  -F "partition_week=2024-W01" \
  -F "partition_region=north"
```

##### 使用测试脚本

```bash
# 不带分区字段
./test_upload_data.sh table-123 data.xlsx

# 带分区字段
./test_upload_data.sh table-123 data.xlsx week=2024-W01 region=north
```

##### 使用 JavaScript (fetch)

```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('partition_week', '2024-W01');
formData.append('partition_region', 'north');

const response = await fetch('http://localhost:8080/api/v1/data-tables/table-123/upload', {
  method: 'POST',
  body: formData
});

const result = await response.json();
console.log(result);
```

##### 使用 Python (requests)

```python
import requests

files = {'file': open('data.xlsx', 'rb')}
data = {
    'partition_week': '2024-W01',
    'partition_region': 'north'
}

response = requests.post(
    'http://localhost:8080/api/v1/data-tables/table-123/upload',
    files=files,
    data=data
)

print(response.json())
```

#### 响应

**成功响应** (200 OK):

```json
{
  "message": "Data uploaded successfully",
  "rows_inserted": 150
}
```

**错误响应**:

- `400 Bad Request`: 请求参数错误
  ```json
  {
    "error": "InvalidInput",
    "message": "File data is required"
  }
  ```

- `404 Not Found`: 数据表不存在
  ```json
  {
    "error": "NotFound",
    "message": "Data table not found"
  }
  ```

- `500 Internal Server Error`: 服务器内部错误
  ```json
  {
    "error": "InternalError",
    "message": "Failed to insert data: ..."
  }
  ```

## Excel 文件格式要求

### 基本要求

1. **文件格式**: 必须是 `.xlsx` 格式
2. **工作表**: 使用第一个工作表的数据
3. **表头**: 第一行必须是列名，列名必须与数据表定义的列名完全匹配
4. **数据行**: 从第二行开始是数据

### 列匹配规则

1. **非分区列**: Excel 文件必须包含所有非分区列
2. **分区列**: 分区列的值通过表单参数 `partition_<字段名>` 提供，不需要在 Excel 中包含
3. **列顺序**: Excel 中的列顺序可以与数据表定义的顺序不同
4. **额外列**: Excel 中可以包含额外的列，这些列会被忽略

### 示例

假设数据表定义如下：

| 列名 | 类型 | 是否分区列 |
|------|------|-----------|
| week | VARCHAR | 是 |
| region | VARCHAR | 是 |
| product_id | VARCHAR | 否 |
| product_name | VARCHAR | 否 |
| sales | DECIMAL | 否 |
| quantity | INTEGER | 否 |

Excel 文件格式（不包含分区列）：

| product_id | product_name | sales | quantity |
|------------|--------------|-------|----------|
| P001 | 产品A | 1000.50 | 10 |
| P002 | 产品B | 2500.00 | 25 |
| P003 | 产品C | 1500.75 | 15 |

上传时需要提供分区字段：
```bash
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@sales_data.xlsx" \
  -F "partition_week=2024-W01" \
  -F "partition_region=north"
```

## 数据覆盖逻辑

### 分区覆盖

上传数据时，系统会：

1. **删除现有数据**: 删除指定分区的所有现有数据
   - 如果提供了分区字段，只删除匹配的分区数据
   - 如果没有提供分区字段，删除整个表的数据

2. **插入新数据**: 将 Excel 文件中的所有数据插入到指定分区

### 示例场景

**场景 1: 更新特定分区**

```bash
# 第一次上传 2024-W01 北区数据
./test_upload_data.sh table-123 week01_north.xlsx week=2024-W01 region=north

# 第二次上传 2024-W01 北区数据（覆盖第一次的数据）
./test_upload_data.sh table-123 week01_north_updated.xlsx week=2024-W01 region=north

# 上传 2024-W01 南区数据（不影响北区数据）
./test_upload_data.sh table-123 week01_south.xlsx week=2024-W01 region=south
```

**场景 2: 全表覆盖**

```bash
# 如果数据表没有分区列，上传会覆盖整个表
./test_upload_data.sh table-456 all_data.xlsx
```

## 数据类型转换

系统会自动将 Excel 单元格的值转换为数据库字段类型：

| Excel 类型 | 数据库类型 | 转换规则 |
|-----------|-----------|---------|
| 文本 | VARCHAR/TEXT | 直接转换，单引号会被转义 |
| 数字 | INTEGER | 转换为整数 |
| 数字 | DECIMAL/FLOAT | 保持小数 |
| 布尔值 | BOOLEAN | true/false |
| 日期时间 | TIMESTAMP | 转换为 ISO 格式 |
| 空单元格 | 任意类型 | 转换为 NULL |

## 错误处理

### 常见错误及解决方法

1. **"File data is required"**
   - 原因: 没有上传文件
   - 解决: 确保表单中包含 `file` 字段

2. **"Data table has no columns defined"**
   - 原因: 数据表没有定义列
   - 解决: 先为数据表定义列结构

3. **"Missing partition value for column: xxx"**
   - 原因: 缺少必需的分区字段值
   - 解决: 添加 `partition_xxx` 参数

4. **"Column 'xxx' not found in Excel file"**
   - 原因: Excel 文件缺少必需的列
   - 解决: 在 Excel 文件中添加缺失的列

5. **"Failed to open Excel file"**
   - 原因: 文件格式不正确或文件损坏
   - 解决: 确保文件是有效的 .xlsx 格式

6. **"Failed to connect to target database"**
   - 原因: 数据源连接配置错误
   - 解决: 检查数据源的连接配置

7. **"Failed to insert data"**
   - 原因: 数据类型不匹配或违反约束
   - 解决: 检查 Excel 数据是否符合数据表的约束条件

## 性能考虑

### 大文件上传

- **推荐**: 单次上传不超过 10,000 行
- **原因**: 每行数据都会执行一次 INSERT 语句
- **优化**: 对于大量数据，考虑分批上传

### 并发上传

- **支持**: 可以并发上传到不同的分区
- **注意**: 不要并发上传到同一个分区，可能导致数据不一致

## 安全注意事项

1. **SQL 注入防护**: 系统会自动转义特殊字符
2. **文件大小限制**: 建议在反向代理（如 Nginx）中设置文件大小限制
3. **权限控制**: 建议添加 JWT 认证中间件保护此接口

## 完整工作流程

```
1. 用户准备 Excel 文件
   ↓
2. 调用上传 API
   ↓
3. 系统验证数据表和列定义
   ↓
4. 系统解析 Excel 文件
   ↓
5. 系统验证列匹配
   ↓
6. 系统连接到目标数据库
   ↓
7. 系统删除指定分区的现有数据
   ↓
8. 系统逐行插入新数据
   ↓
9. 返回插入行数
```

## 相关 API

- `GET /api/v1/data-tables/{id}`: 获取数据表信息
- `GET /api/v1/data-tables/{id}/details`: 获取数据表详细信息（包含列定义）
- `GET /api/v1/data-table-columns?data_table_id={id}`: 获取数据表的列定义
