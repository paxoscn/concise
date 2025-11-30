import apiClient from './client'
import type { DataSource, CreateDataSourceRequest, UpdateDataSourceRequest } from './types'

export const dataSourceApi = {
  // 获取数据源列表
  list: async (): Promise<DataSource[]> => {
    const response = await apiClient.get<DataSource[]>('/data-sources')
    return response.data
  },

  // 创建数据源
  create: async (data: CreateDataSourceRequest): Promise<DataSource> => {
    const response = await apiClient.post<DataSource>('/data-sources', data)
    return response.data
  },

  // 获取数据源详情
  get: async (id: string): Promise<DataSource> => {
    const response = await apiClient.get<DataSource>(`/data-sources/${id}`)
    return response.data
  },

  // 更新数据源
  update: async (id: string, data: UpdateDataSourceRequest): Promise<DataSource> => {
    const response = await apiClient.put<DataSource>(`/data-sources/${id}`, data)
    return response.data
  },

  // 删除数据源
  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/data-sources/${id}`)
  },
}
