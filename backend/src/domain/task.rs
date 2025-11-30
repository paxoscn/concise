use serde::{Deserialize, Serialize};
use crate::domain::error::ClientError;

// Task data structures
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub name: String,
    pub task_type: String,
    pub status: String,
    pub metadata: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTaskRequest {
    pub name: String,
    pub task_type: String,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateTaskRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>,
}

// TaskCenterClient - HTTP client for external task center
pub struct TaskCenterClient {
    client: reqwest::Client,
    base_url: String,
}

impl TaskCenterClient {
    pub fn new(base_url: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client");
        
        Self { client, base_url }
    }

    pub async fn list_tasks(&self) -> Result<Vec<Task>, ClientError> {
        let url = format!("{}/tasks", self.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| ClientError::RequestFailed(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(ClientError::RequestFailed(
                format!("HTTP {}: {}", response.status(), response.text().await.unwrap_or_default())
            ));
        }
        
        response
            .json::<Vec<Task>>()
            .await
            .map_err(|e| ClientError::ParseError(e.to_string()))
    }

    pub async fn create_task(&self, req: CreateTaskRequest) -> Result<Task, ClientError> {
        let url = format!("{}/tasks", self.base_url);
        
        let response = self.client
            .post(&url)
            .json(&req)
            .send()
            .await
            .map_err(|e| ClientError::RequestFailed(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(ClientError::RequestFailed(
                format!("HTTP {}: {}", response.status(), response.text().await.unwrap_or_default())
            ));
        }
        
        response
            .json::<Task>()
            .await
            .map_err(|e| ClientError::ParseError(e.to_string()))
    }

    pub async fn get_task(&self, id: &str) -> Result<Task, ClientError> {
        let url = format!("{}/tasks/{}", self.base_url, id);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| ClientError::RequestFailed(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(ClientError::RequestFailed(
                format!("HTTP {}: {}", response.status(), response.text().await.unwrap_or_default())
            ));
        }
        
        response
            .json::<Task>()
            .await
            .map_err(|e| ClientError::ParseError(e.to_string()))
    }

    pub async fn update_task(&self, id: &str, req: UpdateTaskRequest) -> Result<Task, ClientError> {
        let url = format!("{}/tasks/{}", self.base_url, id);
        
        let response = self.client
            .put(&url)
            .json(&req)
            .send()
            .await
            .map_err(|e| ClientError::RequestFailed(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(ClientError::RequestFailed(
                format!("HTTP {}: {}", response.status(), response.text().await.unwrap_or_default())
            ));
        }
        
        response
            .json::<Task>()
            .await
            .map_err(|e| ClientError::ParseError(e.to_string()))
    }

    pub async fn delete_task(&self, id: &str) -> Result<(), ClientError> {
        let url = format!("{}/tasks/{}", self.base_url, id);
        
        let response = self.client
            .delete(&url)
            .send()
            .await
            .map_err(|e| ClientError::RequestFailed(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(ClientError::RequestFailed(
                format!("HTTP {}: {}", response.status(), response.text().await.unwrap_or_default())
            ));
        }
        
        Ok(())
    }
}

// TaskService - Business logic layer for task management
pub struct TaskService {
    task_center_client: std::sync::Arc<TaskCenterClient>,
}

impl TaskService {
    pub fn new(task_center_client: std::sync::Arc<TaskCenterClient>) -> Self {
        Self { task_center_client }
    }

    pub async fn list(&self) -> Result<Vec<Task>, ClientError> {
        self.task_center_client.list_tasks().await
    }

    pub async fn create(&self, req: CreateTaskRequest) -> Result<Task, ClientError> {
        self.task_center_client.create_task(req).await
    }

    pub async fn get(&self, id: String) -> Result<Task, ClientError> {
        self.task_center_client.get_task(&id).await
    }

    pub async fn update(&self, id: String, req: UpdateTaskRequest) -> Result<Task, ClientError> {
        self.task_center_client.update_task(&id, req).await
    }

    pub async fn delete(&self, id: String) -> Result<(), ClientError> {
        self.task_center_client.delete_task(&id).await
    }
}
