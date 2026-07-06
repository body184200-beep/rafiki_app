enum PrayerState {
  locked,               // before prayer time
  available,            // during prayer window — this is the ONLY open prayer
  completedIndividual,  // prayed alone on time
  completedCongregation,// prayed in congregation on time
  oadaPending,          // missed (qada owed)
  oadaCompleted,        // qada made up
}

extension PrayerStateX on PrayerState {
  bool get isCompleted =>
      this == PrayerState.completedIndividual ||
      this == PrayerState.completedCongregation ||
      this == PrayerState.oadaCompleted;

  bool get isFinal => isCompleted;

  String toJson() => name;
  static PrayerState fromJson(String s) =>
      PrayerState.values.firstWhere((e) => e.name == s,
          orElse: () => PrayerState.locked);
}

class PrayerRecord {
  PrayerState state;
  Set<int> completedSunnah;
  double scoreAwarded;       // actual fardh score credited
  double sunnahScoreAwarded; // sunnah score accumulated separately
  bool countedInStreak;

  PrayerRecord({
    this.state = PrayerState.locked,
    Set<int>? completedSunnah,
    this.scoreAwarded = 0,
    this.sunnahScoreAwarded = 0,
    this.countedInStreak = false,
  }) : completedSunnah = completedSunnah ?? {};

  Map<String, dynamic> toJson() => {
    'state': state.toJson(),
    'sunnah': completedSunnah.toList(),
    'score': scoreAwarded,
    'sunnahScore': sunnahScoreAwarded,
    'countedInStreak': countedInStreak,
  };

  factory PrayerRecord.fromJson(Map<String, dynamic> j) => PrayerRecord(
    state: PrayerStateX.fromJson(j['state'] as String? ?? 'locked'),
    completedSunnah: Set<int>.from((j['sunnah'] as List<dynamic>?) ?? []),
    scoreAwarded: (j['score'] as num?)?.toDouble() ?? 0,
    sunnahScoreAwarded: (j['sunnahScore'] as num?)?.toDouble() ?? 0,
    countedInStreak: (j['countedInStreak'] as bool?) ?? false,
  );
}

class DayRecord {
  final String dateKey;
  final Map<String, PrayerRecord> prayers; // keyed by prayer name
  double totalScore;
  int dailyStreakCount;

  DayRecord({
    required this.dateKey,
    Map<String, PrayerRecord>? prayers,
    this.totalScore = 0,
    this.dailyStreakCount = 0,
  }) : prayers = prayers ?? {};

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'prayers': prayers.map((k, v) => MapEntry(k, v.toJson())),
    'total': totalScore,
    'dailyStreak': dailyStreakCount,
  };

  factory DayRecord.fromJson(Map<String, dynamic> j) {
    final raw = j['prayers'] as Map<String, dynamic>? ?? {};
    return DayRecord(
      dateKey: j['date'] as String,
      prayers: raw.map((k, v) =>
          MapEntry(k, PrayerRecord.fromJson(v as Map<String, dynamic>))),
      totalScore: (j['total'] as num?)?.toDouble() ?? 0,
      dailyStreakCount: (j['dailyStreak'] as int?) ?? 0,
    );
  }

  PrayerRecord recordFor(dynamic prayer) {
    final String name = prayer is String ? prayer : (prayer as dynamic).name;
    return prayers.putIfAbsent(name, () => PrayerRecord());
  }
}

class QadaEntry {
  final String prayerName;
  final String dateKey;

  QadaEntry({required this.prayerName, required this.dateKey});

  Map<String, dynamic> toJson() => {
    'prayer': prayerName,
    'date': dateKey,
  };

  factory QadaEntry.fromJson(Map<String, dynamic> j) => QadaEntry(
    prayerName: j['prayer'] as String? ?? '',
    dateKey: j['date'] as String? ?? '',
  );
}
