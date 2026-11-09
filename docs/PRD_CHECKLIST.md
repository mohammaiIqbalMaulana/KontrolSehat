# Checklist Kepatuhan PRD KontrolSehat

> Status tidak boleh diubah menjadi `PASS` tanpa bukti eksekusi yang tercatat. Checklist ini memakai kondisi repository saat ini dan harus dilengkapi setelah uji Supabase, emulator, dan perangkat fisik.

## Status

- **PASS** — bukti eksekusi tersedia dan acceptance terpenuhi.
- **PARTIAL** — sebagian alur tersedia, tetapi ada acceptance/gap yang belum selesai.
- **NOT RUN** — implementasi atau query mungkin tersedia, tetapi belum dijalankan.
- **BLOCKED** — ada gap implementasi yang mencegah acceptance.

**Tanggal audit kode:** 9 November 2026. **Bukti otomatis:** `flutter analyze`, `flutter test`, dan build debug telah dijalankan pada sesi ini; hasil dicatat di bagian verifikasi.

## Functional Requirements

| ID | Kriteria ringkas | Status | Bukti/gap |
|---|---|---|---|
| FR-101 | Registrasi valid membuat akun/profil dan masuk Beranda; email duplikat tepat | PARTIAL | Form/Auth metadata ada; Supabase nyata dan email duplikat belum diuji |
| FR-102 | Login benar/salah dengan pesan PRD | PARTIAL | AuthMapper ada; belum ada evidence runtime |
| FR-103 | Sesi bertahan setelah restart aplikasi | NOT RUN | AuthGate memakai currentSession/authChanges; belum diuji restart |
| FR-104 | Logout dan pembatalan notifikasi | PARTIAL | Logout ada; integrasi notifikasi belum terbukti penuh |
| FR-201 | Sapaan nama depan | PARTIAL | Home menampilkan sapaan; belum diuji akun nyata |
| FR-202 | Dosis berikutnya/status/aksi | PARTIAL | Implementasi ada; timezone profile belum konsisten |
| FR-203 | Ring progres hari ini | PARTIAL | Rumus ada; animasi/acceptance manual belum diuji |
| FR-204 | BP terakhir, label, ikon, waktu | PARTIAL | Kartu/chip ada; waktu profile dan evidence belum lengkap |
| FR-205 | Kontrol terdekat/countdown | PARTIAL | Query/countdown ada; timezone profile belum konsisten |
| FR-206 | Refresh + skeleton awal | PARTIAL | Refresh ada; skeleton belum sesuai PRD |
| FR-207 | ensure_doses(7) sebelum baca data | PARTIAL | Home memanggil; runtime/error evidence belum ada |
| FR-301 | Daftar obat aktif/nonaktif | PARTIAL | UI/repository ada; Supabase nyata belum diuji |
| FR-302 | Tambah obat, katalog, rollback | PARTIAL | Alur/repository ada; notifikasi dan error database belum lengkap |
| FR-303 | Preset 1x/2x/3x/manual | PASS (kode) | Implementasi dan widget smoke test; manual belum dicatat |
| FR-304 | Ubah obat, tanggal mulai terkunci, RPC jadwal | PARTIAL | Implementasi ada; rollback/update acceptance belum diuji |
| FR-305 | Aktif/nonaktif menjaga riwayat | PARTIAL | SQL/UI ada; notifikasi dan NFR-11 belum diuji |
| FR-306 | Hapus permanen dengan konfirmasi | PASS (kode) | Dialog dan delete ada; runtime belum diuji |
| FR-401 | Tandai taken/jendela waktu/server taken_at | PARTIAL | SQL/UI ada; runtime database belum diuji |
| FR-402 | Tandai skipped/jendela waktu | PARTIAL | SQL/UI ada; runtime database belum diuji |
| FR-403 | Ubah status sampai 23:59 | BLOCKED | UI perubahan status belum tersedia |
| FR-404 | Pending tanggal lampau tampil Terlewat | PARTIAL | Utilitas ada; layar history penuh/evidence belum ada |
| FR-501 | Upcoming/history/status lewat | PARTIAL | UI ada; runtime belum diuji |
| FR-502 | Tambah kontrol masa depan | PASS (kode) | Validasi client/SQL ada; runtime belum diuji |
| FR-503 | Ubah dan hapus kontrol | BLOCKED | Hapus ada; mode edit belum tersedia |
| FR-504 | Selesai/batal | PARTIAL | UI/status ada; cancel notification belum terbukti |
| FR-505 | Countdown PRD 8.6 | PASS (kode) | `Fmt.countdown` dan unit test ada |
| FR-601 | Input BP + tombol disabled | PASS (kode) | Validator/form ada; runtime belum diuji |
| FR-602 | Label/advice langsung | PASS (kode) | `classifyBp` dan form preview ada |
| FR-603 | Category dari DB generated | PARTIAL | SQL/model ada; Supabase runtime belum diuji |
| FR-604 | Ubah/hapus BP | PARTIAL | Hapus ada; edit belum tersedia |
| FR-605 | Riwayat range + kategori | PARTIAL | Range ada; filter kategori belum tersedia |
| FR-701 | Tab harian/mingguan/bulanan | PASS (kode) | UI/repository ada |
| FR-702 | Summary kepatuhan/BP/count | PARTIAL | UI ada; seed/manual comparison belum dilakukan |
| FR-703 | Bar chart + nilai saat tap | PARTIAL | Chart ada; evidence interaksi belum ada |
| FR-704 | Line chart + nilai titik | PARTIAL | Chart/tooltip ada; evidence belum ada |
| FR-705 | Empty state ilustratif | PARTIAL | Pesan ada; ilustrasi belum sesuai PRD |
| FR-801 | Ubah nama/tahun lahir | PASS (kode) | Form/update/validator ada; runtime belum diuji |
| FR-802 | Tema tersimpan | PASS (kode) | SharedPreferences/theme notifier ada |
| FR-803 | Toggle/pengaturan sistem/baterai | PARTIAL | UI ada; izin/reschedule kategori belum lengkap |
| FR-804 | HAPUS + RPC delete account | PARTIAL | Alur ada; cascade runtime belum diuji |
| FR-805 | Tentang + SEC-07 | PASS (kode) | Teks tersedia; screenshot belum dicatat |
| FR-901 | Pengingat obat | BLOCKED | Service ada, caller end-to-end baru mulai diintegrasikan; belum diuji perangkat |
| FR-902 | Pengingat kontrol | BLOCKED | Service ada; caller/runtime belum terbukti |
| FR-903 | Reschedule 7 hari/startup/mutasi | PARTIAL | Orchestrator/service ada; full integration/evidence belum selesai |
| FR-904 | Pembatalan semua kondisi | PARTIAL | cancel API ada; semua mutation path belum diuji |
| FR-905 | Bertahan restart | NOT RUN | Manifest permission ada; boot/device test belum dilakukan |
| FR-906 | Permission/exact fallback | PARTIAL | API/permission ada; flow UI/fallback runtime belum diuji |

## NFR dan Security

| ID | Kriteria | Status | Bukti/gap |
|---|---|---|---|
| NFR-01 | Home ≤2 detik | NOT RUN | Stopwatch belum dicatat |
| NFR-02 | Responsive 360–1024 | PARTIAL | Layout diperbaiki; screenshot matrix belum ada |
| NFR-03 | 16sp, 48dp, 4.5:1, 130% | PARTIAL | Theme/UI audit ada; audit manual belum ada |
| NFR-04 | HTTPS/RLS/publishable | PARTIAL | Kode/SQL sesuai; runtime/RLS belum dijalankan |
| NFR-05 | Retry jaringan/isian tidak hilang | PARTIAL | RetryView ada; offline mutation belum diuji |
| NFR-06 | API26 + emulator + fisik | NOT RUN | Perangkat fisik belum diuji |
| NFR-07 | APK ≤60MB | NOT RUN | Release split size belum diukur |
| NFR-08 | Format Indonesia/24 jam | PARTIAL | Fmt ada; seluruh layar belum diperiksa |
| NFR-09 | ensure idempoten | NOT RUN | Belum panggil 3x di Supabase |
| NFR-10 | Zona profil | BLOCKED | Banyak client path masih memakai zona perangkat |
| NFR-11 | Riwayat tidak berubah | NOT RUN | Belum uji before/after adherence |
| NFR-12 | SQL verifikasi lulus | NOT RUN | `03_verifikasi.sql` belum dijalankan |
| SEC-01 | Auth/password aman | PARTIAL | Auth ada; runtime/log audit belum lengkap |
| SEC-02 | RLS ownership | NOT RUN | Uji dua akun belum dilakukan |
| SEC-03 | Publishable key only | PARTIAL | Env guard ada; secret scan/history belum dibuktikan |
| SEC-04 | HTTPS | PARTIAL | URL Supabase di env; runtime belum dicek |
| SEC-05 | Data minimal | PASS (kode) | Tidak ada field lokasi/NIK/BPJS/analytics terlihat |
| SEC-06 | User edit/delete data | PARTIAL | Beberapa edit belum tersedia |
| SEC-07 | Disclaimer | PASS (kode) | Onboarding/About memuat teks |
| SEC-08 | No health logs | PARTIAL | Tidak ada print health yang terlihat; release audit belum ada |
| SEC-09 | Private notification | PARTIAL | Obat private; kontrol/fisik belum diuji |
| SEC-10 | Least privilege | NOT RUN | SQL verification belum dijalankan |
| SEC-11 | Secure definer | NOT RUN | Inspeksi SQL belum dieksekusi |
| SEC-12 | Password policy Auth | NOT RUN | Dashboard Supabase belum diverifikasi |

## G1–G7

| ID | Target | Status | Bukti/gap |
|---|---|---|---|
| G1 | 10/10 notifikasi ≤1 menit | BLOCKED | Belum uji fisik dan scheduling belum terbukti penuh |
| G2 | Dosis ≤2 tap, BP ≤30 detik | NOT RUN | Stopwatch 5 responden belum ada |
| G3 | Adherence sama manual | NOT RUN | Seed/oracle belum dijalankan |
| G4 | 22 kasus BP benar | NOT RUN | Unit test ada; SQL block belum dijalankan |
| G5 | Dua akun no leakage | NOT RUN | Belum uji API/RLS |
| G6 | Kuesioner ≥4.0/5 | NOT RUN | Belum ada lima responden |
| G7 | Demo 3x tanpa crash | NOT RUN | Run log belum dibuat |

## Automated evidence saat audit ini

- `flutter analyze`: **PASS — No issues found**.
- `flutter test`: **PASS — 61 tests passed**.
- `flutter build apk --debug --dart-define-from-file=env.json`: **PASS**.
- SQL execution, physical device, RLS two-account, G1–G7: **belum dijalankan**.

## Urutan menutup checklist

1. Selesaikan FR-503/FR-604/FR-605 dan timezone NFR-10.
2. Hubungkan dan uji F9 pada perangkat fisik.
3. Jalankan schema, `03_verifikasi.sql`, seed fixed, dan uji dua akun.
4. Catat G1–G7 dan matriks device/responsive/performance.
5. Ubah status hanya berdasarkan evidence ID yang disimpan.
