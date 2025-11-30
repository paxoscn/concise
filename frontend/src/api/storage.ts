import apiClient from './client'
import type { Storage, CreateStorageRequest, UpdateStorageRequest } from './types'

export const storageApi = {
  // 获取数据存储列表
  list: async (): Promise<Storage[]> => {
    const response = await apiClient.get<Storage[]>('/storages')
    return response.data
  },

  // 创建数据存储
  create: async (data: CreateStorageRequest): Promise<Storage> => {
    const response = await apiClient.post<Storage>('/storages', data)
    return response.data
  },

  // 获取数据存储详情
  get: async (id: string): Promise<Storage> => {
    const response = await apiClient.get<Storage>(`/storages/${id}`)
    return response.data
  },

  // 更新数据存储
  update: async (id: string, data: UpdateStorageRequest): Promise<Storage> => {
    const response = await apiClient.put<Storage>(`/storages/${id}`, data)
    return response.data
  },

  // 删除数据存储
  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/storages/${id}`)
  },
}
