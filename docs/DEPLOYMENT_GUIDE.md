# Deployment Guide (Legacy - PostgreSQL/Render)

**NOTE: This guide is for reference only. This branch uses SQLite for fully local operation.**

For local SQLite setup, see [Local Setup Guide](LOCAL_SETUP.md).

---

# Legacy Deployment Guide: Render + Supabase

Panduan lengkap untuk deploy backend Flask ke Render dan setup database PostgreSQL di Supabase.
**This is kept for reference but not used in the current SQLite-only branch.**

## Daftar Isi

1. [Prerequisites](#prerequisites)
2. [Setup Supabase Database](#setup-supabase-database)
3. [Setup Render Backend](#setup-render-backend)
4. [Configure Environment Variables](#configure-environment-variables)
5. [Update Flutter App](#update-flutter-app)
6. [Testing Deployment](#testing-deployment)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Sebelum memulai, pastikan Anda memiliki:

- ✅ Akun GitHub (untuk connect repository ke Render)
- ✅ Repository code sudah di-push ke GitHub
- ✅ Email untuk daftar Supabase dan Render (gratis)

---

## Setup Supabase Database

### Step 1: Daftar Supabase

1. Buka [supabase.com](https://supabase.com)
2. Klik **Start your project** atau **Sign Up**
3. Pilih **Continue with GitHub** (recommended) atau email
4. Verifikasi email jika diperlukan

### Step 2: Create New Project

1. Setelah login, klik **New Project**
2. Isi form:
   - **Name**: `financial-app` (atau nama lain)
   - **Database Password**: Buat password yang kuat (simpan dengan aman!)
   - **Region**: Pilih yang terdekat (misalnya `Southeast Asia (Singapore)`)
   - **Pricing Plan**: Pilih **Free** (gratis selamanya)
3. Klik **Create new project**
4. Tunggu beberapa menit untuk project setup (biasanya 1-2 menit)

### Step 3: Get Connection String

1. Setelah project siap, klik **Project Settings** (icon gear di sidebar kiri)
2. Klik **Database** di menu settings
3. Scroll ke bagian **Connection string**
4. Pilih tab **URI**
5. **Copy connection string** yang terlihat seperti:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
   ```

**⚠️ PENTING**:

- Ganti `[YOUR-PASSWORD]` dengan password yang Anda buat di Step 2
- Simpan connection string dengan aman! Ini akan digunakan untuk environment variable `DATABASE_URL`

**Alternatif**: Jika ingin menggunakan individual parameters:

- **Host**: `db.xxxxx.supabase.co`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: (password yang Anda buat)
- **Port**: `5432`

### Step 4: Setup Database Schema

1. Di Supabase dashboard, klik **SQL Editor** di sidebar kiri
2. Klik **New query**
3. Copy dan paste isi file `backend/financial_db_232143_postgresql.sql`
4. Klik **Run** atau tekan `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)
5. Tunggu hingga semua tables, indexes, dan constraints dibuat

**Catatan**:

- Script akan otomatis enable UUID extension
- Semua tables akan dibuat dengan schema yang sudah dikonversi dari MySQL ke PostgreSQL
- Jika ada error, cek apakah extension sudah enabled: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

---

## Setup Render Backend

### Step 1: Daftar Render

1. Buka [render.com](https://render.com)
2. Klik **Get Started for Free**
3. Pilih **Continue with GitHub** (recommended)
4. Authorize Render untuk akses GitHub repository

### Step 2: Create New Web Service

1. Di dashboard Render, klik **New +**
2. Pilih **Web Service**
3. Klik **Connect account** jika belum connect GitHub
4. Pilih repository yang berisi folder `backend/`
5. Klik **Connect**

### Step 3: Configure Web Service

Isi form dengan konfigurasi berikut:

**Basic Settings:**

- **Name**: `financial-app-backend` (atau nama lain)
- **Region**: Pilih yang terdekat (misalnya `Singapore`)
- **Branch**: `main` (atau branch yang digunakan)
- **Root Directory**: `backend` (penting! karena code ada di folder backend)
- **Runtime**: `Python 3`
- **Build Command**: `pip install --upgrade pip setuptools wheel && pip install -r requirements.txt`
- **Start Command**: `gunicorn app:create_app\(\) --bind 0.0.0.0:$PORT --workers 2 --timeout 120`

**⚠️ CATATAN**:

- Root Directory harus `backend` karena struktur project Anda
- Start Command menggunakan `create_app()` karena Flask app menggunakan factory pattern
- `$PORT` akan otomatis disediakan oleh Render

### Step 4: Add Environment Variables

Scroll ke bagian **Environment Variables** dan tambahkan:

**Option 1: Using Connection String (Recommended)**

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.xxxxx.supabase.co:5432/postgres
JWT_SECRET_KEY=<generate-strong-random-secret>
DEBUG=False
PORT=10000
```

**Option 2: Using Individual Parameters**

```
POSTGRES_HOST=db.xxxxx.supabase.co
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_PASSWORD
POSTGRES_DB=postgres
POSTGRES_PORT=5432
JWT_SECRET_KEY=<generate-strong-random-secret>
DEBUG=False
PORT=10000
```

**Cara generate JWT_SECRET_KEY:**

```bash
# Di terminal (Mac/Linux)
openssl rand -hex 32

# Atau di Python
python -c "import secrets; print(secrets.token_hex(32))"
```

**Contoh nilai (Option 1 - Recommended):**

```
DATABASE_URL=postgresql://postgres:MySecurePassword123@db.abcdefghijklmnop.supabase.co:5432/postgres
JWT_SECRET_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
DEBUG=False
PORT=10000
```

**⚠️ CATATAN**:

- Ganti `YOUR_PASSWORD` dengan password Supabase yang Anda buat
- Ganti `xxxxx` dengan project ID Supabase Anda
- Connection string format: `postgresql://user:password@host:port/database`

### Step 5: Deploy

1. Klik **Create Web Service**
2. Render akan mulai build dan deploy
3. Tunggu beberapa menit (biasanya 3-5 menit)
4. Setelah selesai, Anda akan mendapat URL seperti: `https://financial-app-backend.onrender.com`

**⚠️ CATATAN**:

- Free tier akan sleep setelah 15 menit idle
- Request pertama setelah sleep mungkin lambat (cold start ~30 detik)
- Untuk production, pertimbangkan upgrade ke paid plan

### Step 6: Test Health Check

1. Buka URL Render di browser: `https://your-app.onrender.com/`
2. Seharusnya muncul JSON:

```json
{
  "status": "healthy",
  "message": "Finance Manager API is running",
  "version": "1.0.0"
}
```

Jika muncul error, cek **Logs** di dashboard Render untuk troubleshooting.

---

## Configure Environment Variables

### Environment Variables Summary

Berikut adalah semua environment variables yang diperlukan:

**Option 1: Using Connection String (Recommended)**

| Variable         | Description                | Example                                                       |
| ---------------- | -------------------------- | ------------------------------------------------------------- |
| `DATABASE_URL`   | Supabase connection string | `postgresql://postgres:pass@db.xxx.supabase.co:5432/postgres` |
| `JWT_SECRET_KEY` | Secret untuk JWT tokens    | `random-hex-string-64-chars`                                  |
| `DEBUG`          | Debug mode                 | `False` (production)                                          |
| `PORT`           | Server port                | `10000` (Render auto-set)                                     |

**Option 2: Using Individual Parameters**

| Variable            | Description             | Example                      |
| ------------------- | ----------------------- | ---------------------------- |
| `POSTGRES_HOST`     | Supabase host           | `db.xxxxx.supabase.co`       |
| `POSTGRES_USER`     | Supabase username       | `postgres`                   |
| `POSTGRES_PASSWORD` | Supabase password       | `your-password`              |
| `POSTGRES_DB`       | Database name           | `postgres`                   |
| `POSTGRES_PORT`     | PostgreSQL port         | `5432`                       |
| `JWT_SECRET_KEY`    | Secret untuk JWT tokens | `random-hex-string-64-chars` |
| `DEBUG`             | Debug mode              | `False` (production)         |
| `PORT`              | Server port             | `10000` (Render auto-set)    |

---

## Update Flutter App

### Step 1: Update Production URL

1. Buka file `lib/core/app_config.dart`
2. Update `_prodBaseUrl` dengan URL Render Anda:

```dart
static const String _prodBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-app-name.onrender.com/api/v1', // GANTI INI
);
```

### Step 2: Build Flutter App untuk Production

**Option A: Build dengan Environment Variable**

```bash
# Android
flutter build apk --release --dart-define=API_BASE_URL=https://your-app-name.onrender.com/api/v1

# iOS
flutter build ios --release --dart-define=API_BASE_URL=https://your-app-name.onrender.com/api/v1
```

**Option B: Update Default di Code**

Edit `lib/core/app_config.dart` dan ganti default value:

```dart
static const String _prodBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-app-name.onrender.com/api/v1', // Update ini
);
```

Kemudian build normal:

```bash
flutter build apk --release
```

### Step 3: Test Connection

1. Install APK/IPA ke device/emulator
2. Buka app dan coba login/register
3. Cek apakah API calls berhasil
4. Monitor logs di Render dashboard untuk melihat requests

---

## Testing Deployment

### 1. Health Check Test

```bash
curl https://your-app.onrender.com/
```

Expected response:

```json
{
  "status": "healthy",
  "message": "Finance Manager API is running",
  "version": "1.0.0"
}
```

### 2. Database Connection Test

Cek logs di Render dashboard. Seharusnya ada:

```
✅ Database connection successful
```

Jika ada error, cek:

- Environment variables sudah benar (terutama `DATABASE_URL` atau `POSTGRES_*` variables)
- Supabase project masih aktif (tidak di-pause atau di-delete)
- Password sudah benar
- Connection string format sudah benar (harus `postgresql://` bukan `mysql://`)

### 3. API Endpoint Test

```bash
# Test register endpoint
curl -X POST https://financial-app-fua2.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "full_name": "Test User"
  }'
```

### 4. Flutter App Test

1. Install app di device
2. Test login/register
3. Test create transaction
4. Test semua fitur utama
5. Monitor error logs jika ada

---

## Troubleshooting

### Problem: Render deployment fails

**Error**: Build command failed

**Solution**:

- Pastikan `requirements.txt` ada di folder `backend/`
- Pastikan Root Directory di Render adalah `backend`
- Cek logs untuk error spesifik

---

### Problem: Database connection failed

**Error**: `Database connection failed` atau `Connection refused` ke localhost

**Solution**:

1. **PENTING: Pastikan DATABASE_URL sudah di-set di Render**

   - Buka Render Dashboard → Service → Environment
   - Pastikan ada environment variable `DATABASE_URL` dengan nilai connection string
   - Format: `postgresql://user:password@host:port/database`
   - Jika tidak ada, tambahkan sekarang!

2. **Jika error menunjukkan "localhost" atau "Connection refused":**

   - Ini berarti `DATABASE_URL` tidak ter-set atau kosong
   - Aplikasi fallback ke localhost (yang tidak tersedia di production)
   - **Solusi**: Set `DATABASE_URL` di Render environment variables
   - Copy connection string dari Supabase (Project Settings → Database → Connection string)

3. Cek semua environment variables sudah benar

   - Jika menggunakan `DATABASE_URL`, pastikan format: `postgresql://user:password@host:port/db`
   - Jika menggunakan individual parameters, pastikan semua `POSTGRES_*` variables sudah diisi
   - **Catatan**: Di production (Render), gunakan `DATABASE_URL`, bukan individual parameters

4. Pastikan Supabase project masih aktif (tidak di-pause atau di-delete)

5. Reset password di Supabase jika perlu (Project Settings → Database → Reset database password)

6. Cek connection string di Supabase dashboard (Project Settings → Database → Connection string)

7. Pastikan database schema sudah dibuat (jalankan `financial_db_232143_postgresql.sql` di SQL Editor)

8. Supabase free tier tidak memerlukan IP whitelist

**Cara verifikasi DATABASE_URL di Render:**

1. Buka Render Dashboard
2. Pilih service Anda
3. Klik tab "Environment"
4. Scroll ke bawah, cari `DATABASE_URL`
5. Jika tidak ada, klik "Add Environment Variable"
6. Key: `DATABASE_URL`
7. Value: Copy dari Supabase connection string
8. Klik "Save Changes"
9. Render akan auto-redeploy service

---

### Problem: 404 errors di API

**Error**: `Endpoint not found (404)`

**Solution**:

- Pastikan URL menggunakan `/api/v1` prefix
- Cek apakah endpoint sudah terdaftar di `app.py`
- Pastikan CORS sudah configured dengan benar

---

### Problem: CORS errors di Flutter

**Error**: CORS policy blocked

**Solution**:

1. Buka `backend/app.py`
2. Pastikan CORS configured:

```python
CORS(app, resources={r"/api/*": {"origins": "*"}})
```

Atau untuk production, specify domain Flutter app:

```python
CORS(app, resources={r"/api/*": {"origins": ["*"]}})
```

---

### Problem: App sleep terlalu lama

**Issue**: Request pertama setelah idle sangat lambat (~30 detik)

**Solution**:

- Ini normal untuk Render free tier
- Pertimbangkan upgrade ke paid plan untuk no-sleep
- Atau setup cron job untuk ping app setiap 10 menit (mencegah sleep)

**Cron job example** (gunakan service seperti cron-job.org):

```
URL: https://your-app.onrender.com/
Method: GET
Schedule: Every 10 minutes
```

---

### Problem: JWT token expired quickly

**Error**: Token expired

**Solution**:

- Default JWT expiry adalah 7 hari (sudah cukup)
- Jika perlu lebih lama, update `config.py`:

```python
JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=30)  # 30 hari
```

---

### Problem: Flutter app tidak connect ke production

**Error**: Connection timeout / Failed to connect

**Solution**:

1. Pastikan URL di `app_config.dart` sudah benar (dengan `https://`)
2. Pastikan tidak ada typo di URL
3. Test URL di browser terlebih dahulu
4. Cek apakah Render service masih running (tidak sleep)
5. Pastikan device/emulator punya internet connection

---

## Security Best Practices

### 1. JWT Secret Key

- ✅ Gunakan strong random secret (min 32 characters)
- ✅ Jangan commit secret ke Git
- ✅ Gunakan environment variable
- ✅ Rotate secret secara berkala

### 2. Database Credentials

- ✅ Jangan commit credentials ke Git
- ✅ Gunakan environment variables
- ✅ Rotate password secara berkala
- ✅ Monitor database access logs

### 3. HTTPS

- ✅ Render otomatis provide HTTPS (gratis)
- ✅ Pastikan Flutter app menggunakan `https://` bukan `http://`

### 4. CORS

- ✅ Untuk production, consider restrict CORS ke specific domains
- ✅ Jangan set `origins: ["*"]` di production jika tidak perlu

---

## Monitoring & Maintenance

### 1. Monitor Logs

- Render dashboard → Your service → Logs
- Monitor untuk errors, slow queries, dll

### 2. Database Monitoring

- Supabase dashboard → Project → Database → Database Health
- Monitor connection count, query performance, storage usage
- Supabase dashboard → Project → Logs → Postgres Logs

### 3. Backup

- Supabase free tier tidak include automated backups
- Consider export database secara manual:

```bash
# Using pg_dump (PostgreSQL)
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres > backup.sql

# Or use Supabase dashboard → Database → Backups (paid plans only)
```

### 4. Updates

- Update dependencies secara berkala
- Test di staging environment sebelum deploy ke production
- Monitor untuk security vulnerabilities

---

## Cost Estimation

### Free Tier Limits

**Render (Free):**

- ✅ Unlimited deploys
- ✅ 750 hours/month (cukup untuk 1 service)
- ⚠️ Sleep setelah 15 menit idle
- ⚠️ Cold start ~30 detik

**Supabase (Free):**

- ✅ Unlimited projects
- ✅ 500MB database storage
- ✅ 2GB bandwidth
- ✅ 50,000 monthly active users
- ✅ Unlimited API requests
- ✅ PostgreSQL database (full featured)

**Total Cost: $0/month** (selama dalam free tier limits)

### Upgrade Options (Jika Perlu)

**Render Paid:**

- $7/month: No sleep, faster cold start
- $25/month: More resources, better performance

**Supabase Paid:**

- $25/month (Pro): 8GB database, 50GB bandwidth, automated backups
- $599/month (Team): More storage, better performance, team features

---

## Next Steps

Setelah deployment berhasil:

1. ✅ Test semua fitur di production
2. ✅ Setup monitoring & alerts
3. ✅ Document production URL untuk team
4. ✅ Setup backup strategy
5. ✅ Consider CI/CD untuk auto-deploy

---

## Support & Resources

- **Render Docs**: [render.com/docs](https://render.com/docs)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Supabase PostgreSQL Guide**: [supabase.com/docs/guides/database](https://supabase.com/docs/guides/database)
- **Flutter Build**: [flutter.dev/docs/deployment](https://flutter.dev/docs/deployment)
- **PostgreSQL Migration Guide**: [postgresql.org/docs/current/](https://www.postgresql.org/docs/current/)

---

## Migration Notes: MySQL to PostgreSQL

Jika Anda migrasi dari MySQL ke PostgreSQL, berikut perbedaan penting:

1. **Parameterized Queries**: `psycopg2` mendukung `%s` (sama seperti MySQL), jadi tidak perlu ubah query syntax
2. **Data Types**:
   - `enum` → `VARCHAR` dengan `CHECK` constraint
   - `tinyint(1)` → `BOOLEAN`
   - `json` → `JSONB` (recommended untuk PostgreSQL)
3. **Functions**:
   - `CURDATE()` → `CURRENT_DATE`
   - `NOW()` → `CURRENT_TIMESTAMP` (sama)
   - `uuid()` → `gen_random_uuid()`
4. **Triggers**: PostgreSQL menggunakan function-based triggers (sudah dikonversi di schema)
5. **ON UPDATE CURRENT_TIMESTAMP**: PostgreSQL tidak support langsung, perlu trigger (sudah dibuat di schema)

---

**Selamat! Backend Anda sudah live di production dengan Supabase! 🎉**
