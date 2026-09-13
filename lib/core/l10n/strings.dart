import 'package:flutter/widgets.dart';

class S {
  const S(this.locale);
  final Locale locale;

  bool get en => locale.languageCode == 'en';

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(Localizations.localeOf(context));
  }

  String get appName => en ? 'RP Board' : 'RP Board';
  String get signIn => en ? 'Sign in' : 'Connexion';
  String get signUp => en ? 'Create account' : 'Créer un compte';
  String get email => 'Email';
  String get password => en ? 'Password' : 'Mot de passe';
  String get emailHint => 'toi@mail.com';
  String get passwordHint => en ? '8+ characters' : '8 caractères min';
  String get or => en ? 'or' : 'ou';
  String get continueGoogle => en ? 'Continue with Google' : 'Continuer avec Google';
  String get continueApple => en ? 'Continue with Apple' : 'Continuer avec Apple';
  String get haveAccount => en ? 'Already in?' : 'Déjà un compte ?';
  String get noAccount => en ? 'New here?' : 'Pas encore de compte ?';
  String get signOut => en ? 'Sign out' : 'Déconnexion';
  String get profile => en ? 'Profile' : 'Profil';
  String get completeProfile => en ? 'Finish your profile' : 'Termine ton profil';
  String get displayName => en ? 'App name' : 'Pseudo app';
  String get ingameName => en ? 'In-game name' : 'Pseudo in-game';
  String get platform => en ? 'Platform' : 'Plateforme';
  String get save => en ? 'Save' : 'Enregistrer';
  String get saved => en ? 'Saved.' : 'C’est enregistré.';
  String get ps5 => 'PS5';
  String get xbox => 'Xbox';
  String get homeTitle => en ? 'Your RPs' : 'Mes RP';
  String get homeEmpty =>
      en ? 'No session yet. Create one next.' : 'Aucun RP. Prochaine étape : créer une annonce.';
  String get required => en ? 'Required.' : 'Obligatoire.';
  String get invalidEmail => en ? 'That email looks off.' : 'Email invalide.';
  String get weakPassword => en ? '8 characters minimum.' : '8 caractères minimum.';
  String get invalidIngame =>
      en ? '2–24 letters, numbers, _ or -.' : '2–24 lettres, chiffres, _ ou -.';
  String get authFailed => en ? 'Sign-in failed.' : 'Connexion ratée.';
  String get networkError => en ? 'No network.' : 'Pas de réseau.';
  String get cancelled => en ? 'Cancelled.' : 'Annulé.';
  String get envMissing =>
      en
          ? 'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Copy .env.example to .env'
          : 'SUPABASE_URL / SUPABASE_ANON_KEY manquants. Copie .env.example vers .env';
  String get sessionExpired => en ? 'Session expired.' : 'Session expirée.';
}

class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();

  @override
  bool isSupported(Locale locale) => {'fr', 'en'}.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<S> old) => false;
}
