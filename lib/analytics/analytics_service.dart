import 'package:collection/collection.dart';

import '../models/call_record.dart';

class AnalyticsSummary {
  AnalyticsSummary({
    required this.totalCalls,
    required this.totalDuration,
    required this.averageDuration,
    required this.breakdown,
  });

  final int totalCalls;
  final int totalDuration;
  final double averageDuration;
  final Map<CallType, int> breakdown;
}

class ReturnedCallStats {
  ReturnedCallStats({
    required this.missedCount,
    required this.returnedCount,
  });

  final int missedCount;
  final int returnedCount;

  double get returnRate => missedCount == 0 ? 0 : returnedCount / missedCount;
}

class AnalyticsService {
  List<CallRecord> filterBySimSlot(List<CallRecord> calls, int simSlot) {
    if (simSlot == -1) return calls;
    return calls.where((call) => call.simSlot == simSlot).toList();
  }

  AnalyticsSummary buildSummary(List<CallRecord> calls) {
    final totalCalls = calls.length;
    final totalDuration = calls.fold<int>(0, (sum, call) => sum + call.durationSec);
    final double averageDuration = totalCalls == 0 ? 0 : totalDuration / totalCalls;
    final breakdown = <CallType, int>{};
    for (final call in calls) {
      breakdown.update(call.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return AnalyticsSummary(
      totalCalls: totalCalls,
      totalDuration: totalDuration,
      averageDuration: averageDuration,
      breakdown: breakdown,
    );
  }

  Map<DateTime, int> bucketCallsByDay(List<CallRecord> calls) {
    final buckets = <DateTime, int>{};
    for (final call in calls) {
      final day = DateTime(call.timestamp.year, call.timestamp.month, call.timestamp.day);
      buckets.update(day, (value) => value + 1, ifAbsent: () => 1);
    }
    return buckets;
  }

  Map<DateTime, int> bucketDurationByDay(List<CallRecord> calls) {
    final buckets = <DateTime, int>{};
    for (final call in calls) {
      final day = DateTime(call.timestamp.year, call.timestamp.month, call.timestamp.day);
      buckets.update(day, (value) => value + call.durationSec, ifAbsent: () => call.durationSec);
    }
    return buckets;
  }

  Map<int, int> bucketByHour(List<CallRecord> calls) {
    final buckets = <int, int>{};
    for (final call in calls) {
      buckets.update(call.timestamp.hour, (value) => value + 1, ifAbsent: () => 1);
    }
    return buckets;
  }

  Map<int, int> bucketByWeekday(List<CallRecord> calls) {
    final buckets = <int, int>{};
    for (final call in calls) {
      buckets.update(call.timestamp.weekday, (value) => value + 1, ifAbsent: () => 1);
    }
    return buckets;
  }

  ReturnedCallStats returnedCallStats(List<CallRecord> calls) {
    final missedCalls = calls
        .where((call) => call.type == CallType.missed)
        .sortedBy((call) => call.timestamp);
    final outgoingCalls = calls
        .where((call) => call.type == CallType.outgoing)
        .sortedBy((call) => call.timestamp);

    var returnedCount = 0;
    var outgoingIndex = 0;

    for (final missed in missedCalls) {
      while (outgoingIndex < outgoingCalls.length &&
          outgoingCalls[outgoingIndex].timestamp.isBefore(missed.timestamp)) {
        outgoingIndex++;
      }
      final cutoff = missed.timestamp.add(const Duration(minutes: 60));
      final matched = outgoingCalls
          .skip(outgoingIndex)
          .firstWhereOrNull((call) =>
              call.number == missed.number &&
              !call.timestamp.isAfter(cutoff));
      if (matched != null) {
        returnedCount++;
      }
    }

    return ReturnedCallStats(
      missedCount: missedCalls.length,
      returnedCount: returnedCount,
    );
  }
}
