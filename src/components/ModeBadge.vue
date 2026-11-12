<script setup lang="ts">
import type { LabMode } from '@/types/models'

defineProps<{ mode: LabMode }>()

const titles: Record<LabMode, string> = {
  'parameter-simulator': 'Тренажёр',
  'code-lab': 'Реальная лаборатория',
  'case-practicum': 'Практикум',
}
</script>

<template>
  <span class="tag">
    Режим {{ mode }} · {{ titles[mode] }}
  </span>
</template>
