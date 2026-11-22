<script setup lang="ts">
import { ref } from 'vue'
import { fetchCourses, fetchModules, fetchLaboratories, isConfigured } from '@/lib/api'
import type { Course } from '@/types/models'

const configured = isConfigured()
const published = ref(0)
const drafts = ref(0)
const courses = ref<Course[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

async function load() {
  loading.value = true
  error.value = null
  try {
    courses.value = await fetchCourses()
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

if (configured) {
  void load()
}
</script>

<template>
  <div class="flex flex-col gap-6">
    <header>
      <h1 class="text-3xl">Администрирование</h1>
      <p class="mt-1 text-sm text-muted">
        Курсы, блоки, лаборатории и журнал действий. Данные загружаются из Supabase.
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

      <div v-if="!loading && !error" class="grid gap-4 lg:grid-cols-2">
        <section class="card">
          <h2 class="text-lg">Курсы и контент</h2>
          <p class="mt-1 text-sm text-muted">
            Версии, публикация, порядок блоков и архивирование вместо удаления.
          </p>
          <ul class="mt-3 divide-y divide-line text-sm">
            <li v-for="course in courses" :key="course.id" class="py-2">
              <p class="font-medium">{{ course.title }}</p>
              <p class="text-xs text-muted">
                {{ course.code }} · {{ course.modules?.length ?? 0 }} блока · {{ course.status }}
              </p>
            </li>
          </ul>
          <p v-if="courses.length === 0" class="mt-2 text-sm text-muted">Курсов пока нет.</p>
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
    </div>
  </div>
</template>
