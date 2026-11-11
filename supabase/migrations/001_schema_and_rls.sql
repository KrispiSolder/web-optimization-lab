-- Web Optimization Lab: базовая схема и RLS (стартовый вариант по ТЗ, разделы 9-10)
-- Применять через Supabase CLI (supabase db push) или SQL Editor.

create extension if not exists pgcrypto;

-- ---------- Таблицы ----------
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null default '',
  role text not null default 'student' check (role in ('student','teacher','admin')),
  status text not null default 'active' check (status in ('active','blocked','archived')),
  created_at timestamptz not null default now()
);
create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null, academic_year text, owner_id uuid references profiles(id)
);
create table group_members (
  group_id uuid references groups on delete cascade,
  user_id uuid references profiles on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);
create table courses (
  id uuid primary key default gen_random_uuid(),
  title text not null, code text, description text,
  status text not null default 'draft' check (status in ('draft','published','archived'))
);
create table course_staff (
  course_id uuid references courses on delete cascade,
  user_id uuid references profiles on delete cascade,
  role text not null default 'teacher',
  primary key (course_id, user_id)
);
create table modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses on delete cascade,
  title text not null, sort_order int not null default 0,
  status text not null default 'draft' check (status in ('draft','published','archived'))
);
create table laboratories (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references modules on delete cascade,
  type text not null check (type in ('parameter-simulator','code-lab','case-practicum')),
  template_key text not null, title text not null,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  current_version_id uuid
);
create table laboratory_versions (
  id uuid primary key default gen_random_uuid(),
  laboratory_id uuid not null references laboratories on delete cascade,
  version int not null, schema_version int not null default 1,
  config_json jsonb not null, created_by uuid references profiles,
  published_at timestamptz,
  unique (laboratory_id, version)
);
create table tasks (
  id uuid primary key default gen_random_uuid(),
  laboratory_id uuid not null references laboratories on delete cascade
);
create table task_versions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks on delete cascade,
  version int not null, statement text not null,
  rubric_json jsonb not null default '{}', max_score numeric not null default 10,
  published_at timestamptz,
  unique (task_id, version)
);
-- Приватные тесты и эталоны хранятся отдельно и недоступны клиенту
create table task_private (
  task_version_id uuid primary key references task_versions on delete cascade,
  tests_json jsonb not null default '{}'
);
create table assignments (
  id uuid primary key default gen_random_uuid(),
  task_version_id uuid not null references task_versions,
  group_id uuid not null references groups,
  opens_at timestamptz not null default now(), due_at timestamptz,
  max_attempts int not null default 3,
  status text not null default 'active' check (status in ('active','archived'))
);
create table attempts (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references assignments,
  user_id uuid not null references profiles,
  task_version_id uuid not null references task_versions,
  status text not null default 'in_progress'
    check (status in ('in_progress','submitted','graded','returned','closed')),
  started_at timestamptz not null default now(), submitted_at timestamptz
);
create table experiments (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references attempts on delete cascade,
  sequence int not null, input_json jsonb not null, output_json jsonb not null,
  metric_source text not null check (metric_source in ('measured','modelled')),
  engine_version text, created_at timestamptz not null default now()
);
create table submissions (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null unique references attempts,
  answer_json jsonb not null, report_ref text,
  submitted_at timestamptz not null default now()
);
create table grades (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references submissions,
  auto_score numeric not null default 0, teacher_score numeric,
  total_score numeric generated always as (auto_score + coalesce(teacher_score,0)) stored,
  feedback text, graded_by uuid references profiles
);
create table audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid, event text not null, entity_type text, entity_id uuid,
  at timestamptz not null default now(), detail_json jsonb
);

-- ---------- Вспомогательные функции ----------
create function app_role() returns text language sql stable security definer set search_path = public as
$$ select role from profiles where id = auth.uid() and status = 'active' $$;
create function is_admin() returns boolean language sql stable as $$ select app_role() = 'admin' $$;
create function is_staff() returns boolean language sql stable as $$ select app_role() in ('teacher','admin') $$;

-- Автосоздание профиля: ВСЕГДА student, роль из метаданных клиента игнорируется
create function handle_new_user() returns trigger language plpgsql security definer set search_path = public as
$$ begin
  insert into profiles (id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- Запрет самостоятельной смены role/status (кроме администратора и service_role)
create function protect_profile() returns trigger language plpgsql as
$$ begin
  if (new.role is distinct from old.role or new.status is distinct from old.status)
     and not (coalesce(is_admin(), false) or auth.role() = 'service_role') then
    raise exception 'role/status can be changed by admin only';
  end if;
  return new;
end $$;
create trigger trg_protect_profile before update on profiles
  for each row execute function protect_profile();

-- Старт попытки: проверка группы, сроков и лимита попыток на сервере
create function start_attempt(p_assignment uuid) returns uuid
language plpgsql security definer set search_path = public as
$$ declare a assignments; n int; new_id uuid; begin
  select * into a from assignments where id = p_assignment and status = 'active';
  if not found then raise exception 'assignment not found'; end if;
  if not exists (select 1 from group_members where group_id = a.group_id and user_id = auth.uid())
    then raise exception 'not a member of the group'; end if;
  if now() < a.opens_at or (a.due_at is not null and now() > a.due_at)
    then raise exception 'assignment is closed'; end if;
  select count(*) into n from attempts where assignment_id = a.id and user_id = auth.uid();
  if n >= a.max_attempts then raise exception 'attempt limit reached'; end if;
  insert into attempts (assignment_id, user_id, task_version_id)
    values (a.id, auth.uid(), a.task_version_id) returning id into new_id;
  return new_id;
end $$;

-- Сдача: неизменяемый снимок; баллы студент записать не может
create function submit_attempt(p_attempt uuid, p_answer jsonb) returns uuid
language plpgsql security definer set search_path = public as
$$ declare sid uuid; begin
  update attempts set status = 'submitted', submitted_at = now()
    where id = p_attempt and user_id = auth.uid() and status in ('in_progress','returned');
  if not found then raise exception 'attempt is not open'; end if;
  insert into submissions (attempt_id, answer_json) values (p_attempt, p_answer)
    on conflict (attempt_id) do update set answer_json = excluded.answer_json, submitted_at = now()
    returning id into sid;
  return sid;
end $$;

-- ---------- RLS: включить везде, политики по ролям ----------
do $$ declare t text; begin
  foreach t in array array['profiles','groups','group_members','courses','course_staff','modules',
    'laboratories','laboratory_versions','tasks','task_versions','task_private','assignments',
    'attempts','experiments','submissions','grades','audit_log'] loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- profiles: свой профиль; преподаватель/админ видят всех; менять можно свой (роль защищена триггером)
create policy profiles_select on profiles for select using (id = auth.uid() or is_staff());
create policy profiles_update on profiles for update using (id = auth.uid() or is_admin());

-- Контент: студенты видят только опубликованное, персонал управляет
create policy courses_select on courses for select using (status = 'published' or is_staff());
create policy courses_write  on courses for all using (is_staff()) with check (is_staff());
create policy modules_select on modules for select using (status = 'published' or is_staff());
create policy modules_write  on modules for all using (is_staff()) with check (is_staff());
create policy labs_select on laboratories for select using (status = 'published' or is_staff());
create policy labs_write  on laboratories for all using (is_staff()) with check (is_staff());
create policy labver_select on laboratory_versions for select
  using (published_at is not null or is_staff());
create policy labver_write on laboratory_versions for all using (is_staff()) with check (is_staff());
create policy tasks_select on tasks for select using (true);
create policy tasks_write  on tasks for all using (is_staff()) with check (is_staff());
create policy taskver_select on task_versions for select
  using (published_at is not null or is_staff());
create policy taskver_write on task_versions for all using (is_staff()) with check (is_staff());
-- task_private: политик для студентов нет, только персонал
create policy taskpriv_staff on task_private for all using (is_staff()) with check (is_staff());

-- Группы и назначения
create policy groups_select on groups for select
  using (is_staff() or exists (select 1 from group_members m where m.group_id = id and m.user_id = auth.uid()));
create policy groups_write on groups for all using (is_staff()) with check (is_staff());
create policy gm_select on group_members for select using (user_id = auth.uid() or is_staff());
create policy gm_write  on group_members for all using (is_admin()) with check (is_admin());
create policy cs_select on course_staff for select using (user_id = auth.uid() or is_staff());
create policy cs_write  on course_staff for all using (is_admin()) with check (is_admin());
create policy asg_select on assignments for select
  using (is_staff() or exists (select 1 from group_members m where m.group_id = assignments.group_id and m.user_id = auth.uid()));
create policy asg_write on assignments for all using (is_staff()) with check (is_staff());

-- Попытки: создаются только через start_attempt(), прямой INSERT/UPDATE студенту запрещён
create policy att_select on attempts for select using (user_id = auth.uid() or is_staff());
create policy att_staff_update on attempts for update using (is_staff());
create policy exp_select on experiments for select
  using (exists (select 1 from attempts a where a.id = attempt_id and (a.user_id = auth.uid() or is_staff())));
create policy exp_insert on experiments for insert
  with check (exists (select 1 from attempts a where a.id = attempt_id and a.user_id = auth.uid() and a.status = 'in_progress'));
create policy sub_select on submissions for select
  using (exists (select 1 from attempts a where a.id = attempt_id and (a.user_id = auth.uid() or is_staff())));
-- Оценки: студент только читает свои; пишет персонал
create policy grades_select on grades for select
  using (is_staff() or exists (select 1 from submissions s join attempts a on a.id = s.attempt_id
         where s.id = submission_id and a.user_id = auth.uid()));
create policy grades_write on grades for all using (is_staff()) with check (is_staff());
create policy audit_admin on audit_log for select using (is_admin());
