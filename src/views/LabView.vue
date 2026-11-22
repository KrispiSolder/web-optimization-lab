<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchCourses, fetchModules, fetchLaboratories, isConfigured } from '@/lib/api'
import type { Course, Module, Laboratory } from '@/types/models'
import ModeBadge from '@/components/ModeBadge.vue'

const route = useRoute()
const configured = isConfigured()
const labId = String(route.params.id)

const found = ref<{ course: Course; module: Module; lab: Laboratory } | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

const mode = computed(() => found.value?.lab.type ?? 'parameter-simulator')
const activePanel = ref<'work' | 'history'>('work')

const modeNotes: Record<string, string> = {
  'parameter-simulator': 'Параметры формы меняют расчётные метрики. Движок моделей подключается на этапе 3.',
  'code-lab': 'Редактор Monaco, предпросмотр в sandboxed iframe и функциональные тесты подключаются на этапе 3.',
  'case-practicum': 'Этапы кейса, промежуточные эксперименты и итоговый отчёт подключаются на этапе 3.',
}

const tabs = [
  { id: 'work', label: 'Рабочее место' },
  { id: 'history', label: 'История запусков' },
] as const

const stages = [
  'Постановка задачи',
  'Диагностика',
  'Гипотеза',
  'Эксперимент',
  'Сравнение',
  'Вывод',
  'Сдача',
]

async function load() {
  loading.value = true
  error.value = null
  try {
    const courses = await fetchCourses()

    for (const course of courses) {
      const modules = await fetchModules(course.id)
      for (const module of modules) {
        const labs = await fetchLaboratories(module.id)
        const lab = labs.find((l) => l.id === labId)
        if (lab) {
          found.value = { course, module, lab }
          return
        }
      }
    }

    found.value = null
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить лабораторию'
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

  <div v-else-if="found" class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'courses' }" class="hover:text-ink">Курсы</RouterLink>
      <span aria-hidden="true"> / </span>
      <RouterLink :to="{ name: 'course', params: { id: found.course.id } }" class="hover:text-ink">
        {{ found.course.code }}
      </RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">{{ found.module.title }}</span>
    </nav>

    <header class="flex flex-col gap-3">
      <div class="flex flex-wrap items-center gap-2">
        <ModeBadge :mode="mode" />
        <span class="tag-warn">версия 1</span>
        <span v-if="found.lab.status === 'draft'" class="tag-warn">черновик</span>
      </div>
      <h1 class="text-3xl">{{ found.lab.title }}</h1>
      <p class="max-w-3xl text-sm text-muted">{{ found.lab.description }}</p>
      <p class="text-xs text-muted">
        Шаблон: <code class="font-mono">{{ found.lab.template_key }}</code>
      </p>
    </header>

    <div class="flex gap-2 border-b border-line" role="tablist" aria-label="Разделы лаборатории">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        role="tab"
        class="-mb-px border-b-2 px-3 py-2 text-sm font-medium"
        :class="
          activePanel === tab.id
            ? 'border-accent text-accent'
            : 'border-transparent text-muted hover:text-ink'
        "
        :aria-selected="activePanel === tab.id"
        @click="activePanel = tab.id"
      >
        {{ tab.label }}
      </button>
    </div>

    <section v-if="activePanel === 'work'" class="flex flex-col gap-4">
      <!-- Режим А -->
      <div v-if="mode === 'parameter-simulator'" class="grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
        <form class="card flex flex-col gap-4" @submit.prevent>
          <h2 class="text-lg">Параметры эксперимента</h2>
          <div>
            <label class="label" for="format">Формат</label>
            <select id="format" class="field" disabled>
              <option>jpeg</option>
              <option>webp</option>
              <option>avif</option>
            </select>
          </div>
          <div>
            <label class="label" for="quality">Качество, %</label>
            <input id="quality" class="w-full accent-[var(--accent)]" type="range" min="30" max="100" disabled />
          </div>
          <button class="btn btn-primary" type="button" disabled>Записать запуск</button>
          <p class="text-xs text-muted">
            Форма строится из JSON-конфигурации шаблона. Произвольный JS в конфигурации запрещён —
            только каталог разрешённых операций.
          </p>
        </form>

        <div class="card flex flex-col gap-3">
          <div class="flex items-center justify-between">
            <h2 class="text-lg">Метрики</h2>
            <span class="tag-warn">учебная модель</span>
          </div>
          <p class="font-serif text-4xl font-bold text-accent">— <span class="text-base font-sans font-normal text-muted">КБ</span></p>
          <p class="text-sm text-muted">
            Целевое значение задаётся в конфигурации. Источник метрики и формула выводятся рядом с
            показателем, чтобы симулятор не воспринимался как реальное измерение.
          </p>
          <div class="mt-auto rounded-md bg-surface-2 p-3 text-xs text-muted">
            Движок параметрического тренажёра: этап 3.
          </div>
        </div>
      </div>

      <!-- Режим Б -->
      <div v-else-if="mode === 'code-lab'" class="grid gap-4 lg:grid-cols-2">
        <div class="card flex flex-col gap-3">
          <h2 class="text-lg">Исходный код</h2>
          <div class="grid min-h-64 place-items-center rounded-md border border-line bg-surface-2 font-mono text-xs text-muted">
            Monaco Editor подключается лениво на этапе 3
          </div>
          <div class="flex flex-wrap gap-2">
            <button class="btn btn-primary" type="button" disabled>Запустить и проверить</button>
            <button class="btn" type="button" disabled>Сбросить к исходной версии</button>
          </div>
        </div>

        <div class="card flex flex-col gap-3">
          <h2 class="text-lg">Предпросмотр</h2>
          <div class="grid min-h-64 place-items-center rounded-md border border-line bg-surface-2 text-xs text-muted">
            <p class="max-w-xs text-center">
              sandboxed iframe с отдельным origin. Токены Supabase и доступ к родительскому DOM
              не передаются.
            </p>
          </div>
          <div class="rounded-md bg-surface-2 p-3 text-xs text-muted">
            <p class="font-semibold text-ink">Консоль и тесты</p>
            <p>Ошибки выполнения и результаты функциональных тестов появятся здесь.</p>
          </div>
        </div>
      </div>

      <!-- Режим В -->
      <div v-else class="flex flex-col gap-4">
        <ol class="grid gap-2 sm:grid-cols-4 lg:grid-cols-7">
          <li
            v-for="(stage, index) in stages"
            :key="stage"
            class="card !p-3 text-xs"
          >
            <span class="block font-serif text-lg font-bold text-accent">{{ index + 1 }}</span>
            {{ stage }}
          </li>
        </ol>

        <div class="grid gap-4 lg:grid-cols-2">
          <div class="card flex flex-col gap-3">
            <h2 class="text-lg">Кейс</h2>
            <p class="text-sm text-muted">
              Интернет-магазин с низкой скоростью загрузки и слабым SEO. Нужно провести аудит,
              выбрать последовательность решений и обосновать результат.
            </p>
            <div class="rounded-md bg-warn-soft px-3 py-2 text-xs text-warn">
              Показатели кейса — учебная модель. Реальные данные требуют подключения внешних
              сервисов аналитики.
            </div>
          </div>
          <div class="card flex flex-col gap-3">
            <h2 class="text-lg">Обоснование</h2>
            <label class="label" for="hypothesis">Гипотеза</label>
            <textarea id="hypothesis" class="field min-h-20" disabled placeholder="Что и почему вы ожидаете изменить" />
            <label class="label" for="conclusion">Вывод</label>
            <textarea id="conclusion" class="field min-h-24" disabled placeholder="Какие решения выбраны и почему" />
            <button class="btn btn-primary" type="button" disabled>Сдать работу</button>
          </div>
        </div>
      </div>

      <p class="rounded-md bg-surface-2 px-3 py-2 text-xs text-muted">{{ modeNotes[mode] }}</p>
    </section>

    <section v-else class="card">
      <h2 class="text-lg">История запусков</h2>
      <p class="mt-2 text-sm text-muted">
        Здесь появятся входные и выходные значения, тип измерения (measured/modelled), версия
        модели и время выполнения. История сохраняется в <code class="font-mono">experiments</code>
        и не меняется после отправки работы.
      </p>
      <p class="mt-4 rounded-md border border-dashed border-line p-6 text-center text-sm text-muted">
        Запусков пока нет
      </p>
    </section>
  </div>

  <div v-else-if="!loading && !error" class="card">
    <h1 class="text-2xl">Лаборатория не найдена</h1>
    <p class="mt-2 text-sm text-muted">Возможно, ссылка устарела или лаборатория архивирована.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>

  <div v-else-if="loading" class="card text-sm text-muted">Загрузка лаборатории…</div>

  <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">{{ error }}</p>
</template>
