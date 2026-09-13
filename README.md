# GTA 6 RP Board

App mobile LFG / casting RP. Flutter + Supabase.

## Étape 1 — Base

Fichier : `supabase/migrations/20260913120000_init_schema_rls_cast.sql`

Dans le SQL editor du projet Supabase EU (rôle postgres) : coller et exécuter.

- `filled` n'est pas une colonne : `COUNT(signups)`
- Inscriptions via RPC uniquement : `join_role` / `leave_role` / `switch_role`
- Jamais de `service_role` / clé xAI dans le binaire Flutter
