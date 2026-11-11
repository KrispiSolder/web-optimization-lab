<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { findLab } from '@/data/catalog'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()
const found = computed(() => findLab(String(route.params.id)))

function printReport() {
  window.print()
}
</script>

<template>
  <div v-if="found" class="flex flex-col gap-4">
    <div class="flex flex-wrap items-center justify-between gap-3 print:hidden">
      <div>
        <h1 class="text-3xl">Отчёт об эксперименте</h1>
        <p class="text-sm text-muted">Предпросмотр шаблона отчёта. PDF формируется на этапе 4.</p>
      </div>
      <div class="flex gap-2">
        <RouterLink :to="{ name: 'lab', params: { id: found.lab.id } }" class="btn">К лаборатории</RouterLink>
        <button class="btn btn-primary" type="button" @click="printReport">Печать / PDF</button>
      </div>
    </div>

    <article class="card flex flex-col gap-6 print:border-0 print:shadow-none">
      <header class="border-b border-line pb-4">
        <p class="text-xs text-muted">Web Optimization Lab · МДК.09.02</p>
        <h2 class="mt-1 text-2xl">{{ found.lab.title }}</h2>
        <p class="mt-1 text-sm text-muted">
          {{ auth.displayName }} · {{ found.course.code }} · {{ found.module.title }}
        </p>
      </header>

      <section>
        <h3 class="text-lg">Постановка</h3>
        <p class="mt-1 text-sm text-muted">{{ found.lab.description }}</p>
      </section>

      <section class="grid gap-4 sm:grid-cols-2">
        <div>
          <h3 class="text-lg">Исходные параметры</h3>
          <p class="mt-1 rounded-md bg-surface-2 p-3 font-mono text-xs text-muted">
            { "format": "jpeg", "quality": 80 }
          </p>
        </div>
        <div>
          <h3 class="text-lg">Итоговые показатели</h3>
          <p class="mt-1 rounded-md bg-surface-2 p-3 font-mono text-xs text-muted">
            { "estimated_bytes": 2400, "source": "modelled" }
          </p>
        </div>
      </section>

      <section>
        <h3 class="text-lg">Сравнение запусков</h3>
        <div class="mt-2 overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="text-left text-xs text-muted">
              <tr>
                <th class="border-b border-line py-2 pr-4">№</th>
                <th class="border-b border-line py-2 pr-4">Входные значения</th>
                <th class="border-b border-line py-2 pr-4">Результат</th>
                <th class="border-b border-line py-2">Тип измерения</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="border-b border-line py-2 pr-4">1</td>
                <td class="border-b border-line py-2 pr-4">jpeg, 80</td>
                <td class="border-b border-line py-2 pr-4">1717 КБ</td>
                <td class="border-b border-line py-2">modelled</td>
              </tr>
              <tr>
                <td class="border-b border-line py-2 pr-4">2</td>
                <td class="border-b border-line py-2 pr-4">webp, 70</td>
                <td class="border-b border-line py-2 pr-4">780 КБ</td>
                <td class="border-b border-line py-2">modelled</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <h3 class="text-lg">Выводы</h3>
        <p class="mt-1 text-sm text-muted">
          Раздел заполняется студентом: какие изменения внесены, как они повлияли на показатели и
          какие ограничения модели нужно учитывать.
        </p>
      </section>

      <section class="grid gap-4 border-t border-line pt-4 sm:grid-cols-3">
        <div>
          <p class="text-xs text-muted">Автоматическая оценка</p>
          <p class="font-serif text-2xl font-bold">—</p>
        </div>
        <div>
          <p class="text-xs text-muted">Оценка преподавателя</p>
          <p class="font-serif text-2xl font-bold">—</p>
        </div>
        <div>
          <p class="text-xs text-muted">Итого</p>
          <p class="font-serif text-2xl font-bold">— / 10</p>
        </div>
      </section>
    </article>
  </div>

  <div v-else class="card">
    <h1 class="text-2xl">Отчёт недоступен</h1>
    <p class="mt-2 text-sm text-muted">Сначала выполните лабораторию и отправьте работу.</p>
    <RouterLink :to="{ name: 'courses' }" class="btn btn-primary mt-4">К каталогу курсов</RouterLink>
  </div>
</template>
