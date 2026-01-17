import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/call_repository.dart';
import '../models/call_record.dart';
import '../native/call_log_channel.dart';
import 'providers.dart';

class SyncService {
  SyncService(this.repository, this.preferences);

  final CallRepository repository;
  final SharedPreferences preferences;

  static const _lastSyncKey = 'lastSyncMillis';

  static Future<void> runBackgroundSync() async {
    final container = ProviderContainer();
    final database = await container.read(databaseProvider.future);
    final prefs = await container.read(sharedPreferencesProvider.future);
    final service = SyncService(CallRepository(database.db), prefs);
    await service.syncCallLogs();
    container.dispose();
  }

  Future<void> syncCallLogs() async {
    final now = DateTime.now();
    final lastSyncMillis = preferences.getInt(_lastSyncKey);
    final fromMillis = lastSyncMillis ?? 0;
    final logs = await CallLogChannel.getCallLogs(
      fromMillis: fromMillis,
      toMillis: now.millisecondsSinceEpoch,
    );
    final calls = logs.map(_mapCallLog).toList();
    await repository.upsertCalls(calls);
    await preferences.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
  }

  CallRecord _mapCallLog(Map<String, Object?> entry) {
    final timestampMillis = entry['timestamp'] as int? ?? 0;
    final simSlot = entry['simSlot'] as int? ?? 0;
    final typeIndex = entry['type'] as int? ?? CallType.unknown.index;
    final safeTypeIndex = typeIndex.clamp(0, CallType.values.length - 1).toInt();
    return CallRecord(
      callId: entry['callId'] as int? ?? 0,
      number: (entry['number'] as String?) ?? 'Unknown',
      name: entry['name'] as String?,
      type: CallType.values[safeTypeIndex],
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      durationSec: entry['durationSec'] as int? ?? 0,
      simSlot: simSlot,
      subscriptionId: entry['subscriptionId'] as int?,
      phoneAccountId: entry['phoneAccountId'] as String?,
      phoneAccountComponentName: entry['phoneAccountComponentName'] as String?,
      createdAt: DateTime.now(),
    );
  }
}
