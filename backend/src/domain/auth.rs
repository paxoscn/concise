use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

// AuthToken 数据结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthToken {
    pub token: String,
    pub expires_at: chrono::DateTime<Utc>,
}

// UserClaims 数据结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserClaims {
    pub user_id: String,
    pub nickname: String,
    pub exp: i64,
}

// JWT工具函数
pub fn generate_jwt_token(
    user_id: String,
    nickname: String,
    secret: &str,
    expiration_hours: i64,
) -> Result<AuthToken, jsonwebtoken::errors::Error> {
    let expiration = Utc::now() + Duration::hours(expiration_hours);
    
    let claims = UserClaims {
        user_id,
        nickname,
        exp: expiration.timestamp(),
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )?;

    Ok(AuthToken {
        token,
        expires_at: expiration,
    })
}

pub fn verify_jwt_token(
    token: &str,
    secret: &str,
) -> Result<UserClaims, jsonwebtoken::errors::Error> {
    let token_data = decode::<UserClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;

    Ok(token_data.claims)
}

// 密码加密工具函数
pub fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    bcrypt::hash(password, bcrypt::DEFAULT_COST)
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, bcrypt::BcryptError> {
    bcrypt::verify(password, hash)
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_password_hashing() {
        let password = "test_password_123";
        let hash = hash_password(password).unwrap();
        
        assert!(verify_password(password, &hash).unwrap());
        assert!(!verify_password("wrong_password", &hash).unwrap());
    }

    #[test]
    fn test_jwt_generation_and_verification() {
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let secret = "test_secret_key";
        
        let auth_token = generate_jwt_token(
            user_id.clone(),
            nickname.clone(),
            secret,
            24,
        ).unwrap();
        
        let claims = verify_jwt_token(&auth_token.token, secret).unwrap();
        
        assert_eq!(claims.user_id, user_id);
        assert_eq!(claims.nickname, nickname);
    }

    #[test]
    fn test_jwt_verification_with_wrong_secret() {
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let secret = "test_secret_key";
        
        let auth_token = generate_jwt_token(
            user_id,
            nickname,
            secret,
            24,
        ).unwrap();
        
        let result = verify_jwt_token(&auth_token.token, "wrong_secret");
        assert!(result.is_err());
    }
}

use crate::repository::UserRepository;
use super::error::AuthError;
use std::sync::Arc;

// AuthService 业务逻辑
pub struct AuthService {
    user_repo: Arc<UserRepository>,
    jwt_secret: String,
    jwt_expiration_hours: i64,
}

impl AuthService {
    pub fn new(user_repo: Arc<UserRepository>, jwt_secret: String, jwt_expiration_hours: i64) -> Self {
        Self {
            user_repo,
            jwt_secret,
            jwt_expiration_hours,
        }
    }

    /// 用户登录
    pub async fn login(&self, nickname: String, password: String) -> Result<AuthToken, AuthError> {
        // 查找用户
        let user = self.user_repo
            .find_by_nickname(&nickname)
            .await?
            .ok_or(AuthError::InvalidCredentials)?;

        // 验证密码
        let is_valid = verify_password(&password, &user.password_hash)?;
        if !is_valid {
            return Err(AuthError::InvalidCredentials);
        }

        // 生成JWT令牌
        let auth_token = generate_jwt_token(
            user.id.clone(),
            user.nickname.clone(),
            &self.jwt_secret,
            self.jwt_expiration_hours,
        )?;

        Ok(auth_token)
    }

    /// 验证JWT令牌
    pub fn verify_token(&self, token: &str) -> Result<UserClaims, AuthError> {
        match verify_jwt_token(token, &self.jwt_secret) {
            Ok(claims) => {
                // 检查令牌是否过期
                let now = Utc::now().timestamp();
                if claims.exp < now {
                    return Err(AuthError::TokenExpired);
                }
                Ok(claims)
            }
            Err(e) => {
                // 根据JWT错误类型返回相应的AuthError
                match e.kind() {
                    jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                        Err(AuthError::TokenExpired)
                    }
                    _ => Err(AuthError::InvalidToken),
                }
            }
        }
    }
}

#[cfg(test)]
mod auth_service_tests {
    use super::*;
    use crate::entities::user;
    use sea_orm::{DatabaseBackend, MockDatabase};
    use uuid::Uuid;

    #[tokio::test]
    async fn test_login_with_valid_credentials() {
        // 创建测试用户
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let password = "test_password";
        let password_hash = hash_password(password).unwrap();

        let user_model = user::Model {
            id: user_id.clone(),
            nickname: nickname.clone(),
            password_hash,
            created_at: Utc::now().naive_utc(),
            updated_at: Utc::now().naive_utc(),
        };

        // 创建Mock数据库
        let db = MockDatabase::new(DatabaseBackend::Postgres)
            .append_query_results(vec![vec![user_model.clone()]])
            .into_connection();

        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        );

        // 测试登录
        let result = auth_service.login(nickname, password.to_string()).await;
        assert!(result.is_ok());
        
        let auth_token = result.unwrap();
        assert!(!auth_token.token.is_empty());
    }

    #[tokio::test]
    async fn test_login_with_invalid_password() {
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let password_hash = hash_password("correct_password").unwrap();

        let user_model = user::Model {
            id: user_id,
            nickname: nickname.clone(),
            password_hash,
            created_at: Utc::now().naive_utc(),
            updated_at: Utc::now().naive_utc(),
        };

        let db = MockDatabase::new(DatabaseBackend::Postgres)
            .append_query_results(vec![vec![user_model]])
            .into_connection();

        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        );

        let result = auth_service.login(nickname, "wrong_password".to_string()).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AuthError::InvalidCredentials));
    }

    #[tokio::test]
    async fn test_login_with_nonexistent_user() {
        let db = MockDatabase::new(DatabaseBackend::Postgres)
            .append_query_results(vec![Vec::<user::Model>::new()])
            .into_connection();

        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        );

        let result = auth_service.login("nonexistent".to_string(), "password".to_string()).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AuthError::InvalidCredentials));
    }

    #[test]
    fn test_verify_valid_token() {
        let user_id = Uuid::new_v4().to_string();
        let nickname = "test_user".to_string();
        let secret = "test_secret";

        let auth_token = generate_jwt_token(
            user_id.clone(),
            nickname.clone(),
            secret,
            24,
        ).unwrap();

        let db = MockDatabase::new(DatabaseBackend::Postgres).into_connection();
        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = AuthService::new(
            user_repo,
            secret.to_string(),
            24,
        );

        let result = auth_service.verify_token(&auth_token.token);
        assert!(result.is_ok());
        
        let claims = result.unwrap();
        assert_eq!(claims.user_id, user_id);
        assert_eq!(claims.nickname, nickname);
    }

    #[test]
    fn test_verify_invalid_token() {
        let db = MockDatabase::new(DatabaseBackend::Postgres).into_connection();
        let user_repo = Arc::new(UserRepository::new(db));
        let auth_service = AuthService::new(
            user_repo,
            "test_secret".to_string(),
            24,
        );

        let result = auth_service.verify_token("invalid_token");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AuthError::InvalidToken));
    }
}
