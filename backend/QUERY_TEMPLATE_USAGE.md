# Query Template Usage

## Overview

The `QueryContext::build_query()` method allows you to generate SQL queries from templates defined in the spec with dynamic parameter binding.

## Template Syntax

### Basic Parameter Substitution

Use `{param_name}` to insert parameters. They will be replaced with PostgreSQL placeholders (`$1`, `$2`, etc.) and automatically bound.

```sql
SELECT * FROM users WHERE id = {user_id} AND status = {status}
```

With params:
```json
{
  "user_id": "123",
  "status": "active"
}
```

Generates:
```sql
SELECT * FROM users WHERE id = $1 AND status = $2
```

### Conditional Blocks

Use `<param_name:content>` to include content only when a parameter exists.

```sql
SELECT * FROM products 
WHERE category = {category}
<min_price:AND price >= {min_price}>
<max_price:AND price <= {max_price}>
```

With params:
```json
{
  "category": "electronics",
  "min_price": "100"
}
```

Generates:
```sql
SELECT * FROM products 
WHERE category = $1
AND price >= $2
```

Note: `max_price` condition is excluded because the parameter doesn't exist.

## Usage Example

### In a Query Strategy

```rust
use crate::domain::query::{QueryStrategy, QueryContext, QueryError};
use async_trait::async_trait;
use serde_json::Value;

pub struct MyStrategy;

#[async_trait]
impl QueryStrategy for MyStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // Get the data source pool
        let (ds_name, pool) = context.data_sources.iter().next()
            .ok_or_else(|| QueryError::DatabaseError("No data sources available".to_string()))?;

        // Build the query from spec.sql template
        let built = context.build_query()?;
        
        // Create sqlx query
        let mut query = sqlx::query(&built.sql);
        
        // Bind all parameters in order
        for param_name in &built.param_names {
            query = context.bind_param(query, param_name)?;
        }
        
        // Execute the query
        let rows = query.fetch_all(pool).await
            .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;
        
        // Process results...
        Ok(serde_json::json!({ "rows": rows.len() }))
    }
}
```

### Spec Example

```json
{
  "sql": "SELECT IF(s.shop_name = '', 'self', s.shop_name) merchant_name, SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount FROM default_datasource.dwd_rival_stats_distincted_di_1d s WHERE s.date_str BETWEEN {start} AND {end} AND s.category_level1 = {category_level1} <shop_names:AND s.shop_name IN {shop_names}> GROUP BY s.shop_name"
}
```

### Params Example 1 (without shop_names)

```json
{
  "start": "20250101",
  "end": "20250201",
  "category_level1": "1"
}
```

Generated SQL:
```sql
SELECT IF(s.shop_name = '', 'self', s.shop_name) merchant_name,
       SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount
FROM default_datasource.dwd_rival_stats_distincted_di_1d s
WHERE s.date_str BETWEEN $1 AND $2
  AND s.category_level1 = $3
GROUP BY s.shop_name
```

Bindings: `["20250101", "20250201", "1"]`

### Params Example 2 (with shop_names)

```json
{
  "start": "20250101",
  "end": "20250201",
  "category_level1": "1",
  "shop_names": ["shop1", "shop2"]
}
```

Generated SQL:
```sql
SELECT IF(s.shop_name = '', 'self', s.shop_name) merchant_name,
       SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount
FROM default_datasource.dwd_rival_stats_distincted_di_1d s
WHERE s.date_str BETWEEN $1 AND $2
  AND s.category_level1 = $3
  AND s.shop_name IN $4
GROUP BY s.shop_name
```

Bindings: `["20250101", "20250201", "1", ["shop1", "shop2"]]`

## Supported Parameter Types

- `String`: Bound as string
- `Number`: Bound as i64 or f64
- `Boolean`: Bound as bool
- `Array`: Bound as Vec<String> (useful for IN clauses)
- `Null`: Bound as None

## Error Handling

The method returns `QueryError` in these cases:
- Missing `sql` field in spec
- Invalid regex pattern (shouldn't happen with hardcoded patterns)
- Missing required parameter referenced in template
- Unsupported parameter type (e.g., nested objects)
