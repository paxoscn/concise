import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/',
      redirect: '/dashboard',
    },
    {
      path: '/dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'home',
          component: () => import('../views/HomeView.vue'),
        },
        {
          path: '/data-sources',
          name: 'data-sources',
          component: () => import('../views/DataSourcesView.vue'),
        },
        {
          path: '/storages',
          name: 'storages',
          component: () => import('../views/StoragesView.vue'),
        },
        {
          path: '/tasks',
          name: 'tasks',
          component: () => import('../views/TasksView.vue'),
        },
      ],
    },
  ],
})

// 路由守卫 - 保护需要认证的路由
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  const requiresAuth = to.meta.requiresAuth !== false

  if (requiresAuth) {
    // 需要认证的路由
    if (!authStore.isAuthenticated) {
      // 未登录，跳转到登录页
      next({
        path: '/login',
        query: { redirect: to.fullPath }, // 保存目标路由，登录后可跳转回来
      })
      return
    }

    // 已登录，检查token是否过期
    const isValid = authStore.checkTokenExpiry()
    if (!isValid) {
      // Token已过期，跳转到登录页
      next({
        path: '/login',
        query: { redirect: to.fullPath },
      })
      return
    }
  } else if (to.path === '/login' && authStore.isAuthenticated) {
    // 已登录用户访问登录页，跳转到首页或重定向目标
    const redirect = (to.query.redirect as string) || '/dashboard'
    next(redirect)
    return
  }

  next()
})

export default router
