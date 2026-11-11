import { createRouter, createWebHashHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { Role } from '@/types/models'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    roles?: Role[]
    title?: string
  }
}

/**
 * Hash history выбран сознательно: GitHub Pages не умеет отдавать index.html
 * для вложенных путей без схемы с 404.html (ТЗ, 8.2). Позже можно перейти
 * на createWebHistory с fallback-страницей.
 */
const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/HomeView.vue'),
    meta: { title: 'Главная' },
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { title: 'Вход' },
  },
  {
    path: '/courses',
    name: 'courses',
    component: () => import('@/views/CoursesView.vue'),
    meta: { title: 'Курсы', requiresAuth: true },
  },
  {
    path: '/courses/:id',
    name: 'course',
    component: () => import('@/views/CourseView.vue'),
    meta: { title: 'Курс', requiresAuth: true },
  },
  {
    path: '/labs/:id',
    name: 'lab',
    component: () => import('@/views/LabView.vue'),
    meta: { title: 'Лаборатория', requiresAuth: true },
  },
  {
    path: '/assignments/:id',
    name: 'assignment',
    component: () => import('@/views/AssignmentView.vue'),
    meta: { title: 'Задание', requiresAuth: true },
  },
  {
    path: '/profile',
    name: 'profile',
    component: () => import('@/views/ProfileView.vue'),
    meta: { title: 'Личный кабинет', requiresAuth: true },
  },
  {
    path: '/reports/:id',
    name: 'report',
    component: () => import('@/views/ReportView.vue'),
    meta: { title: 'Отчёт', requiresAuth: true },
  },
  {
    path: '/teacher',
    name: 'teacher',
    component: () => import('@/views/TeacherView.vue'),
    meta: { title: 'Кабинет преподавателя', requiresAuth: true, roles: ['teacher', 'admin'] },
  },
  {
    path: '/admin',
    name: 'admin',
    component: () => import('@/views/AdminView.vue'),
    meta: { title: 'Администрирование', requiresAuth: true, roles: ['admin'] },
  },
  {
    path: '/forbidden',
    name: 'forbidden',
    component: () => import('@/views/ForbiddenView.vue'),
    meta: { title: 'Доступ запрещён' },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: { title: 'Страница не найдена' },
  },
]

const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.init()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  // Проверка роли в UI — только удобство. Реальные права ограничивает RLS (ТЗ, раздел 2).
  if (to.meta.roles && auth.role && !to.meta.roles.includes(auth.role)) {
    return { name: 'forbidden' }
  }
})

router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} — Web Optimization Lab` : 'Web Optimization Lab'
})

export default router
