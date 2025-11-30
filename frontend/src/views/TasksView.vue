<template>
  <div class="tasks-view">
    <el-card>
      <template #header>
        <div class="card-header">
          <h2>任务管理</h2>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>
            创建任务
          </el-button>
        </div>
      </template>

      <!-- 搜索和筛选 -->
      <div class="search-bar">
        <el-input
          v-model="searchQuery"
          placeholder="搜索任务名称"
          clearable
          style="width: 300px"
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-select
          v-model="filterTaskType"
          placeholder="筛选任务类型"
          clearable
          style="width: 200px; margin-left: 16px"
          @change="handleFilter"
        >
          <el-option label="SQL" value="sql" />
          <el-option label="Excel" value="excel" />
        </el-select>

        <el-select
          v-model="filterStatus"
          placeholder="筛选状态"
          clearable
          style="width: 200px; margin-left: 16px"
          @change="handleFilter"
        >
          <el-option label="待执行" value="pending" />
          <el-option label="执行中" value="running" />
          <el-option label="已完成" value="completed" />
          <el-option label="失败" value="failed" />
        </el-select>
      </div>

      <!-- 数据表格 -->
      <el-table
        v-loading="loading"
        :data="paginatedData"
        style="width: 100%; margin-top: 20px"
        stripe
      >
        <el-table-column prop="name" label="任务名称" min-width="180" />
        <el-table-column prop="task_type" label="任务类型" width="120">
          <template #default="{ row }">
            <el-tag :type="getTaskTypeTagType(row.task_type)" size="small">
              {{ getTaskTypeLabel(row.task_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)" size="small">
              {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="元数据" min-width="200">
          <template #default="{ row }">
            <el-tooltip
              v-if="Object.keys(row.metadata).length > 0"
              effect="dark"
              placement="top"
            >
              <template #content>
                <pre style="max-width: 400px; white-space: pre-wrap">{{ JSON.stringify(row.metadata, null, 2) }}</pre>
              </template>
              <el-tag size="small" style="cursor: pointer">
                查看详情
              </el-tag>
            </el-tooltip>
            <span v-else style="color: #999">无</span>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button
              type="success"
              size="small"
              link
              @click="handleExecute(row)"
              :disabled="row.status === 'running'"
            >
              执行
            </el-button>
            <el-button
              type="primary"
              size="small"
              link
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              type="danger"
              size="small"
              link
              @click="handleDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="filteredData.length"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="700px"
      @close="handleDialogClose"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="120px"
      >
        <el-form-item label="任务名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入任务名称" />
        </el-form-item>

        <el-form-item label="任务类型" prop="task_type">
          <el-select v-model="formData.task_type" placeholder="请选择任务类型" style="width: 100%">
            <el-option label="SQL" value="sql" />
            <el-option label="Excel" value="excel" />
          </el-select>
        </el-form-item>

        <el-divider content-position="left">任务元数据</el-divider>

        <el-form-item label="元数据配置" prop="metadataJson">
          <el-input
            v-model="metadataJson"
            type="textarea"
            :rows="10"
            placeholder='请输入JSON格式的元数据，例如：
{
  "dependencies": ["task-id-1", "task-id-2"],
  "next_actions": [
    {
      "action_type": "trigger",
      "target_task_id": "next-task-id"
    }
  ],
  "config": {
    "sql": "SELECT * FROM users",
    "data_source_id": "uuid-here"
  }
}'
          />
        </el-form-item>

        <el-alert
          v-if="metadataError"
          :title="metadataError"
          type="error"
          :closable="false"
          style="margin-top: 10px"
        />
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 执行任务对话框 -->
    <el-dialog
      v-model="executeDialogVisible"
      title="执行任务"
      width="500px"
    >
      <el-alert
        title="确认执行"
        type="warning"
        :closable="false"
        style="margin-bottom: 20px"
      >
        <template #default>
          <p>即将执行任务: <strong>{{ executingTask?.name }}</strong></p>
          <p>任务类型: <strong>{{ getTaskTypeLabel(executingTask?.task_type || '') }}</strong></p>
        </template>
      </el-alert>

      <template #footer>
        <el-button @click="executeDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="executing" @click="confirmExecute">
          确认执行
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import { taskApi, type Task, type CreateTaskRequest } from '@/api'

// 数据列表
const tasks = ref<Task[]>([])
const loading = ref(false)

// 搜索和筛选
const searchQuery = ref('')
const filterTaskType = ref('')
const filterStatus = ref('')

// 分页
const currentPage = ref(1)
const pageSize = ref(10)

// 对话框
const dialogVisible = ref(false)
const dialogTitle = ref('创建任务')
const isEditMode = ref(false)
const editingId = ref('')
const submitting = ref(false)

// 执行对话框
const executeDialogVisible = ref(false)
const executingTask = ref<Task | null>(null)
const executing = ref(false)

// 表单
const formRef = ref<FormInstance>()
const formData = ref<CreateTaskRequest>({
  name: '',
  task_type: '',
  metadata: {},
})

// 元数据JSON字符串
const metadataJson = ref('')
const metadataError = ref('')

// 监听元数据JSON变化，验证格式
watch(metadataJson, (newVal) => {
  if (!newVal.trim()) {
    metadataError.value = ''
    formData.value.metadata = {}
    return
  }

  try {
    formData.value.metadata = JSON.parse(newVal)
    metadataError.value = ''
  } catch (error) {
    metadataError.value = 'JSON格式错误，请检查'
  }
})

const formRules: FormRules = {
  name: [
    { required: true, message: '请输入任务名称', trigger: 'blur' },
    { min: 2, max: 100, message: '长度在 2 到 100 个字符', trigger: 'blur' },
  ],
  task_type: [
    { required: true, message: '请选择任务类型', trigger: 'change' },
  ],
}

// 计算属性：筛选后的数据
const filteredData = computed(() => {
  let result = tasks.value

  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter((item) => item.name.toLowerCase().includes(query))
  }

  // 类型过滤
  if (filterTaskType.value) {
    result = result.filter((item) => item.task_type === filterTaskType.value)
  }

  // 状态过滤
  if (filterStatus.value) {
    result = result.filter((item) => item.status === filterStatus.value)
  }

  return result
})

// 计算属性：分页后的数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 加载任务列表
const loadTasks = async () => {
  loading.value = true
  try {
    tasks.value = await taskApi.list()
  } catch (error) {
    console.error('加载任务列表失败:', error)
    ElMessage.error('加载任务列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = () => {
  currentPage.value = 1
}

// 筛选处理
const handleFilter = () => {
  currentPage.value = 1
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  currentPage.value = 1
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
}

// 格式化日期
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// 获取任务类型标签
const getTaskTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    sql: 'SQL',
    excel: 'Excel',
  }
  return labels[type] || type
}

const getTaskTypeTagType = (type: string) => {
  const types: Record<string, any> = {
    sql: 'primary',
    excel: 'success',
  }
  return types[type] || ''
}

// 获取状态标签
const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: '待执行',
    running: '执行中',
    completed: '已完成',
    failed: '失败',
  }
  return labels[status] || status
}

const getStatusTagType = (status: string) => {
  const types: Record<string, any> = {
    pending: 'info',
    running: 'warning',
    completed: 'success',
    failed: 'danger',
  }
  return types[status] || ''
}

// 创建任务
const handleCreate = () => {
  isEditMode.value = false
  dialogTitle.value = '创建任务'
  formData.value = {
    name: '',
    task_type: '',
    metadata: {},
  }
  metadataJson.value = ''
  metadataError.value = ''
  dialogVisible.value = true
}

// 编辑任务
const handleEdit = (row: Task) => {
  isEditMode.value = true
  editingId.value = row.id
  dialogTitle.value = '编辑任务'
  formData.value = {
    name: row.name,
    task_type: row.task_type,
    metadata: { ...row.metadata },
  }
  metadataJson.value = JSON.stringify(row.metadata, null, 2)
  metadataError.value = ''
  dialogVisible.value = true
}

// 删除任务
const handleDelete = async (row: Task) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除任务 "${row.name}" 吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    await taskApi.delete(row.id)
    ElMessage.success('删除成功')
    await loadTasks()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除任务失败:', error)
      ElMessage.error('删除任务失败')
    }
  }
}

// 执行任务
const handleExecute = (row: Task) => {
  executingTask.value = row
  executeDialogVisible.value = true
}

const confirmExecute = async () => {
  if (!executingTask.value) return

  executing.value = true
  try {
    const result = await taskApi.execute(
      executingTask.value.id,
      executingTask.value.task_type,
      executingTask.value.metadata
    )
    
    ElMessage.success('任务执行成功')
    executeDialogVisible.value = false
    await loadTasks()
    
    // 显示执行结果
    if (result.message) {
      ElMessageBox.alert(result.message, '执行结果', {
        confirmButtonText: '确定',
        type: result.success ? 'success' : 'error',
      })
    }
  } catch (error) {
    console.error('执行任务失败:', error)
    ElMessage.error('执行任务失败')
  } finally {
    executing.value = false
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return

  // 检查元数据JSON格式
  if (metadataError.value) {
    ElMessage.error('请修正元数据JSON格式错误')
    return
  }

  try {
    await formRef.value.validate()
    submitting.value = true

    if (isEditMode.value) {
      await taskApi.update(editingId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await taskApi.create(formData.value)
      ElMessage.success('创建成功')
    }

    dialogVisible.value = false
    await loadTasks()
  } catch (error) {
    if (error !== false) {
      console.error('提交失败:', error)
      ElMessage.error('操作失败，请重试')
    }
  } finally {
    submitting.value = false
  }
}

// 对话框关闭处理
const handleDialogClose = () => {
  formRef.value?.resetFields()
  metadataJson.value = ''
  metadataError.value = ''
}

// 组件挂载时加载数据
onMounted(() => {
  loadTasks()
})
</script>

<style scoped>
.tasks-view {
  width: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
}

.search-bar {
  display: flex;
  align-items: center;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
