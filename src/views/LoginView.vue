<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { isConfigured } from '../lib/supabase'
const auth = useAuthStore(), router = useRouter(), route = useRoute()
const mode = ref<'login' | 'register'>('login'), email = ref(''), password = ref(''), fullName = ref(''), error = ref(''), info = ref(''), busy = ref(false)
async function submit() {
  error.value = ''; info.value = ''; busy.value = true
  try {
    if (mode.value === 'register') {
      if (fullName.value.trim().length < 2) throw new Error('Укажите имя и фамилию')
      await auth.signUp(email.value.trim(), password.value, fullName.value.trim())
      info.value = 'Регистрация отправлена. Проверьте почту для подтверждения, если оно включено в Supabase.'
    } else {
      await auth.signIn(email.value.trim(), password.value)
      const redirect = typeof route.query.redirect === 'string' && route.query.redirect.startsWith('/') && !route.query.redirect.startsWith('//') ? route.query.redirect : '/dashboard'
      await router.push(redirect)
    }
  } catch (e) { error.value = e instanceof Error ? e.message : 'Ошибка авторизации' } finally { busy.value = false }
}
</script>
<template><div class="auth-wrapper"><div class="auth-card"><div class="eyebrow">ЛИЧНЫЙ КАБИНЕТ</div><h1>{{ mode === 'login' ? 'С возвращением' : 'Создать аккаунт' }}</h1><p class="muted">{{ mode === 'login' ? 'Войдите, чтобы продолжить обучение.' : 'Новый аккаунт автоматически получает роль студента.' }}</p><div class="tabs"><button :class="{ active: mode === 'login' }" @click="mode='login';error='';info=''">Вход</button><button :class="{ active: mode === 'register' }" @click="mode='register';error='';info=''">Регистрация</button></div><form @submit.prevent="submit"><label v-if="mode === 'register'">Имя и фамилия<input v-model="fullName" required minlength="2" autocomplete="name" placeholder="Иван Иванов"/></label><label>Электронная почта<input v-model="email" type="email" autocomplete="email" required placeholder="student@example.com"/></label><label>Пароль<input v-model="password" type="password" :autocomplete="mode === 'login' ? 'current-password' : 'new-password'" minlength="6" required placeholder="Не менее 6 символов"/></label><p v-if="error" class="form-error" role="alert">{{ error }}</p><p v-if="info" class="form-success" role="status">{{ info }}</p><button class="btn btn-primary full" :disabled="busy || !isConfigured">{{ busy ? 'Проверяем…' : (mode === 'login' ? 'Войти' : 'Зарегистрироваться') }}</button></form></div></div></template>
