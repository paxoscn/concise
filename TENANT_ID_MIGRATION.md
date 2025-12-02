# 租户ID功能实现说明

## 概述
为数据源（data_sources）、存储（storages）和用户（users）表添加了租户ID（tenant_id）列，实现多租户数据隔离。

## 数据库变更

### 迁移文件
创建了三个新的数据库迁移文件：

1. **m20241202_000001_add_tenant_id_to_data_sources.rs**
   - 为 `data_sources` 表添加 `tenant_id` 列（VARCHAR(36)）
   - 创建索引 `idx_data_sources_tenant_id` 提高查询性能

2. **m20241202_000002_add_tenant_id_to_storages.rs**
   - 为 `storages` 表添加 `tenant_id` 列（VARCHAR(36)）
   - 创建索引 `idx_storages_tenant_id` 提高查询性能

3. **m20241202_000003_add_tenant_id_to_users.rs**
   - 为 `users` 表添加 `tenant_id` 列（VARCHAR(36)）
   - 创建索引 `idx_users_tenant_id` 提高查询性能

### 运行迁移
```bash
cd backend
cargo run --bin migration
```

## 代码变更

### 1. 实体层（Entities）
更新了三个实体模型，添加 `tenant_id` 字段：
- `backend/src/entities/data_source.rs`
- `backend/src/entities/storage.rs`
- `backend/src/entities/user.rs`

### 2. Repository层
为数据源和存储的 Repository 添加了按租户查询的方法：
- `DataSourceRepository::find_by_tenant(tenant_id: &str)`
- `StorageRepository::find_by_tenant(tenant_id: &str)`

### 3. Domain层

#### 认证服务（Auth）
- 更新 `UserClaims` 结构，添加 `tenant_id` 字段
- 更新 `generate_jwt_token` 函数，在JWT中包含租户ID
- 更新 `AuthService::login` 方法，从用户信息中获取租户ID并生成JWT

#### 数据源服务（DataSource）
- `CreateDataSourceRequest` 添加 `tenant_id` 字段（标记为 `skip_deserializing`）
- `create` 方法验证并使用租户ID
- 新增 `list_by_tenant` 方法，按租户查询数据源

#### 存储服务（Storage）
- `CreateStorageRequest` 添加 `tenant_id` 字段（标记为 `skip_deserializing`）
- `create` 方法验证并使用租户ID
- 新增 `list_by_tenant` 方法，按租户查询存储

#### 错误处理
- `ServiceError` 添加 `Unauthorized` 变体

### 4. API层
更新了数据源和存储的API处理函数：

#### 列表查询
- 从JWT claims中提取 `tenant_id`
- 调用 `list_by_tenant` 方法，只返回当前租户的数据

#### 创建操作
- 从JWT claims中提取 `tenant_id`
- 自动设置请求的 `tenant_id` 字段
- 确保创建的资源属于当前租户

## 安全性
1. **自动租户隔离**：所有列表查询自动过滤为当前租户的数据
2. **创建时自动关联**：创建资源时自动关联到当前用户的租户
3. **JWT验证**：所有API都通过JWT中间件验证，确保租户ID来自可信源
4. **防止跨租户访问**：租户ID从JWT中提取，用户无法通过请求参数修改

## 注意事项
1. 现有数据的 `tenant_id` 默认为空字符串，需要手动更新
2. 建议在生产环境运行迁移前备份数据库
3. 如果有现有用户，需要为他们分配租户ID
4. 更新操作（update）保持原有租户ID不变，防止跨租户修改

## 后续工作
1. 为现有数据分配租户ID
2. 考虑添加租户管理API
3. 添加超级管理员角色，可以跨租户查看数据
4. 为其他需要租户隔离的表添加 `tenant_id` 列
