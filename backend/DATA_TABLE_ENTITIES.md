# 数据表实体说明

本文档描述了新增的三个数据表相关实体。

## 实体概览

### 1. data_tables (数据表)

存储数据源中的数据表信息。

**字段说明：**

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | String(72) | 主键ID | NOT NULL, PRIMARY KEY |
| tenant_id | String(36) | 租户ID | NOT NULL |
| data_source_id | String(36) | 数据源ID | NOT NULL |
| name | String(200) | 数据表名称 | NOT NULL |
| desc | Text | 数据表描述 | NULL |
| created_at | Timestamp | 创建时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | Timestamp | 更新时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

**索引：**
- `idx_data_tables_tenant_datasource`: (tenant_id, data_source_id)
- `idx_data_tables_tenant_datasource_name`: (tenant_id, data_source_id, name) - UNIQUE

### 2. data_table_columns (数据表字段)

存储数据表的字段信息。

**字段说明：**

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | String(72) | 主键ID | NOT NULL, PRIMARY KEY |
| data_table_id | String(72) | 数据表ID | NOT NULL |
| column_index | Integer | 字段在数据表中的序号(从0开始) | NOT NULL |
| name | String(200) | 字段名称 | NOT NULL |
| desc | Text | 字段描述 | NULL |
| data_type | String(100) | 字段数据类型 | NOT NULL |
| nullable | Boolean | 字段是否允许为空 | NOT NULL, DEFAULT true |
| default_value | Text | 字段默认值 | NULL |
| partitioner | Boolean | 是否分区字段 | NOT NULL, DEFAULT false |
| created_at | Timestamp | 创建时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | Timestamp | 更新时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

**索引：**
- `idx_data_table_columns_table_id`: (data_table_id)
- `idx_data_table_columns_table_index`: (data_table_id, column_index) - UNIQUE
- `idx_data_table_columns_table_name`: (data_table_id, name) - UNIQUE

### 3. data_table_usages (数据表统计)

存储数据表的使用统计信息。

**字段说明：**

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | String(72) | 主键ID | NOT NULL, PRIMARY KEY |
| data_table_id | String(72) | 数据表ID | NOT NULL |
| row_count | BigInteger | 行数 | NOT NULL, DEFAULT 0 |
| partition_count | Integer | 分区数 | NOT NULL, DEFAULT 0 |
| storage_size | BigInteger | 存储占用(Byte) | NOT NULL, DEFAULT 0 |
| created_at | Timestamp | 创建时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | Timestamp | 更新时间 | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

**索引：**
- `idx_data_table_usages_table_id`: (data_table_id) - UNIQUE (一个表只有一条统计记录)

## 实体关系

```
data_sources (1) ----< (N) data_tables
data_tables (1) ----< (N) data_table_columns
data_tables (1) ---- (1) data_table_usages
```

## 迁移文件

新增的迁移文件：
- `m20241226_000001_create_data_tables_table.rs`
- `m20241226_000002_create_data_table_columns_table.rs`
- `m20241226_000003_create_data_table_usages_table.rs`

## 实体模型文件

新增的实体模型文件：
- `backend/src/entities/data_table.rs`
- `backend/src/entities/data_table_column.rs`
- `backend/src/entities/data_table_usage.rs`

## 使用说明

1. **自动迁移**: 当应用启动时，数据库迁移会自动执行，创建这三张表。

2. **手动迁移**: 如需手动执行迁移：
   ```bash
   cd backend/migration
   cargo run -- up
   ```

3. **实体使用**: 在代码中使用这些实体：
   ```rust
   use crate::entities::{DataTable, DataTableColumn, DataTableUsage};
   ```

## 设计说明

1. **租户隔离**: `data_tables` 表包含 `tenant_id` 字段，支持多租户数据隔离。

2. **唯一性约束**: 
   - 同一租户下，同一数据源中的表名必须唯一
   - 同一数据表中，字段序号和字段名必须唯一

3. **字段顺序**: `column_index` 从0开始，保证字段在表中的顺序。

4. **统计信息**: `data_table_usages` 与 `data_tables` 是一对一关系，每个表只有一条统计记录。

5. **分区支持**: `partitioner` 字段标识该字段是否为分区字段，支持分区表的元数据管理。
