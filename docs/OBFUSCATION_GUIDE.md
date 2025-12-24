# Panduan Obfuscation untuk Flutter

Dokumen ini menjelaskan cara melindungi kode Dart/Flutter Anda dengan obfuscation sebelum melakukan build release.

## Apa itu Obfuscation?

Obfuscation adalah proses mengubah kode menjadi versi yang sulit dibaca dan dipahami, namun tetap berfungsi dengan baik. Ini membantu melindungi kode Anda dari reverse engineering.

## Mengapa Perlu Obfuscation?

- Melindungi logika bisnis dari reverse engineering
- Menyulitkan penyerang untuk memahami struktur aplikasi
- Mengurangi ukuran aplikasi (dalam beberapa kasus)
- Menyembunyikan string dan konstanta sensitif

## Build dengan Obfuscation

### Android (Release Build)

```bash
# Build APK dengan obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Build App Bundle dengan obfuscation (untuk Google Play)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### iOS (Release Build)

```bash
# Build iOS dengan obfuscation
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
```

### Web (Release Build)

```bash
# Build web dengan obfuscation
flutter build web --release
```

## Parameter Obfuscation

### `--obfuscate`
Mengaktifkan obfuscation untuk kode Dart. Ini akan:
- Mengubah nama class, method, dan variable menjadi nama yang tidak bermakna
- Menyembunyikan string literal
- Mengoptimalkan kode

### `--split-debug-info=<directory>`
Menyimpan file debug info terpisah. File ini diperlukan untuk:
- Symbolication crash reports
- Debugging (jika diperlukan)
- **PENTING**: Simpan file debug info dengan aman, jangan commit ke repository!

## Konfigurasi Android

### 1. Update `android/app/build.gradle.kts`

Pastikan ProGuard/R8 sudah dikonfigurasi:

```kotlin
android {
    buildTypes {
        release {
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 2. Buat `android/app/proguard-rules.pro`

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep your custom classes if needed
# -keep class com.yourpackage.** { *; }
```

## Konfigurasi iOS

### 1. Update `ios/Runner.xcodeproj/project.pbxproj`

Pastikan build settings untuk release sudah optimal:

- **Optimization Level**: `-Os` (Optimize for size)
- **Strip Debug Symbols**: `YES`
- **Enable Bitcode**: `NO` (Flutter tidak mendukung bitcode)

### 2. Build Settings di Xcode

1. Buka project di Xcode
2. Pilih target "Runner"
3. Build Settings → Search "Optimization"
4. Set **Swift Compiler - Code Generation → Optimization Level** ke `-Os` untuk Release

## Best Practices

### 1. Simpan Debug Info dengan Aman

File debug info diperlukan untuk symbolication. Simpan di tempat yang aman:

```bash
# Buat direktori untuk menyimpan debug info
mkdir -p build/debug-info

# Build dengan menyimpan debug info
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Backup debug info (jangan commit ke git!)
# Tambahkan ke .gitignore:
echo "build/debug-info/" >> .gitignore
```

### 2. Test Build Obfuscated

Selalu test aplikasi setelah obfuscation:

```bash
# Install dan test
flutter install --release
```

### 3. Monitor Crash Reports

Setelah obfuscation, pastikan crash reporting service Anda bisa melakukan symbolication dengan file debug info.

### 4. Jangan Obfuscate di Development

Obfuscation hanya untuk release builds. Development builds harus tetap readable untuk debugging:

```bash
# Development (tanpa obfuscation)
flutter run

# Release (dengan obfuscation)
flutter build apk --release --obfuscate
```

## Script Otomatis

Buat script untuk memudahkan build dengan obfuscation:

### `scripts/build-release.sh`

```bash
#!/bin/bash

# Build release dengan obfuscation
echo "Building release with obfuscation..."

# Android
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/debug-info/ios

echo "Build complete! Debug info saved in build/debug-info/"
echo "⚠️  Remember to backup debug info files securely!"
```

### `scripts/build-release.bat` (Windows)

```batch
@echo off
echo Building release with obfuscation...

REM Android
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android

REM iOS (requires macOS)
REM flutter build ios --release --obfuscate --split-debug-info=build/debug-info/ios

echo Build complete! Debug info saved in build/debug-info/
echo ⚠️  Remember to backup debug info files securely!
```

## Verifikasi Obfuscation

### 1. Cek APK/AAB

Setelah build, Anda bisa memeriksa apakah obfuscation bekerja:

```bash
# Extract dan lihat kode (akan terlihat ter-obfuscate)
unzip -q app-release.apk -d extracted
# Kode Dart akan terlihat dengan nama yang tidak bermakna
```

### 2. Cek Ukuran File

Obfuscated build biasanya lebih kecil dari non-obfuscated build.

## Troubleshooting

### Issue: Aplikasi crash setelah obfuscation

**Solusi:**
- Pastikan semua dependencies kompatibel dengan obfuscation
- Cek ProGuard rules untuk Android
- Test secara menyeluruh sebelum release

### Issue: Debug info hilang

**Solusi:**
- Selalu gunakan `--split-debug-info` saat build
- Backup file debug info dengan aman
- Jangan commit debug info ke repository

### Issue: Ukuran aplikasi lebih besar

**Solusi:**
- Ini normal jika menggunakan `--split-debug-info` (debug info disimpan terpisah)
- Pastikan `isShrinkResources = true` di Android
- Gunakan `--split-per-abi` untuk Android untuk mengurangi ukuran per APK

## Catatan Penting

1. **Obfuscation bukan enkripsi**: Kode masih bisa dianalisis, hanya lebih sulit
2. **Debug info penting**: Simpan dengan aman untuk symbolication
3. **Test sebelum release**: Selalu test aplikasi setelah obfuscation
4. **Tidak 100% aman**: Obfuscation memperlambat reverse engineering, bukan mencegahnya
5. **Backend security**: Obfuscation hanya melindungi client-side code. Pastikan backend API juga aman

## Referensi

- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Flutter Code Obfuscation](https://docs.flutter.dev/deployment/obfuscate)
- [Android ProGuard](https://developer.android.com/studio/build/shrink-code)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

