import 'package:flutter/services.dart';

class CallLogChannel {
  static const MethodChannel _channel = MethodChannel('callsense/call_log');

  static Future<List<Map<String, Object?>>> getCallLogs({
    required int fromMillis,
    required int toMillis,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('getCallLogs', {
      'fromMillis': fromMillis,
      'toMillis': toMillis,
    });
    return result
            ?.map((entry) => Map<String, Object?>.from(entry as Map))
            .toList() ??
        [];
  }

  static Future<List<Map<String, Object?>>> getSubscriptions() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getSubscriptions');
    return result
            ?.map((entry) => Map<String, Object?>.from(entry as Map))
            .toList() ??
        [];
  }
}
