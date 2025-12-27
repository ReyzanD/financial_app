# Financial App

Aplikasi keuangan lengkap yang dibangun dengan Flutter. Aplikasi ini menyediakan fitur manajemen keuangan pribadi termasuk tracking transaksi, budgeting, goals, dan analisis keuangan. **Aplikasi ini berjalan fully standalone tanpa perlu backend server - semua data tersimpan lokal di device.**

## ⚠️ Copyright & License

**Copyright (c) 2024 Financial App. All Rights Reserved.**

Kode sumber ini adalah proprietary dan dilindungi oleh hak cipta. Penggunaan, modifikasi, distribusi, atau penjualan kode ini tanpa izin tertulis dari pemilik adalah dilarang.

**Peringatan Penting:**
- Kode ini dipublikasikan untuk tujuan referensi dan pembelajaran semata
- Anda TIDAK diperbolehkan menggunakan kode ini untuk tujuan komersial atau produksi tanpa izin
- Forking untuk tujuan pembelajaran diperbolehkan, namun penggunaan dalam proyek komersial memerlukan izin tertulis

**Untuk pertanyaan lisensi atau penggunaan komersial, silakan hubungi pemilik repository.**

Lihat file [LICENSE](LICENSE) untuk informasi lengkap tentang hak cipta dan batasan penggunaan.

## Fitur Utama

- 💰 Manajemen Transaksi (Pemasukan & Pengeluaran)
- 📊 Budgeting & Tracking
- 🎯 Financial Goals
- 📈 Analisis & Laporan Keuangan
- 🔐 Autentikasi & Keamanan
- 📱 Multi-platform (Android, iOS, Web)
- 🌍 Multi-language Support (Indonesia & English)

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Flutter Secure Storage** - Secure data storage

### Database
- **SQLite** - Local database (stored on device, no internet required)
- **sqflite** - Flutter SQLite plugin

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Git

**Note**: Aplikasi ini berjalan fully standalone - tidak perlu Python, backend server, atau database cloud. Semua data tersimpan lokal di device.

### Installation

1. Clone repository ini:
```bash
git clone <repository-url>
cd financial_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Jalankan aplikasi:
```bash
flutter run
```

**Tidak perlu setup backend!** Aplikasi akan membuat database lokal otomatis saat pertama kali dibuka.

## Dokumentasi

- [Local Setup Guide](docs/LOCAL_SETUP.md) - **Panduan setup lokal dengan SQLite (Recommended untuk branch ini)**
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Panduan deployment ke cloud (Render/Supabase) - Optional
- [Obfuscation Guide](docs/OBFUSCATION_GUIDE.md) - Panduan melindungi kode dengan obfuscation
- [Security Guidelines](SECURITY.md) - Panduan keamanan dan best practices

## Quick Start

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run aplikasi**:
   ```bash
   flutter run
   ```

3. **Build APK untuk distribusi**:
   ```bash
   flutter build apk --release
   ```

Database akan dibuat otomatis saat pertama kali aplikasi dibuka. Tidak perlu setup backend atau konfigurasi apapun!

## Contributing

Repository ini adalah proyek proprietary. Kontribusi eksternal tidak diterima tanpa izin tertulis dari pemilik.

## Support

Untuk pertanyaan atau dukungan, silakan buat issue di repository ini atau hubungi pemilik repository.

## Disclaimer

Software ini disediakan "sebagaimana adanya" tanpa jaminan apapun. Penggunaan software ini adalah tanggung jawab pengguna sendiri.
