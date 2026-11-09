-- =====================================================================
-- KontrolSehat - fixed demo seed: 9 Nov 2026 sampai 13 Nov 2026
--
-- Ini DATASET DEMO TERPISAH. Jangan menjalankan 02_seed_demo.sql setelah
-- script ini pada akun yang sama karena 02_seed_demo.sql menghapus seluruh
-- data simulasi akun lalu membuat dataset relatif terhadap hari eksekusi.
--
-- Prasyarat:
-- 1. Jalankan 01_schema.sql.
-- 2. Daftarkan akun demo melalui aplikasi/Auth (jangan membuat role admin).
-- 3. Ganti v_email dengan email akun demo.
-- 4. Jalankan script ini di SQL Editor sebagai operator database.
--
-- Semua data adalah data simulasi. Script ini memakai profile timezone untuk
-- mengubah tanggal/jam lokal menjadi timestamptz UTC.
-- =====================================================================

begin;

do $$
declare
  v_email text := 'GANTI_DENGAN_EMAIL_AKUN_DEMO';
  v_uid uuid;
  v_tz text;
  v_from date := date '2026-11-09';
  v_to date := date '2026-11-13';
  v_marker text := 'Fixed demo 2026-11-09..2026-11-13';
  v_amlo uuid;
  v_capto uuid;
  v_hct uuid;
  v_due integer;
  v_taken integer;
begin
  select id into strict v_uid
  from auth.users
  where lower(email) = lower(v_email);

  select timezone into strict v_tz
  from public.profiles
  where id = v_uid;

  if not exists (select 1 from pg_timezone_names where name = v_tz) then
    raise exception 'Zona waktu profil tidak valid: %', v_tz;
  end if;

  -- Hanya hapus data yang dibuat oleh script fixed-date ini.
  delete from public.medications
  where user_id = v_uid and notes = v_marker;
  delete from public.appointments
  where user_id = v_uid and notes = v_marker;
  delete from public.bp_records
  where user_id = v_uid and note = v_marker;

  -- Obat berlaku tepat pada lima tanggal demo.
  insert into public.medications
    (user_id, name, dosage, notes, start_date, end_date, created_at, schedule_from)
  values
    (v_uid, 'Amlodipine', '5 mg', v_marker, v_from, v_to,
      v_from::timestamp at time zone v_tz,
      v_from::timestamp at time zone v_tz)
  returning id into v_amlo;

  insert into public.medications
    (user_id, name, dosage, notes, start_date, end_date, created_at, schedule_from)
  values
    (v_uid, 'Captopril', '25 mg', v_marker, v_from, v_to,
      v_from::timestamp at time zone v_tz,
      v_from::timestamp at time zone v_tz)
  returning id into v_capto;

  insert into public.medications
    (user_id, name, dosage, notes, start_date, end_date, created_at, schedule_from)
  values
    (v_uid, 'Hidroklorotiazid', '25 mg', v_marker, v_from, v_to,
      v_from::timestamp at time zone v_tz,
      v_from::timestamp at time zone v_tz)
  returning id into v_hct;

  insert into public.medication_times (medication_id, time_of_day)
  values
    (v_amlo, time '08:00'),
    (v_capto, time '08:00'),
    (v_capto, time '20:00'),
    (v_hct, time '07:00');

  -- Lima hari x empat dosis = 20 baris. Semua pending agar aman untuk demo.
  -- Ini admin seed SQL; aplikasi tetap tidak boleh insert/delete logs.
  insert into public.medication_logs
    (user_id, medication_id, scheduled_at, status, taken_at)
  select
    v_uid,
    x.medication_id,
    ((d.day::date + x.time_of_day) at time zone v_tz),
    'pending',
    null
  from generate_series(v_from::timestamp, v_to::timestamp, interval '1 day') as d(day)
  cross join (
    values
      (v_amlo, time '08:00'),
      (v_capto, time '08:00'),
      (v_capto, time '20:00'),
      (v_hct, time '07:00')
  ) as x(medication_id, time_of_day)
  on conflict (medication_id, scheduled_at) do nothing;

  -- BP hanya dibuat sampai waktu sekarang agar trigger future-time tidak dilanggar.
  -- Jalankan ulang setelah 13 Nov jika ingin memasukkan catatan future yang nyata.
  insert into public.bp_records
    (user_id, systolic, diastolic, pulse, measured_at, note)
  select
    v_uid,
    x.systolic,
    x.diastolic,
    x.pulse,
    least(
      ((x.day_value + x.measure_time) at time zone v_tz),
      now() - interval '10 minutes'
    ),
    v_marker
  from (
    values
      (date '2026-11-09', time '07:30', 150::smallint, 95::smallint, 76::smallint),
      (date '2026-11-10', time '07:30', 138::smallint, 88::smallint, 74::smallint),
      (date '2026-11-11', time '07:30', 125::smallint, 80::smallint, 72::smallint),
      (date '2026-11-12', time '07:30', 118::smallint, 78::smallint, 70::smallint),
      (date '2026-11-13', time '07:30', 116::smallint, 76::smallint, 68::smallint)
  ) as x(day_value, measure_time, systolic, diastolic, pulse)
  where ((x.day_value + x.measure_time) at time zone v_tz) <= now() + interval '5 minutes';

  -- Kontrol 10 Nov dan 13 Nov hanya dibuat bila sudah future terhadap database now().
  insert into public.appointments
    (user_id, title, facility, doctor, scheduled_at, status, notes)
  select v_uid, x.title, x.facility, x.doctor,
         ((x.day_value + x.time_value) at time zone v_tz),
         'upcoming', v_marker
  from (
    values
      ('Kontrol demo 1', 'Puskesmas Simulasi', 'dr. Simulasi', date '2026-11-10', time '15:00'),
      ('Kontrol demo 2', 'Puskesmas Simulasi', 'dr. Simulasi', date '2026-11-13', time '09:00')
  ) as x(title, facility, doctor, day_value, time_value)
  where ((x.day_value + x.time_value) at time zone v_tz) > now();

  select
    count(*) filter (where l.scheduled_at <= now()),
    count(*) filter (where l.scheduled_at <= now() and l.status = 'taken')
  into v_due, v_taken
  from public.medication_logs l
  join public.medications m on m.id = l.medication_id and m.user_id = l.user_id
  where l.user_id = v_uid and m.notes = v_marker;

  raise notice 'Fixed seed selesai. email=%, timezone=%, local_dates=% sampai %',
    v_email, v_tz, v_from, v_to;
  raise notice 'Dosis fixed seed: %, due saat ini: %, taken saat ini: %, adherence saat ini: % persen',
    (select count(*) from public.medication_logs l
      join public.medications m on m.id = l.medication_id and m.user_id = l.user_id
      where l.user_id = v_uid and m.notes = v_marker),
    v_due,
    v_taken,
    case when v_due = 0 then null else round(100.0 * v_taken / v_due) end;
end $$;

commit;
