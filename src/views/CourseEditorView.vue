<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  fetchCourses,
  updateCourse,
  archiveCourse,
  publishCourse,
  fetchModules,
  createModule,
  archiveModule,
  publishModule,
  fetchLaboratories,
  createLaboratory,
  archiveLaboratory,
  publishLaboratory,
  fetchLabVersions,
  publishLabVersion,
} from '@/lib/api'
import type { Course, Module, Laboratory } from '@/types/models'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const courseId = String(route.params.id)

const course = ref<Course | null>(null)

function openCourseEditor() {
  if (course.value) {
    editCourseDraft.value = { ...course.value }
    openEditCourse.value = true
  }
}
const modules = ref<Module[]>([])
const labsOfModule = ref<Record<string, Laboratory[]>>({})
const versionsOfLab = ref<Record<string, any[]>>({})

const loading = ref(false)
const error = ref<string | null>(null)

const editCourseDraft = ref<Partial<Course>>({})
const openEditCourse = ref(false)

const newModuleDraft = ref<Partial<Module>>({ title: '', intro: '', sort_order: 0, status: 'draft' })
const openNewModule = ref(false)

const newLabDraft = ref<Partial<Laboratory>>({
  module_id: '',
  type: 'parameter-simulator',
  template_key: '',
  title: '',
  description: '',
  status: 'draft',
})
const openNewLab = ref(false)
let selectedModuleIdForLab = ''

const statusLabel: Record<string, string> = {
  draft: 'Черновик',
  published: 'Опубликован',
  archived: 'В архиве',
}

async function load() {
  loading.value = true
  error.value = null
  try {
    const [c, mods] = await Promise.all([fetchCourses(), fetchModules(courseId)])
    course.value = c.find((c) => c.id === courseId) ?? null
    modules.value = mods.filter((m) => m.course_id === courseId)

    // Загружаем лаборатории для каждого блока
    for (const m of modules.value) {
      const labs = await fetchLaboratories(m.id)
      labsOfModule.value[m.id] = labs
      for (const lab of labs) {
        const vers = await fetchLabVersions(lab.id)
        versionsOfLab.value[lab.id] = vers
      }
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось загрузить курс'
  } finally {
    loading.value = false
  }
}

async function saveCourse() {
  if (!course.value) return
  loading.value = true
  try {
    await updateCourse(course.value!.id, editCourseDraft.value)
    openEditCourse.value = false
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось сохранить курс'
  } finally {
    loading.value = false
  }
}

async function toggleCoursePublish() {
  if (!course.value?.id) return
  try {
    if (course.value.status === 'published') {
      await archiveCourse(course.value.id)
    } else {
      await publishCourse(course.value.id)
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось изменить статус курса'
  }
}

async function createModuleHandler() {
  if (!newModuleDraft.value.title) {
    error.value = 'Название блока обязательно'
    return
  }
  loading.value = true
  try {
    await createModule({
      ...newModuleDraft.value,
      course_id: courseId,
    })
    openNewModule.value = false
    newModuleDraft.value = { title: '', intro: '', sort_order: 0, status: 'draft' }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось создать блок'
  } finally {
    loading.value = false
  }
}

async function toggleModulePublish(moduleItem: Module) {
  try {
    if (moduleItem.status === 'published') {
      await archiveModule(moduleItem.id)
    } else {
      await publishModule(moduleItem.id)
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось изменить статус блока'
  }
}

async function createLabHandler() {
  if (!newLabDraft.value.title || !newLabDraft.value.template_key) {
    error.value = 'Название и шаблон лаборатории обязательны'
    return
  }
  loading.value = true
  try {
    await createLaboratory({
      ...newLabDraft.value,
      module_id: selectedModuleIdForLab,
    })
    openNewLab.value = false
    newLabDraft.value = {
      module_id: '',
      type: 'parameter-simulator',
      template_key: '',
      title: '',
      description: '',
      status: 'draft',
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось создать лабораторию'
  } finally {
    loading.value = false
  }
}

async function toggleLabPublish(lab: Laboratory) {
  try {
    if (lab.status === 'published') {
      await archiveLaboratory(lab.id)
    } else {
      await publishLaboratory(lab.id)
    }
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось изменить статус лаборатории'
  }
}

async function publishLabVer(versionId: string) {
  try {
    await publishLabVersion(versionId)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Не удалось опубликовать версию'
  }
}

const modeLabel: Record<string, string> = {
  'parameter-simulator': 'Тренажёр',
  'code-lab': 'Реальная лаборатория',
  'case-practicum': 'Практикум',
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="flex flex-col gap-6">
    <nav class="text-sm text-muted" aria-label="Хлебные крошки">
      <RouterLink :to="{ name: 'teacher' }" class="hover:text-ink">Конструктор</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="text-ink">{{ course?.title }}</span>
    </nav>

    <header class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="text-3xl">{{ course?.title }}</h1>
        <p class="mt-1 text-sm text-muted">{{ course?.code }} · {{ statusLabel[course?.status ?? 'draft'] }}</p>
      </div>

      <div class="flex gap-2">
        <button
          type="button"
          class="btn btn-primary"
          @click="openCourseEditor"
          :disabled="loading || !course"
        >
          Редактировать курс
        </button>
        <button
          type="button"
          class="btn"
          :class="course?.status === 'published' ? 'btn-primary' : ''"
          @click="toggleCoursePublish"
          :disabled="loading"
        >
          {{ course?.status === 'published' ? 'В архив' : 'Опубликовать' }}
        </button>
        <RouterLink :to="{ name: 'teacher' }" class="btn">К списку курсов</RouterLink>
      </div>
    </header>

    <p v-if="error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">
      {{ error }}
    </p>

    <!-- Блоки -->
    <section class="flex flex-col gap-3">
      <div class="flex items-center justify-between gap-2">
        <h2 class="text-lg">Тематические блоки</h2>
        <button
          type="button"
          class="btn btn-primary"
          @click="openNewModule = true"
          :disabled="loading"
        >
          Новый блок
        </button>
      </div>

      <div v-if="modules.length === 0" class="text-sm text-muted">Блоков пока нет.</div>

      <div class="grid gap-3" v-for="module in modules" :key="module.id">
        <div class="card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2 mb-1">
              <span class="tag">{{ statusLabel[module.status] }}</span>
            </div>
            <h3 class="text-lg">{{ module.title }}</h3>
            <p class="text-sm text-muted">{{ module.intro }}</p>
          </div>

          <div class="flex flex-wrap gap-2">
            <button
              type="button"
              class="btn shrink-0"
              :class="module.status === 'published' ? 'btn-primary' : ''"
              @click="toggleModulePublish(module)"
            >
              {{ module.status === 'published' ? 'В архив' : 'Опубликовать' }}
            </button>
          </div>
        </div>

        <!-- Лаборатории внутри блока -->
        <div class="ml-6 mt-3 border-l border-line pl-4 space-y-2">
          <div
            v-for="lab in labsOfModule[module.id] ?? []"
            :key="lab.id"
            class="card flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between p-4"
          >
            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-1.5 mb-1">
                <span class="tag text-xs">{{ modeLabel[lab.type] }}</span>
                <span class="tag text-xs">{{ statusLabel[lab.status] }}</span>
              </div>
              <h4 class="text-base">{{ lab.title }}</h4>
              <p class="text-sm text-muted">{{ lab.description }}</p>
              <div class="mt-1 flex gap-2 text-xs text-muted">
                <span>Версий: {{ (versionsOfLab[lab.id]?.length ?? 0) }}</span>
                <span class="font-mono">шаблон: {{ lab.template_key }}</span>
              </div>
            </div>

            <div class="flex flex-wrap gap-1">
              <button
                type="button"
                class="btn shrink-0 text-xs"
                :class="lab.status === 'published' ? 'btn-primary' : ''"
                @click="toggleLabPublish(lab)"
              >
                {{ lab.status === 'published' ? 'В архив' : 'Опубликовать' }}
              </button>
              <button
                type="button"
                class="btn shrink-0 text-xs btn-primary"
                @click="() => router.push({ name: 'lab', params: { id: lab.id } })"
              >
                Открыть для студента
              </button>
            </div>

            <!-- Версии лаборатории -->
            <div class="mt-3 border-t border-line pt-2 text-sm">
              <p class="text-muted mb-1">Версии:</p>
              <ul class="space-y-1">
                <li
                  v-for="ver in versionsOfLab[lab.id] ?? []"
                  :key="ver.id"
                  class="flex items-center justify-between gap-2"
                >
                  <span class="font-mono text-xs">v{{ ver.version }}</span>
                  <div class="flex gap-1">
                    <button
                      type="button"
                      class="btn text-xs btn-primary"
                      @click="publishLabVer(ver.id)"
                      :disabled="ver.published_at !== null"
                    >
                      {{ ver.published_at ? 'Опубликовано' : 'Опубликовать' }}
                    </button>
                  </div>
                </li>
              </ul>
              <p v-if="(versionsOfLab[lab.id]?.length ?? 0) === 0" class="text-xs text-muted italic">
                Версий пока нет
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Форма создания курса (редактирование метаданных) -->
    <div
      v-if="openEditCourse"
      class="fixed inset-0 z-50 flex items-center justify-center bg-bg/80 backdrop-blur-sm"
    >
      <div class="card w-full max-w-md p-6">
        <h2 class="text-lg mb-4">Редактировать курс</h2>
        <div class="space-y-3">
          <div>
            <label class="label" for="edit-title">Название</label>
            <input
              id="edit-title"
              v-model="editCourseDraft.title"
              class="field"
              type="text"
              required
            />
          </div>
          <div>
            <label class="label" for="edit-code">Код дисциплины</label>
            <input
              id="edit-code"
              v-model="editCourseDraft.code"
              class="field"
              type="text"
              required
            />
          </div>
          <div>
            <label class="label" for="edit-desc">Описание</label>
            <textarea
              id="edit-desc"
              v-model="editCourseDraft.description"
              class="field"
              rows="3"
            />
          </div>
          <div v-if="auth.role === 'admin'">
            <label class="label" for="edit-year">Учебный год</label>
            <input
              id="edit-year"
              v-model="editCourseDraft.academic_year"
              class="field"
              type="text"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button type="button" class="btn" @click="openEditCourse = false">Отмена</button>
          <button type="button" class="btn btn-primary" @click="saveCourse" :disabled="loading">
            Сохранить
          </button>
        </div>
      </div>
    </div>

    <!-- Форма нового блока -->
    <div
      v-if="openNewModule"
      class="fixed inset-0 z-50 flex items-center justify-center bg-bg/80 backdrop-blur-sm"
    >
      <div class="card w-full max-w-md p-6">
        <h2 class="text-lg mb-4">Новый блок</h2>
        <div class="space-y-3">
          <div>
            <label class="label" for="new-mod-title">Название блока</label>
            <input
              id="new-mod-title"
              v-model="newModuleDraft.title"
              class="field"
              type="text"
              required
            />
          </div>
          <div>
            <label class="label" for="new-mod-intro">Вводная теория</label>
            <textarea
              id="new-mod-intro"
              v-model="newModuleDraft.intro"
              class="field"
              rows="3"
            />
          </div>
          <div>
            <label class="label" for="new-mod-order">Порядок</label>
            <input
              id="new-mod-order"
              v-model.number="newModuleDraft.sort_order"
              class="field w-24"
              type="number"
              min="0"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button type="button" class="btn" @click="openNewModule = false">Отмена</button>
          <button type="button" class="btn btn-primary" @click="createModuleHandler" :disabled="loading">
            Создать блок
          </button>
        </div>
      </div>
    </div>

    <!-- Форма новой лаборатории -->
    <div
      v-if="openNewLab"
      class="fixed inset-0 z-50 flex items-center justify-center bg-bg/80 backdrop-blur-sm"
    >
      <div class="card w-full max-w-md p-6">
        <h2 class="text-lg mb-4">Новая лаборатория</h2>
        <div class="space-y-3">
          <div>
            <label class="label" for="new-lab-module">Блок</label>
            <select
              id="new-lab-module"
              v-model="selectedModuleIdForLab"
              class="field w-full"
              required
            >
              <option v-for="m in modules" :key="m.id" :value="m.id">{{ m.title }}</option>
            </select>
          </div>
          <div>
            <label class="label" for="new-lab-type">Тип</label>
            <select
              id="new-lab-type"
              v-model="newLabDraft.type"
              class="field w-full"
              required
            >
              <option value="parameter-simulator">Параметрический тренажёр</option>
              <option value="code-lab">Реальная лаборатория (код)</option>
              <option value="case-practicum">Комплексный практикум</option>
            </select>
          </div>
          <div>
            <label class="label" for="new-lab-template">Ключ шаблона</label>
            <input
              id="new-lab-template"
              v-model="newLabDraft.template_key"
              class="field"
              type="text"
              placeholder="parameter-simulator"
              required
            />
            <p class="text-xs text-muted">Идентификатор шаблона конфигурации (см. ТЗ раздел 5.3)</p>
          </div>
          <div>
            <label class="label" for="new-lab-title">Название</label>
            <input
              id="new-lab-title"
              v-model="newLabDraft.title"
              class="field"
              type="text"
              required
            />
          </div>
          <div>
            <label class="label" for="new-lab-desc">Описание</label>
            <textarea
              id="new-lab-desc"
              v-model="newLabDraft.description"
              class="field"
              rows="3"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <button type="button" class="btn" @click="openNewLab = false">Отмена</button>
          <button type="button" class="btn btn-primary" @click="createLabHandler" :disabled="loading">
            Создать лабораторию
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
