use axum::{
    extract::State,
    Json, Router,
    routing::post,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

use crate::domain::{AuthService, AuthError};

// LoginRequest 请求结构
#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub nickname: String,
    pub password: String,
}

// LoginResponse 响应结构
#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub expires_at: String,
}

// AppState 应用状态
#[derive(Clone)]
pub struct AppState {
    pub auth_service: Arc<AuthService>,
}

// 登录处理函数
async fn login_handler(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, AuthError> {
    let auth_token = state.auth_service
        .login(payload.nickname, payload.password)
        .await?;

    Ok(Json(LoginResponse {
        token: auth_token.token,
        expires_at: auth_token.expires_at.to_rfc3339(),
    }))
}

// 创建认证路由
pub fn create_auth_routes(auth_service: Arc<AuthService>) -> Router {
    let state = AppState { auth_service };

    Router::new()
        .route("/login", post(login_handler))
        .with_state(state)
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use tower::ServiceExt;
    use crate::entities::user;
    use crate::repository::UserRepository;
    use crate::domain::auth::hash_password;
    use sea_orm::{DatabaseBackend, MockDatabase};
    use chrono::Utc;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_login_success() {
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let password = "test_password";
        let password_hash = hash_password(password).unwrap();

        let user_model = user::Model {
            id: user_id,
            nickname: nickname.clone(),
            password_hash,
            created_at: Utc::now().naive_utc(),
            updated_at: Utc::now().naive_utc(),
        };

        let db = MockDatabase::new(DatabaseBackend::MySql)
            .append_query_results(vec![vec![user_model]])
            .into_connection();

        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = Arc::new(AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        ));

        let app = create_auth_routes(auth_service);

        let request_body = serde_json::json!({
            "nickname": nickname,
            "password": password,
        });

        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/login")
                    .header("content-type", "application/json")
                    .body(Body::from(serde_json::to_string(&request_body).unwrap()))
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn test_login_invalid_credentials() {
        let db = MockDatabase::new(DatabaseBackend::MySql)
            .append_query_results(vec![Vec::<user::Model>::new()])
            .into_connection();

        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = Arc::new(AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        ));

        let app = create_auth_routes(auth_service);

        let request_body = serde_json::json!({
            "nickname": "nonexistent",
            "password": "wrong_password",
        });

        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/login")
                    .header("content-type", "application/json")
                    .body(Body::from(serde_json::to_string(&request_body).unwrap()))
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    }
}
