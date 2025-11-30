<template>
  <div class="storages-view">
    <el-card>
      <template #header>
        <div class="card-header">
          <h2>数据存储管理</h2>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>
            创建数据存储
          </el-button>
        </div>
      </template>

      <!-- 搜索和筛选 -->
      <div class="search-bar">
        <el-input
          v-model="searchQuery"
          placeholder="搜索数据存储名称"
          clearable
          style="width: 300px"
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-select
          v-model="filterStorageType"
          placeholder="筛选存储类型"
          clearable
          style="width: 200px; margin-left: 16px"
          @change="handleFilter"
        >
          <el-option label="S3" value="s3" />
          <el-option label="OSS" value="oss" />
          <el-option label="MinIO" value="minio" />
          <el-option label="Azure Blob" value="azure_blob" />
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
        <el-table-column prop="storage_type" label="存储类型" width="150" />
        <el-table-column label="上传端点" min-width="200">
          <template #default="{ row }">
            <el-tag size="small" type="success">
              {{ row.upload_endpoint }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="下载端点" min-width="200">
          <template #default="{ row }">
            <el-tag size="small" type="info">
              {{ row.download_endpoint }}
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
        <el-form-item label="存储名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入存储名称" />
        </el-form-item>

        <el-form-item label="存储类型" prop="storage_type">
          <el-select v-model="formData.storage_type" placeholder="请选择存储类型" style="width: 100%">
            <el-option label="S3" value="s3" />
            <el-option label="OSS" value="oss" />
            <el-option label="MinIO" value="minio" />
            <el-option label="Azure Blob" value="azure_blob" />
          </el-select>
        </el-form-item>

        <el-form-item label="上传端点" prop="upload_endpoint">
          <el-input v-model="formData.upload_endpoint" placeholder="例如: https://upload.example.com" />
        </el-form-item>

        <el-form-item label="下载端点" prop="download_endpoint">
          <el-input v-model="formData.download_endpoint" placeholder="例如: https://download.example.com" />
        </el-form-item>

        <el-divider content-position="left">认证配置</el-divider>

        <el-form-item label="Access Key" prop="auth_config.access_key">
          <el-input v-model="formData.auth_config.access_key" placeholder="请输入Access Key" />
        </el-form-item>

        <el-form-item label="Secret Key" prop="auth_config.secret_key">
          <el-input
            v-model="formData.auth_config.secret_key"
            type="password"
            placeholder="请输入Secret Key"
            show-password
          />
        </el-form-item>

        <el-form-item label="Region" prop="auth_config.region">
          <el-input v-model="formData.auth_config.region" placeholder="例如: us-east-1（可选）" />
        </el-form-item>

        <el-form-item label="Bucket" prop="auth_config.bucket">
          <el-input v-model="formData.auth_config.bucket" placeholder="请输入Bucket名称（可选）" />
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
import { storageApi, type Storage, type CreateStorageRequest } from '@/api'

// 数据列表
const storages = ref<Storage[]>([])
const loading = ref(false)

// 搜索和筛选
const searchQuery = ref('')
const filterStorageType = ref('')

// 分页
const currentPage = ref(1)
const pageSize = ref(10)

// 对话框
const dialogVisible = ref(false)
const dialogTitle = ref('创建数据存储')
const isEditMode = ref(false)
const editingId = ref('')
const submitting = ref(false)

// 表单
const formRef = ref<FormInstance>()
const formData = ref<CreateStorageRequest>({
  name: '',
  storage_type: '',
  upload_endpoint: '',
  download_endpoint: '',
  auth_config: {
    access_key: '',
    secret_key: '',
    region: '',
    bucket: '',
  },
})

const formRules: FormRules = {
  name: [
    { required: true, message: '请输入存储名称', trigger: 'blur' },
    { min: 2, max: 100, message: '长度在 2 到 100 个字符', trigger: 'blur' },
  ],
  storage_type: [
    { required: true, message: '请选择存储类型', trigger: 'change' },
  ],
  upload_endpoint: [
    { required: true, message: '请输入上传端点', trigger: 'blur' },
    { type: 'url', message: '请输入有效的URL', trigger: 'blur' },
  ],
  download_endpoint: [
    { required: true, message: '请输入下载端点', trigger: 'blur' },
    { type: 'url', message: '请输入有效的URL', trigger: 'blur' },
  ],
  'auth_config.access_key': [
    { required: true, message: '请输入Access Key', trigger: 'blur' },
  ],
  'auth_config.secret_key': [
    { required: true, message: '请输入Secret Key', trigger: 'blur' },
  ],
}

// 计算属性：筛选后的数据
const filteredData = computed(() => {
  let result = storages.value

  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter((item) => item.name.toLowerCase().includes(query))
  }

  // 类型过滤
  if (filterStorageType.value) {
    result = result.filter((item) => item.storage_type === filterStorageType.value)
  }

  return result
})

// 计算属性：分页后的数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 加载数据存储列表
const loadStorages = async () => {
  loading.value = true
  try {
    storages.value = await storageApi.list()
  } catch (error) {
    console.error('加载数据存储列表失败:', error)
    ElMessage.error('加载数据存储列表失败')
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

// 创建数据存储
const handleCreate = () => {
  isEditMode.value = false
  dialogTitle.value = '创建数据存储'
  formData.value = {
    name: '',
    storage_type: '',
    upload_endpoint: '',
    download_endpoint: '',
    auth_config: {
      access_key: '',
      secret_key: '',
      region: '',
      bucket: '',
    },
  }
  dialogVisible.value = true
}

// 编辑数据存储
const handleEdit = (row: Storage) => {
  isEditMode.value = true
  editingId.value = row.id
  dialogTitle.value = '编辑数据存储'
  formData.value = {
    name: row.name,
    storage_type: row.storage_type,
    upload_endpoint: row.upload_endpoint,
    download_endpoint: row.download_endpoint,
    auth_config: { ...row.auth_config },
  }
  dialogVisible.value = true
}

// 删除数据存储
const handleDelete = async (row: Storage) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除数据存储 "${row.name}" 吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    await storageApi.delete(row.id)
    ElMessage.success('删除成功')
    await loadStorages()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除数据存储失败:', error)
      ElMessage.error('删除数据存储失败')
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
      await storageApi.update(editingId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await storageApi.create(formData.value)
      ElMessage.success('创建成功')
    }

    dialogVisible.value = false
    await loadStorages()
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
}

// 组件挂载时加载数据
onMounted(() => {
  loadStorages()
})
</script>

<style scoped>
.storages-view {
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
