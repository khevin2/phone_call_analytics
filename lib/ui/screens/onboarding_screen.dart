import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/permission_service.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = PermissionService();
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to CallSense')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline call analytics for your device.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'CallSense reads call log metadata only (number, time, duration, '
              'call type, and SIM slot when available). No audio is recorded. '
              'All processing happens locally and no internet permission is used.',
            ),
            const SizedBox(height: 24),
            const Text('Required permissions:'),
            const SizedBox(height: 8),
            const Text('• Read Call Log'),
            const Text('• Read Phone State (SIM mapping)'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final granted = await permissionService.requestCorePermissions();
                if (context.mounted) {
                  if (granted) {
                    await permissionService.disableLimitedMode();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        granted
                            ? 'Permissions granted!'
                            : 'Limited mode enabled. You can enable permissions later.',
                      ),
                    ),
                  );
                  ref.invalidate(permissionStateProvider);
                }
              },
              child: const Text('Grant permissions'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await permissionService.enableLimitedMode();
                ref.invalidate(permissionStateProvider);
              },
              child: const Text('Continue limited mode'),
            ),
            const Spacer(),
            const Text(
              'You can enable optional contact name resolution in settings.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
