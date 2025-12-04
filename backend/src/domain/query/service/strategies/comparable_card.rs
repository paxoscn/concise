use async_trait::async_trait;
use serde_json::{json, Value};
use sqlx::{Column, Row, TypeInfo};

use crate::domain::query::{QueryStrategy, QueryContext, QueryError};

pub struct ComparableCardStrategy;

impl ComparableCardStrategy {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl QueryStrategy for ComparableCardStrategy {
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError> {
        // Example: Get the first available data source
        let (ds_name, pool) = context.data_sources.iter().next()
            .ok_or_else(|| QueryError::DatabaseError("No data sources available".to_string()))?;

        let built = context.build_query()?;
        let mut query = sqlx::query(&built.sql);
        println!("sql = {}", &built.sql);
        for param_name in &built.param_names {
            println!("param_name = {}", param_name.clone());
            query = context.bind_param(query, param_name)?;
        }
        let rows = query.fetch_all(pool).await
            .map_err(|e| QueryError::ExecutionError(format!("Query failed: {}", e)))?;

        // Extract column names
        let columns: Vec<String> = if let Some(first_row) = rows.first() {
            first_row.columns().iter()
                .map(|col| col.name().to_string())
                .collect()
        } else {
            Vec::new()
        };

        // Convert rows to JSON array
        let mut json_rows = Vec::new();
        for row in rows {
            let mut row_map = serde_json::Map::new();
            for (i, column) in row.columns().iter().enumerate() {
                let column_name = column.name();
                println!("type = {}", column.type_info().name());
                let value: Value = match column.type_info().name() {
                    "TEXT" | "VARCHAR" | "CHAR" => {
                        row.try_get::<Option<String>, _>(i)
                            .unwrap_or(None)
                            .map(Value::String)
                            .unwrap_or(Value::Null)
                    },
                    "INTEGER" | "INT" | "BIGINT" | "INT8" => {
                        row.try_get::<Option<i64>, _>(i)
                            .unwrap_or(None)
                            .map(|v| Value::Number(v.into()))
                            .unwrap_or(Value::Null)
                    },
                    "FLOAT4" => {
                        row.try_get::<Option<f32>, _>(i)
                            .unwrap_or(None)
                            .and_then(|v| serde_json::Number::from_f64(v.into()))
                            .map(Value::Number)
                            .unwrap_or(Value::Null)
                    },
                    "REAL" | "DOUBLE" | "FLOAT" | "FLOAT8" => {
                        row.try_get::<Option<f64>, _>(i)
                            .unwrap_or(None)
                            .and_then(|v| serde_json::Number::from_f64(v))
                            .map(Value::Number)
                            .unwrap_or(Value::Null)
                    },
                    "BOOLEAN" => {
                        row.try_get::<Option<bool>, _>(i)
                            .unwrap_or(None)
                            .map(Value::Bool)
                            .unwrap_or(Value::Null)
                    },
                    _ => Value::Null,
                };
                row_map.insert(column_name.to_string(), value);
            }
            json_rows.push(Value::Object(row_map));
        }

        // Build response
        let result = json!({
            "columns": columns,
            "rows": json_rows
        });

        Ok(result)
    }
}
