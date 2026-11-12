export type Role = 'student' | 'admin'

export type LabMode = 'parameter-simulator' | 'code-lab' | 'case-practicum'

export type ContentStatus = 'draft' | 'published' | 'archived'

export type AttemptStatus =
  | 'not-started'
  | 'in-progress'
  | 'submitted'
  | 'graded'
  | 'returned'
  | 'closed'

export interface Profile {
  id: string
  display_name: string | null
  role: Role
  status: string
  created_at: string
}

export interface Group {
  id: string
  name: string
  academic_year: string | null
  owner_id: string | null
  created_at: string
}

export interface Course {
  id: string
  title: string
  code: string
  description: string
  owner_id: string | null
  academic_year: string | null
  status: ContentStatus
  created_at: string
  modules?: Module[]
}

export interface Module {
  id: string
  course_id: string
  title: string
  intro: string
  sort_order: number
  status: ContentStatus
  created_at: string
  laboratories?: Laboratory[]
}

export interface Laboratory {
  id: string
  module_id: string
  type: LabMode
  template_key: string
  title: string
  description: string
  status: ContentStatus
  current_version_id: string | null
  created_at: string
  versions?: LaboratoryVersion[]
}

export interface LaboratoryVersion {
  id: string
  laboratory_id: string
  version: number
  schema_version: number
  config_json: Record<string, unknown>
  created_by: string | null
  created_at: string
  published_at: string | null
}

export interface Task {
  id: string
  laboratory_id: string
  created_at: string
  versions?: TaskVersion[]
}

export interface TaskVersion {
  id: string
  task_id: string
  version: number
  statement: string
  rubric_json: Record<string, unknown>
  max_score: number
  created_at: string
  published_at: string | null
}

export interface Assignment {
  id: string
  task_version_id: string
  group_id: string
  opens_at: string
  due_at: string | null
  max_attempts: number
  status: ContentStatus
  created_at: string
}

export interface AssignmentSummary {
  id: string
  labId: string
  title: string
  dueAt: string
  maxAttempts: number
  maxScore: number
  criteria: string[]
}

export interface LabSummary {
  id: string
  title: string
  mode: LabMode
  templateKey: string
  description: string
  status: ContentStatus
  attempts: number
  maxAttempts: number
  attemptStatus: AttemptStatus
}

export interface ModuleSummary {
  id: string
  title: string
  intro: string
  labs: LabSummary[]
}

export interface CourseSummary {
  id: string
  title: string
  code: string
  description: string
  academicYear: string
  modules: ModuleSummary[]
}
