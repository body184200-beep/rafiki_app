import 'package:rafiki_app/core/utils/time_format.dart';

class PodcastChannel {
  final int id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String feedUrl;
  final int episodeCount;
  final List<PodcastEpisode> episodes;

  const PodcastChannel({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.feedUrl = '',
    this.episodeCount = 0,
    this.episodes = const [],
  });

  factory PodcastChannel.fromJson(Map<String, dynamic> json) {
    final epList = (json['episodes'] as List? ?? [])
        .map((e) => PodcastEpisode.fromJson(e as Map<String, dynamic>, channelId: json['id'] as int? ?? 0, channelTitle: json['title'] as String? ?? ''))
        .toList();

    return PodcastChannel(
      id: json['id'] as int? ?? json['collectionId'] as int? ?? 0,
      title: (json['title'] as String? ?? json['collectionName'] as String? ?? '').trim(),
      artist: (json['artist'] as String? ?? json['artistName'] as String? ?? '').trim(),
      artworkUrl: json['artworkUrl'] as String? ?? json['artworkUrl600'] as String? ?? json['artworkUrl100'] as String? ?? '',
      feedUrl: json['feedUrl'] as String? ?? '',
      episodeCount: json['episodeCount'] as int? ?? json['trackCount'] as int? ?? epList.length,
      episodes: epList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'artworkUrl': artworkUrl,
    'feedUrl': feedUrl,
    'episodeCount': episodeCount,
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };

  PodcastChannel copyWith({List<PodcastEpisode>? episodes}) {
    return PodcastChannel(
      id: id,
      title: title,
      artist: artist,
      artworkUrl: artworkUrl,
      feedUrl: feedUrl,
      episodeCount: episodeCount,
      episodes: episodes ?? this.episodes,
    );
  }
}

class PodcastEpisode {
  final int id;
  final int channelId;
  final String channelTitle;
  final String title;
  final String description;
  final String audioUrl;
  final int durationMs;
  final String releaseDate;
  final String artworkUrl;

  const PodcastEpisode({
    required this.id,
    this.channelId = 0,
    this.channelTitle = '',
    required this.title,
    required this.description,
    required this.audioUrl,
    this.durationMs = 0,
    this.releaseDate = '',
    this.artworkUrl = '',
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json, {int channelId = 0, String channelTitle = ''}) {
    return PodcastEpisode(
      id: json['id'] as int? ?? json['trackId'] as int? ?? 0,
      channelId: json['channelId'] as int? ?? channelId,
      channelTitle: json['channelTitle'] as String? ?? channelTitle,
      title: _cleanTitle(json['title'] as String? ?? json['trackName'] as String? ?? ''),
      description: _cleanHtml(json['description'] as String? ?? ''),
      audioUrl: json['audioUrl'] as String? ?? json['episodeUrl'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? json['trackTimeMillis'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String? ?? '',
      artworkUrl: json['artworkUrl'] as String? ?? json['artworkUrl600'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'channelId': channelId,
    'channelTitle': channelTitle,
    'title': title,
    'description': description,
    'audioUrl': audioUrl,
    'durationMs': durationMs,
    'releaseDate': releaseDate,
    'artworkUrl': artworkUrl,
  };

  String get formattedDuration {
    if (durationMs <= 0) return 'حلقة صوتية';
    final totalMinutes = (durationMs / 60000).round();
    if (totalMinutes < 60) {
      return '$totalMinutes دقيقة';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '$hours ساعة${mins > 0 ? " و$mins د" : ""}';
  }

  static String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'^\d+[\s_-]*'), '') // Remove leading track numbers like 001_
        .replaceAll('｜', ' - ')
        .replaceAll('|', ' - ')
        .trim();
  }

  static String _cleanHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
