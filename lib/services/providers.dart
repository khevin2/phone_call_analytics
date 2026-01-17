import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/call_repository.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.open();
});

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final database = ref.watch(databaseProvider).value;
  if (database == null) {
    throw StateError('Database not ready');
  }
  return CallRepository(database.db);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});
