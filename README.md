# Contolonerxs

## Cara pakai (TANPA komputer, cukup HP/browser)
1. Buka github.com, login/buat akun, lalu buat repo baru (misal nama "contolonerxs").
2. Di halaman repo, klik "Add file" > "Upload files".
3. Extract zip ini dulu di HP (pakai app file manager/ZIP viewer), lalu upload SEMUA isinya
   (folder `lib` beserta `main.dart` di dalamnya, `pubspec.yaml`, `codemagic.yaml`) ke repo tersebut.
   Pastikan struktur foldernya tetap sama (lib/main.dart, bukan main.dart langsung di root).
4. Commit langsung ke branch `main`.
5. Buka codemagic.io, login pakai akun GitHub kamu, lalu hubungkan repo "contolonerxs".
6. Codemagic otomatis mendeteksi `codemagic.yaml`. Jalankan build (atau otomatis jalan tiap ada push).
   - Build ini akan otomatis membuat folder `android/` dulu (karena belum ada), baru build APK.
7. Setelah build selesai, APK bisa didownload langsung dari halaman build Codemagic
   (dan/atau dikirim ke email yang kamu isi di codemagic.yaml).

## Isi
- `lib/main.dart` — halaman login (username & password), logic login masih dummy/placeholder.
- `pubspec.yaml` — konfigurasi project Flutter minimal.
- `codemagic.yaml` — konfigurasi build APK otomatis di Codemagic, khusus Android,
  termasuk langkah otomatis generate folder android/ kalau belum ada.
