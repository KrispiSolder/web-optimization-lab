<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchCourses, isConfigured } from '@/lib/api'
import type { Course } from '@/types/models'
import ModeBadge from '@/components/ModeBadge.vue'

const route = useRoute()
const configured = isConfigured()
const course = ref<Course | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

const statusLabel: Record<string, string> = {
  'draft': 'черновик',
  'published': 'опубликован',
  'archived': 'в архиве',
}

async function load() {
  loading.value = true
  error.value = null
  try {
    const all = await fetchCourses()
    course.value = all.find((c) => c.id === String(route.params.id)) ?? null
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить курс'
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

  <div v-else-if="course" class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'courses' }" class="hover:text-ink">Курсы</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">{{ course.code }}</span>
    </nav>

    <header class="card">
      <div class="flex flex-wrap items-center gap-2">
        <span class="tag">{{ course.code }}</span>
        <span class="tag-warn">{{ course.academic_year }}</span>
      </div>
      <h1 class="mt-3 text-3xl">{{ course.title }}</h1>
      <p class="mt-2 max-w-3xl text-sm text-muted">{{ course.description }}</p>

      <div class="mt-5">
        <div class="flex items-center justify-between text-sm">
          <span class="text-muted">Статус курса</span>
          <span class="font-semibold">{{ statusLabel[course.status] }}</span>
        </div>
      </div>
    </header>

    <section v-for="module in course?.modules ?? []" :key="module.id" class="flex flex-col gap-3">
      <div>
        <h2 class="text-xl">{{ module.title }}</h2>
        <p class="text-sm text-muted">{{ module.intro }}</p>
      </div>

      <div class="grid gap-3">
        <article
          v-for="lab in module.laboratories ?? []"
          :key="lab.id"
          class="card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
        >
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <ModeBadge :mode="lab.type" />
              <span class="tag-warn">{{ statusLabel[lab.status] }}</span>
            </div>
            <h3 class="mt-2 text-lg">{{ lab.title }}</h3>
            <p class="mt-1 text-sm text-muted">{{ lab.description }}</p>
          </div>

          <RouterLink
            v-if="lab.status === 'published'"
            :to="{ name: 'lab', params: { id: lab.id } }"
            class="btn btn-primary shrink-0"
          >
            Начать
          </RouterLink>
          <span v-else class="btn shrink-0 cursor-not-allowed opacity-60" aria-disabled="true">
            Не опубликовано
          </span>
        </article>
      </div>
    </section>
  </div>

  <div v-else-if="!loading && !error" class="card">
    <h1 class="text-2xl">Курс не найден</h1>
    <p class="mt-2 text-sm text-muted">Проверьте ссылку или вернитесь в каталог.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>

  <div v-else-if="loading" class="card text-sm text-muted">Загрузка курса…</div>

  <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">{{ error }}</p>
</template>
