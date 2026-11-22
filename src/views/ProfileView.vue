<script setup lang="ts">
import { computed, ref } from 'vue'
import { fetchCourses, fetchModules, fetchLaboratories, isConfigured } from '@/lib/api'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const configured = isConfigured()

const visitedLabs = ref<Array<{ id: string; title: string; mode: string; attempts: number; maxAttempts: number; attemptStatus: string }>>([])
const loading = ref(false)
const error = ref<string | null>(null)

const achievements = computed(() => [
  { title: 'Первый эксперимент', text: 'Запустить любую лабораторию', done: visitedLabs.value.length > 0 },
  { title: 'SEO-аудит', text: 'Пройти все тесты метатегов', done: false },
  { title: 'Бюджет изображений', text: 'Уложиться в целевой размер файла', done: false },
  { title: 'Комплексный отчёт', text: 'Сдать практикум с выводами', done: false },
])

async function load() {
  loading.value = true
  error.value = null
  try {
    const courses = await fetchCourses()
    const labs: Array<{ id: string; title: string; mode: string; attempts: number; maxAttempts: number; attemptStatus: string }> = []
    for (const course of courses) {
      const mods = await fetchModules(course.id)
      for (const m of mods) {
        const labsOfModule = await fetchLaboratories(m.id)
        for (const lab of labsOfModule) {
          labs.push({
            id: lab.id,
            title: lab.title,
            mode: lab.type,
            attempts: 0,
            maxAttempts: 3,
            attemptStatus: 'not-started',
          })
        }
      }
    }
    visitedLabs.value = labs
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить профиль'
  } finally {
    loading.value = false
  }
}

if (configured) {
  void load()
}
</script>

<template>
  <div class="flex flex-col gap-6">
    <header>
      <h1 class="text-3xl">Личный кабинет</h1>
      <p class="mt-1 text-sm text-muted">Профиль, достижения и история работ.</p>
    </header>

    <div v-if="!configured" class="card">
      <h2 class="text-lg">Supabase не подключён</h2>
      <p class="mt-2 text-sm text-muted">
        Добавьте переменные <code class="font-mono">VITE_SUPABASE_URL</code> и
        <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> в GitHub → Settings → Secrets and
        variables → Actions → Variables, затем сделайте деплой.
      </p>
    </div>

    <div v-else class="flex flex-col gap-6">
      <div class="grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
        <section class="card">
          <h2 class="text-lg">Профиль</h2>
          <dl class="mt-3 space-y-2 text-sm">
            <div class="flex justify-between gap-3 border-b border-line pb-2">
              <dt class="text-muted">Имя</dt>
              <dd class="font-semibold">{{ auth.displayName }}</dd>
            </div>
            <div class="flex justify-between gap-3 border-b border-line pb-2">
              <dt class="text-muted">Роль</dt>
              <dd class="font-semibold">{{ auth.role ?? 'не назначена' }}</dd>
            </div>
            <div class="flex justify-between gap-3">
              <dt class="text-muted">Режим</dt>
              <dd>{{ auth.isDemo ? 'демо (локальные данные)' : 'Supabase' }}</dd>
            </div>
          </dl>
          <p v-if="auth.isDemo" class="mt-4 rounded-md bg-warn-soft px-3 py-2 text-xs text-warn">
            В рабочей системе роль назначает администратор. В демо-режиме роль выбирается в настройках системы.
          </p>
        </section>

        <section class="card">
          <h2 class="text-lg">Достижения</h2>
          <ul class="mt-3 grid gap-2 sm:grid-cols-2">
            <li
              v-for="item in achievements"
              :key="item.title"
              class="rounded-md border border-line p-3"
              :class="item.done ? 'bg-accent-soft' : ''"
            >
              <p class="text-sm font-semibold" :class="item.done ? 'text-accent' : ''">
                {{ item.done ? '✓' : '○' }} {{ item.title }}
              </p>
              <p class="mt-1 text-xs text-muted">{{ item.text }}</p>
            </li>
          </ul>
        </section>
      </div>

      <section class="card">
        <h2 class="text-lg">История работ</h2>
        <div v-if="visitedLabs.length" class="mt-3 overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="text-left text-xs text-muted">
              <tr>
                <th class="border-b border-line py-2 pr-4">Лаборатория</th>
                <th class="border-b border-line py-2 pr-4">Режим</th>
                <th class="border-b border-line py-2 pr-4">Попытки</th>
                <th class="border-b border-line py-2">Статус</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="lab in visitedLabs" :key="lab.id">
                <td class="border-b border-line py-2 pr-4">
                  <RouterLink :to="{ name: 'lab', params: { id: lab.id } }" class="text-accent hover:underline">
                    {{ lab.title }}
                  </RouterLink>
                </td>
                <td class="border-b border-line py-2 pr-4">{{ lab.mode }}</td>
                <td class="border-b border-line py-2 pr-4">{{ lab.attempts }} / {{ lab.maxAttempts }}</td>
                <td class="border-b border-line py-2">{{ lab.attemptStatus }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-else class="mt-2 text-sm text-muted">Пока нет выполненных или начатых работ.</p>
      </section>

      <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">{{ error }}</p>
    </div>
  </div>
</template>
