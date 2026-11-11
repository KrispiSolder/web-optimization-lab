import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
export type Role = 'student' | 'teacher' | 'admin'
export interface Profile { id: string; full_name: string; role: Role }
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const profile = ref<Profile | null>(null)
  const initialized = ref(false)
  let bootPromise: Promise<void> | null = null
  const isLoggedIn = computed(() => !!user.value)
  const isStaff = computed(() => profile.value?.role === 'teacher' || profile.value?.role === 'admin')
  async function loadProfile() {
    if (!supabase || !user.value) { profile.value = null; return }
    const { data, error } = await supabase.from('profiles').select('id,full_name,role').eq('id', user.value.id).single()
    if (error) { console.warn('Не удалось загрузить профиль:', error.message); profile.value = null; return }
    profile.value = data as Profile
  }
  async function bootstrap() {
    if (bootPromise) return bootPromise
    bootPromise = (async () => {
      try {
        if (supabase) {
          const { data } = await supabase.auth.getUser()
          user.value = data.user
          await loadProfile()
          supabase.auth.onAuthStateChange((_event, session) => {
            // Avoid awaited Supabase queries inside the auth callback.
            user.value = session?.user ?? null
            if (!session?.user) profile.value = null
            else setTimeout(() => { void loadProfile() }, 0)
          })
        }
      } finally { initialized.value = true }
    })()
    return bootPromise
  }
  async function signIn(email: string, password: string) {
    if (!supabase) throw new Error('Supabase ещё не настроен')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    const { data } = await supabase.auth.getUser()
    user.value = data.user
    await loadProfile()
  }
  async function signUp(email: string, password: string, fullName: string) {
    if (!supabase) throw new Error('Supabase ещё не настроен')
    const { error } = await supabase.auth.signUp({ email, password, options: { data: { full_name: fullName } } })
    if (error) throw error
  }
  async function signOut() {
    if (!supabase) return
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    user.value = null; profile.value = null
  }
  return { user, profile, initialized, isLoggedIn, isStaff, bootstrap, signIn, signUp, signOut, loadProfile }
})
