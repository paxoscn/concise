import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import zhCn from 'element-plus/es/locale/lang/zh-cn'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'

const app = createApp(App)

const pinia = createPinia()
app.use(pinia)

// 初始化认证状态（从localStorage恢复）
const authStore = useAuthStore()
authStore.initAuth()

app.use(router)
app.use(ElementPlus, {
  locale: zhCn,
})

app.mount('#app')
