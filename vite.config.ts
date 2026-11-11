import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

// base нужен для GitHub Pages: project-site публикуется в /<repo>/.
// Значение берётся из VITE_BASE, чтобы локальная сборка оставалась на '/'.
const base = process.env.VITE_BASE || '/'

export default defineConfig({
  base,
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    target: 'es2020',
    // Vue, Router и Pinia отдельным чанком: они нужны всем страницам.
    // Monaco и ECharts будут подключаться лениво на этапе 3–4.
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
        },
      },
    },
  },
})
