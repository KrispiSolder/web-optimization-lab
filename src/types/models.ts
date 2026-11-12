export type Role = 'student' | 'admin'

export type LabMode = 'A' | 'B' | 'C'

export type ContentStatus = 'draft' | 'published' | 'archived'

export type AttemptStatus =
  | 'not-started'
  | 'in-progress'
  | 'submitted'
  | 'graded'
  | 'returned'

export interface Profile {
  id: string
  display_name: string | null
  role: Role
  status: string
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

export interface AssignmentSummary {
  id: string
  labId: string
  title: string
  dueAt: string
  maxAttempts: number
  maxScore: number
  criteria: string[]
}
