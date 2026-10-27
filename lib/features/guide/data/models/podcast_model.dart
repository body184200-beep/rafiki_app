class PodcastEpisode {
  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.channelTitle,
    required this.formattedDuration,
    this.duration = Duration.zero,
    this.artworkUrl = '',
  });

  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String channelTitle;
  final String formattedDuration;
  final Duration duration;
  final String artworkUrl;
}

class PodcastChannel {
  const PodcastChannel({
    required this.id,
    required this.title,
    required this.artworkUrl,
    this.artist = '',
    this.episodes = const [],
  });

  final String id;
  final String title;
  final String artworkUrl;
  final String artist;
  final List<PodcastEpisode> episodes;
}
