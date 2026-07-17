class DhikrEntry {
  String text;
  int count;
  int target;     // 0 = no target
  DhikrEntry({required this.text, this.count = 0, this.target = 0});

  Map<String, dynamic> toJson() => {
    'text': text,
    'count': count,
    'target': target,
  };

  factory DhikrEntry.fromJson(Map<String, dynamic> json) => DhikrEntry(
    text: json['text'] as String,
    count: json['count'] as int? ?? 0,
    target: json['target'] as int? ?? 0,
  );
}
