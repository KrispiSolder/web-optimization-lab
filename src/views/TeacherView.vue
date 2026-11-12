<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  fetchCourses,
  createCourse,
  archiveCourse,
  publishCourse,
  fetchGroups,
  fetchProfiles,
  isConfigured,
} from '@/lib/api'
import type { Course } from '@/types/models'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const courses = ref<Course[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
const openCreate = ref(false)
const createDraft = ref<Partial<Course>>({
  title: '',
  code: '',
  description: '',
  academic_year: '',
  status: 'draft',
})

const groups = ref<{ id: string; name: string }[]>([])
const profiles = ref<{ id: string; display_name: string | null; role: string }[]>([])

const statusLabel: Record<string, string> = {
  draft: 'Черновик',
  published: 'Опубликован',
  archived: 'В архиве',
}

async function load() {
  loading.value = true
  error.value = null
  try {
    courses.value = await fetchCourses()
    if (auth.role === 'admin') {
      [groups.value, profiles.value] = await Promise.all([fetchGroups(), fetchProfiles()])
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить курсы'
  } finally {
    loading.value = false
  }
}

async function handleCreate() {
  if (!createDraft.value.title || !createDraft.value.code) {
    error.value = 'Заполните название и код курса'
    return
  }
  loading.value = true
  try {
    await createCourse(createDraft.value)
    openCreate.value = false
    createDraft.value = { title: '', code: '', description: '', academic_year: '', status: 'draft' }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось создать курс'
  } finally {
    loading.value = false
  }
}

async function togglePublish(course: Course) {
  try {
    if (course.status === 'published') {
      await archiveCourse(course.id)
    } else {
      await publishCourse(course.id)
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось изменить статус'
  }
}

function openCourse(course: Course) {
  void router.push({ name: 'course-edit', params: { id: course.id } })
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="flex flex-col gap-6">
    <header class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-3xl">Конструктор курсов</h1>
        <p class="mt-1 text-sm text-muted">
          Курс → тематический блок → лаборатория → задание → версия → назначение.
        </p>
      </div>
      <button
        class="btn btn-primary"
        type="button"
        @click="openCreate = true"
        :disabled="loading"
      >
        Новый курс
      </button>
    </header>

    <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">
      {{ error }}
    </p>

    <div v-if="!isConfigured()" class="card">
      <h2 class="text-lg">Supabase не подключён</h2>
      <p class="mt-2 text-sm text-muted">
        Добавьте переменные <code class="font-mono">VITE_SUPABASE_URL</code> и
        <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> в GitHub → Settings → Secrets and
        variables → Actions → Variables, затем сделайте деплой.
      </p>
    </div>

    <div v-else class="grid gap-4 sm:grid-cols-3">
      <div
        v-for="course in courses"
        :key="course.id"
        class="card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
      >
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2 mb-1">
            <span class="tag">{{ course.code }}</span>
            <span
              class="tag"
              :class="course.status === 'published' ? 'tag-warn' : 'tag'"
            >
              {{ statusLabel[course.status] }}
            </span>
          </div>
          <h3 class="text-lg cursor-pointer hover:text-accent" @click="openCourse(course)">
            {{ course.title }}
          </h3>
          <p class="text-sm text-muted">
            {{ course.academic_year }} ·
            {{ course.modules?.length ?? 0 }} блока
          </p>
        </div>

        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            class="btn btn-primary shrink-0"
            @click="openCourse(course)"
          >
            Редактировать
          </button>
          <button
            type="button"
            class="btn shrink-0"
            :class="course.status === 'published' ? 'btn-primary' : ''"
            @click.stop="togglePublish(course)"
          >
            {{ course.status === 'published' ? 'В архив' : 'Опубликовать' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="courses.length === 0 && !loading && isConfigured()" class="card text-center py-10">
      <p class="text-sm text-muted">Курсов пока нет. Создайте первый.</p>
    </div>

    <!-- Форма создания курса -->
    <div
      v-if="openCreate"
      class="fixed inset-0 z-50 flex items-center justify-center bg-bg/80 backdrop-blur-sm"
    >
      <div class="card w-full max-w-md p-6">
        <h2 class="text-lg mb-4">Новый курс</h2>
        <div class="space-y-3">
          <div>
            <label class="label" for="create-title">Название</label>
            <input
              id="create-title"
              v-model="createDraft.title"
              class="field"
              type="text"
              placeholder="Оптимизация веб-приложений"
              required
            />
          </div>
          <div>
            <label class="label" for="create-code">Код дисциплины</label>
            <input
              id="create-code"
              v-model="createDraft.code"
              class="field"
              type="text"
              placeholder="МДК.09.02"
              required
            />
          </div>
          <div>
            <label class="label" for="create-desc">Описание</label>
            <textarea
              id="create-desc"
              v-model="createDraft.description"
              class="field"
              rows="3"
              placeholder="Чему учатся студенты на курсе"
            />
          </div>
          <div v-if="auth.role === 'admin'">
            <label class="label" for="create-year">Учебный год</label>
            <input
              id="create-year"
              v-model="createDraft.academic_year"
              class="field"
              type="text"
              placeholder="2026/2027"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button type="button" class="btn" @click="openCreate = false">Отмена</button>
          <button type="button" class="btn btn-primary" @click="handleCreate" :disabled="loading">
            Создать
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
