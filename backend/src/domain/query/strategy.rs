use async_trait::async_trait;
use serde_json::Value;
use sqlx::{Pool, Postgres};
use std::collections::HashMap;
use regex::Regex;

use super::error::QueryError;

/// QueryContext contains all the information needed for a query strategy
pub struct QueryContext {
    /// Map of data source name to database connection pool
    pub data_sources: HashMap<String, Pool<Postgres>>,
    /// Tenant ID
    pub tenant_id: String,
    /// Query parameters
    pub params: Value,
    /// Query specification
    pub spec: Value,
}

/// Result of building a query from template
pub struct BuiltQuery {
    /// The SQL query string with placeholders
    pub sql: String,
    /// Ordered list of parameter names
    pub param_names: Vec<String>,
}

impl QueryContext {
    /// Generate SQL and parameter list from spec.sql template and params
    /// 
    /// Template syntax:
    /// - `{param_name}` - replaced with `$N` (PostgreSQL placeholder) and bound to the parameter value
    /// - `<param_name:content>` - includes `content` only if `param_name` exists in params
    /// 
    /// # Example
    /// 
    /// ```
    /// // spec.sql: "SELECT * FROM table WHERE id = {id} <name:AND name = {name}>"
    /// // params: {"id": "1", "name": "test"}
    /// // Result: BuiltQuery { 
    /// //   sql: "SELECT * FROM table WHERE id = $1 AND name = $2",
    /// //   param_names: vec!["id", "name"]
    /// // }
    /// ```
    /// 
    /// Then use it like:
    /// ```
    /// let built = context.build_query()?;
    /// let mut query = sqlx::query(&built.sql);
    /// for param_name in &built.param_names {
    ///     let value = context.params.get(param_name).unwrap();
    ///     query = query.bind(value.as_str().unwrap());
    /// }
    /// let result = query.fetch_all(pool).await?;
    /// ```
    pub fn build_query(&self) -> Result<BuiltQuery, QueryError> {
        // Get SQL template from spec
        let sql_template = self.spec.get("sql")
            .and_then(|v| v.as_str())
            .ok_or_else(|| QueryError::InvalidInput("Missing 'sql' in spec".to_string()))?;

        // Process conditional blocks: <param_name:content>
        let conditional_regex = Regex::new(r"\[([^:\]]+):([^\]]*)\]")
            .map_err(|e| QueryError::InvalidInput(format!("Invalid regex: {}", e)))?;
        
        let mut param_names = Vec::new();
        
        // First pass: handle conditional blocks
        let mut final_sql = String::new();
        let mut last_end = 0;
        
        for cap in conditional_regex.captures_iter(sql_template) {
            let full_match = cap.get(0).unwrap();
            let param_name = cap.get(1).unwrap().as_str();
            let content = cap.get(2).unwrap().as_str();
            
            // Add text before this match
            final_sql.push_str(&sql_template[last_end..full_match.start()]);
            
            // Include content only if parameter exists
            if self.params.get(param_name).is_some() {
                final_sql.push_str(content);
            }
            
            last_end = full_match.end();
        }
        
        // Add remaining text
        final_sql.push_str(&sql_template[last_end..]);
        
        // Second pass: replace {param_name} with $N and collect parameter names
        let param_regex = Regex::new(r"\{([^}]+)\}")
            .map_err(|e| QueryError::InvalidInput(format!("Invalid regex: {}", e)))?;
        
        let mut query_sql = String::new();
        let mut last_end = 0;
        let mut param_index = 1;
        
        for cap in param_regex.captures_iter(&final_sql) {
            let full_match = cap.get(0).unwrap();
            let param_name = cap.get(1).unwrap().as_str();
            
            // Add text before this match
            query_sql.push_str(&final_sql[last_end..full_match.start()]);
            
            // Replace with PostgreSQL placeholder ($1, $2, etc.)
            query_sql.push_str(&format!("${}", param_index));
            param_names.push(param_name.to_string());
            param_index += 1;
            
            last_end = full_match.end();
        }
        
        // Add remaining text
        query_sql.push_str(&final_sql[last_end..]);
        
        // Verify all parameters exist
        for param_name in &param_names {
            if self.params.get(param_name).is_none() {
                return Err(QueryError::InvalidInput(format!("Missing parameter: {}", param_name)));
            }
        }
        
        Ok(BuiltQuery {
            sql: query_sql,
            param_names,
        })
    }
    
    /// Helper method to bind a parameter value to a query based on its JSON type
    pub fn bind_param<'q>(
        &self,
        query: sqlx::query::Query<'q, Postgres, sqlx::postgres::PgArguments>,
        param_name: &str,
    ) -> Result<sqlx::query::Query<'q, Postgres, sqlx::postgres::PgArguments>, QueryError> {
        let param_value = self.params.get(param_name)
            .ok_or_else(|| QueryError::InvalidInput(format!("Missing parameter: {}", param_name)))?;
        
        // Bind based on type
        let bound_query = match param_value {
            Value::String(s) => query.bind(s.clone()),
            Value::Number(n) => {
                if let Some(i) = n.as_i64() {
                    query.bind(i)
                } else if let Some(f) = n.as_f64() {
                    query.bind(f)
                } else {
                    return Err(QueryError::InvalidInput(format!("Invalid number type for parameter: {}", param_name)));
                }
            },
            Value::Bool(b) => query.bind(*b),
            Value::Array(arr) => {
                // For arrays, bind as a vector of strings
                let string_vec: Vec<String> = arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect();
                query.bind(string_vec)
            },
            Value::Null => query.bind(None::<String>),
            _ => return Err(QueryError::InvalidInput(format!("Unsupported parameter type for: {}", param_name))),
        };
        
        Ok(bound_query)
    }
}

/// QueryStrategy trait that all query strategies must implement
#[async_trait]
pub trait QueryStrategy: Send + Sync {
    /// Execute the query strategy and return the result
    async fn execute(&self, context: QueryContext) -> Result<Value, QueryError>;
}
