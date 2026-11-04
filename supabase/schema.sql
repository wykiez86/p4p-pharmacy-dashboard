-- Run in the Supabase SQL Editor for the project used by this app.
create table if not exists public.app_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.staff (
  id uuid primary key default gen_random_uuid(),
  month text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  name text not null check (length(trim(name)) > 0),
  role text not null check (role in ('เภสัชกร', 'เจ้าพนักงานเภสัชกรรม', 'พนักงานประจำห้องยา')),
  created_at timestamptz not null default now(),
  unique (id, month)
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  month text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  name text not null check (length(trim(name)) > 0),
  points_per_task numeric not null default 0 check (points_per_task >= 0),
  created_at timestamptz not null default now(),
  unique (id, month)
);

create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  month text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  staff_id uuid not null,
  activity_id uuid not null,
  day smallint not null check (day between 1 and 31),
  check (day <= extract(day from (to_date(month || '-01', 'YYYY-MM-DD') + interval '1 month - 1 day')),
  count numeric not null check (count >= 0),
  created_at timestamptz not null default now(),
  constraint entries_staff_month_fk foreign key (staff_id, month)
    references public.staff (id, month) on delete cascade,
  constraint entries_activity_month_fk foreign key (activity_id, month)
    references public.activities (id, month) on delete cascade,
  unique (month, staff_id, activity_id, day)
);

create index if not exists entries_month_idx on public.entries (month);
create index if not exists entries_staff_idx on public.entries (staff_id);
create index if not exists entries_activity_idx on public.entries (activity_id);

alter table public.app_users enable row level security;
alter table public.staff enable row level security;
alter table public.activities enable row level security;
alter table public.entries enable row level security;

revoke all on table public.app_users from anon, authenticated;
revoke all on table public.staff from anon, authenticated;
revoke all on table public.activities from anon, authenticated;
revoke all on table public.entries from anon, authenticated;

grant select on table public.app_users to authenticated;
grant select, insert, update, delete on table public.staff to authenticated;
grant select, insert, update, delete on table public.activities to authenticated;
grant select, insert, update, delete on table public.entries to authenticated;

drop policy if exists p4p_users_select_self on public.app_users;
create policy p4p_users_select_self on public.app_users
for select to authenticated
using (user_id = (select auth.uid()) and active = true);

drop policy if exists p4p_staff_select on public.staff;
create policy p4p_staff_select on public.staff
for select to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_staff_insert on public.staff;
create policy p4p_staff_insert on public.staff
for insert to authenticated with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_staff_update on public.staff;
create policy p4p_staff_update on public.staff
for update to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true))
with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_staff_delete on public.staff;
create policy p4p_staff_delete on public.staff
for delete to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));

drop policy if exists p4p_activities_select on public.activities;
create policy p4p_activities_select on public.activities
for select to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_activities_insert on public.activities;
create policy p4p_activities_insert on public.activities
for insert to authenticated with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_activities_update on public.activities;
create policy p4p_activities_update on public.activities
for update to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true))
with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_activities_delete on public.activities;
create policy p4p_activities_delete on public.activities
for delete to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));

drop policy if exists p4p_entries_select on public.entries;
create policy p4p_entries_select on public.entries
for select to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_entries_insert on public.entries;
create policy p4p_entries_insert on public.entries
for insert to authenticated with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_entries_update on public.entries;
create policy p4p_entries_update on public.entries
for update to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true))
with check (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
drop policy if exists p4p_entries_delete on public.entries;
create policy p4p_entries_delete on public.entries
for delete to authenticated using (exists (select 1 from public.app_users as member where member.user_id = (select auth.uid()) and member.active = true));
