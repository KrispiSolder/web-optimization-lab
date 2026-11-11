<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'
import { isConfigured } from './lib/supabase'
const auth = useAuthStore()
const router = useRouter()
const displayName = computed(() => auth.profile?.full_name || auth.user?.email || 'Гость')
async function logout() { await auth.signOut(); await router.push('/') }
</script>
<template>
  <div class="app-shell">
    <header class="site-header">
      <div class="container header-inner">
        <RouterLink class="brand" to="/"><span class="brand-symbol">W/</span><span>Web Optimization <b>Lab</b></span></RouterLink>
        <nav class="nav-links" aria-label="Основная навигация"><RouterLink to="/">Главная</RouterLink><RouterLink v-if="auth.isLoggedIn" to="/dashboard">Кабинет</RouterLink><RouterLink v-if="auth.isStaff" to="/admin">Управление</RouterLink></nav>
        <div class="header-actions"><span v-if="auth.isLoggedIn" class="profile-chip">{{ displayName }}</span><button v-if="auth.isLoggedIn" class="btn btn-ghost" @click="logout">Выйти</button><RouterLink v-else class="btn btn-primary" to="/login">Войти</RouterLink></div>
      </div>
    </header>
    <div v-if="!isConfigured" class="container"><div class="setup-alert">Демо-режим: подключение к Supabase не настроено. Укажите URL и publishable key в <code>.env.local</code>.</div></div>
    <main class="container page"><RouterView /></main>
    <footer class="container footer">Web Optimization Lab · Учебная лаборатория веб-оптимизации · Этап 1</footer>
  </div>
</template>
