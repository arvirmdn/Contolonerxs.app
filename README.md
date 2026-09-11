# Contolonerxs

## Cara pakai (TANPA komputer, cukup HP/browser)
1. Buka github.com, login/buat akun, lalu buat repo baru (misal nama "contolonerxs").
2. Di halaman repo, klik "Add file" > "Upload files".
3. Extract zip ini dulu di HP (pakai app file manager/ZIP viewer), lalu upload SEMUA isinya
   (folder `lib` beserta isinya, folder `assets`, `pubspec.yaml`, `codemagic.yaml`,
   `analysis_options.yaml`) ke repo tersebut. Pastikan struktur foldernya tetap sama.
4. Commit langsung ke branch `main`.
5. Buka codemagic.io, login pakai akun GitHub kamu, lalu hubungkan repo "contolonerxs".
6. Codemagic otomatis mendeteksi `codemagic.yaml`. Jalankan build (atau otomatis jalan tiap ada push).
   - Build ini akan otomatis membuat folder `android/` dulu (karena belum ada), baru build APK.
   - Icon aplikasi custom otomatis di-generate tiap build (lihat bagian "App icon" di bawah).
7. Setelah build selesai, APK bisa didownload langsung dari halaman build Codemagic
   (dan/atau dikirim ke email yang kamu isi di codemagic.yaml).

## Struktur kode
Kode dipecah per halaman biar gampang dicari/diedit (sebelumnya numplek di satu file):
- `lib/main.dart` — entry point, cuma manggil `runApp()`.
- `lib/app.dart` — konfigurasi `MaterialApp` (tema, judul, halaman awal).
- `lib/screens/splash_screen.dart` — halaman splash/loading di awal buka app.
- `lib/screens/login_screen.dart` — halaman login (username & password, logic masih dummy/placeholder).
- `lib/screens/home_screen.dart` — halaman setelah berhasil login.
- `analysis_options.yaml` — aturan lint (biar warning kode jelek kedeteksi otomatis).

## App icon
- `assets/icon/icon.png` — gambar icon custom (gembok + gradient, senada tema app).
- Digenerate otomatis ke semua ukuran Android tiap kali build lewat package
  `flutter_launcher_icons` (konfigurasinya ada di `pubspec.yaml`).
- Mau ganti gambar icon? Tinggal timpa file `assets/icon/icon.png` (ukuran persegi,
  minimal 512x512) terus push, otomatis kepakai di build berikutnya.

## Package name
Sekarang pakai `com.arvirmdn.contolonerxs` (sebelumnya default `com.example.contolonerxs`),
diatur lewat flag `--org com.arvirmdn` di `codemagic.yaml` pas generate folder `android/`.

## Setup signing release (opsional, buat publish beneran)
Selama folder `android/` di-generate ulang tiap build (belum di-commit ke repo), APK yang
dihasilkan otomatis pakai **debug signing** — cukup buat testing sendiri, tapi TIDAK bisa
dipakai upload ke Play Store atau update APK yang udah diinstall pakai keystore beda.

Kalau mau setup signing release beneran, langkahnya (sekali aja):
1. Jalankan satu kali build di Codemagic seperti biasa.
2. Di halaman hasil build, download artifact `android-folder.zip` (isinya folder
   `android/` yang otomatis ke-generate).
3. Extract, lalu upload folder `android/` itu ke repo GitHub kamu (sejajar dengan `lib/`).
4. Tambahkan file `android/key.properties` (JANGAN pakai keystore/password contoh di bawah
   untuk app yang beneran dipublish — ganti sendiri demi keamanan):
   ```
   storePassword=ISI_PASSWORD_KEYSTORE
   keyPassword=ISI_PASSWORD_KEY
   keyAlias=ISI_ALIAS
   storeFile=keystore.jks
   ```
5. Taruh file keystore (`.jks`) kamu di `android/app/keystore.jks`.
6. Buka `android/app/build.gradle` (atau `build.gradle.kts`), tambahkan sebelum blok
   `android { ... }`:
   ```groovy
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   ```
   Lalu di dalam blok `android { ... }`, tambahkan:
   ```groovy
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }
   buildTypes {
       release {
           signingConfig signingConfigs.release
       }
   }
   ```
7. Hapus/nonaktifkan langkah "Generate Android platform files (jika belum ada)" di
   `codemagic.yaml` karena folder `android/` sekarang sudah permanen di repo (tidak perlu
   di-generate ulang tiap build lagi).
8. **PENTING**: jangan commit file `key.properties` atau `keystore.jks` yang isinya
   password/keystore ASLI ke repo public — simpan sebagai secret/encrypted variable di
   Codemagic (Settings > Environment variables) kalau repo-nya public, atau pastikan
   repo di-set **private** kalau mau nyimpen langsung di situ.

## Isi
- `lib/` — kode aplikasi (lihat bagian "Struktur kode" di atas).
- `pubspec.yaml` — konfigurasi project Flutter + dependency icon generator.
- `codemagic.yaml` — konfigurasi build APK otomatis di Codemagic, khusus Android,
  termasuk generate folder android/, icon custom, dan persiapan artifact signing.
- `analysis_options.yaml` — aturan lint kode.
