import apiClient from './client'
import type { LoginRequest, AuthToken } from './types'

export const authApi = {
  // 用户登录
  login: async (data: LoginRequest): Promise<AuthToken> => {
    const response = await apiClient.post<AuthToken>('/auth/login', data)
    return response.data
  },
}
