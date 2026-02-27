# 🏢 HRSync — HR Management System

> Sistem manajemen SDM terintegrasi berbasis Flutter Web dengan fitur absensi digital, penggajian otomatis, dan manajemen izin & cuti.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart)
![Platform](https://img.shields.io/badge/Platform-Web-764ABC?style=for-the-badge)

---

## ✨ Fitur Utama

### 👔 Panel HRD
- **Dashboard Analitik** — Grafik tren kehadiran, statistik real-time, pie chart status cuti
- **Manajemen Karyawan** — CRUD data karyawan, filter departemen, pencarian
- **Monitoring Absensi** — Pantau absensi semua karyawan by date, rekap bulanan per karyawan
- **Approval Cuti** — Setujui/tolak pengajuan cuti langsung dari dashboard
- **Penggajian** — Proses dan bayar gaji dengan kalkulasi otomatis (tunjangan, bonus, potongan, pajak)

### 👤 Portal Karyawan
- **Dashboard Personal** — Tombol check-in, statistik absensi pribadi, status cuti
- **Absensi Digital** — Check-in dengan deteksi keterlambatan otomatis, riwayat lengkap
- **Pengajuan Cuti** — Form cuti dengan date picker, pantau kuota & status approval
- **Slip Gaji** — Lihat detail komponen gaji, riwayat penggajian bulanan

---

## 🎨 Tech Stack & Desain

| Aspek | Detail |
|-------|--------|
| Framework | Flutter 3.x (Web) |
| State Management | Provider |
| Navigation | GoRouter (deep linking) |
| Charts | fl_chart |
| Typography | DM Sans + Google Fonts |
| Color System | Purple-Blue gradient + Coral accent |
| UI Style | Modern Colorful, Glass morphism cards |

---

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK 3.0+ ([flutter.dev](https://flutter.dev))
- Chrome / Edge browser

### Install & Run

```bash
# Clone project
git clone https://github.com/username/hr_management.git
cd hr_management

# Install dependencies
flutter pub get

# Jalankan di web (Chrome)
flutter run -d chrome

# Build untuk production
flutter build web --release
```

### Deploy ke Hosting
```bash
# Build production
flutter build web

# Output ada di: build/web/
# Upload ke: Vercel, Netlify, Firebase Hosting, dll.
```

---

## 🔐 Demo Akun

| Role | Email | Password |
|------|-------|----------|
| HRD Manager | hrd@example.com | hrd123 |
| Karyawan | edwin@example.com | edwin123 |
| Karyawan | clare@example.com | clare123 |

---

## 📁 Struktur Project

```
lib/
├── main.dart                    # Entry point
├── theme/
│   └── app_theme.dart           # Warna, typography, theme
├── models/
│   └── models.dart              # UserModel, Attendance, Leave, Salary
├── services/
│   └── data_service.dart        # State management & business logic
├── utils/
│   └── router.dart              # GoRouter navigation + auth guard
├── widgets/
│   └── shared_widgets.dart      # StatCard, StatusBadge, AvatarWidget, dll.
└── screens/
    ├── auth/
    │   └── login_screen.dart    # Login dengan demo account selector
    ├── hrd/
    │   ├── hrd_shell.dart       # Sidebar HRD + layout
    │   ├── hrd_dashboard.dart   # Dashboard dengan charts
    │   ├── employee_list_screen.dart
    │   ├── hrd_attendance_screen.dart
    │   ├── hrd_leave_screen.dart
    │   └── hrd_salary_screen.dart
    └── employee/
        ├── employee_shell.dart  # Sidebar karyawan + layout
        ├── employee_dashboard.dart
        ├── employee_attendance_screen.dart
        └── (leave & salary screens)
```

---

## 📸 Highlight UI

- **Login Page** — Split layout, demo account chips, animated form
- **HRD Dashboard** — Bar chart kehadiran, pie chart cuti, quick approval
- **Absensi** — Table interaktif by date, progress bar per karyawan
- **Penggajian** — Tabel dengan semua komponen gaji, tombol bayar
- **Employee Dashboard** — Check-in button, welcome card gradient
- **Slip Gaji** — Kartu gaji gradient purple-pink, breakdown komponen

---

## 🛠️ Pengembangan Lanjutan

Fitur yang bisa ditambahkan untuk production:
- [ ] Backend API (Laravel/Django/Node.js)
- [ ] Autentikasi JWT
- [ ] Export laporan ke PDF/Excel
- [ ] Notifikasi push
- [ ] GPS check-in (mobile)
- [ ] Payroll slip PDF generator
- [ ] Multi-company support

---

## 👨‍💻 Dibuat Untuk Portofolio

Project ini menampilkan kemampuan:
- Flutter Web development
- Role-based access control (RBAC)
- State management dengan Provider
- Complex UI dengan charts dan animations
- Responsive design (desktop + mobile)
- Clean architecture dengan separation of concerns

---

*Dibuat dengan ❤️ menggunakan Flutter*
