# 数据查询接口文档

## 概述

数据查询接口提供了一个灵活的查询系统，可以根据不同的视图（view）选择不同的查询策略来处理数据请求。

## 接口信息

- **路径**: `POST /api/v1/query`
- **认证**: 不需要JWT认证，使用 `tenant_id` header
- **Content-Type**: `application/json`

## 请求格式

### Headers
```
tenant_id: <租户ID>
```

### Body
```json
{
  "view": "视图名称",
  "params": {
    "参数名": "参数值"
  },
  "spec": {
    "规格字段": "规格值"
  }
}
```

## 请求示例

```bash
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

## 响应格式

```json
{
  "data": {
    "view": "comparable_card",
    "tenant_id": "1",
    "data_source": "数据源名称",
    "params": {
      "start": "20250101",
      "end": "20250201"
    },
    "spec": {
      "xxx": "yyy"
    },
    "result": {
      // 查询结果数据
    }
  }
}
```

## 错误响应

```json
{
  "error": "错误信息"
}
```

### 错误码

- `400 Bad Request`: 参数错误或缺少必需参数
- `404 Not Found`: 指定的视图策略不存在
- `500 Internal Server Error`: 数据库错误或查询执行错误

## 添加新的查询策略

### 1. 创建策略文件

在 `backend/src/domain/query/service/strategies/` 目录下创建新的策略文件，例如 `my_strategy.rs`:

```rust
use async_trait::async_trait;
use serde_json::{json, Value};
use sqlx::Row;

use crate::domain::query::{QueryStrategy, QueryContext, QueryError};

pub struct MyStrategy;

impl MyStrategy {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl QueryStrategy for MyStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // 1. 提取参数
        let param1 = context.params.get("param1")
            .and_then(|v| v.as_str())
            .ok_or_else(|| QueryError::InvalidInput("Missing 'param1'".to_string()))?;

        // 2. 获取数据源连接
        let (ds_name, pool) = context.data_sources.iter().next()
            .ok_or_else(|| QueryError::DatabaseError("No data sources".to_string()))?;

        // 3. 执行查询
        let query = "SELECT * FROM my_table WHERE field = $1";
        let rows = sqlx::query(query)
            .bind(param1)
            .fetch_all(pool)
            .await
            .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;

        // 4. 处理结果
        let result = json!({
            "view": "my_view",
            "tenant_id": context.tenant_id,
            "result": {
                "count": rows.len()
            }
        });

        Ok(result)
    }
}
```

### 2. 注册策略

在 `backend/src/domain/query/service/strategies/mod.rs` 中导出新策略：

```rust
mod comparable_card;
mod my_strategy;  // 添加这行

pub use comparable_card::ComparableCardStrategy;
pub use my_strategy::MyStrategy;  // 添加这行
```

### 3. 在服务中注册

在 `backend/src/domain/query/service.rs` 的 `QueryService::new()` 方法中注册策略：

```rust
use strategies::{ComparableCardStrategy, MyStrategy};  // 导入

pub fn new(data_source_service: Arc<DataSourceService>) -> Self {
    let mut strategies: HashMap<String, Box<dyn QueryStrategy>> = HashMap::new();
    
    strategies.insert(
        "comparable_card".to_string(),
        Box::new(ComparableCardStrategy::new()),
    );
    
    // 添加新策略
    strategies.insert(
        "my_view".to_string(),
        Box::new(MyStrategy::new()),
    );

    Self {
        data_source_service,
        strategies,
    }
}
```

## QueryContext 说明

每个策略都会接收一个 `QueryContext` 对象，包含：

- `data_sources`: `HashMap<String, Pool<Postgres>>` - 租户下所有数据源名称到数据库连接池的映射
- `tenant_id`: `String` - 租户ID
- `params`: `Value` - 请求中的 params 对象
- `spec`: `Value` - 请求中的 spec 对象

## 数据源配置

数据源的连接配置存储在 `data_sources` 表中，`connection_config` 字段应包含：

```json
{
  "host": "localhost",
  "port": 5432,
  "database": "mydb",
  "username": "user",
  "password": "password"
}
```

## 现有策略

### comparable_card

用于可比卡片数据查询。

**参数**:
- `start`: 开始日期 (格式: YYYYMMDD)
- `end`: 结束日期 (格式: YYYYMMDD)

**示例**:
```json
{
  "view": "comparable_card",
  "params": {
    "start": "20250101",
    "end": "20250201"
  },
  "spec": {
    "xxx": "yyy"
  }
}
```
