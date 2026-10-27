class ProphetStory {
  final int id;
  final String name;
  final String title;
  final String icon;
  final String period;
  final String quranMentions;
  final String summary;
  final String fullStory;

  const ProphetStory({
    required this.id,
    required this.name,
    required this.title,
    required this.icon,
    required this.period,
    required this.quranMentions,
    required this.summary,
    required this.fullStory,
  });

  factory ProphetStory.fromJson(Map<String, dynamic> json) {
    final mentions = json['quranMentions'];
    String mentionsStr;
    if (mentions is int) {
      mentionsStr = '$mentions مرة في القرآن الكريم';
    } else {
      mentionsStr = (mentions ?? '').toString();
    }

    return ProphetStory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '📖',
      period: json['period'] as String? ?? '',
      quranMentions: mentionsStr,
      summary: json['summary'] as String? ?? '',
      fullStory: (json['fullStory'] ?? json['story'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'icon': icon,
    'period': period,
    'quranMentions': quranMentions,
    'summary': summary,
    'fullStory': fullStory,
  };
}
