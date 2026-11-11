<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<template>
  <footer class="border-t border-line bg-surface">
    <div class="mx-auto flex w-full max-w-6xl flex-col gap-1 px-4 py-5 text-xs text-muted sm:flex-row sm:items-center sm:justify-between sm:px-6">
      <p>Web Optimization Lab · МДК.09.02 «Оптимизация веб-приложений»</p>
      <p>Учебный проект, {{ year }}. Показатели тренажёров — учебная модель, а не реальные измерения.</p>
    </div>
  </footer>
</template>
