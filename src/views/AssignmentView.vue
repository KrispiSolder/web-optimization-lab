<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchAssignments, fetchTasks, fetchTaskVersions, fetchCourses, fetchModules, fetchLaboratories, isConfigured } from '@/lib/api'
import type { Assignment, Task, TaskVersion, Course, Module, Laboratory } from '@/types/models'

const route = useRoute()
const configured = isConfigured()
const assignmentId = String(route.params.id)

const assignment = ref<Assignment | null>(null)
const task = ref<Task | null>(null)
const taskVersion = ref<TaskVersion | null>(null)
const lab = ref<Laboratory | null>(null)
const module = ref<Module | null>(null)
const course = ref<Course | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

const dueLabel = computed(() => {
  if (!assignment.value?.due_at) return ''
  return new Intl.DateTimeFormat('ru-RU', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(assignment.value.due_at))
})

async function load() {
  loading.value = true
  error.value = null
  try {
    const assignments = await fetchAssignments()
    const foundAssignment = assignments.find((a) => a.id === assignmentId)
    if (!foundAssignment) return
    assignment.value = foundAssignment

    const tasks = await fetchTasks()
    task.value = tasks.find((t) => t.laboratory_id === (foundAssignment as any).laboratory_id) ?? null
    // Note: Supabase Assignment has task_version_id, not laboratory_id directly.
    // For MVP we resolve via tasks table.
    if (task.value) {
      const versions = await fetchTaskVersions(task.value.id)
      taskVersion.value = versions.find((v) => v.id === foundAssignment.task_version_id) ?? versions[0] ?? null
    }

    // Resolve lab → module → course for breadcrumbs
    const courses = await fetchCourses()
    for (const c of courses) {
      const mods = await fetchModules(c.id)
      for (const m of mods) {
        const labs = await fetchLaboratories(m.id)
        const foundLab = labs.find((l) => l.id === (task.value?.laboratory_id ?? ''))
        if (foundLab) {
          course.value = c
          module.value = m
          lab.value = foundLab
          return
        }
      }
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить задание'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div v-if="!configured" class="card">
    <h2 class="text-lg">Supabase не подключён</h2>
    <p class="mt-2 text-sm text-muted">
      Добавьте переменные <code class="font-mono">VITE_SUPABASE_URL</code> и
      <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> в GitHub → Settings → Secrets and
      variables → Actions → Variables, затем сделайте деплой.
    </p>
  </div>

  <div v-else-if="assignment" class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'courses' }" class="hover:text-ink">Курсы</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">Задание</span>
    </nav>

    <header class="card">
      <div class="flex flex-wrap items-center gap-2">
        <span class="tag">задание</span>
        <span v-if="dueLabel" class="tag-warn">до {{ dueLabel }}</span>
      </div>
      <h1 class="mt-3 text-3xl">{{ taskVersion?.statement ?? assignment.id }}</h1>
      <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-3">
        <div>
          <dt class="text-muted">Максимальный балл</dt>
          <dd class="font-semibold">{{ taskVersion?.max_score ?? 10 }}</dd>
        </div>
        <div>
          <dt class="text-muted">Попытки</dt>
          <dd class="font-semibold">до {{ assignment.max_attempts }}</dd>
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
          <li v-if="taskVersion?.rubric_json" class="text-sm text-muted">
            Критерий оценки (рубрика подключается на этапе 3).
          </li>
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

  <div v-else-if="!loading && !error" class="card">
    <h1 class="text-2xl">Задание не найдено</h1>
    <p class="mt-2 text-sm text-muted">Задание могло быть архивировано или снято с назначения.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>

  <div v-else-if="loading" class="card text-sm text-muted">Загрузка задания…</div>

  <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">{{ error }}</p>
</template>
