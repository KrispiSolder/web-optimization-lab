import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type { User } from '@supabase/supabase-js'
import type { Profile, Role } from '@/types/models'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

const DEMO_ROLE_KEY = 'wol.demoRole'

function readDemoRole(): Role {
  const stored = localStorage.getItem(DEMO_ROLE_KEY)
  return stored === 'teacher' || stored === 'admin' ? stored : 'student'
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const profile = ref<Profile | null>(null)
  const loading = ref(true)
  const error = ref<string | null>(null)
  /** Демо-режим включается автоматически, если Supabase не сконфигурирован. */
  const isDemo = ref(!isSupabaseConfigured)
  const demoRole = ref<Role>(readDemoRole())

  let initialized = false

  const role = computed<Role | null>(() =>
    isDemo.value ? demoRole.value : (profile.value?.role ?? null),
  )

  const isAuthenticated = computed(() => isDemo.value || user.value !== null)

  const displayName = computed(() => {
    if (isDemo.value) {
      return demoRole.value === 'student'
        ? 'Демо-студент'
        : demoRole.value === 'teacher'
          ? 'Демо-преподаватель'
          : 'Демо-администратор'
    }
    return profile.value?.display_name ?? user.value?.email ?? 'Пользователь'
  })

  async function loadProfile() {
    if (!supabase || !user.value) {
      profile.value = null
      return
    }
    const { data, error: profileError } = await supabase
      .from('profiles')
      .select('id, display_name, role, status')
      .eq('id', user.value.id)
      .maybeSingle<Profile>()

    if (profileError) {
      error.value = profileError.message
      profile.value = null
      return
    }
    profile.value = data
  }

  async function init() {
    if (initialized) return
    initialized = true

    if (!supabase) {
      loading.value = false
      return
    }

    try {
      const { data } = await supabase.auth.getSession()
      user.value = data.session?.user ?? null
      await loadProfile()

      supabase.auth.onAuthStateChange((_event, session) => {
        user.value = session?.user ?? null
        void loadProfile()
      })
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : 'Не удалось инициализировать Auth'
    } finally {
      loading.value = false
    }
  }

  async function signIn(email: string, password: string) {
    if (!supabase) {
      error.value = 'Supabase не настроен: доступен только демо-режим.'
      return false
    }
    error.value = null
    loading.value = true
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password })
    loading.value = false
    if (signInError) {
      error.value = signInError.message
      return false
    }
    return true
  }

  async function signOut() {
    if (!supabase) return
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  function setDemoRole(next: Role) {
    demoRole.value = next
    localStorage.setItem(DEMO_ROLE_KEY, next)
  }

  return {
    user,
    profile,
    loading,
    error,
    isDemo,
    demoRole,
    role,
    displayName,
    isAuthenticated,
    init,
    signIn,
    signOut,
    setDemoRole,
  }
})
