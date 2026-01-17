import 'dart:math';

import '../data/call_repository.dart';
import '../models/call_record.dart';

class DemoDataService {
  DemoDataService(this.repository);

  final CallRepository repository;

  Future<void> seedDemoData({int count = 250}) async {
    final now = DateTime.now();
    final random = Random(42);
    final calls = List.generate(count, (index) {
      final timestamp = now.subtract(Duration(
        days: random.nextInt(60),
        hours: random.nextInt(24),
        minutes: random.nextInt(60),
      ));
      final type = CallType.values[random.nextInt(CallType.values.length - 1)];
      return CallRecord(
        callId: 100000 + index,
        number: '+1-555-${random.nextInt(9000) + 1000}',
        name: random.nextBool() ? 'Demo Contact ${index % 12}' : null,
        type: type,
        timestamp: timestamp,
        durationSec: random.nextInt(600),
        simSlot: random.nextBool() ? 1 : 2,
        subscriptionId: random.nextBool() ? 1 : 2,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      );
    });
    await repository.upsertCalls(calls);
  }
}
