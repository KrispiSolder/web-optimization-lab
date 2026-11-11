<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { Role } from '@/types/models'

const auth = useAuthStore()
const router = useRouter()
const menuOpen = ref(false)

const roleLabel: Record<Role, string> = {
  student: 'Студент',
  teacher: 'Преподаватель',
  admin: 'Администратор',
}

const navigation = computed(() => {
  const items = [
    { name: 'courses', label: 'Курсы' },
    { name: 'profile', label: 'Личный кабинет' },
  ]
  if (auth.role === 'teacher' || auth.role === 'admin') {
    items.push({ name: 'teacher', label: 'Кабинет преподавателя' })
  }
  if (auth.role === 'admin') {
    items.push({ name: 'admin', label: 'Администрирование' })
  }
  return items
})

async function handleSignOut() {
  await auth.signOut()
  menuOpen.value = false
  await router.push({ name: 'home' })
}

function handleRoleChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value as Role
  auth.setDemoRole(value)
  void router.push({ name: 'home' })
}
</script>

<template>
  <header class="sticky top-0 z-20 border-b border-line bg-surface/95 backdrop-blur">
    <div class="mx-auto flex w-full max-w-6xl flex-wrap items-center gap-3 px-4 py-3 sm:px-6">
      <RouterLink :to="{ name: 'home' }" class="flex items-center gap-2">
        <span
          class="grid size-8 place-items-center rounded-md bg-accent font-serif text-sm font-bold text-accent-ink"
          aria-hidden="true"
        >
          W
        </span>
        <span class="font-serif text-base font-bold">Web Optimization Lab</span>
      </RouterLink>

      <nav class="order-3 flex w-full flex-wrap gap-1 sm:order-none sm:w-auto" aria-label="Основная навигация">
        <RouterLink
          v-for="item in navigation"
          :key="item.name"
          :to="{ name: item.name }"
          class="rounded-md px-3 py-1.5 text-sm text-muted hover:bg-surface-2 hover:text-ink"
          active-class="bg-accent-soft text-accent"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="ml-auto flex items-center gap-2">
        <span v-if="auth.isDemo" class="tag-warn hidden sm:inline-flex">демо-режим</span>

        <template v-if="auth.isDemo">
          <label class="flex items-center gap-1.5 text-xs text-muted">
            <span class="hidden md:inline">Роль</span>
            <select :value="auth.demoRole" class="field !w-auto !py-1 text-xs" @change="handleRoleChange">
              <option value="student">Студент</option>
              <option value="teacher">Преподаватель</option>
              <option value="admin">Администратор</option>
            </select>
          </label>
        </template>

        <template v-else-if="auth.isAuthenticated">
          <div class="relative">
            <button class="btn !py-1.5 text-sm" type="button" @click="menuOpen = !menuOpen">
              {{ auth.displayName }}
            </button>
            <div
              v-if="menuOpen"
              class="absolute right-0 z-30 mt-1 w-56 rounded-md border border-line bg-surface p-2 shadow-lg"
            >
              <p class="px-2 py-1 text-xs text-muted">
                {{ auth.role ? roleLabel[auth.role] : 'Без роли' }}
              </p>
              <RouterLink
                :to="{ name: 'profile' }"
                class="block rounded px-2 py-1.5 text-sm hover:bg-surface-2"
                @click="menuOpen = false"
              >
                Личный кабинет
              </RouterLink>
              <button
                type="button"
                class="block w-full rounded px-2 py-1.5 text-left text-sm hover:bg-surface-2"
                @click="handleSignOut"
              >
                Выйти
              </button>
            </div>
          </div>
        </template>

        <RouterLink v-else :to="{ name: 'login' }" class="btn btn-primary !py-1.5 text-sm">
          Войти
        </RouterLink>
      </div>
    </div>
  </header>
</template>
