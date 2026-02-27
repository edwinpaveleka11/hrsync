# 🚀 Panduan Setup Supabase — HRSync

## Langkah 1: Buat Project Supabase

1. Buka [supabase.com](https://supabase.com) → **New Project**
2. Beri nama project (misal: `hrsync`) → pilih region → **Create**
3. Tunggu project selesai dibuat (~1 menit)

---

## Langkah 2: Jalankan Schema SQL

1. Di Supabase Dashboard → **SQL Editor** → **New Query**
2. Salin seluruh isi file `supabase_schema.sql` dari project ini
3. Klik **Run** (▶)
4. Semua tabel, RLS policy, dan trigger akan otomatis terbuat

---

## Langkah 3: Buat Akun Demo via Authentication

1. Di Supabase Dashboard → **Authentication** → **Users** → **Add User**
2. Buat akun HRD:
   - Email: `hrd@example.com`
   - Password: `hrd123`
3. Buat beberapa akun karyawan:
   - `edwin@example.com` / `edwin123`
   - `clare@example.com` / `clare123`
   - dst.

---

## Langkah 4: Update Profil Karyawan di Database

Setelah membuat akun di Auth, jalankan SQL berikut di SQL Editor:

```sql
-- Set role HRD
UPDATE public.employees
SET name        = 'Paveleka',
    role        = 'hrd',
    department  = 'Human Resource',
    position    = 'HR Manager',
    phone       = '081234567890',
    join_date   = '2019-03-01',
    base_salary = 12000000
WHERE email = 'hrd@example.com';

-- Set profil Andi
UPDATE public.employees
SET name        = 'Edwin Pavel',
    department  = 'Engineering',
    position    = 'Senior Developer',
    phone       = '081298765432',
    join_date   = '2021-06-15',
    base_salary = 10000000
WHERE email = 'edwin@example.com';

-- Set profil Sari
UPDATE public.employees
SET name        = 'Clarissa Naila',
    department  = 'Marketing',
    position    = 'Marketing Specialist',
    phone       = '082134567890',
    join_date   = '2022-01-10',
    base_salary = 8000000
WHERE email = 'clare@example.com';
```

---

## Langkah 5: Dapatkan Kredensial API

1. Di Supabase Dashboard → **Project Settings** → **API**
2. Copy:
   - **Project URL** → masukkan ke `supabaseUrl`
   - **anon/public key** → masukkan ke `supabaseAnonKey`

---

## Langkah 6: Konfigurasi Flutter App

Buka file `lib/utils/supabase_config.dart` dan isi:

```dart
class SupabaseConfig {
  static const String supabaseUrl    = 'https://xxxxxxxxxxxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...YOUR_ANON_KEY...';
}
```

---

## Langkah 7: Jalankan App

```bash
flutter pub get
flutter run -d chrome
```

---

## Langkah 8: Generate Gaji (Opsional)

Setelah data karyawan ada, HRD bisa generate slip gaji bulanan dari halaman **Penggajian** → klik tombol **Generate Gaji**.

Atau manual via SQL:

```sql
INSERT INTO public.salaries (employee_id, month, year, base_salary, allowance, bonus, deduction, tax, working_days, present_days)
SELECT id, 2, 2025, base_salary, base_salary*0.15, 0, base_salary*0.02, base_salary*0.05, 22, 20
FROM public.employees WHERE role = 'employee'
ON CONFLICT (employee_id, month, year) DO NOTHING;
```

---

## Struktur Tabel

| Tabel         | Deskripsi                                 |
| ------------- | ----------------------------------------- |
| `employees`   | Data profil karyawan (extends auth.users) |
| `attendances` | Data absensi harian per karyawan          |
| `leaves`      | Pengajuan izin & cuti                     |
| `salaries`    | Data penggajian bulanan                   |

## Keamanan (RLS)

Semua tabel menggunakan **Row Level Security**:

- **HRD** → bisa baca/tulis semua data
- **Karyawan** → hanya bisa baca/tulis data milik sendiri

---

## Build Production

```bash
flutter build web --release --web-renderer canvaskit
# Upload folder build/web/ ke hosting pilihan kamu
```

**Hosting gratis yang cocok:**

- [Vercel](https://vercel.com) — drag & drop folder `build/web`
- [Netlify](https://netlify.com) — sama
- [Firebase Hosting](https://firebase.google.com/docs/hosting) — `firebase deploy`
