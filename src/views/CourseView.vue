<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import ModeBadge from '@/components/ModeBadge.vue'
import { findCourse } from '@/data/catalog'

const route = useRoute()
const course = computed(() => findCourse(String(route.params.id)))

const totalLabs = computed(
  () => course.value?.modules.reduce((sum, module) => sum + module.labs.length, 0) ?? 0,
)

const completed = computed(
  () =>
    course.value?.modules
      .flatMap((module) => module.labs)
      .filter((lab) => lab.attemptStatus === 'submitted' || lab.attemptStatus === 'graded').length ?? 0,
)

const progress = computed(() =>
  totalLabs.value === 0 ? 0 : Math.round((completed.value / totalLabs.value) * 100),
)

const statusLabel: Record<string, string> = {
  'not-started': 'не начато',
  'in-progress': 'в работе',
  submitted: 'сдано',
  graded: 'проверено',
  returned: 'на доработке',
}

const statusClass: Record<string, string> = {
  'not-started': 'text-muted',
  'in-progress': 'text-warn',
  submitted: 'text-accent',
  graded: 'text-ok',
  returned: 'text-bad',
}
</script>

<template>
  <div v-if="course" class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'courses' }" class="hover:text-ink">Курсы</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">{{ course.code }}</span>
    </nav>

    <header class="card">
      <div class="flex flex-wrap items-center gap-2">
        <span class="tag">{{ course.code }}</span>
        <span class="tag-warn">{{ course.academicYear }}</span>
      </div>
      <h1 class="mt-3 text-3xl">{{ course.title }}</h1>
      <p class="mt-2 max-w-3xl text-sm text-muted">{{ course.description }}</p>

      <div class="mt-5">
        <div class="flex items-center justify-between text-sm">
          <span class="text-muted">Прогресс по лабораториям</span>
          <span class="font-semibold">{{ completed }} / {{ totalLabs }}</span>
        </div>
        <div
          class="mt-2 h-2 overflow-hidden rounded-full bg-surface-2"
          role="progressbar"
          :aria-valuenow="progress"
          aria-valuemin="0"
          aria-valuemax="100"
        >
          <div class="h-full rounded-full bg-accent transition-all" :style="{ width: `${progress}%` }" />
        </div>
      </div>
    </header>

    <section v-for="module in course.modules" :key="module.id" class="flex flex-col gap-3">
      <div>
        <h2 class="text-xl">{{ module.title }}</h2>
        <p class="text-sm text-muted">{{ module.intro }}</p>
      </div>

      <div class="grid gap-3">
        <article
          v-for="lab in module.labs"
          :key="lab.id"
          class="card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
        >
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <ModeBadge :mode="lab.mode" />
              <span v-if="lab.status === 'draft'" class="tag-warn">черновик</span>
              <span class="text-xs" :class="statusClass[lab.attemptStatus]">
                {{ statusLabel[lab.attemptStatus] }}
              </span>
            </div>
            <h3 class="mt-2 text-lg">{{ lab.title }}</h3>
            <p class="mt-1 text-sm text-muted">{{ lab.description }}</p>
            <p class="mt-1 text-xs text-muted">
              Попытки: {{ lab.attempts }} из {{ lab.maxAttempts }}
            </p>
          </div>

          <RouterLink
            v-if="lab.status === 'published'"
            :to="{ name: 'lab', params: { id: lab.id } }"
            class="btn btn-primary shrink-0"
          >
            {{ lab.attemptStatus === 'not-started' ? 'Начать' : 'Продолжить' }}
          </RouterLink>
          <span v-else class="btn shrink-0 cursor-not-allowed opacity-60" aria-disabled="true">
            Не опубликовано
          </span>
        </article>
      </div>
    </section>
  </div>

  <div v-else class="card">
    <h1 class="text-2xl">Курс не найден</h1>
    <p class="mt-2 text-sm text-muted">Проверьте ссылку или вернитесь в каталог.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>
</template>
