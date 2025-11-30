# 数据湖仓系统 - 前端

基于 Vue 3 + TypeScript + Element Plus 的数据湖仓管理系统前端应用。

## 技术栈

- **框架**: Vue 3 (Composition API)
- **语言**: TypeScript
- **UI库**: Element Plus (中文支持)
- **状态管理**: Pinia
- **路由**: Vue Router
- **HTTP客户端**: Axios
- **构建工具**: Vite

## 功能特性

- ✅ 用户认证（JWT）
- ✅ 苹果风格登录页面
- ✅ 响应式仪表盘布局
- ✅ 路由守卫和自动登录
- ✅ HTTP请求拦截器
- ✅ 统一错误处理
- 🚧 数据源管理（待实现）
- 🚧 数据存储管理（待实现）
- 🚧 任务管理（待实现）

## 项目设置

```sh
npm install
```

### 开发环境运行

```sh
npm run dev
```

访问 http://localhost:5173

### 类型检查

```sh
npm run type-check
```

### 生产环境构建

```sh
npm run build
```

### 预览生产构建

```sh
npm run preview
```

## 环境变量

创建 `.env.local` 文件配置本地环境变量：

```
VITE_API_BASE_URL=http://localhost:8080/api/v1
```

## 项目结构

```
frontend/
├── src/
│   ├── api/              # API接口定义
│   │   ├── client.ts     # Axios客户端配置
│   │   ├── auth.ts       # 认证API
│   │   └── types.ts      # 类型定义
│   ├── stores/           # Pinia状态管理
│   │   └── auth.ts       # 认证状态
│   ├── views/            # 页面组件
│   │   ├── LoginView.vue         # 登录页
│   │   ├── DashboardView.vue     # 仪表盘布局
│   │   ├── HomeView.vue          # 首页
│   │   ├── DataSourcesView.vue   # 数据源管理
│   │   ├── StoragesView.vue      # 数据存储管理
│   │   └── TasksView.vue         # 任务管理
│   ├── router/           # 路由配置
│   ├── App.vue           # 根组件
│   └── main.ts           # 入口文件
├── .env                  # 环境变量
└── vite.config.ts        # Vite配置
```

## 开发指南

### 添加新页面

1. 在 `src/views/` 创建新的 Vue 组件
2. 在 `src/router/index.ts` 添加路由配置
3. 在 `DashboardView.vue` 添加菜单项

### 添加新API

1. 在 `src/api/types.ts` 定义类型
2. 在 `src/api/` 创建新的API模块
3. 在 `src/api/index.ts` 导出

### 状态管理

使用 Pinia 创建新的 store：

```typescript
import { defineStore } from 'pinia'

export const useMyStore = defineStore('my-store', () => {
  // 状态和方法
})
```

## 设计规范

- 采用苹果风格设计语言
- 圆角卡片和按钮（12px）
- 柔和的渐变色
- 简洁的布局和间距
- 响应式设计支持移动端

## IDE 推荐设置

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar)
