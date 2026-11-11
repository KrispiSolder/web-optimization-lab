-- Web Optimization Lab / Шаг 1: профили и роли
-- Выполнить в Supabase SQL Editor. Не изменяйте таблицу auth.users вручную.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'student' check (role in ('student','teacher','admin')),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
-- Вызов может быть повторён: drop policy + create policy
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT TO authenticated USING (id = (select auth.uid()));
-- В этом этапе клиенты не могут изменять профили и роли через Data API.
REVOKE ALL ON public.profiles FROM anon, authenticated;
GRANT SELECT ON public.profiles TO authenticated;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, left(coalesce(new.raw_user_meta_data->>'full_name', ''), 200), 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;
DROP TRIGGER IF EXISTS on_auth_user_created_wol ON auth.users;
CREATE TRIGGER on_auth_user_created_wol
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.create_profile_for_new_user();
-- Дополнительная защита: роль меняет только владелец БД через SQL Editor / будущую доверенную Edge Function.
