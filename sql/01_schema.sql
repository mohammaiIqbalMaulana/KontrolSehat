-- =====================================================================
-- KontrolSehat - 01_schema.sql
-- Jalankan SEKALI di Supabase: SQL Editor > New query > paste semua > Run
-- Isi: tabel, constraint, trigger, RLS, hak akses, fungsi (RPC), katalog obat.
-- Acuan: PRD KontrolSehat bagian 8 (aturan bisnis), 10 (validasi), 11 (data).
-- =====================================================================

-- (OPSIONAL) Ulang dari awal: buka komentar 4 baris di bawah, jalankan, lalu
-- jalankan ulang seluruh file ini. HAPUS SEMUA DATA aplikasi.
-- drop table if exists public.medication_logs, public.medication_times,
--   public.medications, public.appointments, public.bp_records,
--   public.medicine_catalog, public.profiles cascade;

-- =====================================================================
-- 1. TABEL
-- =====================================================================

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null check (char_length(btrim(full_name)) between 2 and 50),
  birth_year  integer not null,
  timezone    text not null default 'Asia/Jakarta',
  created_at  timestamptz not null default now()
);

create table if not exists public.medicine_catalog (
  id                uuid primary key default gen_random_uuid(),
  name              text not null unique,
  drug_class        text not null,
  common_strengths  text[] not null
);

create table if not exists public.medications (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name           text not null check (char_length(btrim(name)) between 2 and 60),
  dosage         text not null check (char_length(btrim(dosage)) between 1 and 30),
  notes          text check (notes is null or char_length(notes) <= 200),
  start_date     date not null,
  end_date       date,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  -- dosis hanya dibuat untuk jam >= schedule_from (lihat PRD 8.3)
  schedule_from  timestamptz not null default now(),
  constraint medications_dates_chk check (end_date is null or end_date >= start_date),
  constraint medications_id_user_uk unique (id, user_id)
);
create index if not exists medications_user_idx on public.medications (user_id);

create table if not exists public.medication_times (
  id             uuid primary key default gen_random_uuid(),
  medication_id  uuid not null references public.medications (id) on delete cascade,
  time_of_day    time not null check (extract(second from time_of_day) = 0),
  unique (medication_id, time_of_day)
);

-- Satu baris = satu dosis. Dibuat otomatis oleh fungsi, bukan oleh pengguna.
create table if not exists public.medication_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null,
  medication_id  uuid not null,
  scheduled_at   timestamptz not null,
  status         text not null default 'pending' check (status in ('pending', 'taken', 'skipped')),
  taken_at       timestamptz,
  unique (medication_id, scheduled_at),
  constraint logs_med_fk foreign key (medication_id, user_id)
    references public.medications (id, user_id) on delete cascade,
  constraint logs_taken_at_chk check (
    (status = 'taken' and taken_at is not null) or (status <> 'taken' and taken_at is null)
  )
);
create index if not exists logs_user_sched_idx on public.medication_logs (user_id, scheduled_at);

create table if not exists public.appointments (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title         text not null default 'Kontrol rutin' check (char_length(btrim(title)) between 2 and 60),
  facility      text not null check (char_length(btrim(facility)) between 2 and 80),
  doctor        text check (doctor is null or char_length(doctor) <= 60),
  scheduled_at  timestamptz not null,
  notes         text check (notes is null or char_length(notes) <= 200),
  status        text not null default 'upcoming' check (status in ('upcoming', 'done', 'cancelled')),
  created_at    timestamptz not null default now()
);
create index if not exists appointments_user_sched_idx on public.appointments (user_id, scheduled_at);

create table if not exists public.bp_records (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  systolic     smallint not null check (systolic between 70 and 250),
  diastolic    smallint not null check (diastolic between 40 and 150),
  pulse        smallint check (pulse is null or pulse between 30 and 200),
  measured_at  timestamptz not null default now(),
  note         text check (note is null or char_length(note) <= 200),
  -- Aturan PRD 8.4, dievaluasi dari atas ke bawah
  category     text generated always as (
    case
      when systolic >= 180 or diastolic >= 120 then 'very_high'
      when systolic >= 140 or diastolic >= 90  then 'high'
      when systolic < 90   or diastolic < 60   then 'low'
      when systolic >= 120 or diastolic >= 80  then 'elevated'
      else 'normal'
    end
  ) stored,
  constraint bp_sys_gt_dia check (systolic > diastolic)
);
create index if not exists bp_user_time_idx on public.bp_records (user_id, measured_at desc);

-- =====================================================================
-- 2. FUNGSI INTERNAL: pembuatan dosis
-- =====================================================================

-- Membuat baris dosis 'pending' dari tanggal mulai sampai hari ini + p_days_ahead.
-- Aman dipanggil berulang (ON CONFLICT DO NOTHING). Hanya untuk jam >= schedule_from.
create or replace function public._generate_doses(p_uid uuid, p_days_ahead integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz        text;
  v_today     date;
  v_inserted  integer := 0;
begin
  select timezone into v_tz from public.profiles where id = p_uid;
  if v_tz is null then
    return 0;
  end if;
  v_today := (now() at time zone v_tz)::date;

  insert into public.medication_logs (user_id, medication_id, scheduled_at)
  select m.user_id, m.id, ((d.day + t.time_of_day) at time zone v_tz)
  from public.medications m
  join public.medication_times t on t.medication_id = m.id
  cross join lateral generate_series(
      m.start_date::timestamp,
      least(coalesce(m.end_date, v_today + p_days_ahead), v_today + p_days_ahead)::timestamp,
      interval '1 day'
  ) as d(day)
  where m.user_id = p_uid
    and m.is_active
    and ((d.day + t.time_of_day) at time zone v_tz) >= m.schedule_from
  on conflict (medication_id, scheduled_at) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

-- =====================================================================
-- 3. TRIGGER
-- =====================================================================

-- 3.1 Profil otomatis saat akun dibuat (data dari metadata registrasi)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz    text := coalesce(nullif(btrim(new.raw_user_meta_data ->> 'timezone'), ''), 'Asia/Jakarta');
  v_year  integer;
begin
  begin
    v_year := (new.raw_user_meta_data ->> 'birth_year')::integer;
  exception when others then
    v_year := null;
  end;
  if not exists (select 1 from pg_timezone_names where name = v_tz) then
    v_tz := 'Asia/Jakarta';
  end if;
  insert into public.profiles (id, full_name, birth_year, timezone)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''), v_year, v_tz);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3.2 Validasi profil (tahun lahir dan zona waktu)
create or replace function public.profiles_validate()
returns trigger
language plpgsql
as $$
declare
  v_cur integer := extract(year from now())::integer;
begin
  new.full_name := btrim(new.full_name);
  if new.birth_year < v_cur - 100 or new.birth_year > v_cur - 18 then
    raise exception 'Tahun lahir tidak valid';
  end if;
  if not exists (select 1 from pg_timezone_names where name = new.timezone) then
    raise exception 'Zona waktu tidak valid';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_validate_trg on public.profiles;
create trigger profiles_validate_trg
  before insert or update on public.profiles
  for each row execute function public.profiles_validate();

-- 3.3 Obat: validasi dan penyesuaian jadwal saat aktif/nonaktif atau tanggal selesai berubah
-- Catatan: pemeriksaan "auth.uid() is not null" membuat skrip admin/seed (SQL Editor) tidak terkena
-- aturan khusus pengguna aplikasi.
create or replace function public.medications_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz text;
begin
  new.name   := btrim(new.name);
  new.dosage := btrim(new.dosage);

  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      select timezone into v_tz from public.profiles where id = new.user_id;
      if new.start_date < (now() at time zone v_tz)::date then
        raise exception 'Tanggal mulai tidak boleh sebelum hari ini';
      end if;
    end if;
  else
    if new.user_id <> old.user_id then
      raise exception 'Pemilik obat tidak boleh diubah';
    end if;
    if new.start_date <> old.start_date then
      raise exception 'Tanggal mulai tidak dapat diubah';
    end if;
    -- Rapikan riwayat (dosis sampai sekarang) sebelum status/akhir jadwal berubah
    if new.is_active is distinct from old.is_active
       or new.end_date is distinct from old.end_date then
      perform public._generate_doses(old.user_id, 0);
    end if;
    -- Diaktifkan kembali atau tanggal selesai diperpanjang: dosis baru hanya dari sekarang
    if new.is_active and not old.is_active then
      new.schedule_from := now();
    elsif old.end_date is not null and (new.end_date is null or new.end_date > old.end_date) then
      new.schedule_from := now();
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists medications_before_write_trg on public.medications;
create trigger medications_before_write_trg
  before insert or update on public.medications
  for each row execute function public.medications_before_write();

-- Setelah dinonaktifkan / tanggal selesai dimajukan: hapus dosis pending di masa depan
create or replace function public.medications_after_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz text;
begin
  if (new.is_active is distinct from old.is_active and not new.is_active)
     or (new.end_date is distinct from old.end_date and new.end_date is not null) then
    select timezone into v_tz from public.profiles where id = new.user_id;
    delete from public.medication_logs as l
    where l.medication_id = new.id
      and l.status = 'pending'
      and l.scheduled_at > now()
      and (
        not new.is_active
        or (new.end_date is not null and (l.scheduled_at at time zone v_tz)::date > new.end_date)
      );
  end if;
  return null;
end;
$$;

drop trigger if exists medications_after_update_trg on public.medications;
create trigger medications_after_update_trg
  after update on public.medications
  for each row execute function public.medications_after_update();

-- 3.4 Maksimal 4 jam per obat
create or replace function public.medication_times_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from public.medication_times where medication_id = new.medication_id) >= 4 then
    raise exception 'Maksimal 4 jam per obat';
  end if;
  return new;
end;
$$;

drop trigger if exists medication_times_limit_trg on public.medication_times;
create trigger medication_times_limit_trg
  before insert on public.medication_times
  for each row execute function public.medication_times_limit();

-- 3.5 Dosis: kunci setelah 23:59, jendela waktu, taken_at diisi server
create or replace function public.medication_logs_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tz text;
begin
  if auth.uid() is null then
    return new;  -- skrip admin / seed
  end if;
  if new.user_id <> old.user_id
     or new.medication_id <> old.medication_id
     or new.scheduled_at <> old.scheduled_at then
    raise exception 'Data dosis tidak boleh diubah';
  end if;

  select timezone into v_tz from public.profiles where id = old.user_id;
  if (old.scheduled_at at time zone v_tz)::date < (now() at time zone v_tz)::date then
    raise exception 'Dosis ini sudah terkunci';
  end if;

  if old.status = 'pending'
     and new.status in ('taken', 'skipped')
     and now() < old.scheduled_at - interval '60 minutes' then
    raise exception 'Belum waktunya minum obat';
  end if;

  if new.status = 'taken' then
    if old.status <> 'taken' then
      new.taken_at := now();
    else
      new.taken_at := old.taken_at;
    end if;
  else
    new.taken_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists medication_logs_guard_trg on public.medication_logs;
create trigger medication_logs_guard_trg
  before update on public.medication_logs
  for each row execute function public.medication_logs_guard();

-- 3.6 Jadwal kontrol: harus di masa depan saat ditambah
create or replace function public.appointments_before_write()
returns trigger
language plpgsql
as $$
begin
  new.title    := btrim(new.title);
  new.facility := btrim(new.facility);
  if tg_op = 'INSERT' and auth.uid() is not null and new.scheduled_at <= now() then
    raise exception 'Jadwal harus di masa depan';
  end if;
  return new;
end;
$$;

drop trigger if exists appointments_before_write_trg on public.appointments;
create trigger appointments_before_write_trg
  before insert or update on public.appointments
  for each row execute function public.appointments_before_write();

-- 3.7 Tekanan darah: waktu tidak boleh lebih dari 5 menit ke depan
create or replace function public.bp_before_write()
returns trigger
language plpgsql
as $$
begin
  if new.measured_at > now() + interval '5 minutes' then
    raise exception 'Waktu pengukuran tidak boleh di masa depan';
  end if;
  return new;
end;
$$;

drop trigger if exists bp_before_write_trg on public.bp_records;
create trigger bp_before_write_trg
  before insert or update on public.bp_records
  for each row execute function public.bp_before_write();

-- =====================================================================
-- 4. FUNGSI UNTUK APLIKASI (RPC)
-- =====================================================================

-- Panggil saat aplikasi dibuka dan setelah login. Mengembalikan jumlah dosis baru.
create or replace function public.ensure_doses(p_days_ahead integer default 7)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Tidak terautentikasi';
  end if;
  if p_days_ahead is null or p_days_ahead < 0 or p_days_ahead > 30 then
    raise exception 'p_days_ahead harus 0 sampai 30';
  end if;
  return public._generate_doses(auth.uid(), p_days_ahead);
end;
$$;

-- Satu-satunya cara mengisi/mengubah jam obat (termasuk saat obat baru ditambahkan).
create or replace function public.apply_schedule_change(p_medication_id uuid, p_times time[])
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_times  time[];
  v_n      integer;
begin
  if v_uid is null then
    raise exception 'Tidak terautentikasi';
  end if;
  if not exists (select 1 from public.medications where id = p_medication_id and user_id = v_uid) then
    raise exception 'Obat tidak ditemukan';
  end if;
  if p_times is null then
    raise exception 'Jam konsumsi wajib diisi';
  end if;

  select array_agg(distinct x), count(distinct x) into v_times, v_n from unnest(p_times) as x;
  if v_n is null or v_n < 1 or v_n > 4 or array_length(p_times, 1) <> v_n then
    raise exception 'Pilih 1 sampai 4 jam yang berbeda';
  end if;
  if exists (select 1 from unnest(v_times) as x where extract(second from x) <> 0) then
    raise exception 'Jam harus dalam format HH:mm';
  end if;

  -- 1) tutup riwayat dengan jam lama sampai akhir hari ini
  perform public._generate_doses(v_uid, 0);
  -- 2) jam baru berlaku mulai sekarang
  update public.medications set schedule_from = now() where id = p_medication_id;
  delete from public.medication_times where medication_id = p_medication_id;
  insert into public.medication_times (medication_id, time_of_day)
    select p_medication_id, x from unnest(v_times) as x;
  -- 3) buang dosis pending di masa depan (jam lama), buat ulang dengan jam baru
  delete from public.medication_logs
    where medication_id = p_medication_id and status = 'pending' and scheduled_at > now();
  perform public._generate_doses(v_uid, 7);
end;
$$;

-- Dosis jatuh tempo dan dosis diminum per tanggal lokal (dasar kepatuhan, PRD 8.2 dan 8.5).
-- Memakai hak pengguna (RLS berlaku). Panggil ensure_doses() dulu agar riwayat lengkap.
create or replace function public.adherence_by_day(p_from date, p_to date)
returns table (day date, due integer, taken integer)
language plpgsql
stable
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_tz   text;
begin
  if v_uid is null then
    raise exception 'Tidak terautentikasi';
  end if;
  if p_from is null or p_to is null or p_from > p_to or p_to - p_from > 366 then
    raise exception 'Rentang tanggal tidak valid';
  end if;
  select p.timezone into v_tz from public.profiles p where p.id = v_uid;

  return query
  select d.day::date,
         (count(l.id) filter (where l.scheduled_at <= now()))::integer,
         (count(l.id) filter (where l.scheduled_at <= now() and l.status = 'taken'))::integer
  from generate_series(p_from::timestamp, p_to::timestamp, interval '1 day') as d(day)
  left join public.medication_logs l
    on l.user_id = v_uid
   and (l.scheduled_at at time zone v_tz)::date = d.day::date
  group by d.day
  order by d.day;
end;
$$;

-- Hapus akun sendiri; seluruh data ikut terhapus lewat cascade.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Tidak terautentikasi';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- =====================================================================
-- 5. ROW LEVEL SECURITY
-- =====================================================================

alter table public.profiles          enable row level security;
alter table public.medicine_catalog  enable row level security;
alter table public.medications       enable row level security;
alter table public.medication_times  enable row level security;
alter table public.medication_logs   enable row level security;
alter table public.appointments      enable row level security;
alter table public.bp_records        enable row level security;

-- profiles
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles for select to authenticated
  using (id = (select auth.uid()));
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- katalog: hanya baca
drop policy if exists catalog_select on public.medicine_catalog;
create policy catalog_select on public.medicine_catalog for select to authenticated using (true);

-- medications
drop policy if exists medications_select_own on public.medications;
create policy medications_select_own on public.medications for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists medications_insert_own on public.medications;
create policy medications_insert_own on public.medications for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists medications_update_own on public.medications;
create policy medications_update_own on public.medications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists medications_delete_own on public.medications;
create policy medications_delete_own on public.medications for delete to authenticated
  using (user_id = (select auth.uid()));

-- medication_times: hanya baca (isi/ubah lewat apply_schedule_change)
drop policy if exists times_select_own on public.medication_times;
create policy times_select_own on public.medication_times for select to authenticated
  using (exists (
    select 1 from public.medications m
    where m.id = medication_times.medication_id and m.user_id = (select auth.uid())
  ));

-- medication_logs: baca dan ubah status saja (dosis dibuat/dihapus oleh sistem)
drop policy if exists logs_select_own on public.medication_logs;
create policy logs_select_own on public.medication_logs for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists logs_update_own on public.medication_logs;
create policy logs_update_own on public.medication_logs for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- appointments
drop policy if exists appointments_select_own on public.appointments;
create policy appointments_select_own on public.appointments for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists appointments_insert_own on public.appointments;
create policy appointments_insert_own on public.appointments for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists appointments_update_own on public.appointments;
create policy appointments_update_own on public.appointments for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists appointments_delete_own on public.appointments;
create policy appointments_delete_own on public.appointments for delete to authenticated
  using (user_id = (select auth.uid()));

-- bp_records
drop policy if exists bp_select_own on public.bp_records;
create policy bp_select_own on public.bp_records for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists bp_insert_own on public.bp_records;
create policy bp_insert_own on public.bp_records for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists bp_update_own on public.bp_records;
create policy bp_update_own on public.bp_records for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists bp_delete_own on public.bp_records;
create policy bp_delete_own on public.bp_records for delete to authenticated
  using (user_id = (select auth.uid()));

-- =====================================================================
-- 6. HAK AKSES (GRANT). Peran anon tidak punya akses apa pun.
-- =====================================================================

revoke all on all tables in schema public from anon, authenticated;

grant usage on schema public to authenticated;

grant select on public.medicine_catalog to authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, birth_year, timezone) on public.profiles to authenticated;

grant select, delete on public.medications to authenticated;
grant insert (name, dosage, notes, start_date, end_date, is_active) on public.medications to authenticated;
grant update (name, dosage, notes, end_date, is_active) on public.medications to authenticated;

grant select on public.medication_times to authenticated;

grant select on public.medication_logs to authenticated;
grant update (status) on public.medication_logs to authenticated;

grant select, insert, update, delete on public.appointments to authenticated;
grant select, insert, update, delete on public.bp_records to authenticated;

-- Fungsi: cabut akses umum, beri hanya yang dibutuhkan aplikasi
revoke all on function public._generate_doses(uuid, integer)       from public, anon, authenticated;
revoke all on function public.handle_new_user()                    from public, anon, authenticated;
revoke all on function public.profiles_validate()                  from public, anon, authenticated;
revoke all on function public.medications_before_write()           from public, anon, authenticated;
revoke all on function public.medications_after_update()           from public, anon, authenticated;
revoke all on function public.medication_times_limit()             from public, anon, authenticated;
revoke all on function public.medication_logs_guard()              from public, anon, authenticated;
revoke all on function public.appointments_before_write()          from public, anon, authenticated;
revoke all on function public.bp_before_write()                    from public, anon, authenticated;

revoke all on function public.ensure_doses(integer)                from public, anon;
revoke all on function public.apply_schedule_change(uuid, time[])  from public, anon;
revoke all on function public.adherence_by_day(date, date)         from public, anon;
revoke all on function public.delete_my_account()                  from public, anon;

grant execute on function public.ensure_doses(integer)                to authenticated;
grant execute on function public.apply_schedule_change(uuid, time[])  to authenticated;
grant execute on function public.adherence_by_day(date, date)         to authenticated;
grant execute on function public.delete_my_account()                  to authenticated;

-- =====================================================================
-- 7. SEED KATALOG OBAT (contoh untuk autocomplete, BUKAN rekomendasi terapi)
-- =====================================================================

insert into public.medicine_catalog (name, drug_class, common_strengths) values
  ('Amlodipine',       'Penghambat kanal kalsium',        array['5 mg', '10 mg']),
  ('Captopril',        'Penghambat ACE',                  array['12,5 mg', '25 mg', '50 mg']),
  ('Lisinopril',       'Penghambat ACE',                  array['5 mg', '10 mg']),
  ('Ramipril',         'Penghambat ACE',                  array['2,5 mg', '5 mg', '10 mg']),
  ('Candesartan',      'Penghambat reseptor angiotensin', array['8 mg', '16 mg']),
  ('Valsartan',        'Penghambat reseptor angiotensin', array['80 mg', '160 mg']),
  ('Telmisartan',      'Penghambat reseptor angiotensin', array['40 mg', '80 mg']),
  ('Bisoprolol',       'Penyekat beta',                   array['2,5 mg', '5 mg', '10 mg']),
  ('Hidroklorotiazid', 'Diuretik',                        array['25 mg']),
  ('Furosemid',        'Diuretik',                        array['40 mg'])
on conflict (name) do nothing;

-- Selesai. Jalankan 03_verifikasi.sql untuk memeriksa hasilnya.
