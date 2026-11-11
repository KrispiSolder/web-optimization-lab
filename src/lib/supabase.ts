import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

/**
 * Клиент Supabase. Пока переменные окружения не заданы, приложение работает
 * в демо-режиме на локальных данных — это позволяет разрабатывать UI без бэкенда.
 *
 * Здесь используется только публичный anon/publishable key: доступ ограничивают RLS-политики.
 * service_role key не должен попадать в клиентский бандл (ТЗ, раздел 10).
 */
export const supabase: SupabaseClient | null =
  url && anonKey
    ? createClient(url, anonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      })
    : null

export const isSupabaseConfigured = supabase !== null
