# Mapbox Hybrid Setup Guide

Aplikasi ini menggunakan **Hybrid Map Provider** dengan Mapbox sebagai primary dan OpenStreetMap sebagai fallback.

## Fitur

✅ **Mapbox sebagai Primary Provider**
- Coverage lebih baik untuk Indonesia
- Free tier: 50,000 map loads/bulan
- 100,000 geocoding requests/bulan
- 25,000 Monthly Active Users

✅ **OpenStreetMap sebagai Fallback**
- Otomatis digunakan jika Mapbox token tidak tersedia
- Atau jika Mapbox API error
- 100% gratis tanpa limit

✅ **Automatic Fallback**
- Jika Mapbox search gagal, otomatis fallback ke OpenStreetMap
- Transparent untuk user
- Logging untuk monitoring

✅ **Caching**
- Geocoding results di-cache selama 24 jam
- Mengurangi API calls
- Meningkatkan performance

## Setup Mapbox (Optional)

### Langkah 1: Daftar Mapbox Account

1. Kunjungi: https://account.mapbox.com/
2. Buat account gratis (tidak perlu kartu kredit)
3. Verifikasi email

### Langkah 2: Buat Access Token

1. Login ke Mapbox account
2. Buka: https://account.mapbox.com/access-tokens/
3. Klik "Create a token"
4. Beri nama: "Financial App"
5. Copy token yang dihasilkan

### Langkah 3: Tambahkan ke .env

Buat file `.env` di root project (jika belum ada):

```env
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token_here
```

**Catatan:** File `.env` sudah di-ignore di `.gitignore`, jadi aman untuk commit.

### Langkah 4: Run Flutter

```bash
flutter pub get
flutter run
```

## Tanpa Mapbox Token

Jika tidak menambahkan Mapbox token, aplikasi akan **otomatis menggunakan OpenStreetMap**:
- Tidak perlu setup tambahan
- Tetap berfungsi normal
- Coverage mungkin lebih terbatas di beberapa area

## Monitoring Usage

Untuk monitoring penggunaan Mapbox:
1. Login ke https://account.mapbox.com/
2. Buka "Usage" dashboard
3. Monitor map loads dan geocoding requests

## Estimasi untuk 20 User

Dengan 20 user aktif:
- **Map Loads**: ~800/bulan (1.6% dari limit 50,000)
- **Geocoding**: ~400/bulan (0.4% dari limit 100,000)
- **MAU**: 20 (0.08% dari limit 25,000)

**Kesimpulan:** Masih banyak ruang untuk berkembang! 🚀

## Troubleshooting

### Map tidak muncul
- Cek apakah `.env` file ada dan berisi `MAPBOX_ACCESS_TOKEN`
- Cek log untuk melihat provider mana yang digunakan
- Pastikan internet connection aktif

### Search tidak menemukan lokasi
- Cek log untuk melihat apakah fallback ke OpenStreetMap berjalan
- Beberapa lokasi mungkin tidak ada di database manapun
- Coba dengan nama yang lebih spesifik

### Error "Mapbox API error"
- Cek apakah token valid
- Cek apakah sudah melewati free tier limit
- Aplikasi akan otomatis fallback ke OpenStreetMap

## File yang Terlibat

- `lib/services/map_provider_service.dart` - Service utama
- `lib/widgets/maps/location_picker_map.dart` - Location picker
- `lib/Screen/map_screen.dart` - Full map screen
- `lib/widgets/transactions/location_insight_card.dart` - Map preview
- `lib/main.dart` - Initialization

## Testing

Untuk test tanpa Mapbox token:
1. Hapus atau comment `MAPBOX_ACCESS_TOKEN` dari `.env`
2. Restart aplikasi
3. Aplikasi akan menggunakan OpenStreetMap

Untuk test dengan Mapbox:
1. Tambahkan valid token ke `.env`
2. Restart aplikasi
3. Cek log untuk konfirmasi "Using Mapbox as primary provider"

