-- ============================================================
-- HRSync — Supabase Database Schema
-- Jalankan file ini di Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste → Run
-- ============================================================

-- ============================================================
-- 1. EXTENSIONS
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- 2. TABEL EMPLOYEES (profil karyawan, extends auth.users)
-- ============================================================
create table public.employees (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null,
  email       text not null unique,
  role        text not null check (role in ('hrd', 'employee')) default 'employee',
  department  text not null default '',
  position    text not null default '',
  phone       text not null default '',
  join_date   date not null default current_date,
  base_salary numeric(15,2) not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 3. TABEL ATTENDANCES
-- ============================================================
create table public.attendances (
  id            uuid primary key default uuid_generate_v4(),
  employee_id   uuid not null references public.employees(id) on delete cascade,
  date          date not null,
  check_in      time,
  check_out     time,
  status        text not null check (status in ('present','absent','late','leave','holiday')),
  notes         text,
  created_at    timestamptz not null default now(),
  unique (employee_id, date)
);

-- ============================================================
-- 4. TABEL LEAVES (izin & cuti)
-- ============================================================
create table public.leaves (
  id            uuid primary key default uuid_generate_v4(),
  employee_id   uuid not null references public.employees(id) on delete cascade,
  type          text not null check (type in ('annual','sick','personal','maternity','paternity','unpaid')),
  start_date    date not null,
  end_date      date not null,
  reason        text not null,
  status        text not null check (status in ('pending','approved','rejected')) default 'pending',
  approved_by   uuid references public.employees(id),
  submitted_at  timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ============================================================
-- 5. TABEL SALARIES
-- ============================================================
create table public.salaries (
  id              uuid primary key default uuid_generate_v4(),
  employee_id     uuid not null references public.employees(id) on delete cascade,
  month           int not null check (month between 1 and 12),
  year            int not null,
  base_salary     numeric(15,2) not null default 0,
  allowance       numeric(15,2) not null default 0,
  bonus           numeric(15,2) not null default 0,
  deduction       numeric(15,2) not null default 0,
  tax             numeric(15,2) not null default 0,
  status          text not null check (status in ('pending','processed','paid')) default 'pending',
  paid_date       date,
  working_days    int not null default 22,
  present_days    int not null default 0,
  created_at      timestamptz not null default now(),
  unique (employee_id, month, year)
);

-- ============================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================================
alter table public.employees  enable row level security;
alter table public.attendances enable row level security;
alter table public.leaves      enable row level security;
alter table public.salaries    enable row level security;

-- Helper function: cek apakah user adalah HRD
create or replace function public.is_hrd()
returns boolean language sql security definer as $$
  select exists (
    select 1 from public.employees
    where id = auth.uid() and role = 'hrd'
  );
$$;

-- ----- EMPLOYEES -----
-- HRD: bisa lihat semua
create policy "HRD can view all employees"
  on public.employees for select
  using (public.is_hrd());

-- Karyawan: hanya lihat data sendiri
create policy "Employee can view own profile"
  on public.employees for select
  using (id = auth.uid());

-- HRD: bisa insert (tambah karyawan)
create policy "HRD can insert employees"
  on public.employees for insert
  with check (public.is_hrd());

-- HRD: bisa update semua
create policy "HRD can update employees"
  on public.employees for update
  using (public.is_hrd());

-- ----- ATTENDANCES -----
-- HRD: bisa lihat semua absensi
create policy "HRD can view all attendances"
  on public.attendances for select
  using (public.is_hrd());

-- Karyawan: hanya lihat absensi sendiri
create policy "Employee can view own attendance"
  on public.attendances for select
  using (employee_id = auth.uid());

-- Karyawan: bisa insert absensi sendiri
create policy "Employee can insert own attendance"
  on public.attendances for insert
  with check (employee_id = auth.uid());

-- HRD: bisa insert semua absensi
create policy "HRD can insert all attendances"
  on public.attendances for insert
  with check (public.is_hrd());

-- HRD: bisa update absensi
create policy "HRD can update attendances"
  on public.attendances for update
  using (public.is_hrd());

-- ----- LEAVES -----
-- HRD: bisa lihat semua cuti
create policy "HRD can view all leaves"
  on public.leaves for select
  using (public.is_hrd());

-- Karyawan: hanya lihat cuti sendiri
create policy "Employee can view own leaves"
  on public.leaves for select
  using (employee_id = auth.uid());

-- Karyawan: bisa ajukan cuti sendiri
create policy "Employee can submit own leave"
  on public.leaves for insert
  with check (employee_id = auth.uid());

-- HRD: bisa update (approve/reject) semua cuti
create policy "HRD can update leave status"
  on public.leaves for update
  using (public.is_hrd());

-- ----- SALARIES -----
-- HRD: bisa lihat semua gaji
create policy "HRD can view all salaries"
  on public.salaries for select
  using (public.is_hrd());

-- Karyawan: hanya lihat gaji sendiri
create policy "Employee can view own salary"
  on public.salaries for select
  using (employee_id = auth.uid());

-- HRD: bisa insert dan update gaji
create policy "HRD can manage salaries"
  on public.salaries for insert
  with check (public.is_hrd());

create policy "HRD can update salaries"
  on public.salaries for update
  using (public.is_hrd());

-- ============================================================
-- 7. TRIGGER: auto-update updated_at pada leaves
-- ============================================================
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger leaves_updated_at
  before update on public.leaves
  for each row execute procedure public.handle_updated_at();

-- ============================================================
-- 8. TRIGGER: auto-create employee profile saat signup
-- ============================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.employees (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'employee')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 9. SEED DATA DEMO
-- ============================================================
-- Catatan: Buat akun HRD & karyawan dulu via Supabase Auth
-- (Authentication → Users → Add User), lalu jalankan bagian ini
-- dengan mengganti UUID yang sesuai dari tabel auth.users

-- Contoh update profil setelah user dibuat via Auth:
-- UPDATE public.employees
-- SET name='Budi Santoso', role='hrd', department='Human Resource',
--     position='HR Manager', phone='081234567890',
--     join_date='2019-03-01', base_salary=12000000
-- WHERE email='hrd@hrms.com';

-- UPDATE public.employees
-- SET name='Andi Wijaya', role='employee', department='Engineering',
--     position='Senior Developer', phone='081298765432',
--     join_date='2021-06-15', base_salary=10000000
-- WHERE email='andi@hrms.com';

-- ============================================================
-- SELESAI! Schema siap digunakan.
-- ============================================================
