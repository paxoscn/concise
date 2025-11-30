<template>
  <div class="dashboard-container">
    <el-container>
      <!-- 侧边栏 -->
      <el-aside width="240px" class="dashboard-aside">
        <div class="logo-section">
          <h2 class="logo-title">数据湖仓</h2>
        </div>

        <el-menu
          :default-active="activeMenu"
          class="dashboard-menu"
          router
        >
          <el-menu-item index="/dashboard">
            <el-icon><HomeFilled /></el-icon>
            <span>首页</span>
          </el-menu-item>

          <el-menu-item index="/data-sources">
            <el-icon><Coin /></el-icon>
            <span>数据源管理</span>
          </el-menu-item>

          <el-menu-item index="/storages">
            <el-icon><FolderOpened /></el-icon>
            <span>数据存储管理</span>
          </el-menu-item>

          <el-menu-item index="/tasks">
            <el-icon><List /></el-icon>
            <span>任务管理</span>
          </el-menu-item>
        </el-menu>
      </el-aside>

      <!-- 主内容区 -->
      <el-container>
        <!-- 顶部导航栏 -->
        <el-header class="dashboard-header">
          <div class="header-left">
            <h3 class="page-title">{{ pageTitle }}</h3>
          </div>

          <div class="header-right">
            <el-dropdown @command="handleCommand">
              <div class="user-info">
                <el-avatar :size="36" class="user-avatar">
                  {{ userInitial }}
                </el-avatar>
                <span class="user-nickname">{{ userInfo?.nickname }}</span>
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </div>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="logout">
                    <el-icon><SwitchButton /></el-icon>
                    退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>

        <!-- 内容区域 -->
        <el-main class="dashboard-main">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import {
  HomeFilled,
  Coin,
  FolderOpened,
  List,
  ArrowDown,
  SwitchButton,
} from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const userInfo = computed(() => authStore.userInfo)
const activeMenu = computed(() => route.path)

const userInitial = computed(() => {
  return userInfo.value?.nickname?.charAt(0).toUpperCase() || 'U'
})

const pageTitle = computed(() => {
  const titles: Record<string, string> = {
    '/dashboard': '首页',
    '/data-sources': '数据源管理',
    '/storages': '数据存储管理',
    '/tasks': '任务管理',
  }
  return titles[route.path] || '首页'
})

const handleCommand = async (command: string) => {
  if (command === 'logout') {
    try {
      await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      })
      
      authStore.logout()
      router.push('/login')
    } catch {
      // 用户取消
    }
  }
}
</script>

<style scoped>
.dashboard-container {
  height: 100vh;
  background: #f5f5f7;
}

.el-container {
  height: 100%;
}

/* 侧边栏样式 */
.dashboard-aside {
  background: #ffffff;
  border-right: 1px solid #e5e5e7;
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.04);
}

.logo-section {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-bottom: 1px solid #e5e5e7;
}

.logo-title {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
  letter-spacing: -0.5px;
}

.dashboard-menu {
  border: none;
  padding: 16px 12px;
}

.dashboard-menu :deep(.el-menu-item) {
  border-radius: 8px;
  margin-bottom: 4px;
  height: 44px;
  line-height: 44px;
  color: #1d1d1f;
  font-size: 14px;
  transition: all 0.2s ease;
}

.dashboard-menu :deep(.el-menu-item:hover) {
  background: #f5f5f7;
}

.dashboard-menu :deep(.el-menu-item.is-active) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #ffffff;
}

.dashboard-menu :deep(.el-menu-item .el-icon) {
  font-size: 18px;
  margin-right: 8px;
}

/* 顶部导航栏样式 */
.dashboard-header {
  background: #ffffff;
  border-bottom: 1px solid #e5e5e7;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 32px;
  height: 64px;
}

.header-left {
  flex: 1;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
  letter-spacing: -0.3px;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.user-info:hover {
  background: #f5f5f7;
}

.user-avatar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #ffffff;
  font-weight: 500;
}

.user-nickname {
  margin: 0 8px 0 12px;
  font-size: 14px;
  color: #1d1d1f;
  font-weight: 500;
}

/* 主内容区样式 */
.dashboard-main {
  padding: 24px;
  overflow-y: auto;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .dashboard-aside {
    width: 200px !important;
  }

  .dashboard-header {
    padding: 0 16px;
  }

  .dashboard-main {
    padding: 16px;
  }

  .user-nickname {
    display: none;
  }
}
</style>
