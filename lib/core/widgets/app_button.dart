import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.filled = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTokens.coral : AppTokens.magenta;
    return SizedBox(
      height: AppTokens.tapMin,
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppTokens.night,
                minimumSize: const Size(44, AppTokens.tapMin),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            )
          : OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.cream,
                side: BorderSide(color: AppTokens.cyan.withOpacity(0.5)),
                minimumSize: const Size(44, AppTokens.tapMin),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            ),
    );
  }
}
