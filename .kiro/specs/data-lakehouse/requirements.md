# 需求文档

## 简介

数据湖仓系统是一个用于管理和执行数据任务的平台。系统提供结构化数据源管理、数据存储管理、任务执行和用户认证功能。后端使用Rust单实例架构，前端提供管理界面和苹果风格的登录页面。

## 术语表

- **System**: 数据湖仓系统
- **User**: 使用系统的用户，具有昵称和密码
- **Structured Data Source**: 结构化数据源，包含数据库连接信息
- **Data Storage**: 数据存储配置，包含对象存储的访问信息
- **Task**: 数据处理任务，由外部任务中心维护
- **Executor**: 执行器，负责执行特定类型的任务
- **SQL Executor**: SQL执行器，执行SQL语句
- **Excel Executor**: Excel执行器，将Excel文件导入数据表
- **Task Metadata**: 任务元数据，包含任务配置和依赖信息
- **Authentication Token**: 认证令牌，包含用户ID和昵称
- **Backend**: 后端服务，使用Rust和Axum框架
- **Frontend**: 前端应用，提供用户界面
- **MySQL Database**: MySQL数据库，存储系统数据
- **SeaORM**: Rust ORM框架，用于数据库访问

## 需求

### 需求 1: 用户认证

**用户故事:** 作为系统用户，我希望能够使用昵称和密码登录系统，以便安全地访问系统功能

#### 验收标准

1. WHEN User提交昵称和密码，THE System SHALL验证凭据的有效性
2. IF 凭据有效，THEN THE System SHALL生成包含用户ID和昵称的Authentication Token
3. IF 凭据无效，THEN THE System SHALL返回认证失败错误
4. THE System SHALL使用bcrypt算法存储和验证密码
5. THE Authentication Token SHALL使用JWT格式编码

### 需求 2: 结构化数据源管理

**用户故事:** 作为系统管理员，我希望能够管理结构化数据源配置，以便系统能够连接到不同的数据库

#### 验收标准

1. THE System SHALL提供创建Structured Data Source的接口
2. THE System SHALL提供查询Structured Data Source列表的接口
3. THE System SHALL提供更新Structured Data Source配置的接口
4. THE System SHALL提供删除Structured Data Source的接口
5. THE Structured Data Source SHALL包含名称、数据库类型和数据库连接属性字段

### 需求 3: 数据存储管理

**用户故事:** 作为系统管理员，我希望能够管理数据存储配置，以便系统能够访问不同的对象存储服务

#### 验收标准

1. THE System SHALL提供创建Data Storage配置的接口
2. THE System SHALL提供查询Data Storage列表的接口
3. THE System SHALL提供更新Data Storage配置的接口
4. THE System SHALL提供删除Data Storage配置的接口
5. THE Data Storage SHALL包含名称、类型、上传域名、下载域名和认证信息字段

### 需求 4: 任务管理

**用户故事:** 作为系统用户，我希望能够通过界面管理任务，以便组织和监控数据处理工作流

#### 验收标准

1. THE System SHALL通过HTTP客户端访问外部任务中心的接口
2. THE System SHALL提供查询Task列表的功能
3. THE System SHALL提供创建Task的功能
4. THE System SHALL提供更新Task的功能
5. THE System SHALL提供删除Task的功能
6. THE System SHALL使用reqwest库实现HTTP请求

### 需求 5: 任务执行

**用户故事:** 作为系统用户，我希望系统能够执行数据处理任务，以便自动化数据工作流

#### 验收标准

1. WHEN System接收任务执行请求，THE System SHALL解析任务类型和Task Metadata
2. THE System SHALL根据任务类型选择对应的Executor
3. THE Executor SHALL能够访问所有配置的Structured Data Source
4. THE Executor SHALL能够访问所有配置的Data Storage
5. WHEN Executor完成任务执行，THE System SHALL根据Task Metadata中的依赖信息触发下一步动作

### 需求 6: SQL执行器

**用户故事:** 作为数据分析师，我希望系统能够执行SQL语句，以便对数据库进行查询和操作

#### 验收标准

1. THE SQL Executor SHALL接收SQL语句作为输入
2. THE SQL Executor SHALL连接到指定的Structured Data Source
3. THE SQL Executor SHALL执行SQL语句并返回结果
4. IF SQL执行失败，THEN THE SQL Executor SHALL返回详细的错误信息
5. THE SQL Executor SHALL支持查询、插入、更新和删除操作

### 需求 7: Excel执行器

**用户故事:** 作为数据导入人员，我希望系统能够将Excel文件导入数据库，以便批量导入数据

#### 验收标准

1. THE Excel Executor SHALL接收Excel文件作为输入
2. THE Excel Executor SHALL解析Excel文件的所有sheet
3. THE Excel Executor SHALL为每个sheet创建或更新对应的数据表
4. THE Excel Executor SHALL将sheet中的数据行写入对应的数据表
5. IF Excel导入失败，THEN THE Excel Executor SHALL返回详细的错误信息

### 需求 8: 数据访问层

**用户故事:** 作为系统开发者，我希望使用统一的ORM框架访问数据库，以便简化数据库操作

#### 验收标准

1. THE Backend SHALL使用SeaORM框架进行数据库访问
2. THE Backend SHALL使用MySQL作为数据库
3. THE Backend SHALL定义User、Structured Data Source和Data Storage的实体模型
4. THE Backend SHALL实现数据库迁移脚本
5. THE Backend SHALL将业务逻辑限制在领域层

### 需求 9: 前端管理界面

**用户故事:** 作为系统用户，我希望通过Web界面管理系统资源，以便方便地操作系统

#### 验收标准

1. THE Frontend SHALL提供Structured Data Source管理页面
2. THE Frontend SHALL提供Data Storage管理页面
3. THE Frontend SHALL提供Task管理页面
4. THE Frontend SHALL提供苹果风格的首页设计
5. THE Frontend SHALL提供登录表单界面

### 需求 10: 系统架构

**用户故事:** 作为系统架构师，我希望系统采用单实例架构，以便简化部署和维护

#### 验收标准

1. THE Backend SHALL使用Rust语言实现
2. THE Backend SHALL使用Axum作为Web框架
3. THE Backend SHALL运行为单个实例进程
4. THE Backend SHALL不拆分为微服务架构
5. THE Backend SHALL使用tokio作为异步运行时
