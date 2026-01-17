import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/call_record.dart';

class ExportService {
  Future<void> exportCsv(List<CallRecord> calls) async {
    final rows = [
      [
        'callId',
        'number',
        'name',
        'type',
        'timestamp',
        'durationSec',
        'simSlot',
        'subscriptionId',
        'phoneAccountId',
        'phoneAccountComponentName',
      ],
      ...calls.map((call) => [
            call.callId,
            call.number,
            call.name ?? '',
            call.type.name,
            call.timestamp.toIso8601String(),
            call.durationSec,
            call.simSlot,
            call.subscriptionId ?? '',
            call.phoneAccountId ?? '',
            call.phoneAccountComponentName ?? '',
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    await _shareFile('callsense_export.csv', csv);
  }

  Future<void> exportJson(List<CallRecord> calls) async {
    final payload = calls
        .map((call) => {
              'callId': call.callId,
              'number': call.number,
              'name': call.name,
              'type': call.type.name,
              'timestamp': call.timestamp.toIso8601String(),
              'durationSec': call.durationSec,
              'simSlot': call.simSlot,
              'subscriptionId': call.subscriptionId,
              'phoneAccountId': call.phoneAccountId,
              'phoneAccountComponentName': call.phoneAccountComponentName,
            })
        .toList();
    final jsonData = const JsonEncoder.withIndent('  ').convert(payload);
    await _shareFile('callsense_export.json', jsonData);
  }

  Future<void> _shareFile(String name, String content) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
