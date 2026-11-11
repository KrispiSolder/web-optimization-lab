<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import ModeBadge from '@/components/ModeBadge.vue'
import { findLab } from '@/data/catalog'

const route = useRoute()
const found = computed(() => findLab(String(route.params.id)))

const mode = computed(() => found.value?.lab.mode ?? 'A')
const activePanel = ref<'work' | 'history'>('work')

const modeNotes: Record<string, string> = {
  A: 'Параметры формы меняют расчётные метрики. Движок моделей подключается на этапе 3.',
  B: 'Редактор Monaco, предпросмотр в sandboxed iframe и функциональные тесты подключаются на этапе 3.',
  C: 'Этапы кейса, промежуточные эксперименты и итоговый отчёт подключаются на этапе 3.',
}

const aFields = [
  { key: 'format', label: 'Формат', type: 'select', options: ['jpeg', 'webp', 'avif'] },
  { key: 'quality', label: 'Качество, %', type: 'range', min: 30, max: 100 },
]

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
</script>

<template>
  <div v-if="found" class="flex flex-col gap-6">
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
        Попытки: {{ found.lab.attempts }} из {{ found.lab.maxAttempts }} ·
        Шаблон: <code class="font-mono">{{ found.lab.templateKey }}</code>
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
      <div v-if="mode === 'A'" class="grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
        <form class="card flex flex-col gap-4" @submit.prevent>
          <h2 class="text-lg">Параметры эксперимента</h2>
          <div v-for="field in aFields" :key="field.key">
            <label class="label" :for="field.key">{{ field.label }}</label>
            <select v-if="field.type === 'select'" :id="field.key" class="field" disabled>
              <option v-for="option in field.options" :key="option">{{ option }}</option>
            </select>
            <input
              v-else
              :id="field.key"
              class="w-full accent-[var(--accent)]"
              type="range"
              :min="field.min"
              :max="field.max"
              disabled
            />
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
            Движок параметрического тренажёра: этап 3. Логика уже проверена в
            <code class="font-mono">prototype/index.html</code>.
          </div>
        </div>
      </div>

      <!-- Режим Б -->
      <div v-else-if="mode === 'B'" class="grid gap-4 lg:grid-cols-2">
        <div class="card flex flex-col gap-3">
          <h2 class="text-lg">Исходный код</h2>
          <div
            class="grid min-h-64 place-items-center rounded-md border border-line bg-surface-2 font-mono text-xs text-muted"
          >
            Monaco Editor подключается лениво на этапе 3
          </div>
          <div class="flex flex-wrap gap-2">
            <button class="btn btn-primary" type="button" disabled>Запустить и проверить</button>
            <button class="btn" type="button" disabled>Сбросить к исходной версии</button>
          </div>
        </div>

        <div class="card flex flex-col gap-3">
          <h2 class="text-lg">Предпросмотр</h2>
          <div
            class="grid min-h-64 place-items-center rounded-md border border-line bg-surface-2 text-xs text-muted"
          >
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

  <div v-else class="card">
    <h1 class="text-2xl">Лаборатория не найдена</h1>
    <p class="mt-2 text-sm text-muted">Возможно, ссылка устарела или лаборатория архивирована.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>
</template>
