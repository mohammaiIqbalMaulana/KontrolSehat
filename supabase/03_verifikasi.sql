-- =====================================================================
-- KontrolSehat - 03_verifikasi.sql
-- Jalankan SETELAH 01_schema.sql. Jalankan SATU BLOK per kali (A, B, C, lalu D):
-- sorot satu blok saja lalu klik Run. Editor dapat menampilkan hasil kueri
-- terakhir saja, jadi jangan menjalankan semua blok sekaligus.
-- =====================================================================

-- A. RLS harus aktif (kolom rls_aktif = true) pada SEMUA 7 tabel
select c.relname as tabel, c.relrowsecurity as rls_aktif
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by c.relname;

-- B. Peran anon TIDAK boleh punya hak apa pun: hasil harus KOSONG (0 baris)
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public' and grantee = 'anon';

-- C. Daftar kebijakan RLS (harus ada untuk tiap tabel; medication_times dan medication_logs
--    tidak punya kebijakan insert/delete, itu disengaja)
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
order by tablename, cmd, policyname;

-- D. Uji klasifikasi tekanan darah (uji G4). Kolom ok harus TRUE di semua baris
--    dan kolom lulus harus sama dengan total (22). Memakai tabel sementara dengan
--    definisi kolom turunan yang SAMA dengan bp_records. Sorot seluruh blok D lalu Run.
drop table if exists _bp_test;
create temp table _bp_test (like public.bp_records including defaults including generated including constraints);

insert into _bp_test (user_id, systolic, diastolic, note)
select gen_random_uuid(), s, d, expected
from (values
  (119, 79,  'normal'),
  (120, 79,  'elevated'),
  (119, 80,  'elevated'),
  (139, 89,  'elevated'),
  (140, 89,  'high'),
  (139, 90,  'high'),
  (179, 119, 'high'),
  (180, 119, 'very_high'),
  (179, 120, 'very_high'),
  (90,  60,  'normal'),
  (89,  70,  'low'),
  (100, 59,  'low'),
  (85,  80,  'low'),
  (138, 92,  'high'),
  (125, 70,  'elevated'),
  (118, 78,  'normal'),
  (250, 140, 'very_high'),
  (70,  40,  'low'),
  (120, 80,  'elevated'),
  (110, 65,  'normal'),
  (160, 100, 'high'),
  (130, 85,  'elevated')
) as t (s, d, expected);

select systolic,
       diastolic,
       note     as seharusnya,
       category as hasil,
       (note = category) as ok,
       count(*) filter (where note = category) over () as lulus,
       count(*) over () as total
from _bp_test
order by systolic, diastolic;
