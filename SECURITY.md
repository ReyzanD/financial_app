# Security Policy & Guidelines

## ⚠️ Peringatan Keamanan

Repository ini berisi kode sumber aplikasi keuangan. Keamanan adalah prioritas utama.

## 🔒 Security Checklist Sebelum Public Repository

Sebelum membuat repository ini menjadi public, pastikan Anda telah:

### 1. Environment Variables & Secrets
- [ ] Semua API keys, secrets, dan credentials disimpan di environment variables
- [ ] File `.env` sudah ditambahkan ke `.gitignore`
- [ ] File `.env.example` sudah dibuat sebagai template (tanpa nilai sensitif)
- [ ] Tidak ada hardcoded secrets di kode
- [ ] Default values di config hanya untuk development, bukan production

### 2. Database & Credentials
- [ ] Tidak ada connection strings dengan password di kode
- [ ] Database credentials hanya di environment variables
- [ ] Tidak ada sample data dengan informasi sensitif
- [ ] SQL files tidak mengandung credentials production

### 3. API Keys & Tokens
- [ ] Semua API keys menggunakan environment variables
- [ ] Tidak ada API keys di kode atau commit history
- [ ] JWT secret key menggunakan strong random value di production
- [ ] Tidak ada tokens atau session data di repository

### 4. File Sensitif
- [ ] File keystore (`.jks`, `.keystore`) tidak di-commit
- [ ] File signing keys tidak di-commit
- [ ] File konfigurasi production tidak di-commit
- [ ] File backup atau temporary tidak di-commit

### 5. Code Review
- [ ] Review semua file sebelum commit
- [ ] Cek commit history untuk secrets yang mungkin ter-expose
- [ ] Gunakan `git-secrets` atau tools serupa untuk scan
- [ ] Pastikan tidak ada komentar dengan informasi sensitif

### 6. Documentation
- [ ] README tidak mengandung credentials atau secrets
- [ ] Dokumentasi tidak menampilkan contoh dengan data sensitif
- [ ] Setup instructions menggunakan `.env.example`

## 🛡️ Best Practices Keamanan

### Environment Variables

**✅ BENAR:**
```python
# config.py
JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-only')
```

**❌ SALAH:**
```python
# config.py
JWT_SECRET_KEY = 'my-super-secret-key-12345'  # JANGAN!
```

### Database Configuration

**✅ BENAR:**
```python
DATABASE_URL = os.getenv('DATABASE_URL')
```

**❌ SALAH:**
```python
DATABASE_URL = 'postgresql://user:password@host/db'  # JANGAN!
```

### API Keys

**✅ BENAR:**
```dart
// lib/services/api_service.dart
final apiKey = Platform.environment['API_KEY'] ?? '';
```

**❌ SALAH:**
```dart
// lib/services/api_service.dart
final apiKey = 'sk-1234567890abcdef';  // JANGAN!
```

## 🔍 Scanning untuk Secrets

### Tools yang Direkomendasikan

1. **git-secrets** (GitHub)
   ```bash
   git secrets --install
   git secrets --register-aws
   ```

2. **truffleHog**
   ```bash
   pip install truffleHog
   truffleHog --regex --entropy=False .
   ```

3. **gitleaks**
   ```bash
   gitleaks detect --source . --verbose
   ```

### Manual Check

```bash
# Cari pattern yang mencurigakan
grep -r "password\|secret\|key\|token" --include="*.py" --include="*.dart" .
grep -r "api[_-]?key" -i .
grep -r "@gmail\|@yahoo" .  # Email addresses
```

## 🚨 Jika Secrets Ter-Expose

Jika Anda menemukan atau tidak sengaja meng-commit secrets:

### Langkah Cepat:

1. **Segera rotate/ubah semua secrets yang ter-expose:**
   - API keys
   - Database passwords
   - JWT secrets
   - OAuth tokens

2. **Hapus dari Git history:**
   ```bash
   # Hapus file dari history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/file" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Atau gunakan BFG Repo-Cleaner (lebih cepat)
   bfg --delete-files file-with-secrets
   ```

3. **Force push (HATI-HATI!):**
   ```bash
   git push origin --force --all
   ```

4. **Monitor untuk aktivitas mencurigakan:**
   - Cek logs API untuk penggunaan tidak sah
   - Monitor database access
   - Cek billing untuk penggunaan tidak terduga

### Pencegahan:

- Gunakan pre-commit hooks untuk scan secrets
- Setup GitHub secret scanning (jika menggunakan GitHub)
- Review semua PR sebelum merge
- Gunakan environment-specific configs

## 📝 Reporting Security Issues

Jika Anda menemukan vulnerability atau security issue:

1. **JANGAN** buat public issue
2. **Hubungi** pemilik repository secara private
3. **Berikan detail:**
   - Deskripsi vulnerability
   - Langkah reproduksi (jika memungkinkan)
   - Dampak potensial
   - Saran perbaikan (jika ada)

## 🔐 Production Security

### Backend

- [ ] Gunakan HTTPS untuk semua komunikasi
- [ ] Enable CORS dengan whitelist domain yang tepat
- [ ] Implement rate limiting
- [ ] Gunakan strong JWT secret (min 32 karakter random)
- [ ] Enable database encryption
- [ ] Setup firewall rules
- [ ] Regular security updates
- [ ] Monitor logs untuk aktivitas mencurigakan

### Frontend

- [ ] Build dengan obfuscation untuk release
- [ ] Jangan hardcode API endpoints production
- [ ] Implement certificate pinning (jika memungkinkan)
- [ ] Secure storage untuk sensitive data
- [ ] Validate semua input
- [ ] Sanitize output

### Database

- [ ] Strong passwords untuk database users
- [ ] Limit database user permissions
- [ ] Enable SSL/TLS untuk connections
- [ ] Regular backups
- [ ] Encrypt sensitive columns
- [ ] Audit logging

## 📚 Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Python Security Best Practices](https://python.readthedocs.io/en/stable/library/security_warnings.html)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

## ⚖️ Legal Notice

Penggunaan kode ini untuk tujuan yang melanggar hukum atau merugikan pihak lain adalah tanggung jawab pengguna. Pemilik repository tidak bertanggung jawab atas penyalahgunaan kode ini.

---

**Ingat:** Keamanan adalah proses berkelanjutan, bukan sekali setup. Selalu review dan update security practices secara berkala.

