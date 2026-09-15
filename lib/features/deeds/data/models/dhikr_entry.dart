class DhikrEntry {
  String text;
  int count;
  int target; // 0 = no target
  String? virtue; // فضل الذكر النبوي
  int cycle; // عدد الدورات المكتملة

  DhikrEntry({
    required this.text,
    this.count = 0,
    this.target = 0,
    this.virtue,
    this.cycle = 0,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'count': count,
    'target': target,
    'virtue': virtue,
    'cycle': cycle,
  };

  factory DhikrEntry.fromJson(Map<String, dynamic> json) => DhikrEntry(
    text: json['text'] as String,
    count: json['count'] as int? ?? 0,
    target: json['target'] as int? ?? 0,
    virtue: json['virtue'] as String?,
    cycle: json['cycle'] as int? ?? 0,
  );
}
