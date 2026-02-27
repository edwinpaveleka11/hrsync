-- Jalankan ini di Supabase SQL Editor setelah membuat akun di Authentication
-- Sesuaikan email dengan akun yang sudah kamu buat

-- Set HRD
UPDATE public.employees
SET name        = 'Admin HRD',
    role        = 'hrd',
    department  = 'Human Resource',
    position    = 'HR Manager',
    phone       = '081234567890',
    join_date   = '2022-01-01',
    base_salary = 12000000
WHERE email = 'hrd@example.com';

-- Set Edwin (karyawan)
UPDATE public.employees
SET name        = 'Edwin',
    role        = 'employee',
    department  = 'Engineering',
    position    = 'Software Developer',
    phone       = '081298765432',
    join_date   = '2023-03-15',
    base_salary = 9000000
WHERE email = 'edwin@example.com';

-- Set Clare (karyawan)
UPDATE public.employees
SET name        = 'Clare',
    role        = 'employee',
    department  = 'Design',
    position    = 'UI/UX Designer',
    phone       = '082134567890',
    join_date   = '2023-06-01',
    base_salary = 8500000
WHERE email = 'clare@example.com';

-- Cek hasilnya
SELECT id, name, email, role, department, position, base_salary FROM public.employees;
