# 查询接口快速开始

## 快速测试

### 1. 启动服务

```bash
cd backend
cargo run
```

### 2. 测试接口

```bash
# 使用测试脚本
./test_query_api.sh

# 或手动测试
curl -X POST http://localhost:8080/api/v1/query \
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
  }'
```

## 添加新策略（3步）

### 步骤 1: 创建策略文件

创建 `backend/src/domain/query/service/strategies/my_view.rs`:

```rust
use async_trait::async_trait;
use serde_json::{json, Value};
use crate::domain::query::{QueryStrategy, QueryContext, QueryError};

pub struct MyViewStrategy;

impl MyViewStrategy {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl QueryStrategy for MyViewStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // 你的查询逻辑
        Ok(json!({
            "view": "my_view",
            "result": {}
        }))
    }
}
```

### 步骤 2: 导出策略

编辑 `backend/src/domain/query/service/strategies/mod.rs`:

```rust
mod comparable_card;
mod my_view;  // 添加

pub use comparable_card::ComparableCardStrategy;
pub use my_view::MyViewStrategy;  // 添加
```

### 步骤 3: 注册策略

编辑 `backend/src/domain/query/service.rs`:

```rust
use strategies::{ComparableCardStrategy, MyViewStrategy};  // 导入

impl QueryService {
    pub fn new(data_source_service: Arc<DataSourceService>) -> Self {
        let mut strategies: HashMap<String, Box<dyn QueryStrategy>> = HashMap::new();
        
        strategies.insert("comparable_card".to_string(), Box::new(ComparableCardStrategy::new()));
        strategies.insert("my_view".to_string(), Box::new(MyViewStrategy::new()));  // 添加
        
        Self { data_source_service, strategies }
    }
}
```

完成！重启服务后即可使用新策略。

## 常见查询模式

### 模式 1: 单数据源查询

```rust
let (ds_name, pool) = context.data_sources.iter().next()
    .ok_or_else(|| QueryError::DatabaseError("No data sources".to_string()))?;

let rows = sqlx::query("SELECT * FROM table WHERE id = $1")
    .bind(param)
    .fetch_all(pool)
    .await?;
```

### 模式 2: 多数据源查询

```rust
let mut results = Vec::new();

for (ds_name, pool) in &context.data_sources {
    let row = sqlx::query("SELECT COUNT(*) as cnt FROM table")
        .fetch_one(pool)
        .await?;
    
    results.push(json!({
        "data_source": ds_name,
        "count": row.get::<i64, _>("cnt")
    }));
}
```

### 模式 3: 参数验证

```rust
// 必需参数
let start = context.params.get("start")
    .and_then(|v| v.as_str())
    .ok_or_else(|| QueryError::InvalidInput("Missing 'start'".to_string()))?;

// 可选参数
let limit = context.params.get("limit")
    .and_then(|v| v.as_i64())
    .unwrap_or(100);

// Spec 字段
let fields = context.spec.get("fields")
    .and_then(|v| v.as_array())
    .ok_or_else(|| QueryError::InvalidInput("Invalid 'fields'".to_string()))?;
```

## 文档

- [API 文档](./QUERY_API.md) - 接口使用说明
- [架构文档](./QUERY_ARCHITECTURE.md) - 系统架构说明
- [示例策略](../src/domain/query/service/strategies/example_strategy.rs) - 完整示例

## 故障排查

### 问题: "Strategy not found"
- 检查 view 名称是否正确
- 确认策略已在 `QueryService::new()` 中注册

### 问题: "No data sources available"
- 检查租户是否有配置数据源
- 确认 tenant_id 正确

### 问题: "Failed to connect to database"
- 检查数据源的 connection_config 配置
- 确认数据库服务正在运行
- 验证网络连接和防火墙设置
