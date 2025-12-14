# MapTiler Troubleshooting

Jika setelah menambahkan API key masih muncul "No API keys found", ikuti langkah berikut:

## 1. Pastikan Format .env Benar

File `.env` harus berada di **root project** (sama level dengan `pubspec.yaml`).

Format yang benar:
```env
MAPTILER_API_KEY=Wuh9Yue4W6uuDw3qCJmo
```

**Jangan pakai quotes:**
```env
# ❌ SALAH
MAPTILER_API_KEY="Wuh9Yue4W6uuDw3qCJmo"
MAPTILER_API_KEY='Wuh9Yue4W6uuDw3qCJmo'

# ✅ BENAR
MAPTILER_API_KEY=Wuh9Yue4W6uuDw3qCJmo
```

## 2. Restart Aplikasi

Setelah menambahkan API key ke `.env`:

1. **Stop aplikasi** (jika sedang running)
2. **Full restart** (bukan hot reload):
   ```bash
   # Stop aplikasi dulu, lalu:
   flutter run
   ```

**Penting:** Hot reload (`r`) atau hot restart (`R`) mungkin tidak cukup. Perlu **full restart**.

## 3. Cek Log Output

Setelah restart, cek log untuk melihat:
- Apakah .env file di-load
- Apakah MAPTILER_API_KEY ditemukan
- Provider mana yang digunakan

Log yang diharapkan:
```
[DEBUG] [Main] Loaded .env file with X keys
[DEBUG] [Main] MAPTILER_API_KEY present: true (length: XX)
[DEBUG] [MapProvider] Env map loaded: X keys
[DEBUG] [MapProvider] MAPTILER_API_KEY found: true
[INFO] [MapProvider] Using MapTiler as primary provider
```

## 4. Verifikasi File .env

Pastikan file `.env` ada di root project:
```bash
# Dari root project
ls -la .env
cat .env | grep MAPTILER
```

## 5. Pastikan .env di Assets

File `.env` harus ada di `pubspec.yaml` assets:
```yaml
flutter:
  assets:
    - .env
```

## 6. Jika Masih Tidak Berfungsi

### Opsi A: Tambahkan Debug Logging

Restart aplikasi dan cek log output. Logging sudah ditambahkan untuk debugging.

### Opsi B: Hardcode untuk Testing (Sementara)

Untuk testing, bisa hardcode di `MapProviderService.initialize()`:
```dart
_maptilerApiKey = 'Wuh9Yue4W6uuDw3qCJmo'; // Testing only
```

**Jangan commit** perubahan ini ke git!

### Opsi C: Gunakan OpenStreetMap

Aplikasi tetap berfungsi dengan OpenStreetMap jika MapTiler tidak tersedia.

## Common Issues

### Issue 1: "Could not load .env file"
- Pastikan file `.env` ada di root project
- Pastikan format file benar (tidak ada BOM, UTF-8 encoding)
- Cek permission file

### Issue 2: "MAPTILER_API_KEY not found"
- Pastikan key name tepat: `MAPTILER_API_KEY` (case-sensitive)
- Pastikan tidak ada space sebelum/setelah `=`
- Pastikan tidak ada quotes

### Issue 3: Aplikasi tidak restart
- Stop aplikasi sepenuhnya
- Run `flutter clean` (opsional)
- Run `flutter run` lagi

## Testing

Untuk test apakah API key bekerja:

1. Restart aplikasi dengan API key
2. Buka map screen
3. Cek log untuk konfirmasi "Using MapTiler as primary provider"
4. Coba search location - seharusnya menggunakan MapTiler geocoding

Jika masih bermasalah, pastikan API key valid di https://cloud.maptiler.com/account/keys/

