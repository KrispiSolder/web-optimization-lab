<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const email = ref('')
const password = ref('')
const submitting = ref(false)

async function handleSubmit() {
  submitting.value = true
  const success = await auth.signIn(email.value, password.value)
  submitting.value = false
  if (success) {
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : null
    await router.push(redirect ?? { name: 'courses' })
  }
}
</script>

<template>
  <div class="mx-auto grid max-w-4xl gap-6 py-6 lg:grid-cols-[1fr_0.9fr]">
    <div>
      <h1 class="text-3xl">Вход в систему</h1>
      <p class="mt-2 text-sm text-muted">
        Доступ выдаётся по приглашению или предварительно разрешённой регистрации. Роль назначает
        администратор — повысить её самостоятельно нельзя.
      </p>

      <form class="card mt-6 flex flex-col gap-4" @submit.prevent="handleSubmit">
        <div>
          <label class="label" for="email">Электронная почта</label>
          <input
            id="email"
            v-model.trim="email"
            class="field"
            type="email"
            autocomplete="email"
            required
            placeholder="student@example.ru"
          />
        </div>
        <div>
          <label class="label" for="password">Пароль</label>
          <input
            id="password"
            v-model="password"
            class="field"
            type="password"
            autocomplete="current-password"
            required
            minlength="6"
          />
        </div>

        <p v-if="auth.error" class="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn" role="alert">
          {{ auth.error }}
        </p>

        <button class="btn btn-primary" type="submit" :disabled="submitting">
          {{ submitting ? 'Проверяем…' : 'Войти' }}
        </button>

        <p class="text-xs text-muted">
          Восстановление доступа и приглашения подключаются на этапе 1 вместе с Supabase Auth.
        </p>
      </form>
    </div>

    <aside class="card h-fit bg-surface-2">
      <h2 class="text-lg">Демо-режим</h2>
      <p class="mt-2 text-sm text-muted">
        Без переменных окружения Supabase приложение работает на локальных данных. Выберите роль,
        чтобы посмотреть интерфейсы студента, преподавателя и администратора.
      </p>
      <div class="mt-4 flex flex-col gap-2">
        <RouterLink :to="{ name: 'courses' }" class="btn btn-primary">Продолжить как студент</RouterLink>
        <button type="button" class="btn" @click="auth.setDemoRole('admin')">
          Включить роль администратора
        </button>
      </div>
      <p class="mt-4 text-xs text-muted">
        Текущая роль: <strong class="text-ink">{{ auth.role ?? 'гость' }}</strong>
      </p>
    </aside>
  </div>
</template>
