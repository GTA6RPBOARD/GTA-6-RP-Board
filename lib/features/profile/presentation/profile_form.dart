import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_banner.dart';
import '../domain/profile.dart';
import 'profile_controller.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    this.initial,
    this.submitLabel,
    this.onSaved,
  });

  final Profile? initial;
  final String? submitLabel;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _display;
  late final TextEditingController _ingame;
  late UserPlatform _platform;

  @override
  void initState() {
    super.initState();
    _display = TextEditingController(text: widget.initial?.displayName ?? '');
    _ingame = TextEditingController(text: widget.initial?.ingameName ?? '');
    _platform = widget.initial?.platform ?? UserPlatform.unknown;
    if (_platform == UserPlatform.unknown) {
      _platform = UserPlatform.ps5;
    }
  }

  @override
  void dispose() {
    _display.dispose();
    _ingame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final form = ref.watch(profileFormProvider);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (form.error != null) ...[
            ErrorBanner(message: form.error!),
            const SizedBox(height: 12),
          ],
          if (form.saved) ...[
            Text(s.saved, style: const TextStyle(color: AppTokens.cyan)),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _display,
            textInputAction: TextInputAction.next,
            maxLength: 32,
            decoration: InputDecoration(labelText: s.displayName),
            validator: (v) => (v == null || v.trim().isEmpty) ? s.required : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ingame,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            decoration: InputDecoration(labelText: s.ingameName),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (!ingamePattern.hasMatch(t)) return s.invalidIngame;
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(s.platform, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<UserPlatform>(
            segments: [
              ButtonSegment(value: UserPlatform.ps5, label: Text(s.ps5)),
              ButtonSegment(value: UserPlatform.xbox, label: Text(s.xbox)),
            ],
            selected: {_platform},
            onSelectionChanged: (v) => setState(() => _platform = v.first),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: widget.submitLabel ?? s.save,
            loading: form.saving,
            onPressed: () async {
              if (_form.currentState?.validate() != true) return;
              final ok = await ref.read(profileFormProvider.notifier).save(
                    displayName: _display.text,
                    ingameName: _ingame.text,
                    platform: _platform,
                  );
              if (ok) widget.onSaved?.call();
            },
          ),
        ],
      ),
    );
  }
}
