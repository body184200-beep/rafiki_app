import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';

class PodcastService {
  PodcastService._internal() {
    _initAudioListeners();
  }
  static final PodcastService instance = PodcastService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final ValueNotifier<PodcastEpisode?> currentEpisode = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isBuffering = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> speed = ValueNotifier(1.0);

  List<PodcastChannel> _cachedChannels = [];
  final Map<int, List<PodcastEpisode>> _episodesCache = {};

  void _initAudioListeners() {
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isBuffering.value = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        position.value = duration.value;
        isPlaying.value = false;
      }
    });

    _player.positionStream.listen((pos) {
      position.value = pos;
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });
  }

  /// Loads the curated offline featured channels from assets/featured_podcasts.json
  Future<List<PodcastChannel>> loadFeaturedChannels() async {
    if (_cachedChannels.isNotEmpty) return _cachedChannels;

    try {
      final jsonStr = await rootBundle.loadString('assets/featured_podcasts.json');
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _cachedChannels = decoded.map((e) => PodcastChannel.fromJson(e as Map<String, dynamic>)).toList();
        for (final c in _cachedChannels) {
          if (c.episodes.isNotEmpty) {
            _episodesCache[c.id] = c.episodes;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Error loading bundled featured podcasts: $e', tag: 'PodcastService');
    }

    return _cachedChannels;
  }

  /// Fetches latest live episodes for a channel from Apple Podcasts API
  Future<List<PodcastEpisode>> fetchEpisodesForChannel(
    int channelId, {
    String channelTitle = '',
    String artworkUrl = '',
  }) async {
    if (_episodesCache.containsKey(channelId) && _episodesCache[channelId]!.isNotEmpty) {
      // Return cached immediately, then refresh in background
      _refreshEpisodesInBackground(channelId, channelTitle: channelTitle, artworkUrl: artworkUrl);
      return _episodesCache[channelId]!;
    }

    return await _fetchEpisodesFromApi(channelId, channelTitle: channelTitle, artworkUrl: artworkUrl);
  }

  Future<List<PodcastEpisode>> _fetchEpisodesFromApi(
    int channelId, {
    String channelTitle = '',
    String artworkUrl = '',
  }) async {
    try {
      final url = Uri.parse('https://itunes.apple.com/lookup?id=$channelId&entity=podcastEpisode&limit=35');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final results = data['results'] as List? ?? [];

        if (results.isNotEmpty) {
          final chHeader = results.first as Map<String, dynamic>;
          final actualTitle = channelTitle.isNotEmpty
              ? channelTitle
              : (chHeader['collectionName'] as String? ?? '');
          final actualArt = artworkUrl.isNotEmpty
              ? artworkUrl
              : (chHeader['artworkUrl600'] as String? ?? '');

          final episodes = results.skip(1).map<PodcastEpisode>((e) {
            final epJson = e as Map<String, dynamic>;
            return PodcastEpisode.fromJson(
              epJson,
              channelId: channelId,
              channelTitle: actualTitle,
            );
          }).where((e) => e.audioUrl.isNotEmpty).toList();

          if (episodes.isNotEmpty) {
            _episodesCache[channelId] = episodes;
            return episodes;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch live episodes for channel $channelId: $e', tag: 'PodcastService');
    }

    return _episodesCache[channelId] ?? [];
  }

  void _refreshEpisodesInBackground(int channelId, {String channelTitle = '', String artworkUrl = ''}) async {
    try {
      final fresh = await _fetchEpisodesFromApi(channelId, channelTitle: channelTitle, artworkUrl: artworkUrl);
      if (fresh.isNotEmpty) {
        _episodesCache[channelId] = fresh;
      }
    } catch (_) {}
  }

  /// Searches the Apple Podcasts global directory for any Islamic podcast
  Future<List<PodcastChannel>> searchPodcasts(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return loadFeaturedChannels();

    try {
      final encoded = Uri.encodeComponent('$cleanQ بودكاست');
      final url = Uri.parse('https://itunes.apple.com/search?term=$encoded&media=podcast&entity=podcast&country=EG&limit=25');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final results = data['results'] as List? ?? [];
        return results.map((e) => PodcastChannel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.warning('Error searching podcasts for "$cleanQ": $e', tag: 'PodcastService');
    }

    // Fallback: search in local cached channels
    return _cachedChannels.where((c) {
      return c.title.contains(cleanQ) || c.artist.contains(cleanQ);
    }).toList();
  }

  // ── Audio Playback Controls ────────────────────────────────────────────────

  Future<void> playEpisode(PodcastEpisode episode) async {
    try {
      if (currentEpisode.value?.id == episode.id && _player.playing) {
        return;
      }

      currentEpisode.value = episode;
      isBuffering.value = true;
      position.value = Duration.zero;

      await _player.setUrl(episode.audioUrl);
      await _player.setSpeed(speed.value);
      await _player.play();
    } catch (e) {
      isBuffering.value = false;
      AppLogger.error('Failed to play podcast episode: ${episode.title}', tag: 'PodcastService', error: e);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration newPosition) async {
    await _player.seek(newPosition);
  }

  Future<void> seekForward10() async {
    final target = position.value + const Duration(seconds: 10);
    final maxDur = duration.value;
    if (target < maxDur) {
      await seek(target);
    } else {
      await seek(maxDur);
    }
  }

  Future<void> seekBackward10() async {
    final target = position.value - const Duration(seconds: 10);
    if (target > Duration.zero) {
      await seek(target);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setPlaybackSpeed(double newSpeed) async {
    speed.value = newSpeed;
    await _player.setSpeed(newSpeed);
  }

  Future<void> stop() async {
    await _player.stop();
    currentEpisode.value = null;
    position.value = Duration.zero;
  }
}
