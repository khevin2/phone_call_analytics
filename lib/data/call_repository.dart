import 'package:sqflite/sqflite.dart';

import '../models/call_record.dart';
import '../models/filters.dart';

class CallRepository {
  CallRepository(this.db);

  final Database db;

  Future<void> upsertCalls(List<CallRecord> calls) async {
    if (calls.isEmpty) return;
    final batch = db.batch();
    for (final call in calls) {
      batch.insert(
        'calls',
        call.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CallRecord>> fetchCalls({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
    int limit = 5000,
    int offset = 0,
  }) async {
    final whereArgs = <Object?>[
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ];
    final whereClauses = <String>[
      'timestamp >= ?',
      'timestamp <= ?',
    ];
    if (simFilter != SimFilter.all) {
      final simSlot = switch (simFilter) {
        SimFilter.sim1 => 1,
        SimFilter.sim2 => 2,
        SimFilter.unknown => 0,
        SimFilter.all => null,
      };
      whereClauses.add('simSlot = ?');
      whereArgs.add(simSlot);
    }
    final rows = await db.query(
      'calls',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  Future<int> totalCalls({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
  }) async {
    final result = await _aggregate(
      'COUNT(*) as total',
      start,
      end,
      simFilter,
    );
    return (result.firstOrNull?['total'] as int?) ?? 0;
  }

  Future<int> totalDuration({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
  }) async {
    final result = await _aggregate(
      'SUM(durationSec) as totalDuration',
      start,
      end,
      simFilter,
    );
    return (result.firstOrNull?['totalDuration'] as int?) ?? 0;
  }

  Future<Map<CallType, int>> typeBreakdown({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
  }) async {
    final whereResult = await _aggregateRows(
      'SELECT type, COUNT(*) as total FROM calls',
      start,
      end,
      simFilter,
      groupBy: 'type',
    );
    final breakdown = <CallType, int>{};
    for (final row in whereResult) {
      final type = CallType.values[(row['type'] as int?) ?? CallType.unknown.index];
      breakdown[type] = (row['total'] as int?) ?? 0;
    }
    return breakdown;
  }

  Future<List<Map<String, Object?>>> callsPerDay({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
  }) async {
    return _aggregateRows(
      '''
      SELECT (timestamp / 86400000) as dayBucket, COUNT(*) as total
      FROM calls
      ''',
      start,
      end,
      simFilter,
      groupBy: 'dayBucket',
      orderBy: 'dayBucket ASC',
    );
  }

  Future<List<Map<String, Object?>>> durationPerDay({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
  }) async {
    return _aggregateRows(
      '''
      SELECT (timestamp / 86400000) as dayBucket, SUM(durationSec) as total
      FROM calls
      ''',
      start,
      end,
      simFilter,
      groupBy: 'dayBucket',
      orderBy: 'dayBucket ASC',
    );
  }

  Future<List<Map<String, Object?>>> topNumbers({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
    int limit = 10,
  }) async {
    return _aggregateRows(
      '''
      SELECT number, name, COUNT(*) as totalCalls, SUM(durationSec) as totalDuration
      FROM calls
      ''',
      start,
      end,
      simFilter,
      groupBy: 'number',
      orderBy: 'totalCalls DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, Object?>>> mostMissed({
    required DateTime start,
    required DateTime end,
    SimFilter simFilter = SimFilter.all,
    int limit = 10,
  }) async {
    return _aggregateRows(
      '''
      SELECT number, name, COUNT(*) as totalMissed
      FROM calls
      ''',
      start,
      end,
      simFilter,
      additionalWhere: 'type = ${CallType.missed.index}',
      groupBy: 'number',
      orderBy: 'totalMissed DESC',
      limit: limit,
    );
  }

  Future<void> clearAll() async {
    await db.delete('calls');
  }

  Future<List<Map<String, Object?>>> _aggregate(
    String projection,
    DateTime start,
    DateTime end,
    SimFilter simFilter,
  ) async {
    return _aggregateRows(
      'SELECT $projection FROM calls',
      start,
      end,
      simFilter,
    );
  }

  Future<List<Map<String, Object?>>> _aggregateRows(
    String baseQuery,
    DateTime start,
    DateTime end,
    SimFilter simFilter, {
    String? groupBy,
    String? orderBy,
    String? additionalWhere,
    int? limit,
  }) async {
    final whereClauses = <String>[
      'timestamp >= ?',
      'timestamp <= ?',
    ];
    final args = <Object?>[
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ];
    if (simFilter != SimFilter.all) {
      whereClauses.add('simSlot = ?');
      args.add(switch (simFilter) {
        SimFilter.sim1 => 1,
        SimFilter.sim2 => 2,
        SimFilter.unknown => 0,
        SimFilter.all => null,
      });
    }
    if (additionalWhere != null) {
      whereClauses.add(additionalWhere);
    }
    final buffer = StringBuffer(baseQuery);
    buffer.write(' WHERE ${whereClauses.join(' AND ')}');
    if (groupBy != null) buffer.write(' GROUP BY $groupBy');
    if (orderBy != null) buffer.write(' ORDER BY $orderBy');
    if (limit != null) buffer.write(' LIMIT $limit');
    return db.rawQuery(buffer.toString(), args);
  }
}

extension on List<Map<String, Object?>> {
  Map<String, Object?>? get firstOrNull => isEmpty ? null : first;
}
