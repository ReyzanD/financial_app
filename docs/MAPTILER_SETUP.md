# MapTiler Hybrid Setup Guide

Aplikasi ini menggunakan **Hybrid Map Provider** dengan MapTiler sebagai primary dan OpenStreetMap sebagai fallback.

## Fitur

✅ **MapTiler sebagai Primary Provider**
- Coverage lebih baik untuk Indonesia
- Free tier: 100,000 API requests/bulan
- 5,000 map sessions/bulan
- Tidak perlu kartu kredit untuk free tier

✅ **OpenStreetMap sebagai Fallback**
- Otomatis digunakan jika MapTiler API key tidak tersedia
- Atau jika MapTiler API error
- 100% gratis tanpa limit

✅ **Automatic Fallback**
- Jika MapTiler search gagal, otomatis fallback ke OpenStreetMap
- Transparent untuk user
- Logging untuk monitoring

✅ **Caching**
- Geocoding results di-cache selama 24 jam
- Mengurangi API calls
- Meningkatkan performance

## Setup MapTiler

### Langkah 1: Daftar MapTiler Account

1. Kunjungi: https://cloud.maptiler.com/account/register/
2. Buat account gratis (tidak perlu kartu kredit)
3. Verifikasi email

### Langkah 2: Buat API Key

1. Login ke MapTiler account
2. Buka: https://cloud.maptiler.com/account/keys/
3. Klik "Create a new key"
4. Beri nama: "Financial App"
5. Pilih scope: "Geocoding API" dan "Maps API"
6. Copy API key yang dihasilkan

### Langkah 3: Tambahkan ke .env

Buat file `.env` di root project (jika belum ada):

```env
MAPTILER_API_KEY=your_maptiler_api_key_here
```

**Catatan:** File `.env` sudah di-ignore di `.gitignore`, jadi aman untuk commit.

### Langkah 4: Run Flutter

```bash
flutter pub get
flutter run
```

## Tanpa MapTiler API Key

Jika tidak menambahkan MapTiler API key, aplikasi akan **otomatis menggunakan OpenStreetMap**:
- Tidak perlu setup tambahan
- Tetap berfungsi normal
- Coverage mungkin lebih terbatas di beberapa area

## Monitoring Usage

Untuk monitoring penggunaan MapTiler:
1. Login ke https://cloud.maptiler.com/
2. Buka "Usage" dashboard
3. Monitor API requests dan map sessions

## Estimasi untuk 20 User

Dengan 20 user aktif:
- **API Requests**: ~400/bulan (0.4% dari limit 100,000)
- **Map Sessions**: ~20/bulan (0.4% dari limit 5,000)

**Kesimpulan:** Masih banyak ruang untuk berkembang! 🚀

## Provider Priority

Aplikasi menggunakan priority berikut:
1. **MapTiler** (jika `MAPTILER_API_KEY` tersedia)
2. **Mapbox** (jika `MAPBOX_ACCESS_TOKEN` tersedia)
3. **OpenStreetMap** (default fallback)

## Troubleshooting

### Map tidak muncul
- Cek apakah `.env` file ada dan berisi `MAPTILER_API_KEY`
- Cek log untuk melihat provider mana yang digunakan
- Pastikan internet connection aktif

### Search tidak menemukan lokasi
- Cek log untuk melihat apakah fallback ke OpenStreetMap berjalan
- Beberapa lokasi mungkin tidak ada di database manapun
- Coba dengan nama yang lebih spesifik

### Error "MapTiler API error"
- Cek apakah API key valid
- Cek apakah sudah melewati free tier limit
- Aplikasi akan otomatis fallback ke OpenStreetMap

## File yang Terlibat

- `lib/services/map_provider_service.dart` - Service utama
- `lib/widgets/maps/location_picker_map.dart` - Location picker
- `lib/Screen/map_screen.dart` - Full map screen
- `lib/widgets/transactions/location_insight_card.dart` - Map preview
- `lib/main.dart` - Initialization

## Testing

Untuk test tanpa MapTiler API key:
1. Hapus atau comment `MAPTILER_API_KEY` dari `.env`
2. Restart aplikasi
3. Aplikasi akan menggunakan OpenStreetMap

Untuk test dengan MapTiler:
1. Tambahkan valid API key ke `.env`
2. Restart aplikasi
3. Cek log untuk konfirmasi "Using MapTiler as primary provider"

## MapTiler Free Tier Details

- **100,000 API requests/bulan** (geocoding, routing, dll)
- **5,000 map sessions/bulan** (map loads)
- **Tidak perlu kartu kredit**
- **Cocok untuk development dan production kecil**

## Alternatif Providers

Jika MapTiler tidak tersedia, aplikasi akan otomatis fallback ke:
1. Mapbox (jika token tersedia)
2. OpenStreetMap (default)

Semua fallback otomatis dan transparent untuk user.

