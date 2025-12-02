# 实施计划

- [x] 1. 初始化项目结构和核心配置
  - 创建Rust后端项目结构（使用cargo init）
  - 配置Cargo.toml依赖项（axum, sea-orm, tokio, serde等）
  - 创建项目目录结构（api, domain, repository, entities, migrations）
  - 创建配置文件结构（config/default.toml）
  - 设置.gitignore和基础文档
  - _需求: 10.1, 10.2, 10.5_

- [x] 2. 实现数据库层和实体模型
- [x] 2.1 设置SeaORM和数据库迁移
  - 配置SeaORM连接和迁移框架
  - 创建数据库迁移脚本目录结构
  - _需求: 8.1, 8.2, 8.4_

- [x] 2.2 实现User实体和迁移
  - 创建users表迁移脚本（id, nickname, password_hash, created_at, updated_at）
  - 定义User实体模型（使用DeriveEntityModel）
  - 实现UserRepository基础CRUD操作
  - _需求: 8.3, 1.1, 1.4_

- [x] 2.3 实现DataSource实体和迁移
  - 创建data_sources表迁移脚本（id, name, db_type, connection_config, created_at, updated_at）
  - 定义DataSource实体模型
  - 实现DataSourceRepository基础CRUD操作
  - _需求: 8.3, 2.5_

- [x] 2.4 实现Storage实体和迁移
  - 创建storages表迁移脚本（id, name, storage_type, upload_endpoint, download_endpoint, auth_config, created_at, updated_at）
  - 定义Storage实体模型
  - 实现StorageRepository基础CRUD操作
  - _需求: 8.3, 3.5_

- [x] 3. 实现认证服务
- [x] 3.1 实现JWT工具和密码加密
  - 创建JWT令牌生成和验证函数
  - 实现bcrypt密码哈希和验证函数
  - 定义AuthToken和UserClaims数据结构
  - _需求: 1.2, 1.4, 1.5_

- [x] 3.2 实现AuthService业务逻辑
  - 实现login方法（验证凭据、生成JWT）
  - 实现verify_token方法（验证JWT有效性）
  - 处理认证错误（InvalidCredentials, InvalidToken, TokenExpired）
  - _需求: 1.1, 1.2, 1.3_

- [x] 3.3 实现认证API端点
  - 创建POST /api/v1/auth/login路由
  - 实现LoginRequest和AuthToken响应结构
  - 添加错误处理和HTTP状态码映射
  - _需求: 1.1, 1.2, 1.3_

- [x] 4. 实现数据源管理服务
- [x] 4.1 实现DataSourceService业务逻辑
  - 实现create方法（创建数据源）
  - 实现list方法（查询数据源列表）
  - 实现get方法（查询单个数据源）
  - 实现update方法（更新数据源）
  - 实现delete方法（删除数据源）
  - _需求: 2.1, 2.2, 2.3, 2.4_

- [x] 4.2 实现数据源管理API端点
  - 创建GET /api/v1/data-sources路由（列表）
  - 创建POST /api/v1/data-sources路由（创建）
  - 创建GET /api/v1/data-sources/{id}路由（详情）
  - 创建PUT /api/v1/data-sources/{id}路由（更新）
  - 创建DELETE /api/v1/data-sources/{id}路由（删除）
  - 添加JWT认证中间件保护
  - _需求: 2.1, 2.2, 2.3, 2.4_

- [x] 5. 实现数据存储管理服务
- [x] 5.1 实现StorageService业务逻辑
  - 实现create方法（创建存储配置）
  - 实现list方法（查询存储列表）
  - 实现get方法（查询单个存储）
  - 实现update方法（更新存储配置）
  - 实现delete方法（删除存储配置）
  - _需求: 3.1, 3.2, 3.3, 3.4_

- [x] 5.2 实现数据存储管理API端点
  - 创建GET /api/v1/storages路由（列表）
  - 创建POST /api/v1/storages路由（创建）
  - 创建GET /api/v1/storages/{id}路由（详情）
  - 创建PUT /api/v1/storages/{id}路由（更新）
  - 创建DELETE /api/v1/storages/{id}路由（删除）
  - 添加JWT认证中间件保护
  - _需求: 3.1, 3.2, 3.3, 3.4_

- [x] 6. 实现任务中心集成
- [x] 6.1 实现TaskCenterClient
  - 创建reqwest HTTP客户端配置
  - 实现list_tasks方法（代理到任务中心）
  - 实现create_task方法（代理到任务中心）
  - 实现get_task方法（代理到任务中心）
  - 实现update_task方法（代理到任务中心）
  - 实现delete_task方法（代理到任务中心）
  - _需求: 4.1, 4.6_

- [x] 6.2 实现TaskService业务逻辑
  - 实现list方法（调用TaskCenterClient）
  - 实现create方法（调用TaskCenterClient）
  - 实现get方法（调用TaskCenterClient）
  - 实现update方法（调用TaskCenterClient）
  - 实现delete方法（调用TaskCenterClient）
  - _需求: 4.2, 4.3, 4.4, 4.5_

- [x] 6.3 实现任务管理API端点
  - 创建GET /api/v1/tasks路由（列表）
  - 创建POST /api/v1/tasks路由（创建）
  - 创建GET /api/v1/tasks/{id}路由（详情）
  - 创建PUT /api/v1/tasks/{id}路由（更新）
  - 创建DELETE /api/v1/tasks/{id}路由（删除）
  - 添加JWT认证中间件保护
  - _需求: 4.2, 4.3, 4.4, 4.5_

- [x] 7. 实现任务执行引擎
- [x] 7.1 实现ExecutorEngine核心框架
  - 定义Executor trait（execute方法）
  - 定义TaskMetadata、ExecutorContext、ExecutionResult数据结构
  - 实现ExecutorEngine结构体
  - 实现get_executor方法（根据任务类型选择执行器）
  - 实现execute_task方法（执行任务流程）
  - 实现trigger_next_actions方法（触发依赖任务）
  - _需求: 5.1, 5.2, 5.5_

- [x] 7.2 实现SqlExecutor
  - 实现Executor trait for SqlExecutor
  - 实现数据库连接逻辑（从ExecutorContext获取数据源）
  - 实现SQL语句执行逻辑（查询、插入、更新、删除）
  - 实现错误处理和结果返回
  - _需求: 6.1, 6.2, 6.3, 6.4, 6.5, 5.3_

- [x] 7.3 实现ExcelExecutor
  - 实现Executor trait for ExcelExecutor
  - 实现Excel文件解析逻辑（读取所有sheet）
  - 实现数据表创建/更新逻辑
  - 实现数据行批量插入逻辑
  - 实现错误处理和结果返回
  - _需求: 7.1, 7.2, 7.3, 7.4, 7.5, 5.4_

- [x] 7.4 实现任务执行API端点
  - 创建POST /api/v1/executor/execute路由
  - 实现请求解析（任务类型、元数据）
  - 调用ExecutorEngine执行任务
  - 返回执行结果
  - 添加JWT认证中间件保护
  - _需求: 5.1, 5.2, 5.5_

- [x] 8. 实现API层基础设施
- [x] 8.1 实现中间件和错误处理
  - 实现请求日志中间件
  - 实现JWT认证中间件
  - 实现统一错误处理中间件（AppError到HTTP响应映射）
  - 定义ErrorResponse结构体
  - _需求: 10.2_

- [x] 8.2 实现应用程序入口和路由配置
  - 创建main.rs入口文件
  - 配置tokio异步运行时
  - 初始化数据库连接池
  - 注册所有路由（auth, data-sources, storages, tasks, executor）
  - 配置服务器监听地址和端口
  - 实现优雅关闭逻辑
  - _需求: 10.2, 10.3, 10.5_

- [x] 9. 实现配置管理
- [x] 9.1 创建配置文件和环境变量支持
  - 创建config/default.toml配置文件（server, database, jwt, task_center, logging）
  - 实现配置加载逻辑（使用config crate）
  - 实现环境变量覆盖支持
  - 定义AppConfig结构体
  - _需求: 10.1, 10.2_

- [x] 10. 初始化前端项目
- [x] 10.1 创建前端项目结构
  - 使用create-react-app或create-vue初始化项目
  - 配置TypeScript支持
  - 安装UI库（Ant Design或Element Plus）
  - 配置路由（React Router或Vue Router）
  - 配置状态管理（Redux或Pinia）
  - 配置Axios HTTP客户端
  - _需求: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10.2 实现登录页面
  - 创建登录页面组件（苹果风格设计）
  - 实现登录表单（昵称、密码输入）
  - 实现表单验证
  - 调用登录API并处理响应
  - 存储JWT令牌到localStorage
  - 实现登录成功后跳转
  - _需求: 1.1, 9.5_

- [x] 10.3 实现首页仪表盘
  - 创建首页布局组件（苹果风格）
  - 实现导航菜单
  - 实现用户信息显示
  - 实现退出登录功能
  - _需求: 9.4_

- [x] 11. 实现数据源管理前端页面
- [x] 11.1 实现数据源列表页面
  - 创建数据源列表组件
  - 实现表格展示（名称、类型、创建时间等）
  - 实现搜索和筛选功能
  - 实现分页功能
  - 添加创建、编辑、删除操作按钮
  - _需求: 2.2, 9.1_

- [x] 11.2 实现数据源创建和编辑页面
  - 创建数据源表单组件
  - 实现表单字段（名称、数据库类型、连接配置）
  - 实现表单验证
  - 调用创建/更新API
  - 实现操作成功后跳转
  - _需求: 2.1, 2.3, 9.1_

- [x] 12. 实现数据存储管理前端页面
- [x] 12.1 实现数据存储列表页面
  - 创建数据存储列表组件
  - 实现表格展示（名称、类型、端点等）
  - 实现搜索和筛选功能
  - 实现分页功能
  - 添加创建、编辑、删除操作按钮
  - _需求: 3.2, 9.2_

- [x] 12.2 实现数据存储创建和编辑页面
  - 创建数据存储表单组件
  - 实现表单字段（名称、类型、上传/下载端点、认证信息）
  - 实现表单验证
  - 调用创建/更新API
  - 实现操作成功后跳转
  - _需求: 3.1, 3.3, 9.2_

- [x] 13. 实现任务管理前端页面
- [x] 13.1 实现任务列表页面
  - 创建任务列表组件
  - 实现表格展示（任务名称、类型、状态等）
  - 实现搜索和筛选功能
  - 实现分页功能
  - 添加创建、编辑、删除、执行操作按钮
  - _需求: 4.2, 9.3_

- [x] 13.2 实现任务创建和编辑页面
  - 创建任务表单组件
  - 实现表单字段（任务名称、类型、元数据、依赖等）
  - 实现表单验证
  - 调用创建/更新API
  - 实现操作成功后跳转
  - _需求: 4.3, 4.4, 9.3_

- [x] 14. 实现前端认证和路由守卫
- [x] 14.1 实现认证状态管理
  - 创建认证store/context
  - 实现登录状态管理
  - 实现JWT令牌存储和读取
  - 实现自动登录（从localStorage恢复）
  - _需求: 1.2_

- [x] 14.2 实现路由守卫和HTTP拦截器
  - 实现路由守卫（未登录跳转到登录页）
  - 实现Axios请求拦截器（自动添加JWT令牌）
  - 实现Axios响应拦截器（处理401错误）
  - 实现令牌过期自动跳转登录
  - _需求: 1.2, 1.3_

- [x] 15. 创建部署配置
- [x] 15.1 创建Docker配置
  - 创建后端Dockerfile（多阶段构建）
  - 创建前端Dockerfile（Nginx静态服务）
  - 创建docker-compose.yml（编排后端、前端、MySQL）
  - 创建.dockerignore文件
  - _需求: 10.3_

- [x] 15.2 创建数据库初始化脚本
  - 创建数据库初始化SQL脚本
  - 创建默认用户数据（用于测试）
  - 配置docker-compose中的数据库初始化
  - _需求: 8.2_

- [ ] 16. 编写集成测试
  - 创建测试数据库配置
  - 编写认证API集成测试
  - 编写数据源管理API集成测试
  - 编写数据存储管理API集成测试
  - 编写任务管理API集成测试
  - 编写任务执行API集成测试
  - _需求: 1.1, 2.1, 3.1, 4.2, 5.1_
