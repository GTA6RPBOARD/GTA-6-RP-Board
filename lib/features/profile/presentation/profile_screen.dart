import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';
import 'profile_form.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTokens.night,
        title: Text(s.profile),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            ProfileForm(initial: p),
            const SizedBox(height: 32),
            AppButton(
              label: s.signOut,
              filled: false,
              danger: true,
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/auth');
              },
            ),
          ],
        ),
      ),
    );
  }
}
