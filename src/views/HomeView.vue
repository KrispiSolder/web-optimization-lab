<script setup lang="ts">
import { computed } from 'vue'
import ModeBadge from '@/components/ModeBadge.vue'
import { demoCourses } from '@/data/catalog'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const mvpLabs = computed(() => {
  const priority = ['lab-meta-seo', 'lab-images', 'lab-robots', 'lab-funnel']
  return demoCourses
    .flatMap((course) => course.modules.flatMap((module) => module.labs))
    .filter((lab) => priority.includes(lab.id))
    .sort((a, b) => priority.indexOf(a.id) - priority.indexOf(b.id))
})

const modes = [
  {
    id: 'A',
    title: 'Тренажёр',
    text: 'Декларативная конфигурация, расчётные метрики и мгновенная обратная связь. Все показатели помечены как учебная модель.',
    points: ['slider, number, select', 'метрики «до/после»', 'история запусков'],
  },
  {
    id: 'B',
    title: 'Реальная лаборатория',
    text: 'Monaco Editor, изолированный предпросмотр в sandboxed iframe и функциональные тесты по DOM.',
    points: ['HTML/CSS/JS', 'sandbox без доступа к токенам', 'серверная проверка результата'],
  },
  {
    id: 'C',
    title: 'Комплексный практикум',
    text: 'Предметный кейс: диагностика, гипотеза, эксперимент, сравнение и итоговый отчёт с экспертной оценкой.',
    points: ['этапы кейса', 'авто- и экспертная оценка', 'отчёт по истории'],
  },
] as const
</script>

<template>
  <div class="flex flex-col gap-10">
    <section class="grid items-center gap-6 lg:grid-cols-[1.15fr_0.85fr]">
      <div>
        <p class="text-xs font-semibold tracking-wide text-accent uppercase">
          ПМ.09 · МДК.09.02 · 09.02.07
        </p>
        <h1 class="mt-2 text-4xl leading-tight sm:text-5xl">
          Исследуйте, измеряйте и&nbsp;оптимизируйте веб-приложения
        </h1>
        <p class="mt-4 max-w-2xl text-base text-muted">
          Единое пространство для лабораторных и самостоятельных работ: три режима экспериментов,
          конструктор заданий, версионирование контента и контроль прогресса.
        </p>
        <div class="mt-6 flex flex-wrap gap-3">
          <RouterLink :to="{ name: 'courses' }" class="btn btn-primary">Перейти к курсам</RouterLink>
          <RouterLink v-if="!auth.isAuthenticated" :to="{ name: 'login' }" class="btn">
            Войти по приглашению
          </RouterLink>
          <RouterLink v-else :to="{ name: 'profile' }" class="btn">Мои результаты</RouterLink>
        </div>
        <p v-if="auth.isDemo" class="mt-4 rounded-md bg-warn-soft px-3 py-2 text-sm text-warn">
          Демо-режим: Supabase не подключён, данные каталога локальные. Роль переключается в шапке.
        </p>
      </div>

      <div class="card bg-surface-2">
        <h2 class="text-lg">Что внутри</h2>
        <dl class="mt-4 grid grid-cols-2 gap-4 text-sm">
          <div>
            <dt class="text-muted">Режимы</dt>
            <dd class="font-serif text-3xl font-bold text-accent">3</dd>
          </div>
          <div>
            <dt class="text-muted">MVP-лаборатории</dt>
            <dd class="font-serif text-3xl font-bold text-accent">4</dd>
          </div>
          <div>
            <dt class="text-muted">Роли</dt>
            <dd class="text-base font-semibold">Студент · Преподаватель · Админ</dd>
          </div>
          <div>
            <dt class="text-muted">Проверка</dt>
            <dd class="text-base font-semibold">Авто + экспертная</dd>
          </div>
        </dl>
        <p class="mt-4 border-t border-line pt-4 text-xs text-muted">
          Расчётные показатели всегда помечаются как учебная модель: симулятор не подменяет
          реальные Google Analytics и Яндекс.Метрику.
        </p>
      </div>
    </section>

    <section>
      <h2 class="text-2xl">Три режима лабораторий</h2>
      <div class="mt-4 grid gap-4 md:grid-cols-3">
        <article v-for="mode in modes" :key="mode.id" class="card flex flex-col gap-3">
          <ModeBadge :mode="mode.id" />
          <h3 class="text-lg">{{ mode.title }}</h3>
          <p class="text-sm text-muted">{{ mode.text }}</p>
          <ul class="mt-auto space-y-1 text-sm">
            <li v-for="point in mode.points" :key="point" class="flex gap-2">
              <span class="text-accent" aria-hidden="true">—</span>{{ point }}
            </li>
          </ul>
        </article>
      </div>
    </section>

    <section>
      <div class="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 class="text-2xl">Стартовые лаборатории MVP</h2>
          <p class="text-sm text-muted">На этих четырёх сценариях проверяются все три режима и конструктор.</p>
        </div>
        <RouterLink :to="{ name: 'courses' }" class="text-sm font-semibold text-accent hover:underline">
          Все курсы →
        </RouterLink>
      </div>

      <div class="mt-4 grid gap-4 sm:grid-cols-2">
        <RouterLink
          v-for="lab in mvpLabs"
          :key="lab.id"
          :to="{ name: 'lab', params: { id: lab.id } }"
          class="card group flex flex-col gap-2 transition-colors hover:border-accent"
        >
          <div class="flex flex-wrap items-center gap-2">
            <ModeBadge :mode="lab.mode" />
            <span v-if="lab.status === 'draft'" class="tag-warn">черновик</span>
          </div>
          <h3 class="text-lg group-hover:text-accent">{{ lab.title }}</h3>
          <p class="text-sm text-muted">{{ lab.description }}</p>
          <p class="mt-auto text-xs text-muted">
            Попытки: {{ lab.attempts }} из {{ lab.maxAttempts }}
          </p>
        </RouterLink>
      </div>
    </section>
  </div>
</template>
