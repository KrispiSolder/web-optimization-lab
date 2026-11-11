<template>
  <div class="mx-auto max-w-xl py-10 text-center">
    <p class="font-serif text-6xl font-bold text-accent">404</p>
    <h1 class="mt-3 text-2xl">Страница не найдена</h1>
    <p class="mt-2 text-sm text-muted">
      Проверьте адрес или вернитесь к каталогу курсов.
    </p>
    <div class="mt-6 flex justify-center gap-2">
      <RouterLink :to="{ name: 'home' }" class="btn btn-primary">На главную</RouterLink>
      <RouterLink :to="{ name: 'courses' }" class="btn">К курсам</RouterLink>
    </div>
  </div>
</template>
