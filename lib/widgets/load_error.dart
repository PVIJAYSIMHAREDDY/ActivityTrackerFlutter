import 'package:flutter/material.dart';

class LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const LoadError({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your profile could not load. Check your connection and try again.',
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
