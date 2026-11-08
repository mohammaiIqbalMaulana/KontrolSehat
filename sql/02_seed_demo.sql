-- =====================================================================
-- KontrolSehat - 02_seed_demo.sql
-- Mengisi data simulasi untuk SATU akun demo (obat, riwayat dosis 28 hari,
-- tekanan darah, jadwal kontrol). Semua tanggal relatif terhadap hari ini.
--
-- SEBELUM MENJALANKAN: akun demo harus sudah terdaftar lewat alur registrasi
-- (supaya profilnya terbentuk oleh trigger). Cara paling mudah, sebelum aplikasi
-- siap, lewat PowerShell (ganti 3 nilai yang huruf besar):
--
--   Invoke-RestMethod -Method Post `
--     -Uri "https://PROJECT_REF.supabase.co/auth/v1/signup" `
--     -Headers @{ apikey = "PUBLISHABLE_KEY" } `
--     -ContentType "application/json" `
--     -Body '{"email":"EMAIL_DEMO","password":"Demo12345","data":{"full_name":"Bu Rina","birth_year":1972}}'
--
-- Lalu GANTI nilai v_email di bawah dengan EMAIL_DEMO yang sama, dan jalankan.
-- Aman dijalankan ulang: data simulasi akun ini dihapus dulu lalu dibuat lagi.
-- =====================================================================

do $$
declare
  v_email        text := 'GANTI_DENGAN_EMAIL_AKUN_DEMO';
  v_uid          uuid;
  v_tz           text;
  v_today        date;
  v_start_today  timestamptz;
  v_amlo         uuid;
  v_capto        uuid;
  v_hct          uuid;
  v_due          integer;
  v_taken        integer;
begin
  select id into v_uid from auth.users where lower(email) = lower(v_email);
  if v_uid is null then
    raise exception 'Akun % tidak ditemukan. Daftarkan dulu (lihat petunjuk di bagian atas file).', v_email;
  end if;

  select timezone into v_tz from public.profiles where id = v_uid;
  if v_tz is null then
    raise exception 'Profil akun % belum ada. Akun harus dibuat lewat registrasi dengan metadata nama dan tahun lahir.', v_email;
  end if;

  v_today       := (now() at time zone v_tz)::date;
  v_start_today := v_today::timestamp at time zone v_tz;

  -- Bersihkan data simulasi lama milik akun ini
  delete from public.medications  where user_id = v_uid;   -- jam dan dosis ikut terhapus
  delete from public.appointments where user_id = v_uid;
  delete from public.bp_records   where user_id = v_uid;

  -- 1) Tiga obat, mulai 28 hari lalu (4 dosis per hari)
  insert into public.medications (user_id, name, dosage, notes, start_date, created_at, schedule_from)
  values (v_uid, 'Amlodipine', '5 mg', 'Data simulasi', v_today - 28,
          (v_today - 28)::timestamp at time zone v_tz, (v_today - 28)::timestamp at time zone v_tz)
  returning id into v_amlo;

  insert into public.medications (user_id, name, dosage, notes, start_date, created_at, schedule_from)
  values (v_uid, 'Captopril', '25 mg', 'Data simulasi', v_today - 28,
          (v_today - 28)::timestamp at time zone v_tz, (v_today - 28)::timestamp at time zone v_tz)
  returning id into v_capto;

  insert into public.medications (user_id, name, dosage, notes, start_date, created_at, schedule_from)
  values (v_uid, 'Hidroklorotiazid', '25 mg', 'Data simulasi', v_today - 28,
          (v_today - 28)::timestamp at time zone v_tz, (v_today - 28)::timestamp at time zone v_tz)
  returning id into v_hct;

  insert into public.medication_times (medication_id, time_of_day) values
    (v_amlo,  '08:00'),
    (v_capto, '08:00'),
    (v_capto, '20:00'),
    (v_hct,   '07:00');

  -- 2) Dosis 28 hari ke belakang sampai 7 hari ke depan
  perform public._generate_doses(v_uid, 7);

  -- Sebelum hari ini: sekitar 85% diminum, 8% dilewati, 7% terlewat (tetap pending).
  -- Hari ini dibiarkan pending supaya bisa dicoba saat demo.
  update public.medication_logs as l
  set status   = case when x.h < 85 then 'taken' when x.h < 93 then 'skipped' else 'pending' end,
      taken_at = case when x.h < 85
                      then l.scheduled_at + ((x.h % 45) || ' minutes')::interval
                      else null end
  from (
    select id, (hashtext(id::text) & 2147483647) % 100 as h
    from public.medication_logs
    where user_id = v_uid and scheduled_at < v_start_today
  ) as x
  where l.id = x.id;

  -- 3) 22 catatan tekanan darah dalam 28 hari, tren turun sekitar 152/96 ke 116/76
  --    (catatan terakhir pasti kategori Normal, awal pasti Tinggi, tengah Waspada)
  insert into public.bp_records (user_id, systolic, diastolic, pulse, measured_at)
  select v_uid,
         (round(152 - 36 * i / 21.0) + ((hashtext('s' || i) & 2147483647) % 7) - 3)::smallint,
         (round(96  - 20 * i / 21.0) + ((hashtext('d' || i) & 2147483647) % 5) - 2)::smallint,
         (68 + (hashtext('p' || i) & 2147483647) % 15)::smallint,
         least(
           ((v_today - (27 - (i * 27 / 21)))
              + case when i = 21 or i % 2 = 0 then time '07:30' else time '19:30' end) at time zone v_tz,
           now() - interval '10 minutes'
         )
  from generate_series(0, 21) as i;

  -- 4) Jadwal kontrol: 1 selesai, 2 akan datang
  insert into public.appointments (user_id, title, facility, doctor, scheduled_at, status, notes) values
    (v_uid, 'Kontrol rutin', 'Puskesmas Simulasi', 'dr. Simulasi',
       ((v_today - 14) + time '09:00') at time zone v_tz, 'done',     'Data simulasi'),
    (v_uid, 'Kontrol rutin', 'Puskesmas Simulasi', 'dr. Simulasi',
       ((v_today + 3)  + time '09:00') at time zone v_tz, 'upcoming', 'Data simulasi'),
    (v_uid, 'Kontrol rutin', 'Puskesmas Simulasi', 'dr. Simulasi',
       ((v_today + 30) + time '09:00') at time zone v_tz, 'upcoming', 'Data simulasi');

  -- 5) Angka acuan untuk uji G3 (bandingkan dengan hitungan aplikasi)
  select count(*) filter (where scheduled_at <= now()),
         count(*) filter (where scheduled_at <= now() and status = 'taken')
    into v_due, v_taken
  from public.medication_logs where user_id = v_uid;

  raise notice 'Seed selesai untuk %. Dosis jatuh tempo: %, diminum: %, kepatuhan: % persen',
    v_email, v_due, v_taken,
    case when v_due = 0 then null else round(100.0 * v_taken / v_due) end;
end;
$$;
