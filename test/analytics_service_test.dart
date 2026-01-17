import 'package:flutter_test/flutter_test.dart';

import 'package:callsense/analytics/analytics_service.dart';
import 'package:callsense/models/call_record.dart';

void main() {
  test('buckets calls by day', () {
    final service = AnalyticsService();
    final calls = [
      CallRecord(
        callId: 1,
        number: '1',
        name: null,
        type: CallType.incoming,
        timestamp: DateTime(2024, 1, 1, 10),
        durationSec: 10,
        simSlot: 1,
        subscriptionId: 1,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
      CallRecord(
        callId: 2,
        number: '2',
        name: null,
        type: CallType.outgoing,
        timestamp: DateTime(2024, 1, 1, 12),
        durationSec: 20,
        simSlot: 2,
        subscriptionId: 2,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
      CallRecord(
        callId: 3,
        number: '3',
        name: null,
        type: CallType.missed,
        timestamp: DateTime(2024, 1, 2, 9),
        durationSec: 0,
        simSlot: 1,
        subscriptionId: 1,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
    ];

    final buckets = service.bucketCallsByDay(calls);
    expect(buckets[DateTime(2024, 1, 1)], 2);
    expect(buckets[DateTime(2024, 1, 2)], 1);
  });

  test('returned call stats detect call backs', () {
    final service = AnalyticsService();
    final calls = [
      CallRecord(
        callId: 1,
        number: '555',
        name: null,
        type: CallType.missed,
        timestamp: DateTime(2024, 1, 1, 10, 0),
        durationSec: 0,
        simSlot: 1,
        subscriptionId: 1,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
      CallRecord(
        callId: 2,
        number: '555',
        name: null,
        type: CallType.outgoing,
        timestamp: DateTime(2024, 1, 1, 10, 30),
        durationSec: 45,
        simSlot: 1,
        subscriptionId: 1,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
      CallRecord(
        callId: 3,
        number: '777',
        name: null,
        type: CallType.missed,
        timestamp: DateTime(2024, 1, 1, 9, 0),
        durationSec: 0,
        simSlot: 2,
        subscriptionId: 2,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
    ];

    final stats = service.returnedCallStats(calls);
    expect(stats.missedCount, 2);
    expect(stats.returnedCount, 1);
  });

  test('filters by SIM slot', () {
    final service = AnalyticsService();
    final calls = [
      CallRecord(
        callId: 1,
        number: '1',
        name: null,
        type: CallType.incoming,
        timestamp: DateTime(2024, 1, 1, 10),
        durationSec: 10,
        simSlot: 1,
        subscriptionId: 1,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
      CallRecord(
        callId: 2,
        number: '2',
        name: null,
        type: CallType.outgoing,
        timestamp: DateTime(2024, 1, 1, 12),
        durationSec: 20,
        simSlot: 2,
        subscriptionId: 2,
        phoneAccountId: null,
        phoneAccountComponentName: null,
        createdAt: DateTime.now(),
      ),
    ];

    final sim1Calls = service.filterBySimSlot(calls, 1);
    expect(sim1Calls.length, 1);
    expect(sim1Calls.first.simSlot, 1);
  });
}
