import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_banner.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ui = ref.watch(authControllerProvider);
    final ctrl = ref.read(authControllerProvider.notifier);
    final map = (Object e) => ref.read(authRepositoryProvider).mapError(e, s);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(s.appName, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              ui.mode == AuthMode.signIn ? s.signIn : s.signUp,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 28),
            if (ui.error != null) ...[
              ErrorBanner(message: ui.error!),
              const SizedBox(height: 16),
            ],
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: s.email,
                      hintText: s.emailHint,
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return s.required;
                      if (!t.contains('@') || !t.contains('.')) {
                        return s.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: s.password,
                      hintText: s.passwordHint,
                    ),
                    validator: (v) {
                      if ((v ?? '').length < 8) return s.weakPassword;
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: ui.mode == AuthMode.signIn ? s.signIn : s.signUp,
              loading: ui.loading,
              onPressed: () {
                if (_form.currentState?.validate() != true) return;
                ctrl.submit(_email.text.trim(), _password.text, map);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTokens.creamMuted)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(s.or, style: Theme.of(context).textTheme.bodyMedium),
                ),
                const Expanded(child: Divider(color: AppTokens.creamMuted)),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: s.continueGoogle,
              filled: false,
              loading: ui.loading,
              onPressed: () => ctrl.oauth(OAuthProvider.google, map),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: s.continueApple,
              filled: false,
              loading: ui.loading,
              onPressed: () => ctrl.oauth(OAuthProvider.apple, map),
            ),
            const SizedBox(height: 24),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, AppTokens.tapMin),
                foregroundColor: AppTokens.cyan,
              ),
              onPressed: ui.loading ? null : ctrl.toggleMode,
              child: Text(ui.mode == AuthMode.signIn ? s.noAccount : s.haveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
