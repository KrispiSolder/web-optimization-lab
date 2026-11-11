<script setup lang="ts">
import type { LabMode } from '@/types/models'

defineProps<{ mode: LabMode }>()

const titles: Record<LabMode, string> = {
  A: 'Тренажёр',
  B: 'Реальная лаборатория',
  C: 'Практикум',
}
</script>

<template>
  <span class="tag">
    Режим {{ mode }} · {{ titles[mode] }}
  </span>
</template>
