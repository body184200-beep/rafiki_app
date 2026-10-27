import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';

class PodcastService {
  PodcastService._() {
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isBuffering.value = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
    });
    _player.positionStream.listen((value) => position.value = value);
    _player.durationStream.listen((value) {
      if (value != null) duration.value = value;
    });
    _player.speedStream.listen((value) => speed.value = value);
  }

  static final PodcastService instance = PodcastService._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<PodcastEpisode?> currentEpisode = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isBuffering = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> speed = ValueNotifier(1);

  static const _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];

  Future<List<PodcastChannel>> loadFeaturedChannels() {
    return searchPodcasts('بودكاست إسلامي');
  }

  Future<List<PodcastChannel>> searchPodcasts(String query) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'media': 'podcast',
      'country': 'sa',
      'limit': '12',
    });
    return _channelsFrom(uri, podcastOnly: true);
  }

  Future<List<PodcastEpisode>> fetchEpisodesForChannel(
    String channelId, {
    required String channelTitle,
    required String artworkUrl,
  }) async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'id': channelId,
      'entity': 'podcastEpisode',
      'limit': '25',
    });
    try {
      final body = await _getJson(uri);
      final results = body['results'];
      if (results is! List) return const [];
      return results.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        if (item['kind'] != 'podcast-episode') return null;
        final audio = item['episodeUrl'] as String? ?? '';
        if (audio.isEmpty) return null;
        final millis = item['trackTimeMillis'] as int? ?? 0;
        final episodeDuration = Duration(milliseconds: millis);
        return PodcastEpisode(
          id: '${item['trackId'] ?? audio}',
          title: item['trackName'] as String? ?? '',
          description: item['description'] as String? ?? item['shortDescription'] as String? ?? '',
          audioUrl: audio,
          channelTitle: channelTitle,
          formattedDuration: _format(episodeDuration),
          duration: episodeDuration,
          artworkUrl: item['artworkUrl160'] as String? ?? artworkUrl,
        );
      }).whereType<PodcastEpisode>().toList();
    } catch (e) {
      debugPrint('Podcast episodes failed: $e');
      return const [];
    }
  }

  Future<void> playEpisode(PodcastEpisode episode) async {
    currentEpisode.value = episode;
    duration.value = episode.duration;
    position.value = Duration.zero;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(episode.audioUrl)));
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else if (currentEpisode.value != null) {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    currentEpisode.value = null;
    position.value = Duration.zero;
  }

  Future<void> seek(Duration to) => _player.seek(to);

  Future<void> seekForward10() {
    final next = position.value + const Duration(seconds: 10);
    final cap = duration.value;
    return seek(next > cap && cap > Duration.zero ? cap : next);
  }

  Future<void> seekBackward10() {
    final next = position.value - const Duration(seconds: 10);
    return seek(next.isNegative ? Duration.zero : next);
  }

  Future<void> setPlaybackSpeed(double value) => _player.setSpeed(value);

  void cycleSpeed() {
    final index = _speeds.indexOf(speed.value);
    final next = _speeds[(index + 1) % _speeds.length];
    setPlaybackSpeed(next);
  }

  Future<List<PodcastChannel>> _channelsFrom(Uri uri, {required bool podcastOnly}) async {
    try {
      final body = await _getJson(uri);
      final results = body['results'];
      if (results is! List) return const [];
      return results.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        if (podcastOnly && item['kind'] != 'podcast') return null;
        final id = item['trackId'] ?? item['collectionId'];
        if (id == null) return null;
        return PodcastChannel(
          id: '$id',
          title: item['trackName'] as String? ?? item['collectionName'] as String? ?? '',
          artworkUrl: item['artworkUrl600'] as String? ?? item['artworkUrl100'] as String? ?? '',
          artist: item['artistName'] as String? ?? '',
        );
      }).whereType<PodcastChannel>().toList();
    } catch (e) {
      debugPrint('Podcast search failed: $e');
      return const [];
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

  String _format(Duration value) {
    if (value == Duration.zero) return '';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
