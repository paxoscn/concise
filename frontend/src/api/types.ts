// 认证相关类型
export interface LoginRequest {
  nickname: string
  password: string
}

export interface AuthToken {
  token: string
  expires_at: string
}

export interface UserInfo {
  user_id: string
  nickname: string
}

// 数据源相关类型
export interface DataSource {
  id: string
  name: string
  db_type: string
  connection_config: Record<string, any>
  created_at: string
  updated_at: string
}

export interface CreateDataSourceRequest {
  name: string
  db_type: string
  connection_config: Record<string, any>
}

export interface UpdateDataSourceRequest {
  name?: string
  db_type?: string
  connection_config?: Record<string, any>
}

// 数据存储相关类型
export interface Storage {
  id: string
  name: string
  storage_type: string
  upload_endpoint: string
  download_endpoint: string
  auth_config: Record<string, any>
  created_at: string
  updated_at: string
}

export interface CreateStorageRequest {
  name: string
  storage_type: string
  upload_endpoint: string
  download_endpoint: string
  auth_config: Record<string, any>
}

export interface UpdateStorageRequest {
  name?: string
  storage_type?: string
  upload_endpoint?: string
  download_endpoint?: string
  auth_config?: Record<string, any>
}

// 任务相关类型
export interface Task {
  id: string
  name: string
  task_type: string
  status: string
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface CreateTaskRequest {
  name: string
  task_type: string
  metadata: Record<string, any>
}

export interface UpdateTaskRequest {
  name?: string
  task_type?: string
  status?: string
  metadata?: Record<string, any>
}
