import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n/strings.dart';
import 'core/router/app_router.dart';
import 'core/supabase/env.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppEnv.isConfigured) {
    runApp(const _MissingEnvApp());
    return;
  }
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const ProviderScope(child: RpBoardApp()));
}

class RpBoardApp extends ConsumerWidget {
  const RpBoardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'RP Board',
      theme: buildAppTheme(),
      routerConfig: router,
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('fr');
        return supported.contains(locale)
            ? locale
            : (locale.languageCode == 'en' ? const Locale('en') : const Locale('fr'));
      },
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        SDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class _MissingEnvApp extends StatelessWidget {
  const _MissingEnvApp();

  @override
  Widget build(BuildContext context) {
    const s = S(Locale('fr'));
    return MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              s.envMissing,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.cream, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
