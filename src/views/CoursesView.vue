<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { fetchCourses, isConfigured } from '@/lib/api'
import type { Course } from '@/types/models'
import ModeBadge from '@/components/ModeBadge.vue'

const query = ref('')
const courses = ref<Course[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

const configured = isConfigured()

async function load() {
  loading.value = true
  error.value = null
  try {
    courses.value = await fetchCourses()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить курсы'
  } finally {
    loading.value = false
  }
}

const filtered = computed(() => {
  const value = query.value.trim().toLowerCase()
  if (!value) return courses.value
  return courses.value.filter(
    (course) =>
      course.title.toLowerCase().includes(value) ||
      course.code.toLowerCase().includes(value) ||
      course.description.toLowerCase().includes(value),
  )
})

function labCount(courseId: string, mode?: string) {
  const course = courses.value.find((item) => item.id === courseId)
  if (!course?.modules) return 0
  const labs = course.modules.flatMap((module) => module.laboratories ?? [])
  return mode ? labs.filter((lab) => lab.type === mode).length : labs.length
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="flex flex-col gap-6">
    <div v-if="!configured" class="card">
      <h2 class="text-lg">Supabase не подключён</h2>
      <p class="mt-2 text-sm text-muted">
        Добавьте переменные <code class="font-mono">VITE_SUPABASE_URL</code> и
        <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> в GitHub → Settings → Secrets and
        variables → Actions → Variables, затем сделайте деплой.
      </p>
    </div>

    <div v-else class="flex flex-col gap-6">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 class="text-3xl">Каталог курсов</h1>
          <p class="mt-1 text-sm text-muted">Доступны курсы, назначенные вашей группе и опубликованные.</p>
        </div>
        <div class="w-full sm:w-72">
          <label class="label" for="course-search">Поиск</label>
          <input
            id="course-search"
            v-model="query"
            class="field"
            type="search"
            placeholder="Название или код дисциплины"
          />
        </div>
      </div>

      <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">
        {{ error }}
      </p>

      <div v-if="loading" class="card text-sm text-muted">Загрузка курсов…</div>

      <div v-if="filtered.length && !loading" class="grid gap-4 md:grid-cols-2">
        <RouterLink
          v-for="course in filtered"
          :key="course.id"
          :to="{ name: 'course', params: { id: course.id } }"
          class="card group flex flex-col gap-3 transition-colors hover:border-accent"
        >
          <div class="flex flex-wrap items-center gap-2">
            <span class="tag">{{ course.code }}</span>
            <span class="tag-warn">{{ course.academic_year }}</span>
          </div>
          <h2 class="text-xl group-hover:text-accent">{{ course.title }}</h2>
          <p class="text-sm text-muted">{{ course.description }}</p>
          <div class="mt-auto flex flex-wrap items-center gap-3 border-t border-line pt-3 text-xs text-muted">
            <span>{{ course.modules?.length ?? 0 }} блока</span>
            <span>{{ labCount(course.id) }} лабораторий</span>
            <span class="flex items-center gap-1">
              <ModeBadge mode="parameter-simulator" /> {{ labCount(course.id, 'parameter-simulator') }}
            </span>
            <span class="flex items-center gap-1">
              <ModeBadge mode="code-lab" /> {{ labCount(course.id, 'code-lab') }}
            </span>
            <span class="flex items-center gap-1">
              <ModeBadge mode="case-practicum" /> {{ labCount(course.id, 'case-practicum') }}
            </span>
          </div>
        </RouterLink>
      </div>

      <div v-else-if="!loading && !error" class="card text-sm text-muted">По запросу «{{ query }}» ничего не найдено.</div>
    </div>
  </div>
</template>
