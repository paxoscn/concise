import apiClient from './client'
import type { Task, CreateTaskRequest, UpdateTaskRequest } from './types'

export const taskApi = {
  // 获取任务列表
  async list(): Promise<Task[]> {
    const response = await apiClient.get('/tasks')
    return response.data
  },

  // 创建任务
  async create(data: CreateTaskRequest): Promise<Task> {
    const response = await apiClient.post('/tasks', data)
    return response.data
  },

  // 获取任务详情
  async get(id: string): Promise<Task> {
    const response = await apiClient.get(`/tasks/${id}`)
    return response.data
  },

  // 更新任务
  async update(id: string, data: UpdateTaskRequest): Promise<Task> {
    const response = await apiClient.put(`/tasks/${id}`, data)
    return response.data
  },

  // 删除任务
  async delete(id: string): Promise<void> {
    await apiClient.delete(`/tasks/${id}`)
  },

  // 执行任务
  async execute(id: string, taskType: string, metadata: Record<string, any>): Promise<any> {
    const response = await apiClient.post('/executor/execute', {
      task_type: taskType,
      metadata: {
        task_id: id,
        ...metadata,
      },
    })
    return response.data
  },
}
