import type { SupabaseClient } from '@supabase/supabase-js'
import type {
  Course,
  Module,
  Laboratory,
  LaboratoryVersion,
  Task,
  TaskVersion,
  Assignment,
  Group,
  Profile,
} from '@/types/models'
import { supabase, isSupabaseConfigured } from '@/lib/supabase'

/* ------------------------------------------------------------------ */
/*  Вспомогательные обёртки                                           */
/* ------------------------------------------------------------------ */

function requireSupabase(): SupabaseClient {
  if (!supabase) {
    throw new Error('Supabase не настроен')
  }
  return supabase
}

async function handle<T>(promise: any): Promise<T> {
  const { data, error } = await promise
  if (error) {
    throw new Error(error.message ?? 'Ошибка Supabase')
  }
  return data as T
}

/* ------------------------------------------------------------------ */
/*  Курсы                                                             */
/* ------------------------------------------------------------------ */

export async function fetchCourses(): Promise<Course[]> {
  return handle(
    requireSupabase()
      .from('courses')
      .select('*')
      .order('created_at', { ascending: false }),
  )
}

export async function createCourse(payload: Partial<Course>): Promise<Course> {
  return handle(
    requireSupabase()
      .from('courses')
      .insert(payload)
      .select()
      .single(),
  )
}

export async function updateCourse(
  id: string,
  payload: Partial<Course>,
): Promise<Course> {
  return handle(
    requireSupabase()
      .from('courses')
      .update(payload)
      .eq('id', id)
      .select()
      .single(),
  )
}

export async function archiveCourse(id: string): Promise<void> {
  await updateCourse(id, { status: 'archived' })
}

export async function publishCourse(id: string): Promise<void> {
  await updateCourse(id, { status: 'published' })
}

/* ------------------------------------------------------------------ */
/*  Блоки                                                             */
/* ------------------------------------------------------------------ */

export async function fetchModules(courseId?: string): Promise<Module[]> {
  let q = requireSupabase().from('modules').select('*').order('sort_order', { ascending: true })
  if (courseId) {
    q = q.eq('course_id', courseId)
  }
  return handle(q)
}

export async function createModule(payload: Partial<Module>): Promise<Module> {
  return handle(
    requireSupabase()
      .from('modules')
      .insert(payload)
      .select()
      .single(),
  )
}

export async function updateModule(
  id: string,
  payload: Partial<Module>,
): Promise<Module> {
  return handle(
    requireSupabase()
      .from('modules')
      .update(payload)
      .eq('id', id)
      .select()
      .single(),
  )
}

export async function archiveModule(id: string): Promise<void> {
  await updateModule(id, { status: 'archived' })
}

export async function publishModule(id: string): Promise<void> {
  await updateModule(id, { status: 'published' })
}

/* ------------------------------------------------------------------ */
/*  Лаборатории                                                       */
/* ------------------------------------------------------------------ */

export async function fetchLaboratories(moduleId?: string): Promise<Laboratory[]> {
  let q = requireSupabase()
    .from('laboratories')
    .select('*')
    .order('created_at', { ascending: false })
  if (moduleId) {
    q = q.eq('module_id', moduleId)
  }
  return handle(q)
}

export async function createLaboratory(
  payload: Partial<Laboratory>,
): Promise<Laboratory> {
  return handle(
    requireSupabase()
      .from('laboratories')
      .insert(payload)
      .select()
      .single(),
  )
}

export async function updateLaboratory(
  id: string,
  payload: Partial<Laboratory>,
): Promise<Laboratory> {
  return handle(
    requireSupabase()
      .from('laboratories')
      .update(payload)
      .eq('id', id)
      .select()
      .single(),
  )
}

export async function archiveLaboratory(id: string): Promise<void> {
  await updateLaboratory(id, { status: 'archived' })
}

export async function publishLaboratory(id: string): Promise<void> {
  await updateLaboratory(id, { status: 'published' })
}

/* ------------------------------------------------------------------ */
/*  Версии лабораторий                                                */
/* ------------------------------------------------------------------ */

export async function fetchLabVersions(labId: string): Promise<LaboratoryVersion[]> {
  return handle(
    requireSupabase()
      .from('laboratory_versions')
      .select('*')
      .eq('laboratory_id', labId)
      .order('version', { ascending: true }),
  )
}

export async function createLabVersion(
  payload: Partial<LaboratoryVersion>,
): Promise<LaboratoryVersion> {
  // Вычисляем следующий номер версии
  const { data: existing } = await requireSupabase()
    .from('laboratory_versions')
    .select('version')
    .eq('laboratory_id', payload.laboratory_id)
    .order('version', { ascending: false })
    .limit(1)

  const nextVersion = (existing?.[0]?.version ?? 0) + 1

  return handle(
    requireSupabase()
      .from('laboratory_versions')
      .insert({
        ...payload,
        version: nextVersion,
        published_at: payload.published_at ?? null,
      })
      .select()
      .single(),
  )
}

export async function publishLabVersion(id: string): Promise<void> {
  const sb = requireSupabase()
  const { data: version } = await sb
    .from('laboratory_versions')
    .select('laboratory_id')
    .eq('id', id)
    .single()
  if (!version) return

  await sb.from('laboratory_versions').update({ published_at: new Date().toISOString() }).eq('id', id)

  // Снимаем флаг публикации с предыдущих версий этой лаборатории
  await sb
    .from('laboratory_versions')
    .update({ published_at: null })
    .eq('laboratory_id', version.laboratory_id)
    .neq('id', id)

  // Указатель текущей версии на лабораторию
  await sb.from('laboratories').update({ current_version_id: id }).eq('id', version.laboratory_id)
}

/* ------------------------------------------------------------------ */
/*  Задания                                                           */
/* ------------------------------------------------------------------ */

export async function fetchTasks(labId?: string): Promise<Task[]> {
  let q = requireSupabase().from('tasks').select('*').order('created_at', { ascending: false })
  if (labId) {
    q = q.eq('laboratory_id', labId)
  }
  return handle(q)
}

export async function createTask(payload: Partial<Task>): Promise<Task> {
  return handle(
    requireSupabase()
      .from('tasks')
      .insert(payload)
      .select()
      .single(),
  )
}

export async function fetchTaskVersions(taskId: string): Promise<TaskVersion[]> {
  return handle(
    requireSupabase()
      .from('task_versions')
      .select('*')
      .eq('task_id', taskId)
      .order('version', { ascending: true }),
  )
}

export async function createTaskVersion(
  payload: Partial<TaskVersion>,
): Promise<TaskVersion> {
  const { data: existing } = await requireSupabase()
    .from('task_versions')
    .select('version')
    .eq('task_id', payload.task_id)
    .order('version', { ascending: false })
    .limit(1)

  const nextVersion = (existing?.[0]?.version ?? 0) + 1

  return handle(
    requireSupabase()
      .from('task_versions')
      .insert({
        ...payload,
        version: nextVersion,
        published_at: payload.published_at ?? null,
      })
      .select()
      .single(),
  )
}

export async function publishTaskVersion(id: string): Promise<void> {
  const sb = requireSupabase()
  const { data: version } = await sb
    .from('task_versions')
    .select('task_id')
    .eq('id', id)
    .single()
  if (!version) return

  await sb
    .from('task_versions')
    .update({ published_at: new Date().toISOString() })
    .eq('id', id)

  await sb
    .from('task_versions')
    .update({ published_at: null })
    .eq('task_id', version.task_id)
    .neq('id', id)
}

/* ------------------------------------------------------------------ */
/*  Назначения                                                        */
/* ------------------------------------------------------------------ */

export async function fetchAssignments(): Promise<Assignment[]> {
  return handle(
    requireSupabase()
      .from('assignments')
      .select('*')
      .order('created_at', { ascending: false }),
  )
}

export async function createAssignment(
  payload: Partial<Assignment>,
): Promise<Assignment> {
  return handle(
    requireSupabase()
      .from('assignments')
      .insert(payload)
      .select()
      .single(),
  )
}

export async function updateAssignment(
  id: string,
  payload: Partial<Assignment>,
): Promise<Assignment> {
  return handle(
    requireSupabase()
      .from('assignments')
      .update(payload)
      .eq('id', id)
      .select()
      .single(),
  )
}

export async function archiveAssignment(id: string): Promise<void> {
  await updateAssignment(id, { status: 'archived' })
}

/* ------------------------------------------------------------------ */
/*  Группы                                                            */
/* ------------------------------------------------------------------ */

export async function fetchGroups(): Promise<Group[]> {
  const { data, error } = await requireSupabase()
    .from('groups')
    .select('*')
    .order('name', { ascending: true })
  if (error) throw new Error(error.message ?? 'Ошибка Supabase')
  return data
}

/* ------------------------------------------------------------------ */
/*  Профили                                                           */
/* ------------------------------------------------------------------ */

export async function fetchProfiles(): Promise<Profile[]> {
  const { data, error } = await requireSupabase()
    .from('profiles')
    .select('*')
    .order('display_name', { ascending: true })
  if (error) throw new Error(error.message ?? 'Ошибка Supabase')
  return data
}

export function isConfigured(): boolean {
  return isSupabaseConfigured
}
