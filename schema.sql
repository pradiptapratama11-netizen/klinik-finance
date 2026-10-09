-- KLINIK FINANCE: database satu klinik
-- Jalankan seluruh isi file ini sekali di Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Klinik Prima Sehat',
  created_at timestamptz not null default now()
);

insert into public.clinics (name)
select 'Klinik Prima Sehat'
where not exists (select 1 from public.clinics);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'staff' check (role in ('owner','staff')),
  clinic_id uuid not null references public.clinics(id),
  created_at timestamptz not null default now()
);

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare first_clinic uuid;
begin
  select id into first_clinic from public.clinics order by created_at limit 1;
  if first_clinic is null then
    insert into public.clinics(name) values ('Klinik Prima Sehat') returning id into first_clinic;
  end if;
  insert into public.profiles(id,email,role,clinic_id)
  values(new.id,new.email,'staff',first_clinic)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_klinik_finance on auth.users;
create trigger on_auth_user_created_klinik_finance
after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  transaction_date date not null default current_date,
  type text not null check (type in ('in','out')),
  category text not null,
  amount numeric(16,2) not null check (amount > 0),
  account text not null default 'Kas Klinik',
  method text not null default 'Tunai',
  note text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.debts (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  supplier_name text not null,
  debt_date date not null default current_date,
  due_date date,
  amount numeric(16,2) not null check (amount > 0),
  paid_amount numeric(16,2) not null default 0 check (paid_amount >= 0 and paid_amount <= amount),
  note text not null default '',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists transactions_clinic_date_idx on public.transactions(clinic_id, transaction_date desc);
create index if not exists debts_clinic_due_idx on public.debts(clinic_id, due_date);

alter table public.clinics enable row level security;
alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.debts enable row level security;

drop policy if exists "signed in can read clinic" on public.clinics;
create policy "signed in can read clinic" on public.clinics
for select to authenticated
using (id = (select clinic_id from public.profiles where id = auth.uid()));

drop policy if exists "users can read own profile" on public.profiles;
create policy "users can read own profile" on public.profiles
for select to authenticated using (id = auth.uid());

drop policy if exists "clinic members read transactions" on public.transactions;
create policy "clinic members read transactions" on public.transactions
for select to authenticated
using (clinic_id = (select clinic_id from public.profiles where id = auth.uid()));

drop policy if exists "clinic members add transactions" on public.transactions;
create policy "clinic members add transactions" on public.transactions
for insert to authenticated
with check (
  clinic_id = (select clinic_id from public.profiles where id = auth.uid())
  and created_by = auth.uid()
);

drop policy if exists "owners delete transactions" on public.transactions;
create policy "owners delete transactions" on public.transactions
for delete to authenticated
using (
  clinic_id = (select clinic_id from public.profiles where id = auth.uid())
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner')
);

drop policy if exists "clinic members read debts" on public.debts;
create policy "clinic members read debts" on public.debts
for select to authenticated
using (clinic_id = (select clinic_id from public.profiles where id = auth.uid()));

drop policy if exists "clinic members add debts" on public.debts;
create policy "clinic members add debts" on public.debts
for insert to authenticated
with check (
  clinic_id = (select clinic_id from public.profiles where id = auth.uid())
  and created_by = auth.uid()
);

drop policy if exists "clinic members update debts" on public.debts;
create policy "clinic members update debts" on public.debts
for update to authenticated
using (clinic_id = (select clinic_id from public.profiles where id = auth.uid()))
with check (clinic_id = (select clinic_id from public.profiles where id = auth.uid()));

drop policy if exists "owners delete debts" on public.debts;
create policy "owners delete debts" on public.debts
for delete to authenticated
using (
  clinic_id = (select clinic_id from public.profiles where id = auth.uid())
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner')
);

grant usage on schema public to authenticated;
grant select on public.clinics, public.profiles, public.transactions, public.debts to authenticated;
grant insert on public.transactions, public.debts to authenticated;
grant update, delete on public.debts to authenticated;
grant delete on public.transactions to authenticated;
