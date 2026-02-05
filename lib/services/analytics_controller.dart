import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_service.dart';
import '../data/call_repository.dart';
import '../models/call_record.dart';
import '../models/filters.dart';
import 'providers.dart';

class AnalyticsState {
  AnalyticsState({
    required this.calls,
    required this.summary,
    required this.returnedStats,
  });

  final List<CallRecord> calls;
  final AnalyticsSummary summary;
  final ReturnedCallStats returnedStats;
}

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AsyncValue<AnalyticsState>>((
      ref,
    ) {
      return AnalyticsController(ref, AnalyticsService());
    });

class AnalyticsController extends StateNotifier<AsyncValue<AnalyticsState>> {
  AnalyticsController(this.ref, this.analyticsService)
    : super(const AsyncValue.loading());

  final Ref ref;
  final AnalyticsService analyticsService;

  Future<void> loadAnalytics({
    required DateTime start,
    required DateTime end,
    required SimFilter simFilter,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(callRepositoryProvider.future);
      final calls = await repository.fetchCalls(
        start: start,
        end: end,
        simFilter: simFilter,
        limit: 20000,
      );
      final summary = analyticsService.buildSummary(calls);
      final returnedStats = analyticsService.returnedCallStats(calls);
      return AnalyticsState(
        calls: calls,
        summary: summary,
        returnedStats: returnedStats,
      );
    });
  }
}
