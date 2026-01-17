class SubscriptionInfoModel {
  SubscriptionInfoModel({
    required this.subscriptionId,
    required this.simSlotIndex,
    required this.displayName,
    required this.carrierName,
    required this.number,
  });

  final int subscriptionId;
  final int simSlotIndex;
  final String displayName;
  final String carrierName;
  final String? number;

  factory SubscriptionInfoModel.fromMap(Map<String, Object?> map) {
    return SubscriptionInfoModel(
      subscriptionId: map['subscriptionId'] as int? ?? -1,
      simSlotIndex: map['simSlotIndex'] as int? ?? 0,
      displayName: (map['displayName'] as String?) ?? 'SIM',
      carrierName: (map['carrierName'] as String?) ?? 'Carrier',
      number: map['number'] as String?,
    );
  }
}
