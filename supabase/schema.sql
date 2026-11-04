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
  month text not null check (month ~ '^\\d{4}-(0[1-9]|1[0-2])$'),
  name text not null check (length(trim(name)) > 0),
  points_per_task numeric not null default 0 check (points_per_task >= 0),
  staff_id uuid,
  role text check (role is null or role in ('เภสัชกร', 'เจ้าพนักงานเภสัชกรรม', 'พนักงานประจำห้องยา')),
  unit text not null default 'รายการ',
  time numeric not null default 1 check (time >= 0),
  factor numeric not null default 1 check (factor >= 0),
  work numeric not null default 1 check (work >= 0),
  created_at timestamptz not null default now(),
  unique (id, month)
);

-- Null staff_id means an activity shared by everyone; a value scopes it to one staff member.
alter table public.activities add column if not exists staff_id uuid;
alter table public.activities add column if not exists role text;
alter table public.activities add column if not exists unit text not null default 'รายการ';
alter table public.activities add column if not exists time numeric not null default 1;
alter table public.activities add column if not exists factor numeric not null default 1;
alter table public.activities add column if not exists work numeric not null default 1;
-- Preserve legacy points_per_task when upgrading existing categories.
update public.activities set factor = points_per_task where time = 1 and factor = 1 and work = 1 and points_per_task <> 1;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'activities_staff_month_fk'
      and conrelid = 'public.activities'::regclass
  ) then
    alter table public.activities
      add constraint activities_staff_month_fk
      foreign key (staff_id, month)
      references public.staff (id, month) on delete cascade;
  end if;
end $$;
create index if not exists activities_staff_month_idx on public.activities (staff_id, month);

-- Standard activity examples from the supplied reference; no staff roster is seeded.
insert into public.activities (month, name, role, unit, time, factor, work, points_per_task)
select '2026-11', seed.name, seed.role, seed.unit, seed.time, seed.factor, seed.work, seed.time * seed.factor * seed.work
from (values
  ('จ่ายยา ร.10/รพ.สต.','เภสัชกร','รายการ',0.8085::numeric,0.17::numeric,1.25::numeric),
  ('ติดตามดูแลผู้ป่วยฯ (Tele-pharmacy)','เภสัชกร','ราย',4.9::numeric,0.17::numeric,1.5::numeric),
  ('งานเยี่ยมบ้าน (Home Healthcare)','เภสัชกร','ราย',120::numeric,0.17::numeric,2::numeric),
  ('จัดอบรม/ประชุม','เภสัชกร','ครั้ง',120::numeric,0.17::numeric,1.5::numeric),
  ('งานคุ้มครองผู้บริโภค','เภสัชกร','แห่ง',120::numeric,0.17::numeric,2::numeric),
  ('นิเทศงาน รพ.สต.','เภสัชกร','แห่ง',120::numeric,0.17::numeric,2::numeric),
  ('จัดยา OPD ร.10/รพ.สต.','เจ้าพนักงานเภสัชกรรม','รายการ',0.8::numeric,0.12::numeric,1.25::numeric),
  ('ตรวจสอบ Stock card','เจ้าพนักงานเภสัชกรรม','รายการ',2::numeric,0.12::numeric,1.25::numeric),
  ('เบิกยา บันทึก stock card','เจ้าพนักงานเภสัชกรรม','รายการ',3::numeric,0.12::numeric,1.25::numeric),
  ('บันทึกข้อมูลระบบ Health Rider','เจ้าพนักงานเภสัชกรรม','เคส',4::numeric,0.12::numeric,2::numeric),
  ('Pre-pack ยา','เจ้าพนักงานเภสัชกรรม','รายการ',30::numeric,0.12::numeric,1.25::numeric),
  ('จัดยา OPD ร.10/รพ.สต.','พนักงานประจำห้องยา','รายการ',0.8::numeric,0.07::numeric,2::numeric),
  ('เบิกจ่ายยาออกจากคลัง','พนักงานประจำห้องยา','รายการ',3::numeric,0.07::numeric,1::numeric),
  ('จัดเตรียมยาออกจ่าย รพ.สต.','พนักงานประจำห้องยา','ครั้ง',30::numeric,0.07::numeric,2::numeric),
  ('Pre-pack ยา','พนักงานประจำห้องยา','รายการ',30::numeric,0.07::numeric,2::numeric)
) as seed(name, role, unit, time, factor, work)
where not exists (
  select 1 from public.activities existing
  where existing.month = '2026-11'
    and existing.name = seed.name
    and existing.role = seed.role
    and existing.staff_id is null
);

create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  month text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  staff_id uuid not null,
  activity_id uuid not null,
  day smallint not null check (day between 1 and 31),
  check (day <= extract(day from (to_date(month || '-01', 'YYYY-MM-DD') + interval '1 month - 1 day'))),
  count numeric not null check (count >= 0),
  evidence text,
  note text,
  created_at timestamptz not null default now(),
  constraint entries_staff_month_fk foreign key (staff_id, month)
    references public.staff (id, month) on delete cascade,
  constraint entries_activity_month_fk foreign key (activity_id, month)
    references public.activities (id, month) on delete cascade,
  unique (month, staff_id, activity_id, day)
);

alter table public.entries add column if not exists evidence text;
alter table public.entries add column if not exists note text;

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
