# Web Optimization Lab

Образовательная платформа оптимизации веб-приложений (ТЗ A297, версия 1.0).
ПМ.09, МДК.09.02 «Оптимизация веб-приложений», специальность 09.02.07.

## Стек

| Слой | Технология |
| --- | --- |
| Frontend | Vue 3 + TypeScript, Vite 5 |
| Роутинг | Vue Router 4 (hash history для GitHub Pages) |
| Состояние | Pinia 4 |
| Стили | Tailwind CSS 4 (`@tailwindcss/vite`), семантические CSS-токены, тёмная тема |
| Backend | Supabase (Auth, PostgreSQL, Storage, Edge Functions) — подключается на этапе 1 |
| Деплой | GitHub Actions → GitHub Pages (`.github/workflows/deploy.yml`) |

## Быстрый старт

Требуется Node.js 22 LTS (в CI используется 22). На Node 21 проект тоже собирается,
потому что Vite зафиксирован на 5.x, но 21 — EOL: обновите Node перед переходом на Vite 6+.

```bash
npm install
npm run dev
```

Откройте `http://localhost:5173`.

```bash
npm run build      # vue-tsc + production-сборка в dist/
npm run preview    # локальный просмотр собранной версии
npm run typecheck  # только проверка типов
```

## Демо-режим

Пока `VITE_SUPABASE_URL` и `VITE_SUPABASE_ANON_KEY` не заданы, приложение работает
на локальном демо-каталоге (`src/data/catalog.ts`): доступны все страницы и
переключатель роли «студент / администратор» в шапке.

Чтобы подключить Supabase, скопируйте `.env.example` в `.env` и заполните
публичные значения из Project Settings → API. `service_role` key в клиент не добавляется.

## Структура

```text
src/
  assets/main.css       дизайн-токены, светлая/тёмная тема, базовые компоненты
  components/           AppHeader, AppFooter, ModeBadge
  data/catalog.ts       демо-каталог курсов, блоков и лабораторий
  lib/supabase.ts       клиент Supabase (null в демо-режиме)
  router/index.ts       маршруты из ТЗ, guard по авторизации и роли
  stores/auth.ts        сессия, профиль, роль, демо-режим
  types/models.ts       Role, LabMode, Course, Lab, Assignment
  views/                Home, Login, Courses, Course, Lab, Assignment, Profile,
                        Report, Teacher, Admin, Forbidden, NotFound
supabase/migrations/    SQL-схема, RLS, функции start_attempt/submit_attempt
prototype/index.html    прототип трёх режимов (localStorage)
```

## Маршруты

`/` · `/login` · `/courses` · `/courses/:id` · `/labs/:id` · `/assignments/:id`
· `/profile` · `/reports/:id` · `/teacher` · `/admin`.

Доступ к `/teacher` — только администратор, к `/admin` — только администратор.
Проверка роли в интерфейсе служит только удобством: реальные ограничения задают
RLS-политики Supabase (ТЗ, раздел 2).

## Supabase

1. Создайте проект на supabase.com (PostgreSQL 15+).
2. Откройте SQL Editor и выполните файл `supabase/migrations/001_schema_and_rls.sql` целиком.
   Он создаёт схему, индексы, RLS-политики, триггеры профиля и функции
   `start_attempt` / `submit_attempt`. Файл идемпотентен: повторный запуск не ломает
   созданные объекты, но не мигрирует уже изменённые таблицы.
3. Назначьте первого администратора вручную:
   `update public.profiles set role = 'admin' where id = '<uuid пользователя>';`
   Через API роль изменить нельзя — это защищено триггером `protect_profile`.
4. Добавьте `VITE_SUPABASE_URL` и `VITE_SUPABASE_ANON_KEY` в `.env` локально
   и в GitHub → Settings → Secrets and variables → Actions → Variables.

Что важно знать о схеме:

- Профиль создаётся триггером при регистрации; поле — `display_name`, роль — `role`.
- `task_private` хранит приватные тесты и эталоны: у студентов нет даже `SELECT`.
- `submissions` неизменяемы: сдача добавляет ревизию (`revision`), обновлять и удалять
  снимок может только `service_role`.
- `attempts` создаются только функцией `start_attempt()`, а не прямым `INSERT`.
- Прямой `UPDATE` роли или статуса в `profiles` блокируется триггером.
- Хранилище файлов настраивается отдельно: приватный бакет `lab-assets`,
  таблица `assets` хранит только метаданные, доступ — по signed URL.

Проверка после применения (SQL Editor):

```sql
-- RLS включён на всех таблицах
select relname, relrowsecurity
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by relname;

-- Политики по таблицам
select schemaname, tablename, policyname, cmd
from pg_policies where schemaname = 'public'
order by tablename, policyname;
```


## Деплой на GitHub Pages

Workflow `.github/workflows/deploy.yml` собирает проект с
`VITE_BASE=/<имя репозитория>/` и публикует `dist` через Pages.
В настройках репозитория выберите Source → GitHub Actions.

Используется hash history (`/#/courses`): GitHub Pages не отдаёт `index.html`
для вложенных путей без отдельной схемы с `404.html`. Переход на history-режим
возможен позже вместе с fallback-страницей.

## Что реализовано в каркасе

- Vue 3 + TS + Vite, алиас `@`, строгий режим TypeScript.
- Дизайн-система: токены, светлая/тёмная тема, адаптив от 360px, доступные подписи и focus-стили.
- Роутинг по информационной архитектуре ТЗ, guard авторизации и ролей, заголовки страниц.
- Pinia-store авторизации: Supabase Auth, профиль из `profiles`, демо-режим без бэкенда.
- Клиент Supabase без секретов; при отсутствии переменных окружения не инициализируется.
- Каркас страниц: каталог, курс с прогрессом, лаборатория с панелями трёх режимов,
  задание, кабинет студента, отчёт под печать, кабинет преподавателя, админка,
  403 и 404.
- CI-workflow публикации на GitHub Pages.

## Дальше по этапам ТЗ

1. **Основа** — подключить Supabase Auth (приглашения), реальные `profiles`, RLS-тесты.
2. **Контент** — админка и конструктор на JSON Schema, версии/публикация, импорт/экспорт.
3. **Движки** — тренажёр (безопасный вычислитель), Monaco + sandboxed iframe, практикум.
4. **Проверка и отчёты** — попытки, эксперименты, журнал, оценки, PDF.
5. **Наполнение и пилот** — четыре MVP-лаборатории, тестовые студенты, публикация.
6. **Передача** — README, миграции, руководства, сценарии восстановления.

## Ограничения текущей версии

- Каталог и задания — демонстрационные, из `src/data/catalog.ts`; Supabase-запросы ещё не подключены.
- Движки лабораторий не реализованы: на странице лаборатории показаны панели-заглушки.
- Политики RLS в миграции упрощены: админ видит весь контент; ограничение
  «инструктор видит только свои курсы» нужно добавить отдельной миграцией на основе `course_staff`.
- `group_members` изменяет только администратор: сценарий приглашений и самостоятельного
  вступления в группу требует Edge Function.
- Миграция не проверялась на живой базе Supabase: синтаксис и RLS нужно прогнать
  на тестовом проекте до пилота.
- Бакет `lab-assets` и политики `storage.objects` не входят в миграцию — настраиваются отдельно.
- PDF-отчёт реализован как предпросмотр с печатью браузера, серверная генерация — этап 4.
