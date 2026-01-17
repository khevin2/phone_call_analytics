import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'services/permission_service.dart';

class CallSenseApp extends ConsumerWidget {
  const CallSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionStateProvider);
    return MaterialApp(
      title: 'CallSense',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: permissionState.when(
        data: (state) =>
            state.hasPermissions || state.limitedMode ? const HomeScreen() : const OnboardingScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
