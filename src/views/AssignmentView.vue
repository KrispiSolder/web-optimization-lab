<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { findAssignment, findLab } from '@/data/catalog'

const route = useRoute()
const assignment = computed(() => findAssignment(String(route.params.id)))
const lab = computed(() => (assignment.value ? findLab(assignment.value.labId)?.lab : undefined))

const dueLabel = computed(() => {
  if (!assignment.value) return ''
  return new Intl.DateTimeFormat('ru-RU', {
    dateStyle: 'long',
    timeStyle: 'short',
  }).format(new Date(assignment.value.dueAt))
})
</script>

<template>
  <div v-if="assignment" class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'courses' }" class="hover:text-ink">Курсы</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">Задание</span>
    </nav>

    <header class="card">
      <div class="flex flex-wrap items-center gap-2">
        <span class="tag">задание</span>
        <span class="tag-warn">до {{ dueLabel }}</span>
      </div>
      <h1 class="mt-3 text-3xl">{{ assignment.title }}</h1>
      <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-3">
        <div>
          <dt class="text-muted">Максимальный балл</dt>
          <dd class="font-semibold">{{ assignment.maxScore }}</dd>
        </div>
        <div>
          <dt class="text-muted">Попытки</dt>
          <dd class="font-semibold">до {{ assignment.maxAttempts }}</dd>
        </div>
        <div>
          <dt class="text-muted">Режим проверки</dt>
          <dd class="font-semibold">Авто + экспертная</dd>
        </div>
      </dl>
    </header>

    <div class="grid gap-4 lg:grid-cols-[1.1fr_0.9fr]">
      <section class="card">
        <h2 class="text-lg">Критерии оценивания</h2>
        <ol class="mt-3 list-decimal space-y-2 pl-5 text-sm">
          <li v-for="criterion in assignment.criteria" :key="criterion">{{ criterion }}</li>
        </ol>
        <p class="mt-4 text-xs text-muted">
          Критерии привязаны к версии задания. Изменение опубликованного задания создаёт новую
          версию и не меняет уже начатые попытки.
        </p>
      </section>

      <section class="card flex flex-col gap-3">
        <h2 class="text-lg">Попытки</h2>
        <p class="rounded-md border border-dashed border-line p-6 text-center text-sm text-muted">
          Попыток пока нет
        </p>
        <RouterLink
          v-if="lab"
          :to="{ name: 'lab', params: { id: lab.id } }"
          class="btn btn-primary"
        >
          Начать попытку
        </RouterLink>
        <p class="text-xs text-muted">
          При старте фиксируются дата, время, версия задания и статус «в работе».
        </p>
      </section>
    </div>
  </div>

  <div v-else class="card">
    <h1 class="text-2xl">Задание не найдено</h1>
    <p class="mt-2 text-sm text-muted">Задание могло быть архивировано или снято с назначения.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>
</template>
