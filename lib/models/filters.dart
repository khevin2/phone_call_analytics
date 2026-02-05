enum DateFilterPreset { today, last7, last30, last90, thisMonth, allTime, custom }

/// Start date used for "All time" filter to capture all historical call data
final allTimeStartDate = DateTime(2000, 1, 1);

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
