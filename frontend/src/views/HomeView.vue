<template>
  <div class="home-view">
    <el-row :gutter="24">
      <el-col :xs="24" :sm="12" :lg="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="40" color="#667eea">
              <Coin />
            </el-icon>
            <div class="stat-info">
              <div class="stat-value">0</div>
              <div class="stat-label">数据源</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :lg="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="40" color="#764ba2">
              <FolderOpened />
            </el-icon>
            <div class="stat-info">
              <div class="stat-value">0</div>
              <div class="stat-label">数据存储</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :lg="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="40" color="#48bb78">
              <List />
            </el-icon>
            <div class="stat-info">
              <div class="stat-value">0</div>
              <div class="stat-label">任务总数</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :lg="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="40" color="#f56c6c">
              <CircleCheck />
            </el-icon>
            <div class="stat-info">
              <div class="stat-value">0</div>
              <div class="stat-label">已完成任务</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="24" style="margin-top: 24px">
      <el-col :span="24">
        <el-card class="welcome-card">
          <h2 class="welcome-title">欢迎使用数据湖仓系统</h2>
          <p class="welcome-text">
            这是一个用于管理和执行数据任务的平台。您可以通过左侧菜单访问各个功能模块。
          </p>
          <div class="quick-actions">
            <el-button type="primary" @click="$router.push('/data-sources')">
              管理数据源
            </el-button>
            <el-button @click="$router.push('/storages')">
              管理数据存储
            </el-button>
            <el-button @click="$router.push('/tasks')">
              管理任务
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { Coin, FolderOpened, List, CircleCheck } from '@element-plus/icons-vue'
</script>

<style scoped>
.home-view {
  width: 100%;
}

.stat-card {
  border-radius: 12px;
  margin-bottom: 24px;
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
}

.stat-card :deep(.el-card__body) {
  padding: 24px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  flex-shrink: 0;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 600;
  color: #1d1d1f;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #86868b;
  font-weight: 400;
}

.welcome-card {
  border-radius: 12px;
}

.welcome-card :deep(.el-card__body) {
  padding: 32px;
}

.welcome-title {
  font-size: 24px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 16px 0;
  letter-spacing: -0.5px;
}

.welcome-text {
  font-size: 15px;
  color: #86868b;
  line-height: 1.6;
  margin: 0 0 24px 0;
}

.quick-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.quick-actions .el-button {
  border-radius: 8px;
  padding: 12px 24px;
  font-weight: 500;
}

@media (max-width: 768px) {
  .stat-card {
    margin-bottom: 16px;
  }

  .welcome-card :deep(.el-card__body) {
    padding: 24px;
  }

  .quick-actions {
    flex-direction: column;
  }

  .quick-actions .el-button {
    width: 100%;
  }
}
</style>
