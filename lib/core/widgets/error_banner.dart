import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTokens.coral.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTokens.coral.withOpacity(0.6)),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppTokens.coral, fontSize: 14),
        ),
      ),
    );
  }
}
