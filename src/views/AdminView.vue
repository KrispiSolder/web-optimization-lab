<script setup lang="ts">
import { computed } from 'vue'
import { demoCourses } from '@/data/catalog'

const labs = computed(() => demoCourses.flatMap((course) => course.modules.flatMap((module) => module.labs)))
const published = computed(() => labs.value.filter((lab) => lab.status === 'published').length)
const drafts = computed(() => labs.value.filter((lab) => lab.status === 'draft').length)

const templates = [
  { key: 'parameter-simulator', title: 'Параметрический тренажёр', schema: 1, labs: 3 },
  { key: 'html-audit', title: 'Аудит HTML-разметки', schema: 1, labs: 1 },
  { key: 'case-study', title: 'Комплексный практикум', schema: 1, labs: 1 },
]
</script>

<template>
  <div class="flex flex-col gap-6">
    <header>
      <h1 class="text-3xl">Администрирование</h1>
      <p class="mt-1 text-sm text-muted">
        Пользователи, каталог, шаблоны лабораторий и журнал действий. Разделы будут подключены к
        Supabase на этапах 1–2.
      </p>
    </header>

    <div class="grid gap-4 sm:grid-cols-3">
      <div class="card">
        <p class="text-sm text-muted">Опубликовано лабораторий</p>
        <p class="font-serif text-3xl font-bold text-accent">{{ published }}</p>
      </div>
      <div class="card">
        <p class="text-sm text-muted">Черновиков</p>
        <p class="font-serif text-3xl font-bold text-warn">{{ drafts }}</p>
      </div>
      <div class="card">
        <p class="text-sm text-muted">Шаблонов в каталоге</p>
        <p class="font-serif text-3xl font-bold text-accent">{{ templates.length }}</p>
      </div>
    </div>

    <div class="grid gap-4 lg:grid-cols-2">
      <section class="card">
        <h2 class="text-lg">Пользователи и роли</h2>
        <p class="mt-1 text-sm text-muted">
          Роль хранится в <code class="font-mono">profiles.role</code> и защищена триггером:
          изменить её через API профиля нельзя.
        </p>
        <table class="mt-3 w-full text-sm">
          <thead class="text-left text-xs text-muted">
            <tr>
              <th class="border-b border-line py-2 pr-4">Сотрудник</th>
              <th class="border-b border-line py-2 pr-4">Роль</th>
              <th class="border-b border-line py-2">Группы</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="border-b border-line py-2 pr-4">Иванова А. П.</td>
              <td class="border-b border-line py-2 pr-4">преподаватель</td>
              <td class="border-b border-line py-2">ИС-21, ИС-22</td>
            </tr>
            <tr>
              <td class="border-b border-line py-2 pr-4">Петров С. В.</td>
              <td class="border-b border-line py-2 pr-4">администратор</td>
              <td class="border-b border-line py-2">—</td>
            </tr>
          </tbody>
        </table>
        <button class="btn mt-4" type="button" disabled>Импорт списков (этап 1)</button>
      </section>

      <section class="card">
        <h2 class="text-lg">Каталог шаблонов</h2>
        <p class="mt-1 text-sm text-muted">
          Для шаблона хранятся <code class="font-mono">type</code>, <code class="font-mono">schema_version</code>,
          JSON Schema и разрешённые операции. Добавление принципиально новой модели требует
          расширения каталога разработчиком.
        </p>
        <ul class="mt-3 divide-y divide-line text-sm">
          <li v-for="template in templates" :key="template.key" class="flex items-center justify-between gap-3 py-2">
            <div>
              <p class="font-medium">{{ template.title }}</p>
              <p class="font-mono text-xs text-muted">{{ template.key }} · schema v{{ template.schema }}</p>
            </div>
            <span class="tag">{{ template.labs }} лаб.</span>
          </li>
        </ul>
      </section>

      <section class="card">
        <h2 class="text-lg">Курсы и контент</h2>
        <p class="mt-1 text-sm text-muted">
          Версии, публикация, порядок блоков и архивирование вместо удаления.
        </p>
        <ul class="mt-3 divide-y divide-line text-sm">
          <li v-for="course in demoCourses" :key="course.id" class="py-2">
            <p class="font-medium">{{ course.title }}</p>
            <p class="text-xs text-muted">
              {{ course.code }} · {{ course.modules.length }} блока · {{ course.academicYear }}
            </p>
          </li>
        </ul>
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
</template>
