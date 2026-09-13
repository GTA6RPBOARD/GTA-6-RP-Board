-- GTA 6 RP Board — livrable 1
-- Schéma + RLS + RPC join_role / leave_role / switch_role
-- filled n'est PAS une colonne. COUNT(signups) uniquement.
-- Le LLM (Metteur / Casting / Radar / Régie) ne commit jamais filled/max.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_clean_text(p text)
returns boolean
language sql
immutable
as $$
  select
    p is not null
    and length(btrim(p)) > 0
    and p !~* 'https?://'
    and p !~* 'www\.'
    and p !~* 'discord\.gg'
    and p !~* 't\.me/'
    and p !~* '[0-9]{2,3}[-.\s]?[0-9]{2}[-.\s]?[0-9]{2}[-.\s]?[0-9]{2}[-.\s]?[0-9]{2}';
$$;

create or replace function public.is_ingame_name(p text)
returns boolean
language sql
immutable
as $$
  select p is not null and p ~ '^[A-Za-z0-9][A-Za-z0-9_-]{1,23}$';
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text not null default '',
  ingame_name text,
  platform text not null default 'unknown'
    check (platform in ('ps5', 'xbox', 'unknown')),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint users_display_name_len check (char_length(display_name) <= 32),
  constraint users_ingame_name_ok
    check (ingame_name is null or public.is_ingame_name(ingame_name))
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.users (id),
  title text not null,
  description text not null default '',
  location text not null,
  notes text not null default '',
  host_ingame_name text not null default '',
  planned_duration_min integer not null
    check (planned_duration_min > 0 and planned_duration_min <= 720),
  start_at timestamptz,
  status text not null default 'open'
    check (status in ('open', 'full', 'started', 'ended', 'cancelled')),
  flagged boolean not null default false,
  flagged_reason text,
  flagged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcements_title_len check (char_length(title) between 3 and 80),
  constraint announcements_desc_len check (char_length(description) <= 2000),
  constraint announcements_loc_len check (char_length(location) between 2 and 80),
  constraint announcements_notes_len check (char_length(notes) <= 1000),
  constraint announcements_title_clean check (public.is_clean_text(title)),
  constraint announcements_location_clean check (public.is_clean_text(location))
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  name text not null,
  max_slots integer not null check (max_slots > 0 and max_slots <= 50),
  unique (announcement_id, name),
  constraint roles_name_len check (char_length(name) between 2 and 32),
  constraint roles_name_clean check (public.is_clean_text(name))
);

create table public.signups (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  role_id uuid not null references public.roles (id) on delete cascade,
  user_id uuid not null references public.users (id),
  ingame_name_snapshot text not null,
  created_at timestamptz not null default now(),
  unique (announcement_id, user_id),
  unique (role_id, user_id),
  constraint signups_ingame_ok check (public.is_ingame_name(ingame_name_snapshot))
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users (id),
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now(),
  unique (reporter_id, announcement_id),
  constraint reports_reason_len check (char_length(reason) between 3 and 500)
);

create table public.rate_limit_events (
  id bigserial primary key,
  user_id uuid not null references public.users (id) on delete cascade,
  action text not null,
  created_at timestamptz not null default now()
);

create index announcements_status_start_idx on public.announcements (status, start_at);
create index announcements_host_idx on public.announcements (host_id);
create index roles_announcement_idx on public.roles (announcement_id);
create index signups_announcement_idx on public.signups (announcement_id);
create index signups_role_idx on public.signups (role_id);
create index signups_user_idx on public.signups (user_id);
create index rate_limit_user_action_idx on public.rate_limit_events (user_id, action, created_at);

-- Profil public : jamais l'email
-- security_invoker=false : tourne en owner, colonnes safe uniquement (pas d'email)
create view public.profiles
with (security_invoker = false)
as
select id, display_name, ingame_name, platform
from public.users
where deleted_at is null;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create trigger announcements_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, display_name, platform)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(coalesce(new.email, 'joueur'), '@', 1)),
    'unknown'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Ceinture : même un service_role maladroit ne peut pas surbooker
create or replace function public.enforce_role_quota()
returns trigger
language plpgsql
as $$
declare
  n integer;
  mx integer;
  role_ann uuid;
begin
  select announcement_id, max_slots into role_ann, mx
  from public.roles
  where id = new.role_id
  for update;

  if role_ann is null then
    raise exception 'role_not_found' using errcode = 'foreign_key_violation';
  end if;
  if role_ann is distinct from new.announcement_id then
    raise exception 'role_announcement_mismatch' using errcode = 'check_violation';
  end if;

  select count(*) into n from public.signups where role_id = new.role_id;
  if n > mx then
    raise exception 'role_full' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger signups_enforce_quota
after insert on public.signups
for each row execute function public.enforce_role_quota();

-- status=full est dérivé. Le client hôte ne peut pas le forcer.
create or replace function public.guard_announcement_status()
returns trigger
language plpgsql
as $$
begin
  if current_setting('app.from_rpc', true) is distinct from '1' then
    if new.status = 'full' and old.status is distinct from 'full' then
      raise exception 'status_full_is_derived';
    end if;
    if new.title is distinct from old.title
       or new.location is distinct from old.location
       or new.planned_duration_min is distinct from old.planned_duration_min then
      if old.status in ('started', 'ended', 'cancelled') then
        raise exception 'announcement_locked';
      end if;
    end if;
  end if;
  return new;
end;
$$;

create trigger announcements_guard_status
before update on public.announcements
for each row execute function public.guard_announcement_status();

create or replace function public.guard_role_max()
returns trigger
language plpgsql
as $$
declare
  filled integer;
begin
  if tg_op = 'UPDATE' and new.max_slots < old.max_slots then
    select count(*) into filled from public.signups where role_id = new.id;
    if new.max_slots < filled then
      raise exception 'max_below_filled';
    end if;
  end if;
  return new;
end;
$$;

create trigger roles_guard_max
before update on public.roles
for each row execute function public.guard_role_max();

-- ---------------------------------------------------------------------------
-- Casting : état des rôles (COUNT, jamais une colonne filled)
-- ---------------------------------------------------------------------------

create or replace function public.roles_state(p_announcement_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.name), '[]'::jsonb)
  from (
    select
      r.name,
      (select count(*) from public.signups s where s.role_id = r.id)::int as filled,
      r.max_slots as max,
      coalesce((
        select jsonb_agg(s.ingame_name_snapshot order by s.created_at)
        from public.signups s
        where s.role_id = r.id
      ), '[]'::jsonb) as players
    from public.roles r
    where r.announcement_id = p_announcement_id
  ) x;
$$;

create or replace function public.sync_announcement_status(p_announcement_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  cur text;
  all_full boolean;
begin
  perform set_config('app.from_rpc', '1', true);

  select status into cur
  from public.announcements
  where id = p_announcement_id
  for update;

  if cur is null then
    raise exception 'announcement_not_found';
  end if;
  if cur in ('started', 'ended', 'cancelled') then
    return cur;
  end if;

  select not exists (
    select 1
    from public.roles r
    where r.announcement_id = p_announcement_id
      and (select count(*) from public.signups s where s.role_id = r.id) < r.max_slots
  ) and exists (
    select 1 from public.roles r where r.announcement_id = p_announcement_id
  )
  into all_full;

  if all_full and cur = 'open' then
    update public.announcements set status = 'full' where id = p_announcement_id;
    return 'full';
  elsif not all_full and cur = 'full' then
    update public.announcements set status = 'open' where id = p_announcement_id;
    return 'open';
  end if;
  return cur;
end;
$$;

create or replace function public.assert_rate_limit(p_action text, p_max int, p_window interval)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  n integer;
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;
  select count(*) into n
  from public.rate_limit_events
  where user_id = uid
    and action = p_action
    and created_at > now() - p_window;
  if n >= p_max then
    raise exception 'rate_limited';
  end if;
  insert into public.rate_limit_events (user_id, action) values (uid, p_action);
end;
$$;

create or replace function public.cast_payload(
  p_ok boolean,
  p_action text,
  p_reason text,
  p_player text,
  p_role text,
  p_announcement_id uuid,
  p_status text
) returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'ok', p_ok,
    'action', p_action,
    'reason', coalesce(p_reason, ''),
    'player_ingame_name', coalesce(p_player, ''),
    'role', coalesce(p_role, ''),
    'roles_state', public.roles_state(p_announcement_id),
    'status', case when p_status in ('open', 'full') then p_status else p_status end
  );
$$;

-- Port Casting : action join | leave | switch_role
-- Source de vérité = cette transaction, pas le LLM.
create or replace function public.apply_cast_action(
  p_announcement_id uuid,
  p_action text,
  p_role text default null,
  p_player_ingame_name text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  ann_status text;
  role_rec public.roles%rowtype;
  existing public.signups%rowtype;
  player text;
  filled integer;
  new_status text;
begin
  if uid is null then
    return public.cast_payload(false, 'rejected', 'not_authenticated', '', coalesce(p_role, ''), p_announcement_id, 'open');
  end if;
  if not exists (select 1 from public.users u where u.id = uid and u.deleted_at is null) then
    return public.cast_payload(false, 'rejected', 'user_deleted', '', coalesce(p_role, ''), p_announcement_id, 'open');
  end if;

  perform set_config('app.from_rpc', '1', true);

  select status into ann_status
  from public.announcements
  where id = p_announcement_id
  for update;

  if ann_status is null then
    return public.cast_payload(false, 'rejected', 'announcement_not_found', '', coalesce(p_role, ''), p_announcement_id, 'open');
  end if;

  select * into existing
  from public.signups
  where announcement_id = p_announcement_id and user_id = uid;

  player := nullif(btrim(coalesce(p_player_ingame_name, '')), '');
  if player is null then
    select ingame_name into player from public.users where id = uid;
  end if;

  if p_action = 'leave' then
    perform public.assert_rate_limit('leave', 30, interval '10 minutes');
    if existing.id is null then
      return public.cast_payload(false, 'rejected', 'not_signed_up', coalesce(player, ''), '', p_announcement_id, ann_status);
    end if;
    select r.name into p_role from public.roles r where r.id = existing.role_id;
    delete from public.signups where id = existing.id;
    new_status := public.sync_announcement_status(p_announcement_id);
    return public.cast_payload(true, 'leave', '', existing.ingame_name_snapshot, coalesce(p_role, ''), p_announcement_id, new_status);
  end if;

  if p_action not in ('join', 'switch_role') then
    return public.cast_payload(false, 'rejected', 'unknown_action', coalesce(player, ''), coalesce(p_role, ''), p_announcement_id, ann_status);
  end if;

  if ann_status not in ('open') then
    return public.cast_payload(false, 'rejected', 'announcement_' || ann_status, coalesce(player, ''), coalesce(p_role, ''), p_announcement_id, ann_status);
  end if;

  if not public.is_ingame_name(player) then
    return public.cast_payload(false, 'rejected', 'invalid_ingame_name', coalesce(player, ''), coalesce(p_role, ''), p_announcement_id, ann_status);
  end if;

  if p_role is null or btrim(p_role) = '' then
    return public.cast_payload(false, 'rejected', 'role_required', player, '', p_announcement_id, ann_status);
  end if;

  select * into role_rec
  from public.roles
  where announcement_id = p_announcement_id and name = btrim(p_role)
  for update;

  if role_rec.id is null then
    return public.cast_payload(false, 'rejected', 'role_not_found', player, p_role, p_announcement_id, ann_status);
  end if;

  select count(*) into filled from public.signups where role_id = role_rec.id;

  if p_action = 'join' then
    perform public.assert_rate_limit('join', 15, interval '10 minutes');
    if existing.id is not null then
      return public.cast_payload(false, 'rejected', 'already_signed_up', player, role_rec.name, p_announcement_id, ann_status);
    end if;
    if filled >= role_rec.max_slots then
      return public.cast_payload(false, 'rejected', 'role_full', player, role_rec.name, p_announcement_id, ann_status);
    end if;
    insert into public.signups (announcement_id, role_id, user_id, ingame_name_snapshot)
    values (p_announcement_id, role_rec.id, uid, player);
    new_status := public.sync_announcement_status(p_announcement_id);
    return public.cast_payload(true, 'join', '', player, role_rec.name, p_announcement_id, new_status);
  end if;

  -- switch_role
  perform public.assert_rate_limit('join', 15, interval '10 minutes');
  if existing.id is null then
    return public.cast_payload(false, 'rejected', 'not_signed_up', player, role_rec.name, p_announcement_id, ann_status);
  end if;
  if existing.role_id = role_rec.id then
    return public.cast_payload(true, 'switch_role', '', existing.ingame_name_snapshot, role_rec.name, p_announcement_id, ann_status);
  end if;
  if filled >= role_rec.max_slots then
    return public.cast_payload(false, 'rejected', 'role_full', player, role_rec.name, p_announcement_id, ann_status);
  end if;

  delete from public.signups where id = existing.id;
  insert into public.signups (announcement_id, role_id, user_id, ingame_name_snapshot)
  values (p_announcement_id, role_rec.id, uid, coalesce(player, existing.ingame_name_snapshot));
  new_status := public.sync_announcement_status(p_announcement_id);
  return public.cast_payload(true, 'switch_role', '', coalesce(player, existing.ingame_name_snapshot), role_rec.name, p_announcement_id, new_status);
end;
$$;

create or replace function public.join_role(
  p_announcement_id uuid,
  p_role text,
  p_player_ingame_name text default null
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.apply_cast_action(p_announcement_id, 'join', p_role, p_player_ingame_name);
$$;

create or replace function public.leave_role(
  p_announcement_id uuid
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.apply_cast_action(p_announcement_id, 'leave', null, null);
$$;

create or replace function public.switch_role(
  p_announcement_id uuid,
  p_role text,
  p_player_ingame_name text default null
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.apply_cast_action(p_announcement_id, 'switch_role', p_role, p_player_ingame_name);
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.users enable row level security;
alter table public.announcements enable row level security;
alter table public.roles enable row level security;
alter table public.signups enable row level security;
alter table public.reports enable row level security;
alter table public.rate_limit_events enable row level security;

alter table public.users force row level security;
alter table public.announcements force row level security;
alter table public.roles force row level security;
alter table public.signups force row level security;
alter table public.reports force row level security;
alter table public.rate_limit_events force row level security;

-- users : soi uniquement (bloque le leak email si la clé anon est extraite)
create policy users_select_own on public.users
  for select to authenticated
  using (id = auth.uid());

create policy users_update_own on public.users
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and deleted_at is null);

-- visibilité annonce : feed + hôte + inscrits
create or replace function public.is_announcement_visible(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.announcements a
    where a.id = p_id
      and (
        a.status in ('open', 'full', 'started')
        or a.host_id = auth.uid()
        or exists (
          select 1 from public.signups s
          where s.announcement_id = a.id and s.user_id = auth.uid()
        )
      )
  );
$$;

create policy announcements_select on public.announcements
  for select to authenticated
  using (public.is_announcement_visible(id));

create policy announcements_insert_host on public.announcements
  for insert to authenticated
  with check (host_id = auth.uid());

create policy announcements_update_host on public.announcements
  for update to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

create policy roles_select on public.roles
  for select to authenticated
  using (public.is_announcement_visible(announcement_id));

create policy roles_write_host on public.roles
  for all to authenticated
  using (
    exists (select 1 from public.announcements a where a.id = announcement_id and a.host_id = auth.uid())
  )
  with check (
    exists (select 1 from public.announcements a where a.id = announcement_id and a.host_id = auth.uid())
  );

-- Lecture des inscrits (fiche). Écriture = RPC uniquement.
create policy signups_select on public.signups
  for select to authenticated
  using (public.is_announcement_visible(announcement_id));

create policy reports_insert_own on public.reports
  for insert to authenticated
  with check (reporter_id = auth.uid());

create policy reports_select_own_or_host on public.reports
  for select to authenticated
  using (
    reporter_id = auth.uid()
    or exists (
      select 1 from public.announcements a
      where a.id = announcement_id and a.host_id = auth.uid()
    )
  );

-- rate_limit_events : aucune policy → inaccessible via PostgREST

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

grant usage on schema public to anon, authenticated;

grant select, update on public.users to authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update on public.announcements to authenticated;
grant select, insert, update, delete on public.roles to authenticated;
grant select on public.signups to authenticated;
grant select, insert on public.reports to authenticated;

revoke all on public.rate_limit_events from anon, authenticated;
revoke insert, update, delete on public.signups from anon, authenticated;

grant execute on function public.join_role(uuid, text, text) to authenticated;
grant execute on function public.leave_role(uuid) to authenticated;
grant execute on function public.switch_role(uuid, text, text) to authenticated;
grant execute on function public.apply_cast_action(uuid, text, text, text) to authenticated;
grant execute on function public.roles_state(uuid) to authenticated;

revoke execute on function public.apply_cast_action(uuid, text, text, text) from anon, public;
revoke execute on function public.join_role(uuid, text, text) from anon, public;
revoke execute on function public.leave_role(uuid) from anon, public;
revoke execute on function public.switch_role(uuid, text, text) from anon, public;
revoke execute on function public.sync_announcement_status(uuid) from anon, authenticated, public;
revoke execute on function public.assert_rate_limit(text, int, interval) from anon, authenticated, public;
revoke execute on function public.handle_new_user() from anon, authenticated, public;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

alter table public.announcements replica identity full;
alter table public.roles replica identity full;
alter table public.signups replica identity full;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    execute 'alter publication supabase_realtime add table public.announcements';
    execute 'alter publication supabase_realtime add table public.roles';
    execute 'alter publication supabase_realtime add table public.signups';
  end if;
end;
$$;
