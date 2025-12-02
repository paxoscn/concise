# 查询接口架构说明

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                         客户端请求                            │
│  POST /api/v1/query                                         │
│  Header: tenant_id=1                                        │
│  Body: { view, params, spec }                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    API 层 (query.rs)                         │
│  - 提取 tenant_id 从 header                                  │
│  - 解析请求 JSON                                             │
│  - 调用 QueryService                                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Domain 层 (QueryService)                        │
│  1. 根据 tenant_id 获取所有数据源                             │
│  2. 为每个数据源创建数据库连接池                               │
│  3. 根据 view 选择对应的策略                                  │
│  4. 构建 QueryContext                                        │
│  5. 执行策略                                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   策略层 (Strategies)                        │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ ComparableCard   │  │  其他策略...      │                │
│  │ Strategy         │  │                  │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                             │
│  每个策略:                                                   │
│  - 接收 QueryContext                                        │
│  - 验证参数                                                  │
│  - 执行数据库查询                                            │
│  - 返回 JSON 结果                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    数据库连接池                               │
│  HashMap<String, Pool<Postgres>>                            │
│  - 数据源名称 -> PostgreSQL 连接池                            │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构

```
backend/src/
├── api/
│   ├── query.rs                    # 查询接口 HTTP 处理
│   └── mod.rs
├── domain/
│   ├── query/
│   │   ├── mod.rs                  # 模块导出
│   │   ├── error.rs                # 错误定义
│   │   ├── strategy.rs             # 策略 trait 定义
│   │   └── service/
│   │       ├── service.rs          # QueryService 实现
│   │       └── strategies/
│   │           ├── mod.rs          # 策略模块导出
│   │           ├── comparable_card.rs  # 可比卡片策略
│   │           └── example_strategy.rs # 示例策略
│   └── mod.rs
└── main.rs                         # 路由注册
```

## 核心组件

### 1. QueryService

负责：
- 管理所有查询策略
- 获取租户的数据源
- 创建数据库连接池
- 分发查询请求到对应策略

### 2. QueryStrategy Trait

所有策略必须实现的接口：
```rust
#[async_trait]
pub trait QueryStrategy: Send + Sync {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError>;
}
```

### 3. QueryContext

传递给策略的上下文信息：
```rust
pub struct QueryContext {
    pub data_sources: HashMap<String, Pool<Postgres>>,  // 数据源连接池
    pub tenant_id: String,                               // 租户ID
    pub params: Value,                                   // 查询参数
    pub spec: Value,                                     // 查询规格
}
```

### 4. 策略实现

每个策略是一个独立的 Rust 文件，实现 `QueryStrategy` trait。

## 数据流

1. **请求到达**: 客户端发送 POST 请求到 `/api/v1/query`
2. **提取租户**: 从 header 中提取 `tenant_id`
3. **获取数据源**: 查询数据库获取该租户的所有数据源配置
4. **建立连接**: 为每个数据源创建 PostgreSQL 连接池
5. **选择策略**: 根据 `view` 字段选择对应的查询策略
6. **执行查询**: 策略使用连接池执行数据库查询
7. **返回结果**: 将查询结果封装为 JSON 返回

## 扩展性

### 添加新策略

1. 在 `strategies/` 目录创建新文件
2. 实现 `QueryStrategy` trait
3. 在 `strategies/mod.rs` 中导出
4. 在 `QueryService::new()` 中注册

### 支持多种数据库

当前实现使用 PostgreSQL，如需支持其他数据库：
1. 修改 `QueryContext` 使用枚举或 trait object
2. 在 `QueryService` 中根据 `db_type` 创建不同类型的连接
3. 策略中使用统一的查询接口

## 安全考虑

- **无 JWT 认证**: 接口不需要 JWT，仅通过 `tenant_id` header 隔离
- **租户隔离**: 每个租户只能访问自己的数据源
- **SQL 注入防护**: 使用参数化查询（`$1`, `$2` 等）
- **连接池管理**: 限制每个数据源的最大连接数

## 性能优化

- **连接池复用**: 每次查询创建新的连接池（可优化为缓存）
- **并发查询**: 策略可以并发查询多个数据源
- **查询超时**: 可添加查询超时机制
- **结果缓存**: 可添加 Redis 缓存层

## 错误处理

所有错误通过 `QueryError` 枚举统一处理：
- `InvalidInput`: 参数错误 (400)
- `StrategyNotFound`: 策略不存在 (404)
- `DatabaseError`: 数据库错误 (500)
- `ExecutionError`: 执行错误 (500)
- `InternalError`: 内部错误 (500)
