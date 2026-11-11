<script setup lang="ts">
import { computed, ref } from 'vue'
import { demoCourses } from '@/data/catalog'
import ModeBadge from '@/components/ModeBadge.vue'

const query = ref('')

const filtered = computed(() => {
  const value = query.value.trim().toLowerCase()
  if (!value) return demoCourses
  return demoCourses.filter(
    (course) =>
      course.title.toLowerCase().includes(value) ||
      course.code.toLowerCase().includes(value) ||
      course.description.toLowerCase().includes(value),
  )
})

function labCount(courseId: string, mode?: 'A' | 'B' | 'C') {
  const course = demoCourses.find((item) => item.id === courseId)
  if (!course) return 0
  const labs = course.modules.flatMap((module) => module.labs)
  return mode ? labs.filter((lab) => lab.mode === mode).length : labs.length
}
</script>

<template>
  <div class="flex flex-col gap-6">
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

    <div v-if="filtered.length" class="grid gap-4 md:grid-cols-2">
      <RouterLink
        v-for="course in filtered"
        :key="course.id"
        :to="{ name: 'course', params: { id: course.id } }"
        class="card group flex flex-col gap-3 transition-colors hover:border-accent"
      >
        <div class="flex flex-wrap items-center gap-2">
          <span class="tag">{{ course.code }}</span>
          <span class="tag-warn">{{ course.academicYear }}</span>
        </div>
        <h2 class="text-xl group-hover:text-accent">{{ course.title }}</h2>
        <p class="text-sm text-muted">{{ course.description }}</p>
        <div class="mt-auto flex flex-wrap items-center gap-3 border-t border-line pt-3 text-xs text-muted">
          <span>{{ course.modules.length }} блока</span>
          <span>{{ labCount(course.id) }} лабораторий</span>
          <span class="flex items-center gap-1">
            <ModeBadge mode="A" /> {{ labCount(course.id, 'A') }}
          </span>
          <span class="flex items-center gap-1">
            <ModeBadge mode="B" /> {{ labCount(course.id, 'B') }}
          </span>
          <span class="flex items-center gap-1">
            <ModeBadge mode="C" /> {{ labCount(course.id, 'C') }}
          </span>
        </div>
      </RouterLink>
    </div>

    <div v-else class="card text-sm text-muted">По запросу «{{ query }}» ничего не найдено.</div>
  </div>
</template>
