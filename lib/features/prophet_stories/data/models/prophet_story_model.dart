class ProphetStory {
  const ProphetStory({
    required this.name,
    required this.title,
    required this.summary,
    required this.fullStory,
    required this.period,
    required this.quranMentions,
    required this.icon,
  });

  final String name;
  final String title;
  final String summary;
  final String fullStory;
  final String period;
  final String quranMentions;
  final String icon;

  factory ProphetStory.fromJson(Map<String, dynamic> json) {
    return ProphetStory(
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      fullStory: json['fullStory'] as String? ?? json['story'] as String? ?? '',
      period: json['period'] as String? ?? '',
      quranMentions: json['quranMentions'] as String? ?? '',
      icon: json['icon'] as String? ?? '📖',
    );
  }
}
