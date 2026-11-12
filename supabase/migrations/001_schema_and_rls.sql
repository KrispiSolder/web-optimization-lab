-- ============================================================================
-- Web Optimization Lab — базовая схема, RLS и серверные функции
-- ТЗ A297, разделы 6, 9, 10.
-- Требуется PostgreSQL 15+ (Supabase): gen_random_uuid() встроен в ядро.
--
-- Как применять:
--   1. Supabase Dashboard → SQL Editor → вставить файл целиком → Run.
--      либо: supabase db push (если проект инициализирован через Supabase CLI).
--   2. Назначить первого администратора вручную:
--      update public.profiles set role = 'admin' where id = '<uuid пользователя>';
--      Роль нельзя повысить через Data API: это блокирует триггер protect_profile.
--
-- Файл идемпотентен: повторный запуск не ломает уже созданные объекты,
-- но НЕ мигрирует старые таблицы (для этого нужны отдельные миграции).
-- Выполнять на чистой базе; при изменении схемы добавляйте новые файлы 002_..., 003_...
--
-- Что НЕ входит:
--   * бакеты Storage и политики storage.objects — настраиваются отдельно
--     (приватный бакет lab-assets, доступ по signed URL);
--   * доверенная проверка тестов и расчёт автооценки — Edge Functions (этап 4).
-- ============================================================================

-- ============================================================================
-- 1. Таблицы
-- ============================================================================

-- Профиль 1:1 с auth.users. Роль назначает только администратор.
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  role         text not null default 'student' check (role in ('student', 'admin')),
  status       text not null default 'active'  check (status in ('active', 'blocked', 'archived')),
  created_at   timestamptz not null default now()
);

create table if not exists public.groups (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  academic_year text,
  owner_id      uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id  uuid not null references public.groups (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.courses (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  code          text,
  description   text not null default '',
  owner_id      uuid references public.profiles (id) on delete set null,
  academic_year text,
  status        text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_at    timestamptz not null default now()
);

-- Закрепление преподавателей за курсом (основа будущего ограничения «только свои курсы»).
create table if not exists public.course_staff (
  course_id uuid not null references public.courses (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  role      text not null default 'instructor' check (role in ('instructor', 'assistant')),
  primary key (course_id, user_id)
);

create table if not exists public.modules (
  id         uuid primary key default gen_random_uuid(),
  course_id  uuid not null references public.courses (id) on delete cascade,
  title      text not null,
  intro      text not null default '',
  sort_order int not null default 0,
  status     text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now()
);

create table if not exists public.laboratories (
  id                 uuid primary key default gen_random_uuid(),
  module_id          uuid not null references public.modules (id) on delete cascade,
  type               text not null check (type in ('parameter-simulator', 'code-lab', 'case-practicum')),
  template_key       text not null,
  title              text not null,
  description        text not null default '',
  status             text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  -- FK добавляется после создания laboratory_versions (циклическая ссылка).
  current_version_id uuid,
  created_at         timestamptz not null default now()
);

create table if not exists public.laboratory_versions (
  id            uuid primary key default gen_random_uuid(),
  laboratory_id uuid not null references public.laboratories (id) on delete cascade,
  version       int not null check (version > 0),
  schema_version int not null default 1 check (schema_version > 0),
  config_json   jsonb not null,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  published_at  timestamptz,
  unique (laboratory_id, version)
);

alter table public.laboratories
  drop constraint if exists laboratories_current_version_fk;
alter table public.laboratories
  add constraint laboratories_current_version_fk
  foreign key (current_version_id) references public.laboratory_versions (id) on delete set null;

create table if not exists public.tasks (
  id            uuid primary key default gen_random_uuid(),
  laboratory_id uuid not null references public.laboratories (id) on delete cascade,
  created_at    timestamptz not null default now()
);

create table if not exists public.task_versions (
  id            uuid primary key default gen_random_uuid(),
  task_id       uuid not null references public.tasks (id) on delete cascade,
  version       int not null check (version > 0),
  statement     text not null,
  rubric_json   jsonb not null default '{}'::jsonb,
  max_score     numeric not null default 10 check (max_score > 0),
  created_at    timestamptz not null default now(),
  published_at  timestamptz,
  unique (task_id, version)
);

-- Приватные тесты и эталоны. Студентам недоступны даже при наличии SELECT на task_versions.
create table if not exists public.task_private (
  task_version_id uuid primary key references public.task_versions (id) on delete cascade,
  tests_json      jsonb not null default '{}'::jsonb
);

create table if not exists public.assignments (
  id              uuid primary key default gen_random_uuid(),
  task_version_id uuid not null references public.task_versions (id),
  group_id        uuid not null references public.groups (id),
  opens_at        timestamptz not null default now(),
  due_at          timestamptz,
  max_attempts    int not null default 3 check (max_attempts > 0),
  status          text not null default 'active' check (status in ('draft', 'active', 'archived')),
  created_at      timestamptz not null default now(),
  check (due_at is null or due_at > opens_at)
);

create table if not exists public.attempts (
  id              uuid primary key default gen_random_uuid(),
  assignment_id   uuid not null references public.assignments (id),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  task_version_id uuid not null references public.task_versions (id),
  status          text not null default 'in_progress'
    check (status in ('draft', 'in_progress', 'submitted', 'graded', 'returned', 'closed')),
  started_at      timestamptz not null default now(),
  submitted_at    timestamptz
);

create table if not exists public.experiments (
  id            uuid primary key default gen_random_uuid(),
  attempt_id    uuid not null references public.attempts (id) on delete cascade,
  sequence      int not null check (sequence > 0),
  input_json    jsonb not null,
  output_json   jsonb not null,
  metric_source text not null check (metric_source in ('measured', 'modelled')),
  engine_version text,
  duration_ms   int check (duration_ms is null or duration_ms >= 0),
  created_at    timestamptz not null default now(),
  unique (attempt_id, sequence)
);

-- Неизменяемый снимок ответа. revision растёт при повторной сдаче
-- после возврата на доработку; прежние ревизии не перезаписываются.
create table if not exists public.submissions (
  id          uuid primary key default gen_random_uuid(),
  attempt_id  uuid not null references public.attempts (id) on delete cascade,
  revision    int not null default 1 check (revision > 0),
  answer_json jsonb not null,
  report_ref  text,
  submitted_at timestamptz not null default now(),
  unique (attempt_id, revision)
);

create table if not exists public.grades (
  id            uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references public.submissions (id) on delete cascade,
  auto_score    numeric not null default 0 check (auto_score >= 0),
  teacher_score numeric check (teacher_score is null or teacher_score >= 0),
  total_score   numeric generated always as (auto_score + coalesce(teacher_score, 0)) stored,
  feedback      text,
  graded_by     uuid references public.profiles (id) on delete set null,
  graded_at     timestamptz not null default now()
);

create table if not exists public.assets (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null unique,
  mime_type    text not null,
  size_bytes   bigint not null check (size_bytes between 0 and 10485760),
  visibility   text not null default 'private' check (visibility in ('private', 'public')),
  created_at   timestamptz not null default now()
);

create table if not exists public.audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid references public.profiles (id) on delete set null,
  event       text not null,
  entity_type text,
  entity_id   uuid,
  at          timestamptz not null default now(),
  detail_json jsonb
);

-- ============================================================================
-- 2. Индексы (внешние ключи и частые фильтры RLS)
-- ============================================================================

create index if not exists idx_group_members_user        on public.group_members (user_id);
create index if not exists idx_course_staff_user         on public.course_staff (user_id);
create index if not exists idx_modules_course            on public.modules (course_id);
create index if not exists idx_laboratories_module       on public.laboratories (module_id);
create index if not exists idx_lab_versions_lab          on public.laboratory_versions (laboratory_id);
create index if not exists idx_tasks_lab                 on public.tasks (laboratory_id);
create index if not exists idx_task_versions_task        on public.task_versions (task_id);
create index if not exists idx_assignments_group         on public.assignments (group_id);
create index if not exists idx_assignments_task_version  on public.assignments (task_version_id);
create index if not exists idx_attempts_user             on public.attempts (user_id);
create index if not exists idx_attempts_assignment       on public.attempts (assignment_id);
create index if not exists idx_experiments_attempt       on public.experiments (attempt_id);
create index if not exists idx_submissions_attempt       on public.submissions (attempt_id);
create index if not exists idx_grades_submission         on public.grades (submission_id);
create index if not exists idx_assets_owner              on public.assets (owner_id);
create index if not exists idx_audit_log_actor           on public.audit_log (actor_id);
create index if not exists idx_audit_log_at              on public.audit_log (at desc);

-- Одна открытая попытка на пару «назначение + студент».
create unique index if not exists uq_attempts_open
  on public.attempts (assignment_id, user_id)
  where status = 'in_progress';

-- ============================================================================
-- 3. Функции и триггеры
-- ============================================================================

-- Роль текущего пользователя. SECURITY DEFINER читает profiles в обход RLS,
-- поэтому не возникает рекурсии в политиках на profiles.
create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid()
    and p.status = 'active'
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
as $$
  select public.app_role() = 'admin'
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.app_role() = 'admin'
$$;

-- Профиль создаётся автоматически при регистрации. Роль всегда 'student',
-- значения из user_metadata клиента игнорируются.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Запрет самостоятельной смены роли и статуса.
-- Администратор и service_role могут менять; остальным — только свои данные.
create or replace function public.protect_profile()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.id <> old.id then
    raise exception 'profiles.id is immutable';
  end if;

  -- Служебные поля меняет только сервер.
  new.created_at := old.created_at;

  if (new.role is distinct from old.role or new.status is distinct from old.status)
     and coalesce(auth.role(), '') <> 'service_role'
     and not public.is_admin() then
    raise exception 'role/status can be changed by admin only';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_protect_profile on public.profiles;
create trigger trg_protect_profile
  before update on public.profiles
  for each row execute function public.protect_profile();

-- Старт попытки. Все проверки выполняются на сервере:
-- членство в группе, окно доступности, лимит попыток, опубликованная версия задания.
create or replace function public.start_attempt(p_assignment uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  a      public.assignments;
  used   int;
  new_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if public.app_role() is null then
    raise exception 'profile is not active';
  end if;

  select * into a
  from public.assignments
  where id = p_assignment
    and status = 'active';

  if not found then
    raise exception 'assignment not found';
  end if;

  if not exists (
    select 1 from public.group_members m
    where m.group_id = a.group_id and m.user_id = auth.uid()
  ) then
    raise exception 'not a member of the group';
  end if;

  if now() < a.opens_at then
    raise exception 'assignment is not open yet';
  end if;
  if a.due_at is not null and now() > a.due_at then
    raise exception 'assignment is closed';
  end if;

  if not exists (
    select 1 from public.task_versions tv
    where tv.id = a.task_version_id and tv.published_at is not null
  ) then
    raise exception 'task version is not published';
  end if;

  -- Незавершённая попытка не дублируется: студент продолжает её.
  select t.id into new_id
  from public.attempts t
  where t.assignment_id = a.id
    and t.user_id = auth.uid()
    and t.status = 'in_progress'
  limit 1;

  if new_id is not null then
    return new_id;
  end if;

  select count(*) into used
  from public.attempts
  where assignment_id = a.id and user_id = auth.uid();

  if used >= a.max_attempts then
    raise exception 'attempt limit reached';
  end if;

  insert into public.attempts (assignment_id, user_id, task_version_id)
  values (a.id, auth.uid(), a.task_version_id)
  returning id into new_id;

  return new_id;
end;
$$;

-- Сдача работы: создаёт новую неизменяемую ревизию submission.
-- Баллы здесь не принимаются: оценку пишет только администратор/Edge Function.
create or replace function public.submit_attempt(p_attempt uuid, p_answer jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  att       public.attempts;
  a         public.assignments;
  next_rev  int;
  sid       uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if public.app_role() is null then
    raise exception 'profile is not active';
  end if;

  if p_answer is null or jsonb_typeof(p_answer) <> 'object' then
    raise exception 'answer must be a json object';
  end if;
  if pg_column_size(p_answer) > 1048576 then
    raise exception 'answer is too large';
  end if;

  select * into att
  from public.attempts
  where id = p_attempt and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'attempt not found';
  end if;
  if att.status not in ('in_progress', 'returned') then
    raise exception 'attempt is not open';
  end if;

  select * into a from public.assignments where id = att.assignment_id;

  if a.due_at is not null and now() > a.due_at then
    raise exception 'deadline passed';
  end if;
  if not exists (
    select 1 from public.task_versions tv
    where tv.id = att.task_version_id and tv.published_at is not null
  ) then
    raise exception 'task version is not published';
  end if;

  select coalesce(max(s.revision), 0) + 1 into next_rev
  from public.submissions s
  where s.attempt_id = p_attempt;

  insert into public.submissions (attempt_id, revision, answer_json)
  values (p_attempt, next_rev, p_answer)
  returning id into sid;

  update public.attempts
  set status = 'submitted', submitted_at = now()
  where id = p_attempt;

  return sid;
end;
$$;

-- ============================================================================
-- 4. Row Level Security
-- ============================================================================

alter table public.profiles            enable row level security;
alter table public.groups              enable row level security;
alter table public.group_members       enable row level security;
alter table public.courses             enable row level security;
alter table public.course_staff        enable row level security;
alter table public.modules             enable row level security;
alter table public.laboratories        enable row level security;
alter table public.laboratory_versions enable row level security;
alter table public.tasks               enable row level security;
alter table public.task_versions       enable row level security;
alter table public.task_private        enable row level security;
alter table public.assignments         enable row level security;
alter table public.attempts            enable row level security;
alter table public.experiments         enable row level security;
alter table public.submissions         enable row level security;
alter table public.grades              enable row level security;
alter table public.assets              enable row level security;
alter table public.audit_log           enable row level security;

-- ---------- profiles ----------
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_staff());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- ---------- groups / members / course staff ----------
drop policy if exists groups_select on public.groups;
create policy groups_select on public.groups
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1 from public.group_members m
      where m.group_id = groups.id and m.user_id = auth.uid()
    )
  );

drop policy if exists groups_write on public.groups;
create policy groups_write on public.groups
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists gm_select on public.group_members;
create policy gm_select on public.group_members
  for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists gm_write on public.group_members;
create policy gm_write on public.group_members
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists cs_select on public.course_staff;
create policy cs_select on public.course_staff
  for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists cs_write on public.course_staff;
create policy cs_write on public.course_staff
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- content ----------
drop policy if exists courses_select on public.courses;
create policy courses_select on public.courses
  for select to authenticated
  using (status = 'published' or public.is_staff());

drop policy if exists courses_write on public.courses;
create policy courses_write on public.courses
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists modules_select on public.modules;
create policy modules_select on public.modules
  for select to authenticated
  using (
    public.is_staff()
    or (
      status = 'published'
      and exists (
        select 1 from public.courses c
        where c.id = modules.course_id and c.status = 'published'
      )
    )
  );

drop policy if exists modules_write on public.modules;
create policy modules_write on public.modules
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists labs_select on public.laboratories;
create policy labs_select on public.laboratories
  for select to authenticated
  using (status = 'published' or public.is_staff());

drop policy if exists labs_write on public.laboratories;
create policy labs_write on public.laboratories
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists labver_select on public.laboratory_versions;
create policy labver_select on public.laboratory_versions
  for select to authenticated
  using (published_at is not null or public.is_staff());

drop policy if exists labver_write on public.laboratory_versions;
create policy labver_write on public.laboratory_versions
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists tasks_select on public.tasks;
create policy tasks_select on public.tasks
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1 from public.laboratories l
      where l.id = tasks.laboratory_id and l.status = 'published'
    )
  );

drop policy if exists tasks_write on public.tasks;
create policy tasks_write on public.tasks
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists taskver_select on public.task_versions;
create policy taskver_select on public.task_versions
  for select to authenticated
  using (published_at is not null or public.is_staff());

drop policy if exists taskver_write on public.task_versions;
create policy taskver_write on public.task_versions
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- Приватные тесты: политик для студентов нет вообще.
drop policy if exists taskpriv_staff on public.task_private;
create policy taskpriv_staff on public.task_private
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- ---------- assignments ----------
drop policy if exists asg_select on public.assignments;
create policy asg_select on public.assignments
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1 from public.group_members m
      where m.group_id = assignments.group_id and m.user_id = auth.uid()
    )
  );

drop policy if exists asg_write on public.assignments;
create policy asg_write on public.assignments
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- ---------- attempts / experiments / submissions / grades ----------
drop policy if exists att_select on public.attempts;
create policy att_select on public.attempts
  for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

-- INSERT только через start_attempt(); UPDATE статуса — персонал.
-- Отдельной политики INSERT/DELETE нет: студент не может создать попытку в обход функции.
drop policy if exists att_staff_update on public.attempts;
create policy att_staff_update on public.attempts
  for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists exp_select on public.experiments;
create policy exp_select on public.experiments
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1 from public.attempts a
      where a.id = experiments.attempt_id and a.user_id = auth.uid()
    )
  );

drop policy if exists exp_insert on public.experiments;
create policy exp_insert on public.experiments
  for insert to authenticated
  with check (
    exists (
      select 1 from public.attempts a
      where a.id = experiments.attempt_id
        and a.user_id = auth.uid()
        and a.status = 'in_progress'
    )
  );

drop policy if exists sub_select on public.submissions;
create policy sub_select on public.submissions
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1 from public.attempts a
      where a.id = submissions.attempt_id and a.user_id = auth.uid()
    )
  );

-- INSERT только через submit_attempt(); изменения и удаление запрещены всем,
-- кроме service_role, — снимок ответа неизменяем.

drop policy if exists grades_select on public.grades;
create policy grades_select on public.grades
  for select to authenticated
  using (
    public.is_staff()
    or exists (
      select 1
      from public.submissions s
      join public.attempts a on a.id = s.attempt_id
      where s.id = grades.submission_id and a.user_id = auth.uid()
    )
  );

drop policy if exists grades_write on public.grades;
create policy grades_write on public.grades
  for all to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- ---------- assets ----------
drop policy if exists assets_select on public.assets;
create policy assets_select on public.assets
  for select to authenticated
  using (visibility = 'public' or owner_id = auth.uid() or public.is_staff());

drop policy if exists assets_insert on public.assets;
create policy assets_insert on public.assets
  for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists assets_update on public.assets;
create policy assets_update on public.assets
  for update to authenticated
  using (owner_id = auth.uid() or public.is_admin())
  with check (owner_id = auth.uid() or public.is_admin());

drop policy if exists assets_delete on public.assets;
create policy assets_delete on public.assets
  for delete to authenticated
  using (owner_id = auth.uid() or public.is_admin());

-- ---------- audit ----------
-- Журнал только читают администраторы; записи создают доверенные функции/Edge Functions.
drop policy if exists audit_admin on public.audit_log;
create policy audit_admin on public.audit_log
  for select to authenticated
  using (public.is_admin());

-- ============================================================================
-- 5. Права доступа
-- ============================================================================
-- RLS фильтрует строки, но базовые GRANT должны быть выданы явно.
-- anon не получает доступа к учебным данным: работа только после входа.

revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Серверные функции: только авторизованные пользователи.
revoke execute on function public.start_attempt(uuid) from public;
revoke execute on function public.submit_attempt(uuid, jsonb) from public;
grant execute on function public.start_attempt(uuid) to authenticated;
grant execute on function public.submit_attempt(uuid, jsonb) to authenticated;

-- ============================================================================
-- 6. Комментарии к объектам
-- ============================================================================

comment on table public.profiles is 'Профиль пользователя. Роль меняет только администратор, см. trg_protect_profile.';
comment on table public.submissions is 'Неизменяемый снимок ответа; revision растёт при повторной сдаче после возврата.';
comment on table public.task_private is 'Приватные тесты и эталоны. Студентам недоступны, RLS запрещает SELECT.';
comment on table public.audit_log is 'Журнал критичных действий: кто, что и когда изменил.';
comment on function public.start_attempt(uuid) is 'Создаёт попытку после проверки группы, сроков, лимита и публикации версии.';
comment on function public.submit_attempt(uuid, jsonb) is 'Сохраняет новую ревизию ответа и переводит попытку в статус submitted.';
