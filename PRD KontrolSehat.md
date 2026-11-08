# PRD KontrolSehat

*Aplikasi Mobile Pengingat Jadwal Kontrol dan Konsumsi Obat bagi Pasien Hipertensi*

Project Individu · Teori Sistem Informasi Layanan Kesehatan (IF2371054) · Penyusun: Mohammad Iqbal Maulana · Versi 2.2 (diselaraskan dengan SQL dan ketentuan tugas) · 8 November 2026

## 1. Ringkasan Produk

KontrolSehat adalah aplikasi Android (Flutter) untuk pasien hipertensi dewasa yang rutin kontrol ke fasilitas kesehatan tingkat pertama, misalnya puskesmas. Pasien memasukkan obat dan jadwal kontrol dari resepnya sendiri. Aplikasi lalu mengingatkan lewat notifikasi, mencatat tekanan darah, dan menampilkan kepatuhan serta tren tekanan darah. Aplikasi ini bukan alat diagnosis dan tidak menggantikan tenaga kesehatan.

| Item | Ketetapan |
| --- | --- |
| Nama produk | KontrolSehat |
| Platform | Android 8.0 (API 26) ke atas, dibangun dengan Flutter |
| Pengguna | Pasien hipertensi dewasa, satu peran saja (tanpa admin) |
| Backend | Supabase: Auth, PostgreSQL, Row Level Security (RLS), fungsi database (RPC). Realtime tidak dipakai pada versi ini |
| Bahasa antarmuka | Indonesia |
| Zona waktu | Semua waktu disimpan UTC; ditampilkan dan dihitung memakai zona waktu profil pengguna (bawaan Asia/Jakarta; diisi dari perangkat saat registrasi dan tidak berubah otomatis) |
| Konektivitas | Wajib online. Notifikasi pengingat dijadwalkan lokal di perangkat |
| Data | Data simulasi; bukan data pasien nyata |
| Sumber data obat dan kontrol | Dimasukkan sendiri oleh pasien dari resep atau kartu kontrol |

## 2. Masalah yang Diselesaikan

| No | Masalah pasien | Akibat | Jawaban produk |
| --- | --- | --- | --- |
| 1 | Lupa jam minum obat atau berhenti saat merasa sehat | Tekanan darah tidak terkontrol | Pengingat per jam dan pencatatan konsumsi (F3, F4, F9) |
| 2 | Lupa atau terlambat kontrol ulang | Pemantauan oleh tenaga kesehatan terputus | Pengingat H-1 dan 2 jam sebelum kontrol (F5, F9) |
| 3 | Catatan tekanan darah tidak rapi (buku atau ingatan) | Sulit dibaca saat kontrol | Catatan terstruktur dengan label otomatis dan riwayat (F6) |
| 4 | Tidak tahu perkembangan kepatuhannya | Motivasi menurun | Statistik harian, mingguan, bulanan (F7) |

**Proses layanan saat ini dan proses yang diusulkan**

| Tahap | Saat ini (tanpa aplikasi) | Dengan KontrolSehat |
| --- | --- | --- |
| Resep dan jadwal kontrol | Dokter menyerahkan resep dan menyebut jadwal kontrol; pasien mengingat atau mencatat di kertas | Pasien memasukkan obat dan jadwal kontrol dari resepnya ke aplikasi |
| Minum obat | Mengandalkan ingatan; dosis yang terlewat tidak tercatat | Pengingat per jam, pencatatan "Sudah minum" atau "Lewati", dosis terlewat tercatat otomatis |
| Pemantauan tekanan darah | Angka di buku atau tidak dicatat sama sekali | Catatan terstruktur dengan label otomatis dan grafik tren |
| Persiapan kontrol | Jadwal terlupa; riwayat sulit dijelaskan ke tenaga kesehatan | Pengingat H-1 dan 2 jam sebelum; riwayat kepatuhan dan tekanan darah dapat ditunjukkan di layar |
| Evaluasi diri | Tidak ada gambaran kepatuhan | Statistik harian, mingguan, dan bulanan |

Aplikasi tidak mengubah proses klinis di fasilitas kesehatan. Ia mendukung pemantauan mandiri pasien di luar fasilitas kesehatan.

## 3. Tujuan dan Metrik Keberhasilan

| ID | Tujuan | Target terukur | Cara mengukur |
| --- | --- | --- | --- |
| G1 | Pengingat obat tepat waktu | Notifikasi muncul paling lambat 1 menit dari jam jadwal pada 10 dari 10 percobaan | Uji manual di perangkat fisik |
| G2 | Pencatatan cepat | Menandai dosis maksimal 2 ketukan dari Beranda; mencatat tekanan darah maksimal 30 detik | Stopwatch pada 5 responden |
| G3 | Kepatuhan dihitung benar | Hasil aplikasi sama dengan hitungan manual pada data seed (selisih 0 poin persen) | Bandingkan dengan tabel hitung manual |
| G4 | Label tekanan darah benar | 100 persen benar pada 20 kasus uji (termasuk semua nilai batas) | Tabel kasus uji |
| G5 | Privasi data | 0 baris milik akun lain terbaca atau berubah pada semua tabel | Uji dua akun, termasuk upaya akses langsung ke API |
| G6 | Mudah dipakai | Rata-rata skor kuesioner minimal 4,0 dari 5 | Kuesioner 5 responden |
| G7 | Demo stabil | Alur demo pada bagian 16 selesai tanpa crash 3 kali berturut-turut | Uji berulang |

## 4. Pengguna dan Peran

**Persona: Bu Rina, 54 tahun.** Memakai ponsel Android, minum amlodipine sekali sehari, kontrol sebulan sekali di puskesmas. Ia sering lupa jadwal kontrol dan mencatat tekanan darah di buku. Ia butuh tulisan besar, tombol jelas, dan alur pendek.

**Hanya ada satu peran: Pasien.** Tidak ada admin dan tidak ada tenaga kesehatan di dalam aplikasi. Dokter dan apoteker hanya berperan di luar aplikasi (memberi resep dan jadwal kontrol); pasien sendiri yang memasukkannya ke aplikasi.

| Peran | Boleh | Tidak boleh |
| --- | --- | --- |
| Belum login | Melihat Onboarding, Login, Registrasi | Mengakses data apa pun |
| Pasien | Membuat, melihat, mengubah, menghapus data miliknya sendiri; membaca katalog obat | Melihat atau mengubah data pasien lain; mengubah katalog obat |

Katalog obat diisi pengembang lewat SQL seed, sehingga tidak ada fitur admin di aplikasi.

## 5. Ruang Lingkup

**Termasuk pada versi ini:**

- Akun (registrasi, login, logout, sesi)
- Beranda ringkas
- Jadwal obat dan pencatatan konsumsi
- Jadwal kontrol
- Catatan tekanan darah dengan label otomatis
- Statistik kepatuhan dan tren tekanan darah
- Profil dan pengaturan
- Notifikasi pengingat lokal
- Katalog obat hipertensi untuk autocomplete
- Data simulasi (seed)

**Tidak termasuk:**

- Peran selain pasien (tidak ada admin dan tidak ada tenaga kesehatan di dalam aplikasi)
- Integrasi SIMRS, BPJS, atau sistem fasilitas kesehatan
- Konsultasi, diagnosis, atau saran dosis
- Lupa password lewat email, login sosial
- iOS dan web
- Mode offline penuh
- Perangkat tensi bluetooth, ekspor PDF
- Notifikasi push dari server

## 6. Asumsi dan Batasan

1. **A1.** Seluruh data adalah data simulasi untuk tugas kuliah; aplikasi tidak dipakai untuk data pasien nyata.
2. **A2.** Konfirmasi email di Supabase dimatikan supaya registrasi langsung bisa masuk.
3. **A3.** Pengguna memasukkan obat sesuai resepnya; aplikasi tidak memverifikasi kebenaran resep.
4. **A4.** Notifikasi dijadwalkan di perangkat tempat pengguna sedang login. Perangkat lain tidak otomatis menerima pengingat.
5. **A5.** Sebagian merek ponsel (misalnya Xiaomi, Oppo) dapat menunda notifikasi karena penghemat baterai; pengguna diberi petunjuk mematikan pembatasan itu.
6. **A6.** Klasifikasi tekanan darah bersifat edukatif, bukan diagnosis.
7. **A7.** Ketepatan waktu minum tidak dinilai; dosis dianggap patuh bila dicatat "Sudah minum".
8. **A8.** Proyek Supabase tetap aktif selama pengujian dan demo.

9) **A9.** Proyek Supabase dibuat dengan opsi "Automatically expose new tables" nonaktif. Semua hak akses diberikan manual lewat `GRANT` di `01_schema.sql`, dan peran `anon` tidak punya hak apa pun.
10) **A10.** Aturan password (minimal 8 karakter, memuat huruf dan angka) dipasang di aplikasi dan di pengaturan Authentication Supabase (Minimum password length dan Password requirements). Fitur "Prevent use of leaked passwords" tidak dipakai karena khusus paket berbayar.
11) **A11.** Aplikasi memakai Publishable key (`sb_publishable_...`). Secret key tidak pernah dipakai di aplikasi atau repositori.
12) **A12.** Zona waktu profil ditetapkan saat registrasi dari perangkat dan tidak berubah otomatis, sehingga batas tanggal dosis tetap konsisten.
13) **A13.** Aplikasi memanggil `ensure_doses` setiap kali dibuka dan setelah login. Dosis pada hari-hari saat aplikasi tidak dibuka dibuat pada pemanggilan berikutnya dan terhitung terlewat.

## 7. Alur Pengguna

**Alur A: Pemakaian pertama**

1. Aplikasi dibuka. Bila sesi valid, langsung ke Beranda; bila tidak, tampil Onboarding (3 slide, bisa dilewati) lalu Login.
2. Pengguna memilih Daftar, mengisi nama, tahun lahir, email, password, lalu menekan Daftar.
3. Bila valid, akun dan profil dibuat dan pengguna masuk ke Beranda. Bila tidak, pesan error tampil di bawah kolom yang salah.
4. Aplikasi meminta izin notifikasi (Android 13 ke atas) dengan penjelasan singkat. Bila ditolak, Beranda menampilkan banner "Pengingat belum aktif" dengan tombol Aktifkan.
5. Beranda yang masih kosong menampilkan ajakan "Tambah obat pertama" dan "Tambah jadwal kontrol".

**Alur B: Menambah obat dari resep**

1. Buka tab Obat, tekan tombol Tambah.
2. Ketik nama obat. Setelah 2 huruf muncul saran dari katalog; pengguna memilih saran atau tetap mengetik bebas.
3. Isi dosis. Bila obat dipilih dari katalog, kekuatan umum tampil sebagai chip yang bisa diketuk; pengguna tetap boleh mengetik sendiri.
4. Pilih frekuensi (preset atau Atur manual, 1 sampai 4 jam).
5. Isi tanggal mulai (bawaan hari ini), tanggal selesai (opsional), catatan (opsional).
6. Tekan Simpan. Bila valid: obat dan jam tersimpan, dosis 7 hari ke depan dibuat, notifikasi dijadwalkan, lalu kembali ke daftar dengan pesan "Obat ditambahkan".

**Alur C: Konsumsi harian**

1. Notifikasi muncul pada jam dosis; diketuk membuka Beranda.
2. Pada kartu "Obat berikutnya", pengguna menekan "Sudah minum" (atau "Lewati").
3. Status berubah, ring progres bertambah, dan notifikasi dosis itu dibatalkan bila belum muncul.
4. Dosis yang tidak dicatat sampai pukul 23:59 menjadi "Terlewat" dan tidak dapat diubah lagi.

**Alur D: Mencatat tekanan darah**

1. Tekan tombol tengah di navigasi bawah.
2. Isi sistolik dan diastolik (nadi opsional); waktu bawaan adalah sekarang.
3. Saat kedua angka valid, label dan anjuran muncul langsung.
4. Tekan Simpan. Kartu tekanan darah di Beranda dan grafik di Statistik ikut diperbarui.

**Alur E: Jadwal kontrol**

1. Buka tab Kontrol, tekan Tambah, isi data, tekan Simpan.
2. Pengingat H-1 dan 2 jam sebelum jadwal dijadwalkan otomatis.
3. Setelah kontrol dilakukan, pengguna menekan "Tandai selesai" atau "Batalkan".

## 8. Aturan Bisnis

Aturan di bagian ini adalah acuan tunggal. Bila bagian lain tampak berbeda, bagian ini yang berlaku.

### 8.1 Dosis terjadwal dan statusnya

Satu **dosis** adalah satu baris pada tabel `medication_logs`: satu obat pada satu jam di satu tanggal. Baris dosis dibuat otomatis oleh fungsi `ensure_doses()` (bagian 11.4), bukan oleh pengguna. Pengguna hanya mengubah status; waktu minum (taken\_at) diisi oleh server. Status ditentukan dari data dan waktu saat ini:

| Status tampil | Syarat | Tombol |
| --- | --- | --- |
| Belum waktunya | Belum dicatat dan sekarang lebih awal dari 60 menit sebelum jam jadwal | Nonaktif |
| Waktunya minum | Belum dicatat dan sekarang antara 60 menit sebelum sampai 120 menit sesudah jam jadwal | "Sudah minum" dan "Lewati" aktif |
| Terlambat | Belum dicatat, lewat 120 menit dari jam jadwal, masih di tanggal yang sama | "Sudah minum" dan "Lewati" aktif |
| Sudah minum | `status = taken` | "Ubah" aktif sampai pukul 23:59 tanggal dosis |
| Dilewati | `status = skipped` | "Ubah" aktif sampai pukul 23:59 tanggal dosis |
| Terlewat | Tidak dicatat sampai tanggal berganti (setelah 23:59) | Tidak ada; tidak dapat diubah |

"Terlewat" tidak disimpan di database. Statusnya dihitung dari baris `pending` yang tanggalnya sudah lewat. Jendela 60 menit sebelum jadwal dan penguncian pukul 23:59 juga ditegakkan oleh database (trigger medication\_logs\_guard).

### 8.2 Dosis jatuh tempo dan kepatuhan

- **Dosis jatuh tempo** = dosis yang jam jadwalnya sudah lewat (jam jadwal ≤ sekarang) pada periode yang dihitung.
- **Kepatuhan** = jumlah dosis `taken` dibagi jumlah dosis jatuh tempo, dikali 100, dibulatkan ke bilangan bulat terdekat. Dosis `skipped` dan terlewat dihitung tidak patuh.
- Bila dosis jatuh tempo = 0, kepatuhan ditampilkan "–" (bukan 0 persen).
- **Ring progres Beranda** berbeda dari kepatuhan: ring = dosis `taken` hari ini dibagi semua dosis hari ini (termasuk yang belum jatuh tempo). Contoh: 4 dosis hari ini, 1 sudah diminum = 25 persen. Bila tidak ada dosis hari ini, ring diganti teks "Belum ada jadwal obat".

### 8.3 Pembuatan dosis

- Dosis dibuat dari tanggal mulai sampai 7 hari ke depan, tidak melewati tanggal selesai bila ada, dan hanya untuk jam yang tidak lebih awal dari `schedule_from` obat. Saat obat dibuat, `schedule_from` = waktu pembuatan. Contoh: obat ditambahkan pukul 15:00 dengan jam 08:00 dan 20:00 menghasilkan dosis 20:00 hari ini, bukan 08:00.
- Tanggal mulai tidak boleh sebelum hari ini saat obat ditambahkan dan tidak dapat diubah setelahnya.
- Mengubah jam obat tidak mengubah dosis yang sudah ada di masa lalu. Urutannya: (1) riwayat dilengkapi sampai akhir hari ini dengan jam lama, (2) `schedule_from` diisi sekarang dan jam diganti, (3) dosis `pending` di masa depan dihapus lalu dibuat ulang dengan jam baru. Jam baru yang sudah lewat hari ini tidak menghasilkan dosis terlewat.
- Menonaktifkan obat: riwayat dilengkapi sampai sekarang, lalu dosis `pending` di masa depan dihapus. Riwayat tetap.
- Mengaktifkan kembali obat: dosis baru hanya dibuat mulai saat itu; masa nonaktif tidak dihitung sebagai terlewat.
- Memajukan tanggal selesai: dosis `pending` setelah tanggal baru dihapus. Memperpanjang tanggal selesai: dosis baru hanya dibuat mulai saat itu.
- Dosis pada hari-hari saat aplikasi tidak dibuka dibuat saat `ensure_doses` dipanggil berikutnya, berstatus `pending` sehingga terhitung terlewat.
- Menghapus obat secara permanen menghapus jam dan seluruh dosisnya, sehingga tidak lagi masuk perhitungan kepatuhan.

### 8.4 Klasifikasi tekanan darah (label edukatif)

Dievaluasi dari atas ke bawah; kategori pertama yang cocok berlaku.

| Urutan | Kategori | Syarat (mmHg) |
| --- | --- | --- |
| 1 | Sangat tinggi | Sistolik ≥ 180 atau diastolik ≥ 120 |
| 2 | Tinggi | Sistolik 140 sampai 179 atau diastolik 90 sampai 119 |
| 3 | Rendah | Sistolik < 90 atau diastolik < 60 |
| 4 | Waspada | Sistolik 120 sampai 139 atau diastolik 80 sampai 89 |
| 5 | Normal | Selain di atas (sistolik < 120 dan diastolik < 80) |

Contoh: 85/80 = Rendah; 138/92 = Tinggi; 125/70 = Waspada; 118/78 = Normal.

Anjuran yang tampil bersama label (teks tetap, bukan diagnosis):

| Kategori | Teks anjuran |
| --- | --- |
| Normal | Tekanan darah dalam rentang normal. Lanjutkan pola hidup sehat dan minum obat sesuai anjuran dokter. |
| Waspada | Sedikit di atas normal. Ukur lagi secara teratur dan jaga pola hidup sehat. |
| Tinggi | Tekanan darah tinggi. Pastikan obat diminum sesuai resep dan konsultasikan ke tenaga kesehatan. |
| Sangat tinggi | Sangat tinggi. Duduk tenang dan ukur ulang setelah 5 menit. Bila tetap tinggi atau muncul nyeri dada, sesak, sakit kepala berat, atau lemah pada satu sisi tubuh, segera ke fasilitas kesehatan atau IGD. |
| Rendah | Lebih rendah dari batas umum. Bila pusing atau lemas, duduk atau berbaring dan hubungi tenaga kesehatan. |

### 8.5 Periode statistik

| Tab | Rentang | Grafik kepatuhan | Grafik tekanan darah |
| --- | --- | --- | --- |
| Harian | Hari ini | Daftar dosis hari ini dengan statusnya | Daftar pengukuran hari ini |
| Mingguan | 7 hari terakhir termasuk hari ini | 7 batang, satu per hari | Garis rata-rata harian (hari tanpa data dilewati) |
| Bulanan | 28 hari terakhir termasuk hari ini | 4 batang, tiap batang satu blok 7 hari berurutan | Garis rata-rata harian |

### 8.6 Hitung mundur kontrol

| Selisih tanggal kalender dari hari ini | Teks |
| --- | --- |
| 0 | "Hari ini, HH:mm" |
| 1 | "Besok, HH:mm" |
| 2 sampai 30 | "N hari lagi" |
| Lebih dari 30 | Tanggal lengkap, misalnya "12 Des 2026" |

## 9. Kebutuhan Fungsional

Prioritas: **M** = wajib (Must), **S** = sebaiknya (Should), **C** = bila sempat (Could). Seluruh fitur M harus berjalan pada demo.

### F1. Akun

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-101 | Registrasi | Dengan data valid (bagian 10) akun dan profil terbentuk dan pengguna langsung masuk Beranda; email yang sudah terdaftar menampilkan "Email sudah terdaftar" | M |
| FR-102 | Login | Email dan password benar membuka Beranda; bila salah tampil "Email atau password salah" (tidak menyebut mana yang salah) | M |
| FR-103 | Sesi bertahan | Setelah aplikasi ditutup dan dibuka lagi pengguna tetap masuk sampai logout; token diperbarui otomatis | M |
| FR-104 | Logout | Kembali ke Login dan semua notifikasi terjadwal di perangkat dibatalkan | M |

### F2. Beranda

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-201 | Sapaan | Tampil "Halo, {nama depan}!" | M |
| FR-202 | Kartu Obat berikutnya | Menampilkan dosis hari ini yang belum dicatat dengan jam paling awal, beserta statusnya (bagian 8.1) dan tombol "Sudah minum" dan "Lewati"; bila semua dosis hari ini sudah dicatat tampil "Semua obat hari ini sudah dicatat" | M |
| FR-203 | Ring progres | Menampilkan persentase dan teks "N dari M dosis" sesuai bagian 8.2; bergerak animasi saat berubah | M |
| FR-204 | Kartu tekanan darah terakhir | Menampilkan angka, label berwarna beserta ikon, dan waktu pengukuran; bila belum ada data tampil ajakan mencatat | M |
| FR-205 | Kartu kontrol terdekat | Menampilkan kontrol berstatus `upcoming` dengan waktu terdekat di masa depan beserta hitung mundur (bagian 8.6); bila tidak ada tampil ajakan menambah | M |
| FR-206 | Muat ulang | Tarik ke bawah memuat ulang semua kartu; skeleton tampil saat pemuatan pertama | M |
| FR-207 | Penyusulan dosis | Saat aplikasi dibuka dan setelah login, aplikasi memanggil ensure\_doses(7) sebelum menampilkan dosis; bila gagal tampil pesan sesuai NFR-05 | M |

### F3. Jadwal obat

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-301 | Daftar obat | Menampilkan obat aktif (nama, dosis, jam); obat nonaktif ada di bagian terpisah yang bisa dibuka | M |
| FR-302 | Tambah obat | Form sesuai bagian 10.2; saran katalog muncul setelah 2 huruf; boleh mengetik nama bebas; obat dan jam disimpan sebagai satu kesatuan (bila penyimpanan jam gagal, obat yang baru dibuat dihapus kembali) | M |
| FR-303 | Preset frekuensi | Pilihan: "1x sehari" (08:00), "2x sehari" (08:00 dan 20:00), "3x sehari" (08:00, 14:00, 20:00), "Atur manual" (1 sampai 4 jam). Jam hasil preset tetap bisa diubah | M |
| FR-304 | Ubah obat | Semua kolom bisa diubah kecuali tanggal mulai; perubahan jam dilakukan lewat apply\_schedule\_change dan mengikuti bagian 8.3 | M |
| FR-305 | Nonaktifkan dan aktifkan obat | Mengikuti bagian 8.3; mengaktifkan kembali membuat dosis ke depan lagi | M |
| FR-306 | Hapus permanen | Dialog konfirmasi menyebut bahwa riwayat konsumsi obat itu ikut terhapus; setelah konfirmasi, obat, jam, dan dosisnya hilang | S |

### F4. Pencatatan konsumsi

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-401 | Sudah minum | Meng`ubah status menjadi taken; taken_at diisi server dengan` waktu sekarang; hanya bisa pada status "Waktunya minum" atau "Terlambat" | M |
| FR-402 | Lewati | Mengisi `status = skipped`; aturan waktu sama dengan FR-401 | M |
| FR-403 | Ubah catatan | Status `taken` dan `skipped` bisa diganti satu sama lain atau dikembalikan ke `pending` sampai pukul 23:59 tanggal dosis; sesudahnya terkunci | S |
| FR-404 | Dosis terlewat | Dosis `pending` pada tanggal yang sudah lewat tampil "Terlewat" dan dihitung tidak patuh | M |

### F5. Jadwal kontrol

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-501 | Daftar kontrol | Tab "Akan datang" (status `upcoming` dan waktu belum lewat, urut terdekat) dan tab "Riwayat" (status `done`, `cancelled`, atau `upcoming` yang waktunya sudah lewat dengan lencana "Belum dikonfirmasi") | M |
| FR-502 | Tambah kontrol | Form sesuai bagian 10.3; waktu kontrol harus di masa depan | M |
| FR-503 | Ubah dan hapus | Ubah semua kolom; hapus dengan konfirmasi; pengingat dijadwalkan ulang atau dibatalkan | M |
| FR-504 | Konfirmasi hasil | Tombol "Tandai selesai" mengubah status `done`; "Batalkan" mengubah `cancelled`; pengingat yang tersisa dibatalkan | M |
| FR-505 | Hitung mundur | Tampil sesuai bagian 8.6 | M |

### F6. Tekanan darah

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-601 | Input | Form sesuai bagian 10.4; tombol Simpan nonaktif sampai input valid | M |
| FR-602 | Label langsung | Saat sistolik dan diastolik valid, kategori dan anjuran (bagian 8.4) tampil sebelum disimpan | M |
| FR-603 | Penyimpanan kategori | Kategori dihitung oleh database dari angka (kolom turunan), sehingga selalu konsisten | M |
| FR-604 | Ubah dan hapus catatan | Bisa diubah atau dihapus dengan konfirmasi; kategori ikut dihitung ulang | S |
| FR-605 | Riwayat | Daftar urut terbaru; filter rentang (7 hari, 30 hari, semua) dan kategori | M |

### F7. Statistik

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-701 | Tab periode | Tab Harian, Mingguan, Bulanan sesuai bagian 8.5 | M |
| FR-702 | Kartu ringkasan | Menampilkan: kepatuhan periode (bagian 8.2), rata-rata sistolik/diastolik periode (dibulatkan ke bilangan bulat), dan jumlah pengukuran | M |
| FR-703 | Grafik kepatuhan | Grafik batang sesuai bagian 8.5; nilai tampil saat batang diketuk | M |
| FR-704 | Grafik tekanan darah | Grafik garis sistolik dan diastolik; nilai tampil saat titik diketuk | M |
| FR-705 | Data kosong | Bila tidak ada data pada periode, tampil ilustrasi dan teks penjelas, bukan grafik kosong | M |

### F8. Profil dan pengaturan

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-801 | Lihat dan ubah profil | Nama dan tahun lahir bisa diubah dengan validasi bagian 10.1 | S |
| FR-802 | Tema | Pilihan Terang, Gelap, Ikuti sistem; disimpan di perangkat | C |
| FR-803 | Pengaturan pengingat | Saklar pengingat obat dan pengingat kontrol (disimpan di perangkat); bila izin sistem ditolak tampil tombol "Buka pengaturan sistem" dan petunjuk penghemat baterai | S |
| FR-804 | Hapus akun | Pengguna mengetik "HAPUS" untuk konfirmasi; seluruh data akun dan akun login terhapus (RPC `delete_my_account`); aplikasi kembali ke Login | S |
| FR-805 | Tentang | Menampilkan versi aplikasi dan pernyataan edukatif (bagian 14, SEC-07) | M |

### F9. Notifikasi

| ID | Kebutuhan | Kriteria penerimaan | Prioritas |
| --- | --- | --- | --- |
| FR-901 | Pengingat obat | Pada jam dosis tampil notifikasi berjudul "Waktunya minum obat" dengan isi "{nama obat}, {dosis}" | M |
| FR-902 | Pengingat kontrol | Dua notifikasi per kontrol: H-1 pukul 18:00 dan 2 jam sebelum jam kontrol; yang waktunya sudah lewat saat penjadwalan dilewati | M |
| FR-903 | Cakupan penjadwalan | Notifikasi dijadwalkan untuk 7 hari ke depan; dijadwalkan ulang saat aplikasi dibuka, setelah login, dan setelah setiap perubahan obat atau kontrol | M |
| FR-904 | Pembatalan | Notifikasi dibatalkan bila dosis sudah dicatat, obat dinonaktifkan atau dihapus, kontrol diselesaikan atau dihapus, pengingat dimatikan di pengaturan, atau pengguna logout | M |
| FR-905 | Bertahan setelah restart | Notifikasi terjadwal tetap berjalan setelah perangkat dihidupkan ulang | M |
| FR-906 | Izin | Izin notifikasi (Android 13 ke atas) dan alarm tepat waktu diminta setelah registrasi dengan penjelasan; bila izin alarm tepat waktu tidak diberikan, pengingat memakai waktu perkiraan dan pengguna diberi tahu | M |

## 10. Aturan Input dan Validasi

Validasi dilakukan di aplikasi (pesan langsung di bawah kolom) dan diulang di database (constraint atau trigger), sehingga data tetap benar walau API dipanggil langsung. Semua teks di-trim sebelum dicek.

### 10.1 Akun dan profil

| Kolom | Wajib | Aturan | Pesan error |
| --- | --- | --- | --- |
| Nama lengkap | Ya | 2 sampai 50 karakter | Nama harus 2 sampai 50 karakter |
| Tahun lahir | Ya | Bilangan bulat dari (tahun berjalan − 100) sampai (tahun berjalan − 18); pada 2026 berarti 1926 sampai 2008 | Tahun lahir tidak valid |
| Email | Ya | Format email valid, maksimal 254 karakter | Format email tidak valid |
| Password | Ya | Registrasi: minimal 8 karakter, memuat minimal 1 huruf dan 1 angka. Login: hanya wajib diisi | Password minimal 8 karakter dan memuat huruf serta angka |

### 10.2 Obat

| Kolom | Wajib | Aturan | Pesan error |
| --- | --- | --- | --- |
| Nama obat | Ya | 2 sampai 60 karakter | Nama obat harus 2 sampai 60 karakter |
| Dosis | Ya | 1 sampai 30 karakter, contoh "5 mg" atau "1 tablet" | Dosis wajib diisi, maksimal 30 karakter |
| Jam konsumsi | Ya | 1 sampai 4 jam, format 24 jam HH:mm, tidak boleh ada jam yang sama | Pilih 1 sampai 4 jam yang berbeda |
| Tanggal mulai | Ya | Bawaan hari ini; tidak boleh sebelum hari ini saat tambah. Saat ubah, kolom ini terkunci | Tanggal mulai tidak boleh sebelum hari ini |
| Tanggal selesai | Tidak | Sama dengan atau setelah tanggal mulai | Tanggal selesai tidak boleh sebelum tanggal mulai |
| Catatan | Tidak | Maksimal 200 karakter | Catatan maksimal 200 karakter |

### 10.3 Jadwal kontrol

| Kolom | Wajib | Aturan | Pesan error |
| --- | --- | --- | --- |
| Judul | Ya | Bawaan "Kontrol rutin"; 2 sampai 60 karakter | Judul harus 2 sampai 60 karakter |
| Fasilitas kesehatan | Ya | 2 sampai 80 karakter | Nama fasilitas harus 2 sampai 80 karakter |
| Dokter atau petugas | Tidak | Maksimal 60 karakter | Maksimal 60 karakter |
| Tanggal dan jam | Ya | Saat tambah harus lebih lambat dari sekarang; saat ubah bebas | Jadwal harus di masa depan |
| Catatan | Tidak | Maksimal 200 karakter | Catatan maksimal 200 karakter |

### 10.4 Tekanan darah

| Kolom | Wajib | Aturan | Pesan error |
| --- | --- | --- | --- |
| Sistolik | Ya | Bilangan bulat 70 sampai 250 | Sistolik harus 70 sampai 250 |
| Diastolik | Ya | Bilangan bulat 40 sampai 150 | Diastolik harus 40 sampai 150 |
| Hubungan sistolik dan diastolik | Ya | Sistolik harus lebih besar dari diastolik | Sistolik harus lebih besar dari diastolik |
| Nadi | Tidak | Bilangan bulat 30 sampai 200 | Nadi harus 30 sampai 200 |
| Waktu pengukuran | Ya | Bawaan sekarang; tidak lebih dari 5 menit ke masa depan | Waktu pengukuran tidak boleh di masa depan |
| Catatan | Tidak | Maksimal 200 karakter | Catatan maksimal 200 karakter |

## 11. Rancangan Data

Bagian ini mengikuti berkas SQL `01_schema.sql`, `02_seed_demo.sql`, dan `03_verifikasi.sql`. Bila ada perbedaan, perbarui salah satunya agar keduanya sama.

### 11.1 Relasi antar tabel

| Dari | Ke | Jenis | Perilaku hapus |
| --- | --- | --- | --- |
| `auth.users` | `profiles` | 1 ke 1 | Hapus akun menghapus profil |
| `profiles` | `medications` | 1 ke banyak | Ikut terhapus |
| `medications` | `medication_times` | 1 ke banyak (maks. 4) | Ikut terhapus |
| `medications` | `medication_logs` | 1 ke banyak. Kunci asing gabungan (`medication_id`, `user_id`) memastikan dosis selalu milik pemilik obat | Ikut terhapus |
| `profiles` | `appointments` | 1 ke banyak | Ikut terhapus |
| `profiles` | `bp_records` | 1 ke banyak | Ikut terhapus |
| `medicine_catalog` | (tidak ada) | Tabel acuan, hanya dibaca | Tidak berelasi |

### 11.2 Tabel dan kolom

**`profiles`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK | Sama dengan `auth.users.id`, on delete cascade |
| full\_name | text | Wajib, 2 sampai 50 karakter setelah trim |
| birth\_year | integer | Wajib, rentang bagian 10.1 (dicek trigger) |
| timezone | text | Wajib, nama zona IANA yang valid (dicek trigger), bawaan `Asia/Jakarta`; diisi dari zona waktu perangkat saat registrasi dan tidak berubah otomatis |
| created\_at | timestamptz | Bawaan `now()` |

**`medicine_catalog`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK | Bawaan `gen_random_uuid()` |
| name | text | Wajib, unik |
| drug\_class | text | Wajib |
| common\_strengths | text\[\] | Wajib, kekuatan umum untuk chip saran |

**`medications`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK |  |
| user\_id | uuid, FK `profiles.id` | Wajib, terisi otomatis dari `auth.uid()`, on delete cascade |
| name | text | Wajib, 2 sampai 60 |
| dosage | text | Wajib, 1 sampai 30 |
| notes | text | Opsional, maks. 200 |
| start\_date | date | Wajib; saat tambah tidak boleh sebelum hari ini; tidak dapat diubah setelah dibuat |
| end\_date | date | Opsional, sama dengan atau setelah start\_date |
| is\_active | boolean | Bawaan true |
| created\_at | timestamptz | Bawaan `now()`; tidak dapat diisi aplikasi |
| schedule\_from | timestamptz | Bawaan `now()`; dosis hanya dibuat untuk jam yang tidak lebih awal dari nilai ini (bagian 8.3); tidak dapat diisi aplikasi |

Kendala unik (`id`, `user_id`) dipakai oleh kunci asing gabungan pada `medication_logs`.

**`medication_times`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK |  |
| medication\_id | uuid, FK `medications.id` | Wajib, on delete cascade |
| time\_of\_day | time | Wajib, detik harus 0; unik per obat; maksimal 4 baris per obat (trigger). Hanya ditulis lewat `apply_schedule_change` |

**`medication_logs`** (satu baris = satu dosis)

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK |  |
| user\_id | uuid | Wajib; bersama `medication_id` membentuk kunci asing gabungan ke `medications` |
| medication\_id | uuid | Wajib, on delete cascade |
| scheduled\_at | timestamptz | Wajib; unik bersama `medication_id` |
| status | text | `pending`, `taken`, atau `skipped`; bawaan `pending` |
| taken\_at | timestamptz | Diisi server: wajib terisi bila `taken`, kosong bila bukan `taken` (constraint dan trigger) |

Indeks: (`user_id`, `scheduled_at`). Baris dibuat dan dihapus oleh sistem, bukan oleh aplikasi.

**`appointments`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK |  |
| user\_id | uuid, FK `profiles.id` | Wajib, terisi otomatis dari `auth.uid()`, on delete cascade |
| title | text | Wajib, 2 sampai 60, bawaan "Kontrol rutin" |
| facility | text | Wajib, 2 sampai 80 |
| doctor | text | Opsional, maks. 60 |
| scheduled\_at | timestamptz | Wajib; saat tambah harus di masa depan (trigger) |
| notes | text | Opsional, maks. 200 |
| status | text | `upcoming`, `done`, atau `cancelled`; bawaan `upcoming` |
| created\_at | timestamptz | Bawaan `now()` |

Indeks: (`user_id`, `scheduled_at`).

**`bp_records`**

| Kolom | Tipe | Aturan |
| --- | --- | --- |
| id | uuid, PK |  |
| user\_id | uuid, FK `profiles.id` | Wajib, terisi otomatis dari `auth.uid()`, on delete cascade |
| systolic | smallint | Wajib, 70 sampai 250 |
| diastolic | smallint | Wajib, 40 sampai 150, harus lebih kecil dari systolic |
| pulse | smallint | Opsional, 30 sampai 200 |
| measured\_at | timestamptz | Wajib, bawaan `now()`, tidak lebih dari 5 menit ke depan (trigger) |
| note | text | Opsional, maks. 200 |
| category | text | Kolom turunan (generated, stored) dari aturan bagian 8.4: `very_high`, `high`, `low`, `elevated`, `normal`; tidak dapat diisi aplikasi |

Indeks: (`user_id`, `measured_at` menurun).

### 11.3 Kebijakan RLS dan hak akses

RLS aktif pada semua tabel. Peran `anon` tidak punya hak apa pun. Pengguna login (`authenticated`) hanya mendapat hak berikut, dan setiap baris dibatasi pemiliknya (`user_id = auth.uid()`, atau `id = auth.uid()` pada `profiles`).

| Tabel | Baca | Tambah (kolom) | Ubah (kolom) | Hapus |
| --- | --- | --- | --- | --- |
| profiles | Milik sendiri | Tidak (dibuat trigger) | `full_name`, `birth_year`, `timezone` | Tidak (lewat `delete_my_account`) |
| medicine\_catalog | Semua pengguna login | Tidak | Tidak | Tidak |
| medications | Milik sendiri | `name`, `dosage`, `notes`, `start_date`, `end_date`, `is_active` | `name`, `dosage`, `notes`, `end_date`, `is_active` | Ya |
| medication\_times | Milik sendiri (lewat obat induk) | Tidak (lewat `apply_schedule_change`) | Tidak | Tidak |
| medication\_logs | Milik sendiri | Tidak (dibuat sistem) | Hanya `status` | Tidak (dihapus sistem) |
| appointments | Milik sendiri | Semua kolom isian | Semua kolom isian | Ya |
| bp\_records | Milik sendiri | Semua kolom isian | Semua kolom isian | Ya |

Kolom `id`, `user_id`, `created_at`, `schedule_from`, `taken_at`, dan `category` tidak dapat diisi langsung oleh aplikasi.

### 11.4 Fungsi dan trigger

Semua fungsi `SECURITY DEFINER` memakai `search_path` terkunci dan selalu mengambil identitas dari `auth.uid()`, bukan dari parameter.

**Fungsi yang dipanggil aplikasi (RPC, hanya untuk pengguna login):**

| Nama | Fungsi |
| --- | --- |
| `ensure_doses(p_days_ahead int default 7)` | Membuat baris dosis `pending` untuk obat aktif dari tanggal mulai sampai hari ini + `p_days_ahead` (0 sampai 30), tidak melewati tanggal selesai, hanya untuk jam ≥ `schedule_from`. Idempoten (`ON CONFLICT DO NOTHING`) sehingga aman dipanggil berulang dan otomatis menyusul hari-hari saat aplikasi tidak dibuka. Mengembalikan jumlah dosis baru |
| `apply_schedule_change(p_medication_id uuid, p_times time[])` | Satu-satunya cara mengisi atau mengubah jam obat. Memeriksa kepemilikan dan 1 sampai 4 jam berbeda berformat HH:mm; melengkapi riwayat sampai akhir hari ini dengan jam lama; mengisi `schedule_from` = sekarang; mengganti jam; menghapus dosis `pending` di masa depan; membuat ulang dosis 7 hari dengan jam baru. Satu transaksi |
| `adherence_by_day(p_from date, p_to date)` | Mengembalikan per tanggal lokal: `day`, `due` (dosis jatuh tempo), `taken` (dosis `taken`). Rentang maksimal 366 hari; berjalan dengan hak pengguna sehingga RLS berlaku. Dasar bagian 8.2 dan 8.5 |
| `delete_my_account()` | Menghapus baris `auth.users` milik pemanggil; seluruh data turunan terhapus lewat cascade |

**Fungsi internal (tidak dapat dipanggil aplikasi):** `_generate_doses(p_uid, p_days_ahead)` membuat dosis dan dipakai oleh `ensure_doses`, `apply_schedule_change`, serta trigger obat.

**Trigger:**

| Trigger | Pada | Fungsi |
| --- | --- | --- |
| `handle_new_user` | `auth.users` (setelah tambah) | Membuat `profiles` dari metadata registrasi (`full_name`, `birth_year`, `timezone`); zona waktu tidak valid diganti `Asia/Jakarta` |
| `profiles_validate` | `profiles` | Rapikan nama; tolak tahun lahir dan zona waktu yang tidak valid |
| `medications_before_write` | `medications` | Rapikan teks; saat tambah, tolak tanggal mulai sebelum hari ini; saat ubah, tolak perubahan pemilik dan tanggal mulai; sebelum status aktif atau tanggal selesai berubah, lengkapi riwayat dosis sampai sekarang; mengisi ulang `schedule_from` bila obat diaktifkan kembali atau tanggal selesai diperpanjang |
| `medications_after_update` | `medications` | Setelah obat dinonaktifkan atau tanggal selesai dimajukan, hapus dosis `pending` di masa depan yang tidak berlaku lagi |
| `medication_times_limit` | `medication_times` | Tolak jam kelima pada satu obat |
| `medication_logs_guard` | `medication_logs` | Tolak perubahan kolom selain status; tolak ubah dosis setelah tanggal lokalnya lewat (kunci 23:59); tolak penandaan lebih awal dari 60 menit sebelum jam jadwal; mengisi `taken_at` oleh server |
| `appointments_before_write` | `appointments` | Rapikan teks; saat tambah, tolak jadwal yang tidak di masa depan |
| `bp_before_write` | `bp_records` | Tolak waktu pengukuran lebih dari 5 menit ke depan |

Aturan khusus pengguna aplikasi pada trigger tidak berlaku untuk skrip admin atau seed yang dijalankan dari SQL Editor (tanpa `auth.uid()`).

### 11.5 Data seed

**Katalog obat (10 baris, hanya contoh untuk autocomplete, bukan rekomendasi terapi; pengguna wajib mengikuti resepnya):**

| Nama | Golongan | Kekuatan umum |
| --- | --- | --- |
| Amlodipine | Penghambat kanal kalsium | 5 mg, 10 mg |
| Captopril | Penghambat ACE | 12,5 mg, 25 mg, 50 mg |
| Lisinopril | Penghambat ACE | 5 mg, 10 mg |
| Ramipril | Penghambat ACE | 2,5 mg, 5 mg, 10 mg |
| Candesartan | Penghambat reseptor angiotensin | 8 mg, 16 mg |
| Valsartan | Penghambat reseptor angiotensin | 80 mg, 160 mg |
| Telmisartan | Penghambat reseptor angiotensin | 40 mg, 80 mg |
| Bisoprolol | Penyekat beta | 2,5 mg, 5 mg, 10 mg |
| Hidroklorotiazid | Diuretik | 25 mg |
| Furosemid | Diuretik | 40 mg |

**Akun demo:** didaftarkan lewat alur registrasi sungguhan (metadata nama dan tahun lahir) memakai email milik pengembang, lalu `02_seed_demo.sql` mengisi datanya. Tanggal selalu relatif terhadap hari skrip dijalankan, dan skrip aman dijalankan ulang.

| Data | Isi |
| --- | --- |
| Obat | 3 obat aktif, 4 dosis per hari: Amlodipine 5 mg (08:00), Captopril 25 mg (08:00 dan 20:00), Hidroklorotiazid 25 mg (07:00) |
| Riwayat dosis | 28 hari ke belakang; sebelum hari ini sekitar 85 persen `taken`, 8 persen `skipped`, 7 persen `pending` (terlewat); dosis hari ini dibiarkan `pending` untuk demo |
| Tekanan darah | 22 catatan dalam 28 hari dengan tren turun dari sekitar 152/96 ke sekitar 121/77, mencakup kategori Tinggi, Waspada, dan Normal |
| Kontrol | 1 selesai (14 hari lalu), 1 akan datang (3 hari lagi), 1 akan datang (30 hari lagi) |

Skrip seed mencetak jumlah dosis jatuh tempo, jumlah diminum, dan persentase kepatuhan; angka itu menjadi acuan uji G3.

### 11.6 Pemetaan operasi aplikasi ke database

| Operasi di aplikasi | Panggilan ke Supabase | Catatan |
| --- | --- | --- |
| Registrasi | `auth.signUp(email, password, data: {full_name, birth_year, timezone})` | Trigger membuat profil. Zona waktu dari perangkat |
| Login | `auth.signInWithPassword`, lalu `rpc ensure_doses(7)` |  |
| Aplikasi dibuka atau Beranda dimuat | `rpc ensure_doses(7)`, lalu `select` dosis hari ini beserta nama dan dosis obat | FR-207 |
| Tambah obat | `insert` ke `medications`, lalu `rpc apply_schedule_change(id, jam[])`, lalu jadwalkan notifikasi | Bila langkah kedua gagal, hapus obat yang baru dibuat agar tidak ada obat tanpa jam |
| Ubah nama, dosis, catatan, atau tanggal selesai | `update` pada `medications` | Tanggal mulai tidak dapat diubah |
| Ubah jam obat | `rpc apply_schedule_change(id, jam[])` | Jadwalkan ulang notifikasi |
| Nonaktifkan atau aktifkan obat | `update medications set is_active` | Trigger mengatur dosis |
| Hapus permanen obat | `delete` pada `medications` | Jam dan dosisnya ikut terhapus |
| Tandai dosis | `update medication_logs set status = 'taken' atau 'skipped' atau 'pending'` | `taken_at` diisi server |
| Jadwal kontrol | `insert`, `update`, `delete` pada `appointments` | Status lewat `update` |
| Catat tekanan darah | `insert` ke `bp_records` (systolic, diastolic, pulse, measured\_at, note) | Kategori dibaca dari baris hasil |
| Statistik | `rpc ensure_doses(7)`, lalu `rpc adherence_by_day(from, to)` dan `select` `bp_records` pada rentang |  |
| Katalog obat | `select` dari `medicine_catalog` | Disimpan sementara di memori selama sesi |
| Ubah profil | `update` pada `profiles` |  |
| Hapus akun | `rpc delete_my_account()`, lalu keluar dari sesi |  |

### 11.7 Pesan kesalahan dari database

Aplikasi menampilkan pesan berikut apa adanya (bahasa Indonesia) di snackbar atau di bawah kolom terkait.

| Pesan | Penyebab |
| --- | --- |
| Belum waktunya minum obat | Menandai dosis lebih awal dari 60 menit sebelum jadwal |
| Dosis ini sudah terkunci | Mengubah dosis setelah tanggalnya lewat |
| Data dosis tidak boleh diubah | Upaya mengubah kolom selain status |
| Maksimal 4 jam per obat | Jam kelima |
| Pilih 1 sampai 4 jam yang berbeda | Jam kosong, lebih dari 4, atau kembar |
| Jam harus dalam format HH:mm | Jam memuat detik |
| Obat tidak ditemukan | `apply_schedule_change` pada obat bukan milik pengguna |
| Tanggal mulai tidak boleh sebelum hari ini | Tambah obat dengan tanggal mulai lampau |
| Tanggal mulai tidak dapat diubah | Ubah obat dengan tanggal mulai berbeda |
| Jadwal harus di masa depan | Tambah kontrol dengan waktu lampau |
| Waktu pengukuran tidak boleh di masa depan | Pengukuran lebih dari 5 menit ke depan |
| Tidak terautentikasi | Sesi berakhir; aplikasi kembali ke Login |

## 12. Kebutuhan Nonfungsional

| ID | Aspek | Kebutuhan | Cara uji |
| --- | --- | --- | --- |
| NFR-01 | Performa | Beranda menampilkan data paling lambat 2 detik pada Wi-Fi atau 4G; skeleton tampil selama menunggu | Stopwatch pada 3 kali percobaan |
| NFR-02 | Responsif | Berfungsi tanpa overflow pada lebar 360 sampai 1024 dp; kurang dari 600 dp memakai 1 kolom, 600 dp ke atas memakai 2 kolom kartu | Emulator ponsel dan tablet |
| NFR-03 | Aksesibilitas | Teks isi minimal 16 sp; area sentuh minimal 48 × 48 dp; kontras teks minimal 4,5 : 1; tata letak utuh sampai skala font sistem 130 persen; status tidak hanya dibedakan warna (selalu ada ikon dan teks) | Pemeriksaan manual dan pengaturan font sistem |
| NFR-04 | Keamanan | Semua lalu lintas HTTPS; RLS aktif di semua tabel; aplikasi hanya memuat kunci `publishable (sb_publishable_...)` | Uji dua akun; periksa kode dan konfigurasi |
| NFR-05 | Ketahanan | Bila jaringan gagal tampil "Tidak ada koneksi. Coba lagi." dengan tombol Coba lagi; isian form tidak hilang | Matikan jaringan saat menyimpan |
| NFR-06 | Kompatibilitas | Android 8.0 (API 26) ke atas; diuji di 1 emulator dan 1 perangkat fisik | Uji perangkat |
| NFR-07 | Ukuran | APK rilis maksimal 60 MB | Cek ukuran berkas |
| NFR-08 | Format | Tanggal "d MMM yyyy", jam 24 jam "HH:mm", bahasa Indonesia, angka desimal memakai koma | Pemeriksaan visual |
| NFR-09 | Idempoten | Memanggil `ensure_doses()` berulang tidak membuat baris ganda | Panggil 3 kali, hitung baris |
| NFR-10 | Konsistensi waktu | Dosis dan notifikasi memakai zona waktu profil; berganti zona waktu perangkat tidak menggeser tanggal dosis yang sudah dibuat | Ubah zona waktu emulator |
| NFR-11 | Integritas riwayat | Mengubah jam, menonaktifkan, atau mengaktifkan kembali obat tidak mengubah status atau jumlah dosis pada hari-hari yang sudah lewat | Catat hasil adherence\_by\_day untuk 7 hari lampau, ubah jam obat, lalu bandingkan |
| NFR-12 | Verifikasi basis data | Berkas 03\_verifikasi.sql lulus: RLS aktif pada 7 tabel, peran anon tanpa hak, dan 22 kasus klasifikasi tekanan darah benar | Jalankan berkas di SQL Editor |

## 13. Spesifikasi UI/UX

### 13.1 Arah visual

Mengacu pada gambar referensi: gaya soft modern dengan latar gradien biru ke lavender, kartu putih bersudut sangat membulat dan bayangan tipis, ilustrasi 3D ramah pada onboarding dan keadaan kosong, judul besar tebal, ring dan grafik berwarna lembut, serta navigasi bawah dengan tombol tengah yang menonjol.

### 13.2 Design system

| Elemen | Spesifikasi |
| --- | --- |
| Warna utama | Ungu #6C4CE0 (tombol utama, ring progres, tab aktif). Teks putih di atasnya berkontras sekitar 5,6 : 1 |
| Aksen | Biru #4A9BF5 hanya untuk aksen, grafik, dan latar kartu statistik; teks di atas biru memakai navy #1E1B3A |
| Latar | Gradien vertikal #CFE3FF ke #E8E0FF |
| Permukaan kartu | Putih dengan opasitas 85 persen, radius 24 dp, bayangan lembut |
| Teks | Utama #1E1B3A; sekunder #5B5878 |
| Status tekanan darah | Chip bertinta dengan teks #1E1B3A dan ikon berwarna: Normal #DDF5EA, Waspada #FFF1CC, Tinggi #FFE0CC, Sangat tinggi #FFD6D6, Rendah #D6E8FF. Selalu disertai ikon dan kata, tidak hanya warna |
| Mode gelap (opsional) | Latar #12142B, kartu #1C1F3D, teks #F2F1FF, utama #A18BFF dengan teks gelap di atasnya |
| Tipografi | Poppins (dibundel di aset): judul layar 28 tebal, judul kartu 18 semi-tebal, isi 16, keterangan 14 |
| Tombol | Bentuk pil, tinggi 52 dp. Utama = ungu solid; sekunder = garis tepi ungu |
| Kolom input | Tinggi 56 dp, radius 16 dp, label di atas, pesan error di bawah |
| Jarak | Kelipatan 8 dp; padding layar 20 dp |
| Ikon | Satu set ikon outline membulat yang konsisten |
| Gerak | Transisi halaman 300 ms; ring progres 600 ms; angka menghitung naik 400 ms; skeleton berkilau saat memuat. Animasi non-esensial dimatikan bila pengguna mengaktifkan pengurangan animasi di sistem |

### 13.3 Navigasi

Navigasi bawah dengan lima slot: **Beranda · Obat · \[tombol tengah Catat TD\] · Kontrol · Statistik**. Tombol tengah berbentuk lingkaran biru yang menonjol dan membuka input tekanan darah (S10). Profil dibuka lewat avatar di pojok kanan atas Beranda.

### 13.4 Daftar layar

| ID | Layar | Isi utama | Keadaan khusus |
| --- | --- | --- | --- |
| S01 | Splash | Logo; memeriksa sesi (maksimal 2 detik) | Sesi valid ke S05; tidak valid ke S02 atau S03 |
| S02 | Onboarding | 3 slide: pengingat obat, catat tekanan darah, pantau progres; slide terakhir memuat pernyataan edukatif; tombol Lewati dan Mulai | Tampil hanya pada pemakaian pertama |
| S03 | Login | Email, password, tombol Masuk, tautan ke Registrasi | Error tampil di bawah kolom; tombol memuat saat proses |
| S04 | Registrasi | Nama, tahun lahir, email, password, tombol Daftar | Validasi langsung per kolom |
| S05 | Beranda | Sapaan, avatar, banner izin (bila perlu), kartu Obat berikutnya, ring progres, kartu TD terakhir, kartu kontrol terdekat | Skeleton, kosong (ajakan tambah obat dan kontrol), gagal muat (Coba lagi) |
| S06 | Daftar obat | Kartu per obat (nama, dosis, jam, status hari ini); bagian Nonaktif; tombol Tambah | Kosong dengan ilustrasi dan ajakan |
| S07 | Form obat | Kolom bagian 10.2, chip kekuatan dari katalog, preset frekuensi | Mode tambah dan ubah; tanggal mulai terkunci saat ubah |
| S08 | Daftar kontrol | Tab Akan datang dan Riwayat; kartu dengan hitung mundur | Kosong per tab; lencana "Belum dikonfirmasi" |
| S09 | Form kontrol | Kolom bagian 10.3 | Mode tambah dan ubah |
| S10 | Catat tekanan darah | Input angka besar, nadi opsional, waktu, kartu label dan anjuran langsung | Simpan nonaktif sampai valid |
| S11 | Statistik | Tab Harian, Mingguan, Bulanan; dua kartu ringkasan; grafik batang kepatuhan; grafik garis TD; tautan ke S12 | Kosong per periode |
| S12 | Riwayat TD | Daftar urut terbaru dengan filter rentang dan kategori | Kosong; ubah dan hapus per baris |
| S13 | Profil dan pengaturan | Ubah nama dan tahun lahir, tema, saklar pengingat, petunjuk penghemat baterai, Tentang, Hapus akun, Keluar | Konfirmasi untuk Hapus akun dan Keluar |

### 13.5 Keadaan standar pada setiap layar data

| Keadaan | Tampilan |
| --- | --- |
| Memuat | Skeleton sesuai bentuk kartu |
| Kosong | Ilustrasi 3D, satu kalimat penjelas, satu tombol ajakan |
| Gagal | "Tidak ada koneksi. Coba lagi." dengan tombol Coba lagi; data yang sudah diisi tidak hilang |
| Berhasil | Snackbar singkat, misalnya "Obat ditambahkan" |
| Aksi berbahaya | Dialog konfirmasi dengan tombol berwarna merah |

### 13.6 Prinsip UX

- Satu aksi utama per layar.
- Aksi tersering (menandai dosis) maksimal 2 ketukan dari Beranda.
- Bahasa Indonesia sederhana tanpa istilah medis berat.
- Umpan balik instan: animasi, getaran ringan, dan pesan singkat setelah menyimpan.

## 14. Keamanan dan Privasi

| ID | Kebutuhan |
| --- | --- |
| SEC-01 | Autentikasi memakai Supabase Auth; password tidak pernah disimpan atau dicatat oleh aplikasi |
| SEC-02 | Otorisasi memakai RLS sesuai bagian 11.3; hasilnya wajib lolos uji G5 |
| SEC-03 | Aplikasi hanya memuat kunci `publishable (sb_publishable_...). Kunci secret (sb_secret_...) dan` `service_role` tidak ada di aplikasi maupun repositori. Kunci konfigurasi tidak di-commit (dimasukkan lewat `--dart-define` atau berkas yang diabaikan git) |
| SEC-04 | Seluruh komunikasi dengan backend memakai HTTPS |
| SEC-05 | Data minimal: tidak mengumpulkan lokasi, kontak, NIK, atau nomor BPJS |
| SEC-06 | Pengguna dapat mengubah dan menghapus data serta seluruh akunnya (FR-801, FR-804) |
| SEC-07 | Pernyataan wajib pada slide terakhir Onboarding dan layar Tentang: "KontrolSehat membantu mencatat dan mengingatkan. Aplikasi ini tidak memberikan diagnosis atau saran pengobatan. Ikuti anjuran dokter atau tenaga kesehatan Anda. Seluruh data pada versi ini adalah data simulasi." |
| SEC-08 | Data kesehatan tidak ditulis ke log perangkat pada versi rilis |
| SEC-09 | Notifikasi berkunci visibilitas privat: pada layar kunci hanya tampil "Waktunya minum obat"; nama obat dan dosis tampil setelah perangkat dibuka |
| SEC-10 | Hak akses minimum: peran anon tanpa hak; pengguna login hanya mendapat hak per tabel dan per kolom sesuai bagian 11.3; fungsi internal tidak dapat dipanggil dari aplikasi |
| SEC-11 | Fungsi SECURITY DEFINER memakai search\_path terkunci dan mengambil identitas dari auth.uid(), bukan dari parameter yang dikirim aplikasi |
| SEC-12 | Kebijakan password: minimal 8 karakter, memuat huruf dan angka; dipasang di aplikasi dan di pengaturan Authentication Supabase |

**Data yang dikumpulkan, tujuan, dan perlindungannya**

| Data | Tujuan penggunaan | Perlindungan |
| --- | --- | --- |
| Email dan password | Masuk ke aplikasi | Dikelola Supabase Auth (password di-hash dan tidak disimpan aplikasi); HTTPS |
| Nama, tahun lahir, zona waktu | Sapaan, memastikan pengguna dewasa, menghitung tanggal dosis | RLS: hanya pemilik; dapat diubah dan dihapus |
| Obat, dosis, jam, catatan | Pengingat dan pencatatan konsumsi | RLS; dapat dihapus per obat atau bersama akun |
| Catatan konsumsi (status dan waktu minum) | Menghitung kepatuhan | RLS; pengguna hanya dapat mengubah status; terhapus bersama akun |
| Tekanan darah, nadi, catatan | Label, tren, dan statistik | RLS; dapat diubah dan dihapus |
| Jadwal kontrol (fasilitas, dokter, waktu) | Pengingat dan hitung mundur | RLS; dapat diubah dan dihapus |

Aplikasi tidak mengumpulkan lokasi, kontak, NIK, atau nomor BPJS.

**Fungsi dan batas penggunaan backend:** Supabase dipakai untuk autentikasi, penyimpanan data simulasi, dan penegakan aturan data (RLS, fungsi, trigger). Backend ini tidak terhubung ke sistem rumah sakit, puskesmas, atau BPJS, tidak menyimpan data pasien nyata, dan tidak memberi diagnosis atau saran pengobatan.

## 15. Matriks Keterlacakan

| Fitur | Kebutuhan | Data dan fungsi | Layar | Tujuan |
| --- | --- | --- | --- | --- |
| F1 Akun | FR-101 sampai FR-104 | `profiles`, `handle_new_user` | S01 sampai S04 | G5, G7 |
| F2 Beranda | FR-201 sampai FR-207 | `ensure_doses`, semua tabel | S05 | G2, G7 |
| F3 Jadwal obat | FR-301 sampai FR-306 | `medications`, `medication_times`, `medicine_catalog`, `apply_schedule_change` | S06, S07 | G1 |
| F4 Konsumsi | FR-401 sampai FR-404 | `medication_logs`, `medication_logs_guard` | S05, S06 | G2, G3 |
| F5 Kontrol | FR-501 sampai FR-505 | `appointments` | S08, S09 | G1 |
| F6 Tekanan darah | FR-601 sampai FR-605 | `bp_records` (kolom `category`) | S10, S12 | G2, G4 |
| F7 Statistik | FR-701 sampai FR-705 | `adherence_by_day`, `bp_records` | S11 | G3 |
| F8 Profil | FR-801 sampai FR-805 | `profiles`, `delete_my_account` | S13 | G5 |
| F9 Notifikasi | FR-901 sampai FR-906 | Penjadwalan lokal di perangkat | Semua | G1 |

## 16. Kriteria Selesai dan Alur Demo

**Produk dianggap selesai bila:**

- [ ] Seluruh kebutuhan berprioritas M lulus kriteria penerimaannya.
- [ ] Uji G1 sampai G7 sudah dijalankan dan hasilnya tercatat.
- [ ] Uji dua akun membuktikan tidak ada kebocoran data (G5).
- [ ] APK rilis terpasang dan berjalan di perangkat fisik.
- [ ] Skrip seed berjalan dan menghasilkan akun demo.
- [ ] Alur demo di bawah selesai 3 kali berturut-turut tanpa crash.

* [ ] `01_schema.sql` berjalan tanpa error di proyek Supabase.
* [ ] `03_verifikasi.sql` lulus: RLS aktif di 7 tabel, hasil pemeriksaan hak `anon` kosong, 22 kasus klasifikasi benar.
* [ ] `02_seed_demo.sql` berjalan dan angka kepatuhan yang dicetaknya dicatat untuk uji G3.

- [ ] Repositori Git berisi kode aplikasi, berkas SQL, dan README (cara menjalankan, tanpa kunci rahasia) dan tautannya siap dikumpulkan.

**Alur demo (sekitar 3 menit):**

1. Login dengan akun demo.
2. Tunjukkan Beranda: ring progres, kartu obat, kartu tekanan darah, kartu kontrol.
3. Tekan "Sudah minum" pada satu dosis; ring bertambah.
4. Catat tekanan darah 150/95; label "Tinggi" dan anjuran muncul.
5. Tambah jadwal kontrol; hitung mundur muncul.
6. Buka Statistik; pindah tab Mingguan ke Bulanan.
7. Tunjukkan notifikasi pengingat (dosis dijadwalkan 1 sampai 2 menit sebelum demo).

## 17. Pertanyaan Terbuka dan Risiko

| ID | Pertanyaan | Dampak bila jawabannya berbeda | Keputusan sementara |
| --- | --- | --- | --- |
| Q1 | Apakah satu peran (pasien) cukup menurut dosen? | Bila dosen mewajibkan lebih dari satu peran, diperlukan rancangan tambahan di luar PRD ini | Satu peran, sesuai dokumen tugas |
| Q2 | Apa format dan batas pengumpulan prototipe (APK, repositori, video)? | Menentukan paket rilis | APK dan video demo |
| Q3 | Adakah batasan teknologi pada dokumen tugas? | Bisa mengubah arsitektur | Flutter dengan Supabase |

| Risiko | Dampak | Penanganan |
| --- | --- | --- |
| Notifikasi ditunda penghemat baterai pada merek tertentu | Pengingat terlambat | Petunjuk di S13; uji di perangkat fisik; cadangan: demo di perangkat yang sudah diuji |
| Proyek Supabase tidak aktif | Aplikasi tidak bisa memuat data | Buka dashboard sebelum demo (A8) |
| Koneksi buruk saat demo | Demo gagal | Siapkan video demo cadangan |
| Kebijakan RLS keliru | Data bocor atau tidak terbaca | Uji dua akun sejak awal pengembangan |
| Kesalahan hitung zona waktu pada dosis | Kepatuhan salah | Uji NFR-10 dan data seed G3 |
| Waktu tidak cukup | Fitur tidak selesai | Kerjakan berurutan M, lalu S, lalu C; fitur C dipangkas lebih dulu |
| Penyimpanan obat dua langkah (insert obat lalu simpan jam) terputus di tengah | Ada obat tanpa jam | Bila langkah kedua gagal, aplikasi menghapus obat yang baru dibuat dan menampilkan Coba lagi |
| Pengaturan hak akses Supabase keliru (error permission denied) | Aplikasi tidak bisa membaca atau menulis data | Jalankan ulang bagian GRANT di 01\_schema.sql dan periksa dengan 03\_verifikasi.sql |
| Aplikasi tidak dibuka beberapa hari | Dosis hari-hari itu baru dibuat saat dibuka lagi | Disengaja: ensure\_doses menyusulnya sebagai terlewat; diuji lewat data seed |

## 18. Pengembangan Lanjutan

Bagian ini bukan bagian dari versi ini. Ia mencatat apa yang sengaja ditunda dan seberapa siap rancangan sekarang menampungnya.

| Pengembangan | Alasan ditunda | Kesiapan rancangan saat ini |
| --- | --- | --- |
| Notifikasi push dari server | Pengingat lokal sudah cukup dan tidak butuh server | Jadwal dosis sudah tersimpan di `medication_logs`, sehingga bisa menjadi sumber pemicu server |
| Mode offline | Butuh sinkronisasi dan penyelesaian konflik | `ensure_doses` idempoten dan dosis berbasis `scheduled_at` yang unik memudahkan sinkronisasi |
| Integrasi SIMRS dan BPJS | Di luar lingkup tugas dan butuh akses sistem fasilitas | Katalog obat dan catatan klinis terpisah sehingga mudah dipetakan |
| Perangkat tensi bluetooth | Butuh perangkat keras | `bp_records` sudah menyimpan nadi dan waktu; cukup menambah kolom sumber data (manual atau perangkat) |
| Ekspor laporan PDF untuk dibawa saat kontrol | Di luar prioritas | Riwayat dan statistik sudah tersedia lewat `bp_records` dan `adherence_by_day` |
| Lupa password lewat email dan login sosial | Butuh konfigurasi email dan penyedia | Supabase Auth mendukungnya tanpa mengubah skema |
| iOS dan web | Fokus pada Android | Flutter mendukungnya; notifikasi lokal perlu penyesuaian per platform |

## 19. Riwayat Versi

| Versi | Perubahan |
| --- | --- |
| 1.0 | Draf awal yang masih bercampur dengan isi laporan |
| 2.0 | PRD murni: aturan bisnis, kebutuhan, validasi, data, UI/UX, keamanan |
| 2.1 | Diselaraskan dengan berkas SQL: hak akses per kolom, `schedule_from`, fungsi dan trigger yang sebenarnya, pemetaan operasi aplikasi ke database, pesan kesalahan, penyusulan dosis (FR-207), kunci publishable, akun demo lewat registrasi, bagian pengembangan lanjutan |
| 2.2 | Menegaskan satu peran (pasien) dan menghapus peran tenaga kesehatan dari rencana lanjutan; menambah tabel proses layanan saat ini dan usulan, tabel data yang dikumpulkan beserta perlindungannya, batas penggunaan backend, dan butir repositori pada kriteria selesai |
