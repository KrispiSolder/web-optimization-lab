<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const fio = ref('')
const password = ref('')
const submitting = ref(false)

async function handleSubmit() {
  submitting.value = true
  const success = await auth.signInOrRegisterByFio(fio.value, password.value)
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
          <label class="label" for="fio">ФИО</label>
          <input
            id="fio"
            v-model.trim="fio"
            class="field"
            type="text"
            autocomplete="name"
            required
            placeholder="Иванов Иван"
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
          При первом входе аккаунт создаётся автоматически по вашему ФИО. Почта формируется
          внутри системы и не требуется вводить отдельно.
        </p>
      </form>
    </div>

    <aside class="card h-fit bg-surface-2">
    
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
