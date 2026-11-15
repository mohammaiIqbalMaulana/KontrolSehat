# KontrolSehat

Aplikasi Android untuk membantu pasien hipertensi mencatat tekanan darah, mengatur jadwal obat, mengingat jadwal kontrol, dan melihat ringkasan kepatuhan.

> **Catatan penting:** KontrolSehat adalah alat pencatatan dan pengingat edukatif. Aplikasi ini bukan alat diagnosis, tidak memberikan saran pengobatan atau perubahan dosis, dan tidak menggantikan dokter maupun tenaga kesehatan. Seluruh data pada versi proyek ini adalah data simulasi.

## Gambaran proyek

KontrolSehat dibuat sebagai proyek individu untuk mata kuliah **Teori Sistem Informasi Layanan Kesehatan (IF2371054)**. Aplikasi ditujukan untuk satu jenis pengguna, yaitu **pasien**. Tidak ada peran admin atau tenaga kesehatan di dalam aplikasi.

Pasien memasukkan obat dan jadwal kontrol berdasarkan resep atau kartu kontrol yang dimilikinya. Aplikasi kemudian:

- menjadwalkan pengingat obat secara lokal di perangkat;
- menyediakan pencatatan `Sudah minum` atau `Lewati`;
- menandai dosis yang tidak dicatat sebagai terlewat setelah hari dosis berakhir;
- menyimpan catatan tekanan darah dan memberi label edukatif;
- menampilkan riwayat serta tren tekanan darah;
- menghitung kepatuhan obat harian, mingguan, dan bulanan;
- mengingatkan jadwal kontrol H-1 pukul 18:00 dan dua jam sebelum jadwal;
- menyimpan pengaturan tema dan jenis pengingat di perangkat.

Aplikasi membutuhkan koneksi internet untuk autentikasi dan sinkronisasi data dengan Supabase. Pengingat dijadwalkan lokal sehingga tetap dapat berjalan di perangkat setelah aplikasi ditutup, selama izin notifikasi/alarm dan pengaturan baterai perangkat mengizinkannya.

## Fitur

### Akun dan onboarding

- Splash screen dan pemeriksaan sesi login.
- Onboarding empat halaman yang hanya ditampilkan pada pemakaian pertama.
- Registrasi menggunakan nama lengkap, tahun lahir, email, dan password.
- Login dan logout menggunakan Supabase Auth.
- Sesi login dipertahankan oleh Supabase.
- Penghapusan akun dan seluruh data milik pengguna melalui RPC database.

### Beranda

Beranda menampilkan:

- sapaan berdasarkan nama pengguna;
- obat berikutnya yang belum dicatat;
- status dosis dan tombol `Sudah minum` atau `Lewati` ketika sudah boleh dicatat;
- progres dosis obat hari ini;
- catatan tekanan darah terakhir;
- jadwal kontrol terdekat beserta hitung mundur;
- kondisi loading, kosong, gagal, dan tombol coba lagi;
- refresh dengan tarik ke bawah.

Saat beranda dimuat, aplikasi memanggil `ensure_doses(7)` untuk menyusulkan dosis sampai tujuh hari ke depan.

### Jadwal obat dan konsumsi

- Melihat obat aktif dan obat nonaktif.
- Menambah obat sesuai resep.
- Autocomplete dari katalog obat setelah mengetik minimal dua karakter.
- Tetap dapat memasukkan nama obat secara bebas.
- Preset jadwal 1x, 2x, atau 3x sehari serta jadwal manual.
- Setiap obat memiliki satu sampai empat jam konsumsi yang berbeda.
- Mengubah nama, dosis, catatan, tanggal selesai, dan jam konsumsi.
- Menonaktifkan, mengaktifkan kembali, atau menghapus obat.
- Melihat daftar dosis hari ini.
- Mengubah status dosis yang sudah dicatat selama tanggal lokal dosis tersebut belum berakhir.

Aturan status dosis:

| Status | Perilaku |
| --- | --- |
| Belum waktunya | Belum dapat dicatat sebelum 60 menit menjelang jadwal |
| Waktunya minum | Dapat ditandai mulai 60 menit sebelum hingga 120 menit sesudah jadwal |
| Terlambat | Masih dapat dicatat setelah jendela utama, selama tanggal lokal belum berakhir |
| Sudah minum | Status `taken`; waktu minum diisi oleh server |
| Dilewati | Status `skipped` |
| Terlewat | Dosis `pending` dari tanggal lampau; dihitung tidak patuh dan tidak dapat diubah |

Dosis dibuat oleh database, bukan diinput langsung oleh aplikasi. Pemanggilan pembuatan dosis bersifat idempoten sehingga tidak membuat baris duplikat.

### Jadwal kontrol

- Menambah jadwal kontrol dengan judul, fasilitas kesehatan, dokter/petugas, waktu, dan catatan.
- Melihat tab **Akan datang** dan **Riwayat**.
- Melihat hitung mundur jadwal.
- Mengubah dan menghapus jadwal.
- Menandai kontrol sebagai selesai atau dibatalkan.
- Menjadwalkan ulang atau membatalkan pengingat secara otomatis setelah perubahan.

### Tekanan darah

- Mencatat sistolik, diastolik, nadi opsional, waktu pengukuran, dan catatan.
- Menampilkan label dan anjuran edukatif sebelum data disimpan.
- Mengubah dan menghapus catatan.
- Melihat riwayat berdasarkan rentang waktu dan kategori.
- Menampilkan kategori yang dihitung oleh database dari nilai sistolik dan diastolik.

Kategori tekanan darah dievaluasi dari atas ke bawah:

| Kategori | Kondisi |
| --- | --- |
| Sangat tinggi | Sistolik >= 180 atau diastolik >= 120 |
| Tinggi | Sistolik 140-179 atau diastolik 90-119 |
| Rendah | Sistolik < 90 atau diastolik < 60 |
| Waspada | Sistolik 120-139 atau diastolik 80-89 |
| Normal | Selain kondisi di atas |

Label tersebut bersifat edukatif dan tidak boleh dipakai sebagai diagnosis mandiri.

### Statistik

Tersedia tiga periode:

- **Harian:** data hari ini.
- **Mingguan:** tujuh hari terakhir termasuk hari ini.
- **Bulanan:** 28 hari terakhir dalam empat blok tujuh hari.

Statistik menampilkan:

- persentase kepatuhan berdasarkan dosis jatuh tempo;
- jumlah dosis diminum dan jumlah dosis jatuh tempo;
- rata-rata sistolik dan diastolik;
- jumlah pengukuran tekanan darah;
- grafik batang kepatuhan untuk periode mingguan/bulanan;
- grafik garis tren tekanan darah;
- keadaan kosong jika belum ada data.

Kepatuhan berbeda dari ring progres di beranda. Kepatuhan hanya memakai dosis yang sudah jatuh tempo, sedangkan ring beranda membandingkan dosis diminum dengan seluruh dosis hari ini.

### Profil dan pengaturan

- Melihat dan mengubah nama serta tahun lahir.
- Memilih tema terang, gelap, atau mengikuti sistem.
- Mengaktifkan atau menonaktifkan pengingat obat.
- Mengaktifkan atau menonaktifkan pengingat kontrol.
- Membuka petunjuk optimasi baterai perangkat.
- Melihat informasi aplikasi.
- Menghapus akun dengan konfirmasi.
- Keluar dan membatalkan seluruh notifikasi terjadwal.

## Teknologi

| Bagian | Teknologi |
| --- | --- |
| Aplikasi | Flutter dan Dart |
| Platform utama | Android |
| Backend | Supabase |
| Autentikasi | Supabase Auth |
| Database | PostgreSQL melalui Supabase |
| Otorisasi | Row Level Security (RLS) |
| Komunikasi data | `supabase_flutter` |
| Grafik | `fl_chart` |
| Notifikasi lokal | `flutter_local_notifications` |
| Zona waktu | `timezone` dan `flutter_timezone` |
| Penyimpanan lokal | `shared_preferences` |
| Format tanggal | `intl` |
| Tipografi | Poppins yang dibundel di `assets/fonts` |

Dependensi utama dapat dilihat di [`pubspec.yaml`](pubspec.yaml). Kode aplikasi menggunakan pemisahan feature sederhana dengan repository, controller, model, dan halaman presentasi.

## Struktur direktori

```text
.
├── assets/
│   ├── fonts/                 # Font Poppins dan lisensinya
│   └── images/logo.png        # Logo aplikasi
├── docs/
│   └── PRD_KontrolSehat.md    # Spesifikasi produk dan aturan bisnis lengkap
├── lib/
│   ├── core/                  # Tema, konfigurasi, utilitas, error, widget umum
│   ├── features/
│   │   ├── appointment/       # Jadwal kontrol
│   │   ├── auth/              # Login, registrasi, sesi
│   │   ├── bp/                # Catatan dan riwayat tekanan darah
│   │   ├── home/              # Beranda dan ringkasan
│   │   ├── medication/        # Obat, jam obat, dan dosis
│   │   ├── notifications/     # Penjadwalan notifikasi lokal
│   │   ├── onboarding/        # Onboarding
│   │   ├── profile/           # Profil dan pengaturan
│   │   ├── shell/             # Navigasi utama
│   │   ├── splash/            # Splash screen
│   │   └── stats/             # Statistik dan grafik
│   ├── app.dart               # MaterialApp dan tema global
│   └── main.dart              # Inisialisasi konfigurasi, notifikasi, dan Supabase
├── supabase/
│   ├── 01_schema.sql          # Skema, trigger, RLS, grant, dan RPC
│   ├── 02_seed_demo.sql       # Seed demo relatif terhadap tanggal eksekusi
│   ├── 03_verifikasi.sql      # Verifikasi RLS, hak anon, dan klasifikasi TD
│   └── 04_seed_demo_*.sql     # Dataset demo tanggal tetap, bila diperlukan
├── env.example.json            # Contoh konfigurasi lokal
├── analysis_options.yaml       # Aturan analisis Dart
└── pubspec.yaml                # Dependensi dan metadata Flutter
```

## Prasyarat

Siapkan hal berikut sebelum menjalankan proyek:

- Flutter SDK pada channel stable.
- Dart SDK yang memenuhi constraint `^3.13.7` pada `pubspec.yaml`.
- Android Studio atau Android SDK yang dapat menjalankan perangkat/emulator Android.
- JDK yang kompatibel dengan konfigurasi Android Gradle proyek, yaitu Java 17.
- Proyek Supabase aktif.
- Perangkat atau emulator Android dengan koneksi internet.

Target proyek adalah Android. Dukungan iOS, web, dan desktop bukan bagian dari versi ini.

## Konfigurasi Supabase

### 1. Buat proyek Supabase

Buat atau gunakan satu proyek Supabase untuk aplikasi. Ambil:

- **Project URL**, misalnya `https://PROJECT_REF.supabase.co`;
- **Publishable key**, yaitu kunci yang diawali `sb_publishable_`.

Jangan gunakan `sb_secret_` atau `service_role` di aplikasi. Kunci publishable memang boleh dikirim ke aplikasi client, tetapi keamanan data tetap bergantung pada RLS dan kebijakan database.

### 2. Jalankan skema

Di **Supabase Dashboard > SQL Editor**, jalankan:

1. [`supabase/01_schema.sql`](supabase/01_schema.sql) satu kali.
2. Pastikan konfigurasi Authentication sesuai kebutuhan demo. Alur aplikasi mengharapkan registrasi dapat langsung digunakan; bila konfirmasi email diaktifkan, pengguna perlu menyelesaikan konfirmasi sesuai konfigurasi Supabase.
3. Opsional: jalankan [`supabase/03_verifikasi.sql`](supabase/03_verifikasi.sql) per blok A, B, C, lalu D. Hasil yang diharapkan:
   - RLS aktif pada tujuh tabel;
   - query hak akses `anon` tidak mengembalikan baris;
   - seluruh 22 kasus klasifikasi tekanan darah menghasilkan `ok = true`.

Skema membuat tabel berikut:

- `profiles`
- `medicine_catalog`
- `medications`
- `medication_times`
- `medication_logs`
- `appointments`
- `bp_records`

Skema juga membuat trigger, constraint, RLS, grant per kolom, dan RPC berikut:

- `ensure_doses(p_days_ahead)`
- `apply_schedule_change(p_medication_id, p_times)`
- `adherence_by_day(p_from, p_to)`
- `delete_my_account()`

### 3. Konfigurasi Authentication

Aplikasi menggunakan Supabase Auth dengan email dan password. Kebijakan password yang diterapkan aplikasi adalah:

- minimal 8 karakter;
- mengandung minimal satu huruf;
- mengandung minimal satu angka.

Samakan kebijakan password di pengaturan Authentication Supabase agar validasi aplikasi dan backend konsisten.

## Konfigurasi lokal

Salin [`env.example.json`](env.example.json) menjadi `env.json`, lalu isi dengan URL dan publishable key proyek Supabase:

```json
{
  "SUPABASE_URL": "https://PROJECT_REF.supabase.co",
  "SUPABASE_KEY": "sb_publishable_ISI_KUNCI_PUBLISHABLE"
}
```

`env.json` diabaikan oleh Git. Jangan commit file tersebut atau menuliskan kunci Supabase di source code.

Aplikasi hanya membaca konfigurasi ketika dijalankan dengan `--dart-define-from-file=env.json`. Jika konfigurasi tidak tersedia atau berisi kunci terlarang, aplikasi menampilkan halaman kesalahan konfigurasi.

## Instalasi dan menjalankan aplikasi

Dari root proyek:

```bash
flutter pub get
flutter analyze
flutter run --dart-define-from-file=env.json
```

Untuk memilih perangkat tertentu:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=env.json
```

Aplikasi akan memulai alur berikut:

1. inisialisasi konfigurasi dan tema;
2. inisialisasi notifikasi lokal;
3. inisialisasi Supabase;
4. memulihkan sesi login;
5. menampilkan onboarding, login, atau beranda sesuai keadaan sesi.

## Membuat APK Android

Build debug:

```bash
flutter build apk --debug --dart-define-from-file=env.json
```

Build release untuk demo/pengujian:

```bash
flutter build apk --release --dart-define-from-file=env.json
```

Konfigurasi release saat ini masih menggunakan signing debug pada [`android/app/build.gradle.kts`](android/app/build.gradle.kts). APK tersebut **belum disiapkan sebagai artefak produksi**. Untuk distribusi resmi, tambahkan konfigurasi signing release yang aman dan jangan memasukkan keystore ke repository.

## Data demo

### Seed relatif terhadap hari eksekusi

Setelah akun demo terdaftar melalui aplikasi, ubah nilai `v_email` di [`supabase/02_seed_demo.sql`](supabase/02_seed_demo.sql), lalu jalankan file tersebut di SQL Editor.

Seed ini membuat ulang data simulasi akun tersebut, yaitu:

- tiga obat aktif;
- empat dosis per hari;
- riwayat dosis sekitar 28 hari;
- 22 catatan tekanan darah dengan tren menurun;
- satu kontrol selesai dan dua kontrol akan datang.

Seed ini menghapus data simulasi pada akun yang dituju sebelum mengisinya kembali. Jangan menjalankannya pada akun yang menyimpan data penting.

### Dataset tanggal tetap

[`supabase/04_seed_demo_2026-11-09_13.sql`](supabase/04_seed_demo_2026-11-09_13.sql) adalah dataset demo terpisah untuk tanggal 9-13 November 2026. File ini hanya boleh dipakai bila alur demo memang membutuhkan tanggal tetap. Jangan mencampurnya dengan `02_seed_demo.sql` pada akun yang sama karena kedua script memiliki tujuan dataset yang berbeda.

## Alur demo singkat

1. Daftarkan atau login dengan akun demo.
2. Tunjukkan Beranda dan kartu ringkasan.
3. Tandai satu dosis sebagai `Sudah minum`.
4. Buka `Catat TD`, masukkan contoh 150/95, lalu tunjukkan label `Tinggi` dan anjuran edukatif.
5. Tambahkan jadwal kontrol dan tunjukkan hitung mundurnya.
6. Buka Statistik, lalu pindah antara periode Mingguan dan Bulanan.
7. Uji notifikasi dari profil pada mode debug atau tunggu jadwal notifikasi yang sudah disiapkan.

Untuk pengujian notifikasi, Android dapat meminta dua izin berbeda:

- izin notifikasi, terutama pada Android 13 ke atas;
- izin alarm tepat waktu.

Jika izin alarm tepat waktu tidak diberikan, aplikasi menggunakan mode alarm yang tidak eksak. Penghemat baterai dari beberapa merek perangkat juga dapat menunda notifikasi. Gunakan menu **Profil > Optimasi baterai & pengingat** untuk membuka petunjuk pengaturan perangkat.

## Aturan waktu dan zona waktu

- Waktu disimpan di backend sebagai UTC.
- Zona waktu profil disimpan sebagai nama zona IANA.
- Zona waktu diambil dari perangkat saat registrasi.
- Zona waktu profil menjadi acuan untuk menentukan hari dosis dan notifikasi.
- Pergantian zona waktu perangkat tidak dimaksudkan untuk menggeser tanggal dosis yang sudah dibuat.
- Dosis yang tidak dibuat ketika aplikasi tidak dibuka akan disusulkan saat `ensure_doses` dipanggil kembali dan dapat menjadi dosis terlewat.

## Keamanan dan privasi

Implementasi keamanan utama:

- autentikasi ditangani Supabase Auth;
- password tidak disimpan oleh aplikasi;
- semua tabel data memakai RLS;
- pengguna hanya dapat mengakses data miliknya sendiri;
- peran `anon` tidak diberi hak pada tabel aplikasi;
- identitas pengguna pada RPC diambil dari `auth.uid()`;
- komunikasi backend menggunakan HTTPS melalui URL Supabase;
- aplikasi hanya memakai publishable key;
- data kesehatan tidak ditulis ke log pada build release;
- notifikasi menggunakan visibilitas privat pada layar kunci;
- aplikasi tidak meminta lokasi, kontak, NIK, atau nomor BPJS.

Data yang disimpan mencakup email melalui Supabase Auth, profil dasar, obat dan jadwalnya, status konsumsi, tekanan darah, serta jadwal kontrol. Data tersebut dapat diubah atau dihapus oleh pemilik akun sesuai fitur aplikasi.

## Batasan versi ini

Fitur berikut belum termasuk dalam ruang lingkup versi ini:

- admin atau tenaga kesehatan;
- integrasi SIMRS, puskesmas, BPJS, atau sistem fasilitas kesehatan;
- diagnosis dan rekomendasi dosis;
- pengingat push dari server;
- mode offline penuh dan sinkronisasi konflik;
- integrasi tensimeter Bluetooth;
- ekspor PDF;
- lupa password melalui email;
- login sosial;
- aplikasi iOS dan web;
- penggunaan untuk data pasien nyata.

Notifikasi lokal juga bergantung pada izin Android, pengaturan alarm, kondisi perangkat, dan kebijakan penghemat baterai produsen.

## Pemeriksaan kualitas

Perintah pemeriksaan statis utama:

```bash
flutter analyze
```

Pemeriksaan database dilakukan melalui [`supabase/03_verifikasi.sql`](supabase/03_verifikasi.sql). Saat ini repository berfokus pada aplikasi Flutter dan script SQL; tidak ada direktori test Dart khusus yang menjadi bagian dari proyek.

Dokumentasi kebutuhan dan aturan bisnis yang lebih rinci tersedia di [`docs/PRD_KontrolSehat.md`](docs/PRD_KontrolSehat.md).

## Lisensi dan status proyek

Proyek ini dibuat untuk kebutuhan akademik dan demonstrasi. Lisensi distribusi publik belum ditentukan. Font Poppins yang dibundel menyertakan informasi lisensi di [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt).
