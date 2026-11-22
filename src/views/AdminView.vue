<script setup lang="ts">
import { ref } from 'vue'
import {
  fetchCourses,
  createCourse,
  fetchModules,
  fetchLaboratories,
  fetchTasks,
  fetchTaskVersions,
  createAssignment,
  fetchGroups,
  isConfigured,
} from '@/lib/api'
import type { Course, Group, ContentStatus } from '@/types/models'

const configured = isConfigured()
const published = ref(0)
const drafts = ref(0)
const courses = ref<Course[]>([])
const groups = ref<Group[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

// Course creation form
const openCreateCourse = ref(false)
const createCourseDraft = ref<Partial<Course>>({
  title: '',
  code: '',
  description: '',
  academic_year: '',
  status: 'draft' as const,
})

// Assignment creation form
const openCreateAssignment = ref(false)
const selectedCourseId = ref<string>('')
const assignmentDraft = ref<{
  course_id: string
  task_version_id: string
  group_id: string
  opens_at: string
  due_at: string | null
  max_attempts: number
  status: ContentStatus
}>({
  course_id: '',
  task_version_id: '',
  group_id: '',
  opens_at: '',
  due_at: null,
  max_attempts: 3,
  status: 'draft',
})

// Available task versions for the selected course (for assignment dropdown)
const courseTaskVersions = ref<Array<{ id: string; title: string; labTitle: string }>>([])

async function load() {
  loading.value = true
  error.value = null
  try {
    courses.value = await fetchCourses()
    groups.value = await fetchGroups()
    let pub = 0
    let dr = 0
    for (const course of courses.value) {
      const mods = await fetchModules(course.id)
      for (const m of mods) {
        const labs = await fetchLaboratories(m.id)
        for (const lab of labs) {
          if (lab.status === 'published') pub++
          else if (lab.status === 'draft') dr++
        }
      }
    }
    published.value = pub
    drafts.value = dr
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить данные администрирования'
  } finally {
    loading.value = false
  }
}

async function refreshTaskVersions() {
  if (!selectedCourseId.value) {
    courseTaskVersions.value = []
    return
  }
  try {
    const course = courses.value.find((c) => c.id === selectedCourseId.value)
    if (!course) return
    const versions: Array<{ id: string; title: string; labTitle: string }> = []
    const mods = await fetchModules(course.id)
    for (const m of mods) {
      const labs = await fetchLaboratories(m.id)
      for (const lab of labs) {
        const tasks = await fetchTasks(lab.id)
        for (const task of tasks) {
          const vers = await fetchTaskVersions(task.id)
          for (const v of vers) {
            versions.push({ id: v.id, title: v.statement, labTitle: lab.title })
          }
        }
      }
    }
    courseTaskVersions.value = versions
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить задания курса'
  }
}

function startCreateAssignment(courseId: string) {
  selectedCourseId.value = courseId
  void refreshTaskVersions()
  openCreateAssignment.value = true
}

async function handleCreateCourse() {
  if (!createCourseDraft.value.title || !createCourseDraft.value.code) {
    error.value = 'Заполните название и код курса'
    return
  }
  loading.value = true
  try {
    await createCourse(createCourseDraft.value)
    openCreateCourse.value = false
    createCourseDraft.value = { title: '', code: '', description: '', academic_year: '', status: 'draft' }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось создать курс'
  } finally {
    loading.value = false
  }
}

async function handleCreateAssignment() {
  if (
    !assignmentDraft.value.task_version_id ||
    !assignmentDraft.value.group_id ||
    !assignmentDraft.value.opens_at
  ) {
    error.value = 'Заполните задание, группу и дату начала'
    return
  }
  loading.value = true
  try {
    await createAssignment(assignmentDraft.value)
    openCreateAssignment.value = false
    assignmentDraft.value = {
      course_id: selectedCourseId.value,
      task_version_id: '',
      group_id: '',
      opens_at: '',
      due_at: null,
      max_attempts: 3,
      status: 'draft',
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось создать задание'
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
      <h1 class="text-3xl">Администрирование</h1>
      <p class="mt-1 text-sm text-muted">
        Курсы, задания, блоки и лаборатории. Данные загружаются из Supabase.
      </p>
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
      <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">
        {{ error }}
      </p>

      <div v-if="loading" class="card text-sm text-muted">Загрузка данных…</div>

      <div v-if="!loading && !error" class="grid gap-4 sm:grid-cols-3">
        <div class="card">
          <p class="text-sm text-muted">Опубликовано лабораторий</p>
          <p class="font-serif text-3xl font-bold text-accent">{{ published }}</p>
        </div>
        <div class="card">
          <p class="text-sm text-muted">Черновиков</p>
          <p class="font-serif text-3xl font-bold text-warn">{{ drafts }}</p>
        </div>
        <div class="card">
          <p class="text-sm text-muted">Курсов в каталоге</p>
          <p class="font-serif text-3xl font-bold text-accent">{{ courses.length }}</p>
        </div>
      </div>

      <!-- Курсы: создание и список -->
      <section v-if="!loading && !error" class="card">
        <div class="flex items-center justify-between gap-2">
          <h2 class="text-lg">Курсы</h2>
          <button
            type="button"
            class="btn btn-primary"
            @click="openCreateCourse = true"
            :disabled="loading"
          >
            Создать курс
          </button>
        </div>

        <ul class="mt-3 divide-y divide-line text-sm">
          <li v-for="course in courses" :key="course.id" class="py-3">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <div>
                <p class="font-medium">{{ course.title }}</p>
                <p class="text-xs text-muted">
                  {{ course.code }} · статус: {{ course.status }} ·
                  учебный год: {{ course.academic_year || '—' }}
                </p>
              </div>
              <div class="flex items-center gap-2">
                <RouterLink
                  :to="{ name: 'course-edit', params: { id: course.id } }"
                  class="btn btn-primary text-xs"
                >
                  Редактировать
                </RouterLink>
                <button
                  type="button"
                  class="btn text-xs"
                  @click="startCreateAssignment(course.id)"
                >
                  Добавить задание
                </button>
              </div>
            </div>
          </li>
          <li v-if="courses.length === 0" class="py-3 text-sm text-muted">
            Курсов пока нет. Создайте первый.
          </li>
        </ul>
      </section>

      <!-- Задания для курса -->
      <section v-if="!loading && !error" class="card">
        <h2 class="text-lg">Задания для курса</h2>
        <p class="mt-1 text-sm text-muted">
          Создайте задание, привязанное к варианту задачи лаборатории выбранного курса.
        </p>

        <div class="mt-4 space-y-3">
          <div>
            <label class="label" for="assign-course">Курс</label>
            <select
              id="assign-course"
              v-model="selectedCourseId"
              class="field"
              @change="refreshTaskVersions"
            >
              <option value="">Выберите курс</option>
              <option v-for="course in courses" :key="course.id" :value="course.id">
                {{ course.title }} ({{ course.code }})
              </option>
            </select>
          </div>

          <div v-if="selectedCourseId">
            <label class="label" for="assign-task-version">Задание (вариант задачи)</label>
            <select
              id="assign-task-version"
              v-model="assignmentDraft.task_version_id"
              class="field"
            >
              <option value="">Выберите задание</option>
              <option
                v-for="vt in courseTaskVersions"
                :key="vt.id"
                :value="vt.id"
              >
                {{ vt.labTitle }} — {{ vt.title }}
              </option>
            </select>
          </div>

          <div>
            <label class="label" for="assign-group">Группа</label>
            <select
              id="assign-group"
              v-model="assignmentDraft.group_id"
              class="field"
            >
              <option value="">Выберите группу</option>
              <option v-for="group in groups" :key="group.id" :value="group.id">
                {{ group.name }}
              </option>
            </select>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div>
              <label class="label" for="assign-opens">Дата и время начала</label>
              <input
                id="assign-opens"
                v-model="assignmentDraft.opens_at"
                class="field"
                type="datetime-local"
              />
            </div>
            <div>
              <label class="label" for="assign-due">Дата и время сдачи</label>
              <input
                id="assign-due"
                v-model="assignmentDraft.due_at"
                class="field"
                type="datetime-local"
              />
            </div>
          </div>

          <div>
            <label class="label" for="assign-attempts">Максимум попыток</label>
            <input
              id="assign-attempts"
              v-model.number="assignmentDraft.max_attempts"
              class="field w-24"
              type="number"
              min="1"
            />
          </div>

          <div class="flex justify-end gap-2 mt-4">
            <button type="button" class="btn" @click="openCreateAssignment = false">Отмена</button>
            <button
              type="button"
              class="btn btn-primary"
              @click="handleCreateAssignment"
              :disabled="loading || !assignmentDraft.task_version_id || !assignmentDraft.group_id"
            >
              Создать задание
            </button>
          </div>
        </div>
      </section>

      <section class="card">
        <h2 class="text-lg">Журнал аудита</h2>
        <p class="mt-1 text-sm text-muted">
          Кто, что и когда изменил: публикации, правки ролей, назначения и оценки.
        </p>
        <p class="mt-4 rounded-md border border-dashed border-line p-6 text-center text-sm text-muted">
          События появятся после подключения таблицы <code class="font-mono">audit_log</code>
        </p>
      </section>
    </div>

    <!-- Модалка создания курса -->
    <div
      v-if="openCreateCourse"
      class="fixed inset-0 z-50 flex items-center justify-center bg-bg/80 backdrop-blur-sm"
    >
      <div class="card w-full max-w-md p-6">
        <h2 class="text-lg mb-4">Новый курс</h2>
        <div class="space-y-3">
          <div>
            <label class="label" for="new-course-title">Название</label>
            <input
              id="new-course-title"
              v-model="createCourseDraft.title"
              class="field"
              type="text"
              placeholder="Оптимизация веб-приложений"
              required
            />
          </div>
          <div>
            <label class="label" for="new-course-code">Код дисциплины</label>
            <input
              id="new-course-code"
              v-model="createCourseDraft.code"
              class="field"
              type="text"
              placeholder="МДК.09.02"
              required
            />
          </div>
          <div>
            <label class="label" for="new-course-desc">Описание</label>
            <textarea
              id="new-course-desc"
              v-model="createCourseDraft.description"
              class="field"
              rows="3"
              placeholder="Описание курса"
            />
          </div>
          <div>
            <label class="label" for="new-course-year">Учебный год</label>
            <input
              id="new-course-year"
              v-model="createCourseDraft.academic_year"
              class="field"
              type="text"
              placeholder="2026/2027"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button type="button" class="btn" @click="openCreateCourse = false">Отмена</button>
          <button
            type="button"
            class="btn btn-primary"
            @click="handleCreateCourse"
            :disabled="loading"
          >
            Создать
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
