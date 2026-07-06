class DiscoveryRecord {
  final String rewardId;
  final bool discovered;
  final DateTime? discoveredAt;
  final int timesObtained;

  const DiscoveryRecord({
    required this.rewardId,
    required this.discovered,
    this.discoveredAt,
    this.timesObtained = 0,
  });

  DiscoveryRecord copyWith({
    String? rewardId,
    bool? discovered,
    DateTime? discoveredAt,
    int? timesObtained,
  }) {
    return DiscoveryRecord(
      rewardId: rewardId ?? this.rewardId,
      discovered: discovered ?? this.discovered,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      timesObtained: timesObtained ?? this.timesObtained,
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'discovered': discovered,
        'discoveredAt': discoveredAt?.toIso8601String(),
        'timesObtained': timesObtained,
      };

  factory DiscoveryRecord.fromJson(Map<String, dynamic> json) => DiscoveryRecord(
        rewardId: json['rewardId'] as String? ?? '',
        discovered: json['discovered'] as bool? ?? false,
        discoveredAt: json['discoveredAt'] != null
            ? DateTime.tryParse(json['discoveredAt'] as String)
            : null,
        timesObtained: json['timesObtained'] as int? ?? 0,
      );
}
