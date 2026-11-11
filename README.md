# Web Optimization Lab — Этап 1

Первый рабочий этап образовательной платформы для МДК.09.02: Vue 3 + Vite + TypeScript + Pinia + Supabase Auth. Лаборатории и управление заданиями появятся на следующих этапах.

## 1. Запуск локально

Требуется Node.js 22+. Зависимости устанавливаются локально; архив не включает `node_modules`.

```bash
npm install
cp .env.example .env.local
npm run dev
```

В Windows PowerShell скопируйте файл так:

```powershell
Copy-Item .env.example .env.local
```

Откройте адрес из консоли (обычно http://localhost:5173).

Без настроенного Supabase можно просмотреть главную страницу, но вход и личный кабинет будут недоступны.

## 2. Подключение Supabase

1. Создайте проект в https://supabase.com/dashboard.
2. Откройте **SQL Editor** и выполните `supabase/migrations/001_initial_auth.sql`.
3. В **Project Settings → API Keys** либо разделе **Connect** скопируйте **Project URL** и **Publishable key**.
4. Заполните `.env.local` значениями `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`.
5. В **Authentication → URL Configuration** задайте Site URL для локальной разработки: `http://localhost:5173/`. Добавьте Redirect URLs для вашего GitHub Pages адреса.
6. В **Authentication → Providers → Email** проверьте настройки регистрации и подтверждения email. При включённом подтверждении студент должен перейти по ссылке из письма до первого входа.
7. Выполните `npm run dev` и создайте тестового студента.

**ВАЖНО:** Администратор не создаётся публичной регистрацией. После создания своего пользователя откройте **Authentication → Users**, скопируйте его UUID и в SQL Editor выполните:

```sql
update public.profiles set role = 'admin' where id = 'UUID-ВАШЕГО-ПОЛЬЗОВАТЕЛЯ';
```

Для преподавателя вместо `admin` используйте `teacher`. Если аккаунт уже был создан до миграции, добавьте профиль через SQL Editor вручную.

## 3. Публикация на GitHub Pages

1. Создайте репозиторий GitHub, перенесите файлы проекта (кроме `.env.local`).
2. Откройте **Settings → Pages → Build and deployment → GitHub Actions**.
3. В **Settings → Secrets and variables → Actions → Variables** создайте:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_PUBLISHABLE_KEY`
4. Отправьте код в ветку `main`. Workflow из `.github/workflows/deploy.yml` установит зависимости, выполнит сборку и публикацию.
5. В Supabase **Authentication → URL Configuration** добавьте `https://USERNAME.github.io/REPOSITORY/` в разрешённые Redirect URLs и при необходимости настройте Site URL на опубликованный адрес.

Путь `VITE_BASE_PATH` для GitHub Pages workflow задаёт автоматически. Для навигации используется hash-router (`/#/dashboard`), чтобы перезагрузка страницы не возвращала 404.

**Безопасность:** publishable key предназначен для браузера и не является секретом, но service_role/secret keys НИКОГДА не должны попадать во фронтенд, репозиторий или GitHub Pages. Реальный контроль доступа обеспечивается RLS. Пока разрешено только чтение собственного профиля.

## 4. Что уже работает

- Публичная главная страница с тремя режимами (пока информационными).
- Регистрация и вход по email/password через Supabase.
- Автоматическое создание профиля со статусом `student`.
- Проверка входа и роли перед переходом на закрытые страницы.
- Каркас кабинета и раздела преподавателя/администратора.
- GitHub Actions для сборки GitHub Pages.

## 5. Что будет следующим этапом

- Таблицы `courses`, `modules`, `laboratories` с RLS и привязкой к преподавателям.
- Список курсов в админке и формы создания/редактирования.
- Публикация блоков и назначение группам.
- Затем универсальный движок трёх лабораторных режимов.

Важно: отображаемые в интерфейсе счётчики сейчас равны нулю и являются заглушками. Конструктор и лаборатории ещё не реализованы.
