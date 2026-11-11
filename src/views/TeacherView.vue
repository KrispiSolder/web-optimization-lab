<script setup lang="ts">
import { computed } from 'vue'
import ModeBadge from '@/components/ModeBadge.vue'
import { demoCourses } from '@/data/catalog'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const labs = computed(() => demoCourses.flatMap((course) => course.modules.flatMap((module) => module.labs)))
const active = computed(() => labs.value.filter((lab) => lab.attemptStatus !== 'not-started'))
const averageAttempts = computed(() => {
  if (labs.value.length === 0) return 0
  return (labs.value.reduce((sum, lab) => sum + lab.attempts, 0) / labs.value.length).toFixed(1)
})
</script>

<template>
  <div class="flex flex-col gap-6">
    <header class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-3xl">Кабинет преподавателя</h1>
        <p class="mt-1 text-sm text-muted">
          Журнал выполнения и аналитика. В демо-режиме показан пример структуры данных.
        </p>
      </div>
      <RouterLink :to="{ name: 'courses' }" class="btn">Мои курсы</RouterLink>
    </header>

    <div class="grid gap-4 sm:grid-cols-3">
      <div class="card">
        <p class="text-sm text-muted">Активных работ</p>
        <p class="font-serif text-3xl font-bold text-accent">{{ active.length }}</p>
      </div>
      <div class="card">
        <p class="text-sm text-muted">Среднее число попыток</p>
        <p class="font-serif text-3xl font-bold text-accent">{{ averageAttempts }}</p>
      </div>
      <div class="card">
        <p class="text-sm text-muted">Лабораторий в каталоге</p>
        <p class="font-serif text-3xl font-bold text-accent">{{ labs.length }}</p>
      </div>
    </div>

    <section class="card">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <h2 class="text-lg">Журнал выполнения</h2>
        <span class="tag-warn">данные демонстрационные</span>
      </div>

      <div class="mt-3 overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="text-left text-xs text-muted">
            <tr>
              <th class="border-b border-line py-2 pr-4">Лаборатория</th>
              <th class="border-b border-line py-2 pr-4">Режим</th>
              <th class="border-b border-line py-2 pr-4">Статус</th>
              <th class="border-b border-line py-2 pr-4">Попытки</th>
              <th class="border-b border-line py-2 pr-4">Авто</th>
              <th class="border-b border-line py-2">Комментарий</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="lab in labs" :key="lab.id">
              <td class="border-b border-line py-2 pr-4">{{ lab.title }}</td>
              <td class="border-b border-line py-2 pr-4"><ModeBadge :mode="lab.mode" /></td>
              <td class="border-b border-line py-2 pr-4">{{ lab.attemptStatus }}</td>
              <td class="border-b border-line py-2 pr-4">{{ lab.attempts }} / {{ lab.maxAttempts }}</td>
              <td class="border-b border-line py-2 pr-4">—</td>
              <td class="border-b border-line py-2 text-muted">—</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p class="mt-3 text-xs text-muted">
        Выставление баллов, возврат на доработку и комментарии подключаются вместе с таблицей grades
        на этапе 4. Оценка всегда считается по версии задания, к которой привязана попытка.
      </p>
    </section>

    <section class="grid gap-4 sm:grid-cols-2">
      <div class="card">
        <h2 class="text-lg">Конструктор заданий</h2>
        <p class="mt-1 text-sm text-muted">
          Визуальная форма по шаблону: параметры, критерии, тесты, версии и публикация.
        </p>
        <button class="btn mt-4" type="button" disabled>Открыть конструктор (этап 2)</button>
      </div>
      <div class="card">
        <h2 class="text-lg">Аналитика</h2>
        <p class="mt-1 text-sm text-muted">
          Распределение результатов, популярные ошибки и динамика улучшений по группе.
        </p>
        <p class="mt-4 rounded-md border border-dashed border-line p-4 text-center text-xs text-muted">
          Графики ECharts — этап 4
        </p>
      </div>
    </section>

    <p v-if="auth.isDemo" class="rounded-md bg-surface-2 px-3 py-2 text-xs text-muted">
      Чтобы увидеть страницу с ролью преподавателя, переключите роль в шапке.
    </p>
  </div>
</template>
