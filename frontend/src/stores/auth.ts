import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api'
import type { LoginRequest, UserInfo } from '@/api'
import { jwtDecode } from 'jwt-decode'

interface JwtPayload {
  user_id: string
  nickname: string
  exp: number
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(null)
  const userInfo = ref<UserInfo | null>(null)

  const isAuthenticated = computed(() => !!token.value)

  // 初始化认证状态（从localStorage恢复）
  const initAuth = () => {
    const storedToken = localStorage.getItem('auth_token')
    const storedUserInfo = localStorage.getItem('user_info')

    if (storedToken && storedUserInfo) {
      try {
        // 验证token是否过期
        const decoded = jwtDecode<JwtPayload>(storedToken)
        const currentTime = Date.now() / 1000

        if (decoded.exp > currentTime) {
          // Token未过期，恢复认证状态
          token.value = storedToken
          userInfo.value = JSON.parse(storedUserInfo)
        } else {
          // Token已过期，清除存储
          logout()
        }
      } catch (error) {
        // Token解析失败，清除存储
        logout()
      }
    }
  }

  // 登录
  const login = async (credentials: LoginRequest) => {
    const response = await authApi.login(credentials)
    token.value = response.token
    
    // 解析JWT获取用户信息
    const decoded = jwtDecode<JwtPayload>(response.token)
    userInfo.value = {
      user_id: decoded.user_id,
      nickname: decoded.nickname,
    }

    // 存储到localStorage
    localStorage.setItem('auth_token', response.token)
    localStorage.setItem('user_info', JSON.stringify(userInfo.value))
  }

  // 登出
  const logout = () => {
    token.value = null
    userInfo.value = null
    localStorage.removeItem('auth_token')
    localStorage.removeItem('user_info')
  }

  // 检查token是否过期
  const checkTokenExpiry = () => {
    if (!token.value) return false
    
    try {
      const decoded = jwtDecode<JwtPayload>(token.value)
      const currentTime = Date.now() / 1000
      
      if (decoded.exp < currentTime) {
        logout()
        return false
      }
      return true
    } catch {
      logout()
      return false
    }
  }

  return {
    token,
    userInfo,
    isAuthenticated,
    initAuth,
    login,
    logout,
    checkTokenExpiry,
  }
})
