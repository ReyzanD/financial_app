# Financial App

Aplikasi keuangan lengkap yang dibangun dengan Flutter untuk frontend dan Python Flask untuk backend. Aplikasi ini menyediakan fitur manajemen keuangan pribadi termasuk tracking transaksi, budgeting, goals, dan analisis keuangan.

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

### Backend
- **Python Flask** - Web framework
- **SQLite** - Database (local file, no internet required)
- **JWT** - Authentication
- **RESTful API** - API architecture

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Python 3.8+
- Git

**Note**: This branch uses SQLite (local file database) - no PostgreSQL or cloud database required.

### Installation

1. Clone repository ini:
```bash
git clone <repository-url>
cd financial_app
```

2. Install dependencies Flutter:
```bash
flutter pub get
```

3. Setup backend:
```bash
cd backend
pip install -r requirements.txt
```

4. Konfigurasi environment variables:
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env dan set JWT_SECRET_KEY (generate dengan: openssl rand -hex 32)
   ```

5. Jalankan aplikasi:
```bash
# Backend
cd backend
python app.py

# Frontend (terminal baru)
flutter run
```

## Dokumentasi

- [Local Setup Guide](docs/LOCAL_SETUP.md) - **Panduan setup lokal dengan SQLite (Recommended untuk branch ini)**
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Panduan deployment ke cloud (Render/Supabase) - Optional
- [Obfuscation Guide](docs/OBFUSCATION_GUIDE.md) - Panduan melindungi kode dengan obfuscation
- [Security Guidelines](SECURITY.md) - Panduan keamanan dan best practices

## Quick Start (Local SQLite)

Untuk setup cepat dengan SQLite lokal:

1. **Backend**:
   ```bash
   cd backend
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env dan set JWT_SECRET_KEY
   python app.py
   ```

2. **Flutter**:
   ```bash
   flutter pub get
   flutter run
   ```

Database akan dibuat otomatis saat pertama kali menjalankan backend. Lihat [Local Setup Guide](docs/LOCAL_SETUP.md) untuk detail lengkap.

## Contributing

Repository ini adalah proyek proprietary. Kontribusi eksternal tidak diterima tanpa izin tertulis dari pemilik.

## Support

Untuk pertanyaan atau dukungan, silakan buat issue di repository ini atau hubungi pemilik repository.

## Disclaimer

Software ini disediakan "sebagaimana adanya" tanpa jaminan apapun. Penggunaan software ini adalah tanggung jawab pengguna sendiri.
