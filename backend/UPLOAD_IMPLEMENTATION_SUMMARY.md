# 数据上传功能实现总结

## 实现概述

为 `backend/src/api/data_table.rs` 添加了数据上传接口，支持通过 Excel 文件上传数据到指定的数据表分区。

## 核心功能

### 1. API 端点

- **路径**: `POST /api/v1/data-tables/{id}/upload`
- **功能**: 上传 Excel 文件数据到指定数据表
- **参数**:
  - `file`: Excel 文件 (.xlsx 格式)
  - `partition_<字段名>`: 分区字段值（可选，支持多个）

### 2. 主要特性

✅ **Excel 文件解析**: 使用 `calamine` 库解析 .xlsx 文件
✅ **列名自动匹配**: 根据表头自动匹配数据表列定义
✅ **分区覆盖**: 支持按分区字段覆盖数据
✅ **数据类型转换**: 自动转换 Excel 单元格类型到数据库类型
✅ **动态数据库连接**: 根据数据源配置动态连接目标数据库
✅ **错误处理**: 完善的错误提示和验证

## 修改的文件

### 1. `backend/src/api/data_table.rs`

**新增内容**:
- 导入 `Multipart` 用于处理文件上传
- 导入 `HashMap` 和 `Serialize` 用于处理分区参数
- 新增 `UploadResponse` 结构体
- 新增 `upload_data_handler` 处理函数
- 在路由中添加 `/upload` 端点

**关键代码**:
```rust
async fn upload_data_handler(
    State(state): State<DataTableAppState>,
    Path(id): Path<String>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, ServiceError>
```

### 2. `backend/src/domain/data_table.rs`

**新增内容**:
- 导入 `HashMap`, `calamine`, `Cursor` 等依赖
- 在 `DataTableService` 中添加 `data_source_repo` 字段
- 新增 `upload_data` 方法实现核心上传逻辑
- 新增 `convert_cell_value` 辅助方法处理类型转换

**关键逻辑**:
1. 验证数据表和列定义
2. 解析 Excel 文件
3. 验证列匹配
4. 连接目标数据库
5. 删除指定分区的现有数据
6. 逐行插入新数据

### 3. `backend/src/main.rs`

**修改内容**:
- 更新 `DataTableService::new()` 调用，添加 `data_source_repo` 参数

## 新增文件

### 1. `backend/test_upload_data.sh`

测试脚本，简化 API 调用：

```bash
./test_upload_data.sh <data_table_id> <excel_file> [partition_field=value ...]
```

### 2. `backend/DATA_TABLE_UPLOAD_API.md`

完整的 API 文档，包含：
- API 端点说明
- 请求/响应格式
- Excel 文件格式要求
- 数据覆盖逻辑
- 错误处理
- 性能考虑
- 安全注意事项

### 3. `backend/UPLOAD_EXAMPLE.md`

实际使用示例，包含：
- 销售数据上传示例
- 库存数据上传示例
- 多分区字段示例
- 常见问题解答
- 完整测试流程

## 技术实现细节

### 1. 文件上传处理

使用 Axum 的 `Multipart` 提取器处理 multipart/form-data：

```rust
while let Some(field) = multipart.next_field().await? {
    let name = field.name()?;
    if name == "file" {
        file_data = Some(field.bytes().await?.to_vec());
    } else if name.starts_with("partition_") {
        // 解析分区字段
    }
}
```

### 2. Excel 解析

使用 `calamine` 库解析 Excel：

```rust
let cursor = Cursor::new(file_data);
let mut workbook: Xlsx<_> = open_workbook_from_rs(cursor)?;
let range = workbook.worksheet_range(&sheet_name)?;
```

### 3. 数据类型转换

支持的类型转换：
- `Data::Empty` → `NULL`
- `Data::String` → `'escaped_string'`
- `Data::Float` → 数字或整数
- `Data::Int` → 整数
- `Data::Bool` → 布尔值
- `Data::DateTime` → 时间戳字符串

### 4. 分区覆盖

```rust
// 构建删除条件
let delete_sql = if delete_conditions.is_empty() {
    format!("DELETE FROM {}", table.name)
} else {
    format!("DELETE FROM {} WHERE {}", table.name, delete_conditions.join(" AND "))
};
```

### 5. 动态数据库连接

从数据源配置中提取连接信息：

```rust
let connection_string = format!(
    "postgres://{}:{}@{}:{}/{}",
    username, password, host, port, database
);
let target_db = Database::connect(&connection_string).await?;
```

## 使用示例

### 基本用法

```bash
# 上传到无分区表
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@data.xlsx"

# 上传到分区表
curl -X POST http://localhost:8080/api/v1/data-tables/table-123/upload \
  -F "file=@data.xlsx" \
  -F "partition_week=2024-W01" \
  -F "partition_region=north"
```

### 使用测试脚本

```bash
./test_upload_data.sh table-123 data.xlsx week=2024-W01 region=north
```

## 依赖项

已在 `Cargo.toml` 中包含的依赖：
- `axum` (with `multipart` feature) - Web 框架和文件上传
- `calamine` - Excel 文件解析
- `sea-orm` - 数据库 ORM
- `serde` - 序列化/反序列化

## 错误处理

实现了完善的错误处理：
- 文件格式验证
- 列匹配验证
- 分区字段验证
- 数据库连接错误
- 数据插入错误

所有错误都会返回清晰的错误消息。

## 性能考虑

### 当前实现

- 逐行插入数据
- 适合中小规模数据（< 10,000 行）

### 未来优化方向

1. **批量插入**: 使用 `INSERT INTO ... VALUES (...), (...), ...` 批量插入
2. **事务处理**: 将删除和插入操作包装在事务中
3. **异步处理**: 对于大文件，返回任务 ID，异步处理上传
4. **进度反馈**: 提供上传进度查询接口

## 安全考虑

### 已实现

- SQL 注入防护（字符串转义）
- 文件类型验证（仅支持 .xlsx）

### 建议添加

1. **JWT 认证**: 添加认证中间件保护接口
2. **文件大小限制**: 在 Nginx 或应用层限制文件大小
3. **租户隔离**: 验证用户只能上传到自己租户的表
4. **速率限制**: 防止滥用

## 测试建议

### 单元测试

- Excel 解析逻辑
- 数据类型转换
- 列匹配验证

### 集成测试

- 完整上传流程
- 分区覆盖逻辑
- 错误场景处理

### 性能测试

- 不同大小文件的上传时间
- 并发上传测试
- 内存使用情况

## 后续改进

1. **支持更多文件格式**: CSV, JSON, Parquet
2. **数据验证**: 添加数据质量检查
3. **增量更新**: 支持 UPSERT 操作
4. **数据预览**: 上传前预览数据
5. **回滚功能**: 支持撤销上传操作
6. **审计日志**: 记录上传操作历史

## 总结

成功实现了一个功能完整的数据上传接口，支持：
- ✅ Excel 文件上传
- ✅ 分区字段支持
- ✅ 自动列匹配
- ✅ 数据类型转换
- ✅ 分区覆盖
- ✅ 完善的错误处理
- ✅ 详细的文档和示例

代码已通过编译检查，可以直接使用。
