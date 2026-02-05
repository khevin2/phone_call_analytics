import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../analytics/analytics_service.dart';
import '../../models/call_record.dart';
import '../../models/filters.dart';
import '../../services/analytics_controller.dart';
import '../../services/demo_data_service.dart';
import '../../services/export_service.dart';
import '../../services/permission_service.dart';
import '../../services/providers.dart';
import '../../services/sync_service.dart';
import '../widgets/chart_card.dart';
import '../widgets/summary_card.dart';
import 'contact_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late DateRangeFilter _dateFilter;
  SimFilter _simFilter = SimFilter.all;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFilter = DateRangeFilter(
      preset: DateFilterPreset.last30,
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    await ref
        .read(analyticsControllerProvider.notifier)
        .loadAnalytics(
          start: _dateFilter.start,
          end: _dateFilter.end,
          simFilter: _simFilter,
        );
  }

  Future<void> _syncNow() async {
    final repository = await ref.read(callRepositoryProvider.future);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    try {
      await SyncService(repository, prefs).syncCallLogs();
      await _loadAnalytics();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $error')));
      }
    }
  }

  Future<void> _seedDemoData() async {
    final repository = await ref.read(callRepositoryProvider.future);
    await DemoDataService(repository).seedDemoData();
    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsControllerProvider);
    final formatter = DateFormat('MMM d');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallSense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: _syncNow,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'exportCsv') {
                final state = ref.read(analyticsControllerProvider).valueOrNull;
                if (state != null) {
                  await ExportService().exportCsv(state.calls);
                }
              }
              if (value == 'exportJson') {
                final state = ref.read(analyticsControllerProvider).valueOrNull;
                if (state != null) {
                  await ExportService().exportJson(state.calls);
                }
              }
              if (value == 'seedDemo') {
                await _seedDemoData();
              }
              if (value == 'enableContacts') {
                final granted = await PermissionService()
                    .requestContactsPermission();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        granted
                            ? 'Contacts permission granted.'
                            : 'Contacts permission denied.',
                      ),
                    ),
                  );
                }
              }
              if (value == 'deleteAll') {
                final repository = await ref.read(
                  callRepositoryProvider.future,
                );
                await repository.clearAll();
                await _loadAnalytics();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'exportCsv',
                child: Text('Export CSV'),
              ),
              const PopupMenuItem(
                value: 'exportJson',
                child: Text('Export JSON'),
              ),
              const PopupMenuItem(
                value: 'seedDemo',
                child: Text('Demo mode: seed data'),
              ),
              const PopupMenuItem(
                value: 'enableContacts',
                child: Text('Enable contact name resolution'),
              ),
              const PopupMenuItem(
                value: 'deleteAll',
                child: Text('Delete all data'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Insights'),
            Tab(text: 'Top'),
          ],
        ),
      ),
      body: Column(
        children: [
          _FiltersBar(
            dateFilter: _dateFilter,
            simFilter: _simFilter,
            onDateFilterChanged: (filter) async {
              setState(() => _dateFilter = filter);
              await _loadAnalytics();
            },
            onSimFilterChanged: (filter) async {
              setState(() => _simFilter = filter);
              await _loadAnalytics();
            },
          ),
          Expanded(
            child: analyticsState.when(
              data: (state) {
                if (state.calls.isEmpty) {
                  return const _EmptyState();
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(state: state),
                    _TrendsTab(calls: state.calls, formatter: formatter),
                    _InsightsTab(calls: state.calls),
                    _TopTab(calls: state.calls),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncNow,
        icon: const Icon(Icons.cloud_sync_outlined),
        label: const Text('Sync now'),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.dateFilter,
    required this.simFilter,
    required this.onDateFilterChanged,
    required this.onSimFilterChanged,
  });

  final DateRangeFilter dateFilter;
  final SimFilter simFilter;
  final ValueChanged<DateRangeFilter> onDateFilterChanged;
  final ValueChanged<SimFilter> onSimFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            DropdownButton<DateFilterPreset>(
              value: dateFilter.preset,
              onChanged: (preset) async {
                if (preset == null) return;
                final now = DateTime.now();
                DateTime start = dateFilter.start;
                DateTime end = dateFilter.end;
                if (preset == DateFilterPreset.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: now,
                    initialDateRange: DateTimeRange(start: start, end: end),
                  );
                  if (range == null) return;
                  start = range.start;
                  end = range.end;
                } else {
                  switch (preset) {
                    case DateFilterPreset.today:
                      start = DateTime(now.year, now.month, now.day);
                      end = now;
                    case DateFilterPreset.last7:
                      start = now.subtract(const Duration(days: 7));
                      end = now;
                    case DateFilterPreset.last30:
                      start = now.subtract(const Duration(days: 30));
                      end = now;
                    case DateFilterPreset.last90:
                      start = now.subtract(const Duration(days: 90));
                      end = now;
                    case DateFilterPreset.thisMonth:
                      start = DateTime(now.year, now.month, 1);
                      end = now;
                    case DateFilterPreset.allTime:
                      start = allTimeStartDate;
                      end = now;
                    case DateFilterPreset.custom:
                      break;
                  }
                }
                onDateFilterChanged(
                  DateRangeFilter(preset: preset, start: start, end: end),
                );
              },
              items: DateFilterPreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(_presetLabel(preset)),
                    ),
                  )
                  .toList(),
            ),
            DropdownButton<SimFilter>(
              value: simFilter,
              onChanged: (value) {
                if (value != null) onSimFilterChanged(value);
              },
              items: SimFilter.values
                  .map(
                    (filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(_simLabel(filter)),
                    ),
                  )
                  .toList(),
            ),
            const _PermissionChip(),
          ],
        ),
      ),
    );
  }

  String _presetLabel(DateFilterPreset preset) {
    return switch (preset) {
      DateFilterPreset.today => 'Today',
      DateFilterPreset.last7 => 'Last 7 days',
      DateFilterPreset.last30 => 'Last 30 days',
      DateFilterPreset.last90 => 'Last 90 days',
      DateFilterPreset.thisMonth => 'This month',
      DateFilterPreset.allTime => 'All time',
      DateFilterPreset.custom => 'Custom range',
    };
  }

  String _simLabel(SimFilter filter) {
    return switch (filter) {
      SimFilter.all => 'All SIMs',
      SimFilter.sim1 => 'SIM1',
      SimFilter.sim2 => 'SIM2',
      SimFilter.unknown => 'Unknown SIM',
    };
  }
}

class _PermissionChip extends ConsumerWidget {
  const _PermissionChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(permissionStateProvider)
        .when(
          data: (state) => Chip(
            avatar: Icon(
              state.hasPermissions ? Icons.lock_open : Icons.lock_outline,
            ),
            label: Text(
              state.hasPermissions ? 'Permissions granted' : 'Limited mode',
            ),
            backgroundColor: state.hasPermissions
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
          ),
          loading: () => const Chip(label: Text('Checking permissions...')),
          error: (error, _) => Chip(label: Text('Permission error: $error')),
        );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SummaryCard(
              title: 'Total calls',
              value: summary.totalCalls.toString(),
              icon: Icons.call,
            ),
            SummaryCard(
              title: 'Total duration',
              value: '${summary.totalDuration ~/ 60} min',
              subtitle: '${summary.totalDuration} sec total',
              icon: Icons.timer_outlined,
            ),
            SummaryCard(
              title: 'Avg duration',
              value: '${summary.averageDuration.toStringAsFixed(1)} sec',
              icon: Icons.timelapse,
            ),
            SummaryCard(
              title: 'Returned missed calls',
              value: '${state.returnedStats.returnedCount}',
              subtitle:
                  'Rate ${(state.returnedStats.returnRate * 100).toStringAsFixed(1)}%',
              icon: Icons.reply,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'Call type breakdown',
          child: PieChart(
            PieChartData(
              sections: summary.breakdown.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${entry.key.name}\n${entry.value}',
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab({required this.calls, required this.formatter});

  final List<CallRecord> calls;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final service = AnalyticsService();
    final callBuckets = service.bucketCallsByDay(calls);
    final durationBuckets = service.bucketDurationByDay(calls);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChartCard(
          title: 'Calls per day',
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: callBuckets.entries
                      .map(
                        (entry) => FlSpot(
                          entry.key.millisecondsSinceEpoch.toDouble(),
                          entry.value.toDouble(),
                        ),
                      )
                      .toList(),
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: const Duration(days: 7).inMilliseconds.toDouble(),
                    getTitlesWidget: (value, meta) => Text(
                      formatter.format(
                        DateTime.fromMillisecondsSinceEpoch(value.toInt()),
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'Duration per day (sec)',
          child: BarChart(
            BarChartData(
              barGroups: durationBuckets.entries
                  .map(
                    (entry) => BarChartGroupData(
                      x: entry.key.millisecondsSinceEpoch,
                      barRods: [BarChartRodData(toY: entry.value.toDouble())],
                    ),
                  )
                  .toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      formatter.format(
                        DateTime.fromMillisecondsSinceEpoch(value.toInt()),
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.calls});

  final List<CallRecord> calls;

  @override
  Widget build(BuildContext context) {
    final service = AnalyticsService();
    final byHour = service.bucketByHour(calls);
    final byWeekday = service.bucketByWeekday(calls);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChartCard(
          title: 'Calls by hour',
          child: BarChart(
            BarChartData(
              barGroups: List.generate(24, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(toY: (byHour[index] ?? 0).toDouble()),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'Calls by weekday',
          child: BarChart(
            BarChartData(
              barGroups: List.generate(7, (index) {
                return BarChartGroupData(
                  x: index + 1,
                  barRods: [
                    BarChartRodData(
                      toY: (byWeekday[index + 1] ?? 0).toDouble(),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({required this.calls});

  final List<CallRecord> calls;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CallRecord>>{};
    for (final call in calls) {
      grouped.putIfAbsent(call.number, () => []).add(call);
    }
    final top = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: top.length,
      itemBuilder: (context, index) {
        final entry = top[index];
        final name = entry.value.first.name;
        final duration = entry.value.fold<int>(
          0,
          (sum, call) => sum + call.durationSec,
        );
        return Card(
          child: ListTile(
            title: Text(name?.isNotEmpty == true ? name! : entry.key),
            subtitle: Text(
              '${entry.value.length} calls · ${duration ~/ 60} min',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ContactDetailScreen(
                    number: entry.key,
                    name: name,
                    calls: entry.value,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No calls yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sync your call log or enable demo mode to see analytics.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
