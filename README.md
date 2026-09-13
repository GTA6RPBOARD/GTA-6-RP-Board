# GTA 6 RP Board

App mobile LFG / casting RP. Flutter + Supabase.

## Étape 1 — Base

Fichier : `supabase/migrations/20260913120000_init_schema_rls_cast.sql`

Déjà appliquée si le SQL editor a répondu sans erreur.

- `filled` n'est pas une colonne : `COUNT(signups)`
- Inscriptions via RPC : `join_role` / `leave_role` / `switch_role`
- Jamais de `service_role` / clé xAI dans le binaire

## Étape 2 — Auth + profil

```bash
flutter create . --project-name gta6_rp_board --org com.gta6rpboard --platforms=android,ios
cp .env.example .env
# remplir SUPABASE_URL et SUPABASE_ANON_KEY (clé anon, pas service_role)
flutter pub get
flutter run --dart-define-from-file=.env
```

Supabase Dashboard → Authentication :

1. Providers : Email, Google, Apple
2. URL configuration → Redirect URLs : `io.gta6rpboard.app://login-callback/`
3. Coller le deep link Android (`tool/deeplink-android.xml`) dans `AndroidManifest.xml`
4. Coller le bloc iOS (`tool/deeplink-ios.plist`) dans `Info.plist`

`.env` reste local. Ne le commit pas.
