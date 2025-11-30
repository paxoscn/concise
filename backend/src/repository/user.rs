use sea_orm::*;
use crate::entities::user::{self, Entity as User};

pub struct UserRepository {
    db: DatabaseConnection,
}

impl UserRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create(&self, model: user::ActiveModel) -> Result<user::Model, DbErr> {
        model.insert(&self.db).await
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<user::Model>, DbErr> {
        User::find_by_id(id.to_string()).one(&self.db).await
    }

    pub async fn find_by_nickname(&self, nickname: &str) -> Result<Option<user::Model>, DbErr> {
        User::find()
            .filter(user::Column::Nickname.eq(nickname))
            .one(&self.db)
            .await
    }

    pub async fn find_all(&self) -> Result<Vec<user::Model>, DbErr> {
        User::find().all(&self.db).await
    }

    pub async fn update(&self, model: user::ActiveModel) -> Result<user::Model, DbErr> {
        model.update(&self.db).await
    }

    pub async fn delete(&self, id: &str) -> Result<DeleteResult, DbErr> {
        User::delete_by_id(id.to_string()).exec(&self.db).await
    }
}
