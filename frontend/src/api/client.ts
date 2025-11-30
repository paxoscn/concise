import axios from 'axios'
import type { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'
import { useAuthStore } from '@/stores/auth'

// 创建axios实例
const apiClient: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// 请求拦截器 - 自动添加JWT令牌
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 从auth store获取token
    const authStore = useAuthStore()
    const token = authStore.token
    
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error: AxiosError) => {
    return Promise.reject(error)
  }
)

// 响应拦截器 - 处理错误和401自动跳转
apiClient.interceptors.response.use(
  (response) => {
    return response
  },
  (error: AxiosError) => {
    if (error.response) {
      const status = error.response.status
      const data = error.response.data as any

      switch (status) {
        case 401:
          // 未授权或令牌过期，清除认证状态并跳转到登录页
          const authStore = useAuthStore()
          authStore.logout()
          ElMessage.error('登录已过期，请重新登录')
          
          // 保存当前路由，登录后可跳转回来
          const currentPath = router.currentRoute.value.fullPath
          if (currentPath !== '/login') {
            router.push({
              path: '/login',
              query: { redirect: currentPath },
            })
          }
          break
        case 403:
          ElMessage.error('没有权限访问该资源')
          break
        case 404:
          ElMessage.error('请求的资源不存在')
          break
        case 422:
          ElMessage.error(data?.message || '输入验证失败')
          break
        case 500:
          ElMessage.error('服务器内部错误')
          break
        default:
          ElMessage.error(data?.message || '请求失败')
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接')
    } else {
      ElMessage.error('请求配置错误')
    }
    return Promise.reject(error)
  }
)

export default apiClient
