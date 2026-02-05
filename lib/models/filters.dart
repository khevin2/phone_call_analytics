enum DateFilterPreset { today, last7, last30, last90, thisMonth, allTime, custom }

enum SimFilter { all, sim1, sim2, unknown }

class DateRangeFilter {
  DateRangeFilter({
    required this.preset,
    required this.start,
    required this.end,
  });

  final DateFilterPreset preset;
  final DateTime start;
  final DateTime end;
}
