<template>
  <div class="data-sources-view">
    <el-card>
      <template #header>
        <div class="card-header">
          <h2>数据源管理</h2>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>
            创建数据源
          </el-button>
        </div>
      </template>

      <!-- 搜索和筛选 -->
      <div class="search-bar">
        <el-input
          v-model="searchQuery"
          placeholder="搜索数据源名称"
          clearable
          style="width: 300px"
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-select
          v-model="filterDbType"
          placeholder="筛选数据库类型"
          clearable
          style="width: 200px; margin-left: 16px"
          @change="handleFilter"
        >
          <el-option label="MySQL" value="mysql" />
          <el-option label="PostgreSQL" value="postgresql" />
          <el-option label="SQLite" value="sqlite" />
          <el-option label="SQL Server" value="sqlserver" />
        </el-select>
      </div>

      <!-- 数据表格 -->
      <el-table
        v-loading="loading"
        :data="paginatedData"
        style="width: 100%; margin-top: 20px"
        stripe
      >
        <el-table-column prop="name" label="名称" min-width="150" />
        <el-table-column prop="db_type" label="数据库类型" width="150" />
        <el-table-column label="连接配置" min-width="200">
          <template #default="{ row }">
            <el-tag v-if="row.connection_config.host" size="small">
              {{ row.connection_config.host }}:{{ row.connection_config.port || '3306' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
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
      width="600px"
      @close="handleDialogClose"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="120px"
      >
        <el-form-item label="数据源名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入数据源名称" />
        </el-form-item>

        <el-form-item label="数据库类型" prop="db_type">
          <el-select v-model="formData.db_type" placeholder="请选择数据库类型" style="width: 100%">
            <el-option label="MySQL" value="mysql" />
            <el-option label="PostgreSQL" value="postgresql" />
            <el-option label="SQLite" value="sqlite" />
            <el-option label="SQL Server" value="sqlserver" />
          </el-select>
        </el-form-item>

        <el-divider content-position="left">连接配置</el-divider>

        <el-form-item label="主机地址" prop="connection_config.host">
          <el-input v-model="formData.connection_config.host" placeholder="例如: localhost" />
        </el-form-item>

        <el-form-item label="端口" prop="connection_config.port">
          <el-input-number
            v-model="formData.connection_config.port"
            :min="1"
            :max="65535"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item label="数据库名" prop="connection_config.database">
          <el-input v-model="formData.connection_config.database" placeholder="请输入数据库名" />
        </el-form-item>

        <el-form-item label="用户名" prop="connection_config.username">
          <el-input v-model="formData.connection_config.username" placeholder="请输入用户名" />
        </el-form-item>

        <el-form-item label="密码" prop="connection_config.password">
          <el-input
            v-model="formData.connection_config.password"
            type="password"
            placeholder="请输入密码"
            show-password
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import { dataSourceApi, type DataSource, type CreateDataSourceRequest } from '@/api'

// 数据列表
const dataSources = ref<DataSource[]>([])
const loading = ref(false)

// 搜索和筛选
const searchQuery = ref('')
const filterDbType = ref('')

// 分页
const currentPage = ref(1)
const pageSize = ref(10)

// 对话框
const dialogVisible = ref(false)
const dialogTitle = ref('创建数据源')
const isEditMode = ref(false)
const editingId = ref('')
const submitting = ref(false)

// 表单
const formRef = ref<FormInstance>()
const formData = ref<CreateDataSourceRequest>({
  name: '',
  db_type: '',
  connection_config: {
    host: '',
    port: 3306,
    database: '',
    username: '',
    password: '',
  },
})

const formRules: FormRules = {
  name: [
    { required: true, message: '请输入数据源名称', trigger: 'blur' },
    { min: 2, max: 100, message: '长度在 2 到 100 个字符', trigger: 'blur' },
  ],
  db_type: [
    { required: true, message: '请选择数据库类型', trigger: 'change' },
  ],
  'connection_config.host': [
    { required: true, message: '请输入主机地址', trigger: 'blur' },
  ],
  'connection_config.port': [
    { required: true, message: '请输入端口', trigger: 'blur' },
  ],
  'connection_config.database': [
    { required: true, message: '请输入数据库名', trigger: 'blur' },
  ],
  'connection_config.username': [
    { required: true, message: '请输入用户名', trigger: 'blur' },
  ],
  'connection_config.password': [
    { required: true, message: '请输入密码', trigger: 'blur' },
  ],
}

// 计算属性：筛选后的数据
const filteredData = computed(() => {
  let result = dataSources.value

  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter((item) => item.name.toLowerCase().includes(query))
  }

  // 类型过滤
  if (filterDbType.value) {
    result = result.filter((item) => item.db_type === filterDbType.value)
  }

  return result
})

// 计算属性：分页后的数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 加载数据源列表
const loadDataSources = async () => {
  loading.value = true
  try {
    dataSources.value = await dataSourceApi.list()
  } catch (error) {
    console.error('加载数据源列表失败:', error)
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

// 创建数据源
const handleCreate = () => {
  isEditMode.value = false
  dialogTitle.value = '创建数据源'
  formData.value = {
    name: '',
    db_type: '',
    connection_config: {
      host: '',
      port: 3306,
      database: '',
      username: '',
      password: '',
    },
  }
  dialogVisible.value = true
}

// 编辑数据源
const handleEdit = (row: DataSource) => {
  isEditMode.value = true
  editingId.value = row.id
  dialogTitle.value = '编辑数据源'
  formData.value = {
    name: row.name,
    db_type: row.db_type,
    connection_config: { ...row.connection_config },
  }
  dialogVisible.value = true
}

// 删除数据源
const handleDelete = async (row: DataSource) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除数据源 "${row.name}" 吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    await dataSourceApi.delete(row.id)
    ElMessage.success('删除成功')
    await loadDataSources()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除数据源失败:', error)
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    submitting.value = true

    if (isEditMode.value) {
      await dataSourceApi.update(editingId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await dataSourceApi.create(formData.value)
      ElMessage.success('创建成功')
    }

    dialogVisible.value = false
    await loadDataSources()
  } catch (error) {
    if (error !== false) {
      console.error('提交失败:', error)
    }
  } finally {
    submitting.value = false
  }
}

// 对话框关闭处理
const handleDialogClose = () => {
  formRef.value?.resetFields()
}

// 组件挂载时加载数据
onMounted(() => {
  loadDataSources()
})
</script>

<style scoped>
.data-sources-view {
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
