<template>
  <div class="mx-auto max-w-xl py-10 text-center">
    <p class="font-serif text-6xl font-bold text-accent">403</p>
    <h1 class="mt-3 text-2xl">Недостаточно прав</h1>
    <p class="mt-2 text-sm text-muted">
      Раздел доступен другой роли. Права проверяются и на сервере политиками RLS, поэтому обход
      интерфейса не даст доступа к данным.
    </p>
    <div class="mt-6 flex justify-center gap-2">
      <RouterLink :to="{ name: 'home' }" class="btn btn-primary">На главную</RouterLink>
      <RouterLink :to="{ name: 'courses' }" class="btn">К курсам</RouterLink>
    </div>
  </div>
</template>
