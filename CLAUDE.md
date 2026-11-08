# CLAUDE.md — KontrolSehat

Berkas ini adalah aturan kerja untuk Claude (Claude Code atau chat) pada repositori ini.
Baca seluruhnya sebelum mengubah apa pun. Bila aturan di sini bertentangan dengan permintaan
pengguna, sampaikan pertentangannya dan tanyakan, jangan diam-diam memilih salah satu.

## 1. Proyek

- **Nama:** KontrolSehat, aplikasi Android (Flutter) pengingat obat dan jadwal kontrol untuk pasien hipertensi.
- **Konteks:** Project Individu mata kuliah Teori Sistem Informasi Layanan Kesehatan (IF2371054). Penyusun: Mohammad Iqbal Maulana.
- **Penilaian dosen (bobot):** analisis masalah 15%, analisis pengguna dan kebutuhan 20%, perancangan sistem dan antarmuka 15%, **fungsi dan kelengkapan prototipe 25%**, keamanan dan privasi 10%, evaluasi dan presentasi 15%.
- **Prioritas tertinggi:** alur demo utama harus berjalan mulus dan tidak crash (PRD bagian 16). Stabil lebih penting daripada fitur tambahan.
- **Batas keras:** hanya data simulasi, satu peran (pasien), bukan alat diagnosis, tidak terhubung ke sistem rumah sakit, puskesmas, atau BPJS.
- Pengguna harus bisa menjelaskan setiap keputusan rancangan di depan dosen. Utamakan kode yang sederhana dan mudah dijelaskan daripada yang rumit.

## 2. Sumber kebenaran

Urutan prioritas bila ada perbedaan:

1. `docs/PRD_KontrolSehat.md`. **Bagian 8 (Aturan Bisnis) adalah acuan tunggal** untuk perilaku. Bagian 10 untuk validasi, bagian 11 untuk data.
2. Berkas SQL di `supabase/` (`01_schema.sql`, `02_seed_demo.sql`, `03_verifikasi.sql`).
3. Kode yang sudah ada.

Aturan:
- Sebelum mengerjakan fitur, baca bagian PRD yang relevan (kebutuhan `FR-xxx`, aturan bisnis, validasi, layar `Sxx`) dan sebut ID-nya saat melapor.
- Bila PRD dan SQL berbeda, **berhenti dan laporkan**. Jangan menebak. Pemilik proyek memutuskan mana yang diperbarui.
- Jangan mengarang aturan, angka, atau pesan error. Semua ada di PRD (bagian 10 dan 11.7).
- Jangan memodifikasi PRD atau SQL tanpa diminta. Bila perlu perubahan, usulkan dulu.

## 3. Lingkungan dan perintah

- Flutter 3.47.9 (stable), Dart 3.13.7. Target Android 8.0 (API 26) ke atas. Hanya Android.
- **Jangan menebak versi paket.** Pasang dengan `flutter pub add <paket>` agar Flutter memilih versi yang cocok. Jangan mengetik nomor versi manual di `pubspec.yaml`.
- Peringatan `deprecated_member_use` dari analyzer adalah petunjuk API terbaru: ikuti saran penggantinya (contoh: `Supabase.initialize` memakai `publishableKey`, bukan `anonKey`).
- Bila API paket tidak cocok dengan pengetahuanmu, baca dokumentasi paket di `~/.pub-cache` atau pub.dev. Jangan mengarang API.

```bash
flutter pub get
flutter analyze                     # harus bersih (nol masalah) sebelum selesai
dart format .                       # rapikan
flutter test                        # semua tes lulus
flutter run -d <id> --dart-define-from-file=env.json
flutter devices                     # daftar perangkat (HP fisik dan emulator)
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

- `env.json` berisi `SUPABASE_URL` dan `SUPABASE_KEY` (publishable). Contoh ada di `env.example.json`.
- Jangan menjalankan perintah yang merusak (`git reset --hard`, `git clean -fd`, `rm -rf` di luar `build/`) tanpa izin.

## 4. Stack

| Lapisan | Pilihan |
| --- | --- |
| UI | Flutter, Material 3, font Poppins dibundel di `assets/fonts` (tanpa `google_fonts`: paket itu bentrok dengan tipe `TextTheme` di Flutter 3.47) |
| State | `ChangeNotifier` + `ListenableBuilder` bawaan Flutter. **Tanpa paket state management tambahan** kecuali diminta |
| Backend | Supabase: Auth, PostgreSQL, RLS, RPC. Tanpa Realtime. Tanpa backend lain |
| Grafik | `fl_chart` |
| Notifikasi | `flutter_local_notifications` + `timezone` (lokal di perangkat, bukan push) |
| Penyimpanan lokal | `shared_preferences` hanya untuk tema, saklar pengingat, dan flag onboarding |

Menambah dependensi baru: tanyakan dulu. Setiap paket menambah ukuran APK (batas 60 MB, NFR-07) dan risiko.

## 5. Arsitektur dan struktur folder

Arsitektur berbasis fitur dengan tiga lapisan per fitur. Aliran dependensi **hanya satu arah**:

```
presentation (widget, controller)  ->  data (repository, model)  ->  Supabase
              \______________ core (utilitas murni, tema, widget bersama) ______________/
```

```
lib/
  main.dart               # bootstrap: validasi env, Supabase.initialize, Services.init
  app.dart                # MaterialApp, tema, AuthGate
  core/
    config/               # Env (dart-define)
    di/                   # Services (penyedia repository)
    errors/               # ErrorMapper (error teknis -> pesan Indonesia)
    theme/                # AppColors, AppTheme (token dari PRD 13.2)
    utils/                # Validators, bp_classifier, Fmt, DeviceTimezone  (Dart murni, tanpa Flutter)
    widgets/              # SoftCard, LoadingButton, RetryView, AppBackground, ResponsiveCenter
  features/
    auth/        data/ presentation/
    home/        data/ presentation/
    medication/  data/ presentation/   # obat, jam, dosis, konsumsi
    appointment/ data/ presentation/   # jadwal kontrol
    bp/          data/ presentation/   # tekanan darah
    stats/       data/ presentation/   # statistik dan grafik
    profile/     data/ presentation/
    notifications/                     # penjadwalan lokal (layanan, tanpa UI)
test/
  core/                   # tes unit untuk core/utils
  features/               # tes controller dengan repository palsu
docs/PRD_KontrolSehat.md
supabase/01_schema.sql  02_seed_demo.sql  03_verifikasi.sql
```

Aturan lapisan:
- **`core/utils` Dart murni.** Tidak mengimpor `flutter` atau `supabase`. Semua logika aturan bisnis yang bisa diuji (klasifikasi tekanan darah, kepatuhan, hitung mundur, validasi) tinggal di sini dan **wajib punya tes**.
- **`data/`** satu-satunya tempat yang mengenal Supabase. Repository menerima `SupabaseClient` lewat konstruktor, mengembalikan model Dart bertipe, dan melempar error apa adanya. Tidak ada widget, tidak ada `BuildContext`.
- **`presentation/`** tidak boleh memanggil `Supabase.instance` secara langsung. Halaman mengambil repository dari `Services`, lalu menyerahkannya ke controller lewat konstruktor.
- **Controller** (`ChangeNotifier`) memegang status (loading, ready, failed, kosong), memanggil repository, dan mengubah error lewat `ErrorMapper.message`. Controller tidak mengenal widget.
- **Fitur tidak mengimpor fitur lain secara langsung**, kecuali lewat repository atau model publiknya. Hindari impor melingkar.
- Berkas maksimal sekitar 300 baris. Pecah widget besar menjadi widget kecil bernama, bukan fungsi pembantu yang mengembalikan `Widget`.

## 6. Konvensi kode

- **Bahasa:** teks yang dilihat pengguna Bahasa Indonesia sederhana (PRD 13.6). Identifier kode Bahasa Inggris. Komentar Bahasa Indonesia dan menjelaskan *mengapa*, mengutip ID PRD bila relevan (misalnya `// FR-207`).
- Format tanggal `d MMM yyyy`, jam `HH:mm` 24 jam, desimal memakai koma (NFR-08). Gunakan `Fmt` di `core/utils/formatters.dart`.
- `const` di mana pun bisa. Impor relatif di dalam `lib/`. Satu tanda kutip. Koma di akhir (trailing comma).
- Tipe eksplisit untuk API publik. Tanpa `dynamic`. Tanpa `!` (null assertion) bila ada alternatif yang aman.
- Tanpa `print` (lint menjadikannya error). Data kesehatan tidak boleh ditulis ke log (SEC-08).
- Semua `async` yang melintasi `await` lalu memakai `BuildContext` harus memeriksa `mounted`.
- `dispose()` setiap controller, `TextEditingController`, `StreamSubscription`.
- Model data: kelas `final` immutable dengan `fromJson`. Nama kolom JSON persis seperti di PRD 11.2 (`snake_case`).
- Waktu: disimpan UTC di database. Tampilkan dan hitung memakai **zona waktu profil** (`profiles.timezone`), bukan zona perangkat (NFR-10). Gunakan paket `timezone` untuk konversi.
- Jangan membuat abstraksi spekulatif. Tambahkan lapisan hanya bila sudah ada dua pemakai.

## 7. Aturan data dan Supabase

Ini aturan yang paling mudah dilanggar. Database menegakkan aturan bisnis, aplikasi hanya memakainya.

- **Aplikasi tidak pernah membuat atau menghapus baris `medication_logs`.** Dosis dibuat oleh `ensure_doses` dan fungsi terkait. Aplikasi hanya `update ... set status` (`pending`, `taken`, atau `skipped`). `taken_at` diisi server. Jangan kirim `taken_at`.
- **Jam obat hanya ditulis lewat RPC `apply_schedule_change(p_medication_id, p_times)`.** Jangan `insert` atau `update` langsung ke `medication_times`.
- **Tambah obat adalah dua langkah:** `insert` ke `medications`, lalu `apply_schedule_change`. Bila langkah kedua gagal, **hapus obat yang baru dibuat** dan tampilkan Coba lagi (PRD 11.6, FR-302).
- **Panggil `ensure_doses(7)`** saat aplikasi dibuka, setelah login, dan sebelum membaca dosis atau statistik (FR-207). Fungsi ini idempoten (NFR-09).
- **Kolom yang tidak boleh dikirim aplikasi:** `id`, `user_id`, `created_at`, `schedule_from`, `taken_at`, `category`. `user_id` terisi otomatis dari `auth.uid()`. `category` adalah kolom turunan database.
- **Jangan menghitung ulang klasifikasi tekanan darah untuk disimpan.** Tampilkan label langsung dengan `classifyBp` sebelum simpan (FR-602), tetapi setelah simpan baca `category` dari baris hasil (FR-603).
- **Kepatuhan** dihitung dari RPC `adherence_by_day(p_from, p_to)` (maksimal 366 hari) memakai rumus PRD 8.2. Tanpa dosis jatuh tempo tampilkan "–", bukan 0 persen. Ring progres Beranda berbeda dari kepatuhan (8.2).
- "Terlewat" **tidak disimpan**. Statusnya dihitung dari `pending` pada tanggal yang sudah lewat (8.1).
- Tanggal mulai obat terkunci setelah dibuat. Mengubah jam, menonaktifkan, atau mengaktifkan obat tidak boleh mengubah dosis masa lalu (NFR-11). Itu sudah ditangani database. Jangan menambal di aplikasi.
- Tampilkan pesan error database dari daftar PRD 11.7 apa adanya. Pesan lain jadi pesan umum lewat `ErrorMapper`. Bila pesan "Tidak terautentikasi", kembalikan ke Login.
- Hapus akun lewat RPC `delete_my_account()`, lalu keluar dari sesi (FR-804).
- Saat perlu perubahan skema, ubah `supabase/01_schema.sql` dan PRD bagian 11 bersamaan, lalu jalankan ulang `03_verifikasi.sql`.

## 8. Keamanan dan privasi (PRD bagian 14)

Pelanggaran aturan ini tidak boleh dilakukan walau diminta.

1. Hanya kunci **publishable** (`sb_publishable_...`) yang boleh ada di aplikasi. **Jangan pernah** memakai atau menulis kunci `sb_secret_` atau `service_role`. `Env.isConfigured` menolaknya.
2. `env.json` tidak boleh di-commit. Hanya `env.example.json` yang boleh. Periksa `git status` sebelum commit.
3. Jangan menulis kunci, token, password, atau data kesehatan ke log, ke komentar, ke tes, atau ke jawaban obrolan.
4. Peran `anon` tidak punya hak apa pun. Semua tabel memakai RLS. Jangan menambahkan kebijakan atau `GRANT` longgar untuk "memudahkan".
5. Password tidak disimpan atau dicatat aplikasi. Pesan login gagal tidak menyebut mana yang salah (FR-102).
6. Jangan mengumpulkan lokasi, kontak, NIK, atau nomor BPJS (SEC-05). Jangan menambahkan analitik atau SDK pelacak.
7. Notifikasi berkunci visibilitas privat: layar kunci hanya "Waktunya minum obat" (SEC-09).
8. Pernyataan edukatif wajib di slide terakhir Onboarding dan layar Tentang (SEC-07). Teks persisnya ada di PRD.
9. Hasil klasifikasi tekanan darah adalah label edukatif. Jangan menulis teks yang memberi diagnosis atau saran dosis.
10. Validasi dilakukan di aplikasi **dan** di database. Jangan melonggarkan validasi di aplikasi dengan alasan "database akan menolak".

## 9. Performa (optimasi)

- Daftar panjang pakai `ListView.builder`. Jangan membungkus daftar dalam `Column` di dalam `SingleChildScrollView`.
- Widget statis harus `const`. Pecah widget supaya `setState` atau `notifyListeners` hanya membangun ulang bagian yang berubah. Pakai `ListenableBuilder` pada subpohon sekecil mungkin.
- Jangan melakukan pekerjaan berat di `build()` (parsing, sorting, query). Hitung di controller dan simpan hasilnya.
- Satu pemuatan = sesedikit mungkin panggilan jaringan. Gabungkan permintaan independen dengan `Future.wait`. Katalog obat dimuat sekali per sesi dan disimpan di memori (PRD 11.6).
- Pilih kolom yang dibutuhkan saja pada `select`. Batasi rentang tanggal pada kueri dosis dan tekanan darah.
- Debounce autocomplete katalog obat (mulai setelah 2 huruf, PRD alur B).
- Grafik `fl_chart` dibungkus `RepaintBoundary`. Animasi non-esensial dimatikan bila pengguna meminta pengurangan animasi (PRD 13.2).
- Anggaran: Beranda menampilkan data dalam 2 detik pada Wi-Fi atau 4G dengan skeleton selama menunggu (NFR-01). APK rilis maksimal 60 MB (NFR-07). Rilis memakai `--split-per-abi`. Ukur, jangan menebak.
- Jangan mengoptimalkan sebelum ada masalah terukur. Utamakan kebenaran, lalu ukur dengan DevTools bila terasa lambat.

## 10. UI dan UX (PRD bagian 13)

- Ikuti token di `core/theme`. Warna, radius (kartu 24 dp, input 16 dp, tombol pil 52 dp), jarak kelipatan 8 dp, padding layar 20 dp. Jangan menulis warna atau ukuran mentah di widget. Tambahkan token bila perlu.
- Aksesibilitas wajib (NFR-03): teks isi minimal 16, area sentuh minimal 48x48 dp, kontras minimal 4,5:1, tata letak utuh sampai skala font 130 persen, **status tidak hanya dibedakan warna** (selalu ikon dan teks).
- Responsif (NFR-02): lebar 360 sampai 1024 dp tanpa overflow. Kurang dari 600 dp satu kolom, 600 dp ke atas dua kolom kartu. Gunakan `LayoutBuilder` atau `ResponsiveCenter`. Hindari ukuran tetap yang bisa overflow.
- Setiap layar data punya lima keadaan (13.5): memuat (skeleton), kosong (ilustrasi, satu kalimat, satu tombol ajakan), gagal ("Tidak ada koneksi. Coba lagi." + tombol, isian form tidak hilang), berhasil (snackbar singkat), aksi berbahaya (dialog konfirmasi tombol merah).
- Validasi di bawah kolom, langsung saat berinteraksi. Tombol Simpan tekanan darah nonaktif sampai valid (FR-601).
- Menandai dosis maksimal 2 ketukan dari Beranda (G2). Satu aksi utama per layar.
- Tombol yang memicu proses jaringan harus nonaktif selama proses (cegah kirim ganda). Pakai `LoadingButton`.

## 11. Notifikasi (F9)

- Lokal di perangkat. Jadwalkan 7 hari ke depan. Jadwalkan ulang saat aplikasi dibuka, setelah login, dan setelah setiap perubahan obat atau kontrol (FR-903).
- Obat: judul "Waktunya minum obat", isi "{nama obat}, {dosis}" pada versi penuh, versi publik hanya judul (SEC-09).
- Kontrol: dua notifikasi, H-1 pukul 18:00 dan 2 jam sebelum jam kontrol. Yang waktunya sudah lewat dilewati (FR-902).
- Batalkan notifikasi bila dosis dicatat, obat dinonaktifkan atau dihapus, kontrol selesai atau dihapus, pengingat dimatikan, atau logout (FR-904, FR-104).
- Gunakan ID notifikasi yang deterministik (turunan dari ID dosis atau kontrol dan jenisnya) agar bisa dibatalkan dan tidak ganda.
- Waktu mengikuti zona waktu profil, bukan zona perangkat (NFR-10).
- Izin Android 13+ dan alarm tepat waktu diminta setelah registrasi dengan penjelasan. Bila alarm tepat waktu ditolak, jadwalkan perkiraan dan beri tahu pengguna (FR-906).
- Harus bertahan setelah restart perangkat (FR-905). Wajib diuji di HP fisik, bukan hanya emulator. Sebagian merek menunda notifikasi (A5), jadi sediakan petunjuk penghemat baterai di Profil (S13).

## 12. Pengujian

- **Tes unit wajib** untuk semua logika di `core/utils`: klasifikasi (G4, minimal 22 kasus termasuk nilai batas), kepatuhan dan pembulatan, hitung mundur, validasi, pemetaan zona waktu.
- Controller diuji dengan repository palsu (kelas tulisan tangan yang mengimplementasikan antarmuka atau subclass). Tanpa paket mocking kecuali diminta.
- Jangan memanggil Supabase sungguhan dari `flutter test`.
- Uji manual terdokumentasi untuk G1 (notifikasi 10 dari 10), G2 (stopwatch), G3 (kepatuhan sama dengan hitungan manual pada data seed), G5 (dua akun, tidak ada kebocoran), G6 (kuesioner 5 responden), G7 (alur demo 3 kali tanpa crash).
- Setelah mengubah logika: `flutter analyze` dan `flutter test` harus bersih sebelum menyatakan selesai.
- **Lapor jujur.** Bila tidak bisa menjalankan analisis, tes, atau aplikasi (misalnya di lingkungan tanpa Flutter), katakan "belum dijalankan". Jangan menulis "sudah berjalan" atau "tes lulus" tanpa bukti.

## 13. Git

- Cabang utama `main`. Pekerjaan fitur di cabang `feat/<nama>`.
- Commit kecil dan fokus. Pesan commit Bahasa Indonesia singkat dengan awalan: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Sebelum commit: `git status`, pastikan tidak ada `env.json`, kunci, keystore, atau berkas `build/`.
- Jangan commit langsung hasil yang belum lulus `flutter analyze` dan `flutter test`.
- Jangan menulis ulang riwayat (`--force`, `rebase` publik) tanpa izin.
- Bila rahasia terlanjur ter-commit: lepas dari pelacakan, **ganti kuncinya** di Supabase, dan beri tahu pengguna. Mengubah `.gitignore` saja tidak cukup.

## 14. Urutan pengerjaan

Kerjakan berurutan, selesaikan satu sebelum pindah (prioritas M, lalu S, lalu C; fitur C dipangkas lebih dulu bila waktu mepet):

1. Fondasi: tema, konfigurasi, koneksi, error mapper, tes utilitas (**sudah ada**).
2. Auth: registrasi, login, sesi, logout (F1). Splash dan Onboarding (S01, S02).
3. Beranda: kartu obat berikutnya, ring progres, kartu tekanan darah, kartu kontrol (F2, F4).
4. Jadwal obat: daftar, form, katalog, preset frekuensi (F3).
5. Jadwal kontrol (F5).
6. Catat tekanan darah dan riwayat (F6).
7. Statistik dan grafik (F7).
8. Notifikasi (F9).
9. Profil dan pengaturan (F8). Tema gelap (C) paling akhir.
10. Pengujian, perbaikan, APK rilis, video demo.

## 15. Larangan

- Jangan menambah peran admin atau tenaga kesehatan, mode offline, notifikasi push, iOS, web, atau integrasi SIMRS dan BPJS (PRD bagian 5).
- Jangan memakai data pasien nyata, bahkan untuk uji.
- Jangan melewati RLS dengan RPC `SECURITY DEFINER` baru tanpa persetujuan.
- Jangan menyimpan data kesehatan di `shared_preferences`.
- Jangan menambahkan fitur di luar PRD tanpa diminta. Usulkan dulu.
- Jangan menyatakan fitur "selesai" bila kriteria penerimaan `FR-xxx`-nya belum terpenuhi.

## 16. Definisi selesai untuk satu fitur

- [ ] Semua `FR-xxx` berprioritas M pada fitur itu memenuhi kriteria penerimaannya.
- [ ] Validasi sesuai PRD bagian 10, pesan error persis seperti di PRD.
- [ ] Lima keadaan layar (memuat, kosong, gagal, berhasil, konfirmasi) tersedia.
- [ ] Tidak overflow pada lebar 360 dan 1024 dp, dan skala font 130 persen.
- [ ] Logika murni punya tes unit. `flutter analyze` bersih. `flutter test` lulus.
- [ ] Tidak ada rahasia atau data kesehatan di log, kode, atau commit.
- [ ] Dicoba di emulator dan, untuk notifikasi, di HP fisik.
- [ ] Laporan ke pengguna menyebut ID `FR-xxx` yang dikerjakan, apa yang diuji, dan apa yang **belum** diuji.

## 17. Cara bekerja

1. Pahami permintaan, baca bagian PRD yang relevan, dan lihat kode yang ada sebelum menulis.
2. Bila permintaan ambigu atau bertentangan dengan PRD, ajukan **satu** pertanyaan singkat. Bila jawabannya bisa diasumsikan dengan aman, nyatakan asumsi dalam satu baris lalu lanjut.
3. Kerjakan perubahan sekecil yang menyelesaikan masalah. Jangan merapikan kode lain di luar tugas.
4. Jalankan `dart format`, `flutter analyze`, dan `flutter test` bila tersedia.
5. Laporkan ringkas: apa yang berubah (berkas), mengapa, bagaimana diuji, apa yang belum diuji, dan langkah berikutnya. Jangan melebih-lebihkan.
