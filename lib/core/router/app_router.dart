import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/complete_profile_screen.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../supabase/supabase_providers.dart';

final _refresh = ValueNotifier<int>(0);

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.listen(authStateProvider, (_, __) => _refresh.value++);
  ref.listen(myProfileProvider, (_, __) => _refresh.value++);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: _refresh,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final loc = state.matchedLocation;
      final onAuth = loc == '/auth';

      if (user == null) return onAuth ? null : '/auth';

      final profileAsync = ref.read(myProfileProvider);
      final profile = profileAsync.asData?.value;
      final complete = profile?.isComplete == true;

      if (profileAsync.isLoading && loc == '/auth') return null;
      if (!complete && loc != '/profile/complete') return '/profile/complete';
      if (complete && (onAuth || loc == '/profile/complete')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(
        path: '/profile/complete',
        builder: (c, s) => const CompleteProfileScreen(),
      ),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    ],
  );
});
