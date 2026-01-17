enum CallType { incoming, outgoing, missed, rejected, unknown }

class CallRecord {
  CallRecord({
    required this.callId,
    required this.number,
    required this.name,
    required this.type,
    required this.timestamp,
    required this.durationSec,
    required this.simSlot,
    required this.subscriptionId,
    required this.phoneAccountId,
    required this.phoneAccountComponentName,
    required this.createdAt,
  });

  final int callId;
  final String number;
  final String? name;
  final CallType type;
  final DateTime timestamp;
  final int durationSec;
  final int simSlot;
  final int? subscriptionId;
  final String? phoneAccountId;
  final String? phoneAccountComponentName;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'callId': callId,
      'number': number,
      'name': name,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durationSec': durationSec,
      'simSlot': simSlot,
      'subscriptionId': subscriptionId,
      'phoneAccountId': phoneAccountId,
      'phoneAccountComponentName': phoneAccountComponentName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CallRecord.fromMap(Map<String, Object?> map) {
    return CallRecord(
      callId: map['callId'] as int,
      number: (map['number'] as String?) ?? 'Unknown',
      name: map['name'] as String?,
      type: CallType.values[((map['type'] as int?) ?? CallType.unknown.index)
          .clamp(0, CallType.values.length - 1)
          .toInt()],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      durationSec: (map['durationSec'] as int?) ?? 0,
      simSlot: (map['simSlot'] as int?) ?? 0,
      subscriptionId: map['subscriptionId'] as int?,
      phoneAccountId: map['phoneAccountId'] as String?,
      phoneAccountComponentName: map['phoneAccountComponentName'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }
}
