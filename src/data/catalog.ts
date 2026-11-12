import type { AssignmentSummary, CourseSummary } from '@/types/models'

/**
 * Демонстрационный каталог для каркаса и разработки UI.
 * На этапе 2 эти данные переезжают в таблицы courses/modules/laboratories
 * и загружаются через Supabase (ТЗ, разделы 5 и 9).
 */
export const demoCourses: CourseSummary[] = [
  {
    id: 'mdc-09-02',
    title: 'Оптимизация веб-приложений',
    code: 'МДК.09.02',
    description:
      'Практико-ориентированный курс: техническое SEO, производительность, семантика, веб-аналитика и продвижение.',
    academicYear: '2026/2027',
    modules: [
      {
        id: 'mod-seo',
        title: 'SEO и индексация',
        intro: 'Метатеги, заголовки, robots.txt, sitemap.xml, редиректы и ссылочная структура.',
        labs: [
          {
            id: 'lab-meta-seo',
            title: 'Метатеги и внутренний SEO-аудит',
            mode: 'code-lab',
            templateKey: 'html-audit',
            description:
              'Реальная лаборатория: исправьте HTML-разметку страницы и пройдите функциональные тесты в песочнице.',
            status: 'published',
            attempts: 1,
            maxAttempts: 3,
            attemptStatus: 'in-progress',
          },
          {
            id: 'lab-robots',
            title: 'robots.txt и индексация',
            mode: 'parameter-simulator',
            templateKey: 'parameter-simulator',
            description:
              'Тренажёр: настройте директивы robots.txt и проверьте, какие страницы попадут в индекс.',
            status: 'published',
            attempts: 0,
            maxAttempts: 3,
            attemptStatus: 'not-started',
          },
        ],
      },
      {
        id: 'mod-perf',
        title: 'Производительность',
        intro: 'Форматы и размер изображений, lazy loading, загрузка ресурсов, кеширование.',
        labs: [
          {
            id: 'lab-images',
            title: 'Оптимизация изображений',
            mode: 'parameter-simulator',
            templateKey: 'parameter-simulator',
            description:
              'Тренажёр: подберите формат и качество сжатия, чтобы уложиться в лимит размера файла.',
            status: 'published',
            attempts: 2,
            maxAttempts: 5,
            attemptStatus: 'submitted',
          },
          {
            id: 'lab-cache',
            title: 'Кеш и загрузка ресурсов',
            mode: 'parameter-simulator',
            templateKey: 'parameter-simulator',
            description:
              'Тренажёр: настройте заголовки кеширования и приоритеты загрузки ресурсов.',
            status: 'draft',
            attempts: 0,
            maxAttempts: 3,
            attemptStatus: 'not-started',
          },
        ],
      },
      {
        id: 'mod-analytics',
        title: 'Веб-аналитика',
        intro: 'События и цели, источники трафика, конверсия, метрики KPI.',
        labs: [
          {
            id: 'lab-funnel',
            title: 'Воронка и конверсия',
            mode: 'parameter-simulator',
            templateKey: 'parameter-simulator',
            description:
              'Тренажёр: соберите воронку, настройте цели и оцените влияние изменений на конверсию.',
            status: 'published',
            attempts: 0,
            maxAttempts: 3,
            attemptStatus: 'not-started',
          },
        ],
      },
      {
        id: 'mod-audit',
        title: 'Комплексный аудит',
        intro: 'Аудит → улучшение → отчёт: интернет-магазин с проблемами скорости и SEO.',
        labs: [
          {
            id: 'lab-shop-audit',
            title: 'Кейс: оптимизация интернет-магазина',
            mode: 'case-practicum',
            templateKey: 'case-study',
            description:
              'Практикум: диагностика, гипотеза, эксперимент, сравнение показателей и итоговый отчёт.',
            status: 'published',
            attempts: 0,
            maxAttempts: 2,
            attemptStatus: 'not-started',
          },
        ],
      },
    ],
  },
]

export const demoAssignments: AssignmentSummary[] = [
  {
    id: 'asg-images-01',
    labId: 'lab-images',
    title: 'Оптимизация изображений: уложиться в бюджет',
    dueAt: '2026-11-20T18:00:00+08:00',
    maxAttempts: 5,
    maxScore: 10,
    criteria: [
      'Итоговый размер файла не превышает 900 КБ',
      'Выбран обоснованный формат изображения',
      'В выводе объяснено влияние качества на размер и визуальное восприятие',
    ],
  },
  {
    id: 'asg-meta-seo-01',
    labId: 'lab-meta-seo',
    title: 'Внутренний SEO-аудит главной страницы',
    dueAt: '2026-11-27T18:00:00+08:00',
    maxAttempts: 3,
    maxScore: 10,
    criteria: [
      'Все функциональные тесты пройдены',
      'Заголовки выстроены в логичную иерархию',
      'Описаны найденные проблемы и внесённые исправления',
    ],
  },
]

export function findCourse(id: string): CourseSummary | undefined {
  return demoCourses.find((course) => course.id === id)
}

export function findLab(labId: string) {
  for (const course of demoCourses) {
    for (const module of course.modules) {
      const lab = module.labs.find((item) => item.id === labId)
      if (lab) return { course, module, lab }
    }
  }
  return undefined
}

export function findAssignment(id: string): AssignmentSummary | undefined {
  return demoAssignments.find((assignment) => assignment.id === id)
}
