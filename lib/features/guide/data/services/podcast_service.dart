import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/core/services/media_notification_service.dart';
import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';

class PodcastService {
  PodcastService._internal() {
    _initAudioListeners();
    MediaNotificationService.instance.registerHandlers(
      type: ActiveMediaType.podcast,
      onPlay: () async {
        await _player.play();
      },
      onPause: () async {
        await _player.pause();
      },
      onStop: () async {
        await stop();
      },
    );
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
  final StreamController<int> _episodesUpdateCtrl = StreamController<int>.broadcast();
  Stream<int> get onEpisodesUpdated => _episodesUpdateCtrl.stream;
  static const String _kDownloadedEpisodesMetaKey = 'podcast_downloaded_meta_v1';

  void _initAudioListeners() {
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isBuffering.value = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        position.value = duration.value;
        isPlaying.value = false;
      }

      if (MediaNotificationService.instance.activeType == ActiveMediaType.podcast) {
        if (state.processingState == ProcessingState.completed) {
          MediaNotificationService.instance.dismiss();
        } else if (state.processingState != ProcessingState.idle) {
          MediaNotificationService.instance.updatePlaybackState(state.playing);
        }
      }
    });

    _player.positionStream.listen((pos) {
      position.value = pos;
      if (MediaNotificationService.instance.activeType == ActiveMediaType.podcast) {
        MediaNotificationService.instance.updateProgress(
          position: pos,
          duration: duration.value,
        );
      }
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
        if (MediaNotificationService.instance.activeType == ActiveMediaType.podcast) {
          MediaNotificationService.instance.updateProgress(
            position: position.value,
            duration: dur,
          );
        }
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

  /// Returns all cached episodes across all channels (380+ episodes)
  List<PodcastEpisode> getAllEpisodes() {
    final List<PodcastEpisode> all = [];
    for (final c in _cachedChannels) {
      final eps = _episodesCache[c.id] ?? c.episodes;
      all.addAll(eps);
    }
    return all;
  }

  /// Returns cached episodes for a specific channel
  List<PodcastEpisode> getCachedEpisodesForChannel(int channelId) {
    if (_episodesCache.containsKey(channelId) && _episodesCache[channelId]!.isNotEmpty) {
      return _episodesCache[channelId]!;
    }
    final ch = _cachedChannels.where((c) => c.id == channelId).firstOrNull;
    return ch?.episodes ?? [];
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
      final url = Uri.parse('https://itunes.apple.com/lookup?id=$channelId&entity=podcastEpisode&limit=300');
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
            _episodesUpdateCtrl.add(channelId);
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
        _episodesUpdateCtrl.add(channelId);
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

  // ── Download Management ───────────────────────────────────────────────────

  Future<Directory> _getPodcastDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/podcast_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> getEpisodeFile(int episodeId) async {
    final dir = await _getPodcastDir();
    return File('${dir.path}/ep_$episodeId.mp3');
  }

  Future<bool> isEpisodeDownloaded(int episodeId) async {
    try {
      final file = await getEpisodeFile(episodeId);
      return await file.exists() && (await file.length()) > 5000;
    } catch (_) {
      return false;
    }
  }

  Future<Set<int>> getDownloadedEpisodeIds() async {
    try {
      final dir = await _getPodcastDir();
      if (!await dir.exists()) return {};
      final entities = dir.listSync();
      final Set<int> ids = {};
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.startsWith('ep_')) {
            final idStr = fileName.substring(3, fileName.length - 4);
            final id = int.tryParse(idStr);
            if (id != null) ids.add(id);
          }
        }
      }
      return ids;
    } catch (_) {
      return {};
    }
  }

  Future<List<PodcastEpisode>> getDownloadedEpisodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kDownloadedEpisodesMetaKey) ?? [];
      final downloadedIds = await getDownloadedEpisodeIds();
      final List<PodcastEpisode> episodes = [];

      for (final raw in list) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final ep = PodcastEpisode.fromJson(json);
          if (downloadedIds.contains(ep.id)) {
            episodes.add(ep);
          }
        } catch (_) {}
      }
      return episodes;
    } catch (_) {
      return [];
    }
  }

  Future<bool> downloadEpisode({
    required PodcastEpisode episode,
    required ValueChanged<double> onProgress,
  }) async {
    http.Client? client;
    try {
      final file = await getEpisodeFile(episode.id);
      final tempFile = File('${file.path}.download');
      if (await tempFile.exists()) await tempFile.delete();

      client = http.Client();
      final request = http.Request('GET', Uri.parse(episode.audioUrl));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = tempFile.openWrite();

        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0) {
            onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
          }
        }

        await sink.flush();
        await sink.close();

        if (await tempFile.exists() && (await tempFile.length()) > 5000) {
          if (await file.exists()) await file.delete();
          await tempFile.rename(file.path);

          // Save metadata in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final list = prefs.getStringList(_kDownloadedEpisodesMetaKey) ?? [];
          final epJson = jsonEncode(episode.toJson());
          if (!list.contains(epJson)) {
            list.add(epJson);
            await prefs.setStringList(_kDownloadedEpisodesMetaKey, list);
          }

          onProgress(1.0);
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to download episode ${episode.id}: $e', tag: 'PodcastService');
    } finally {
      client?.close();
    }
    return false;
  }

  Future<void> deleteDownloadedEpisode(int episodeId) async {
    try {
      final file = await getEpisodeFile(episodeId);
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kDownloadedEpisodesMetaKey) ?? [];
      list.removeWhere((item) {
        try {
          final json = jsonDecode(item) as Map<String, dynamic>;
          return (json['id'] as num?)?.toInt() == episodeId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_kDownloadedEpisodesMetaKey, list);
    } catch (_) {}
  }

  // ── Audio Playback Controls ────────────────────────────────────────────────

  Future<void> playEpisode(PodcastEpisode episode) async {
    try {
      if (currentEpisode.value?.id == episode.id && _player.playing) {
        return;
      }

      await MediaNotificationService.instance.ensureExclusivePlayback(ActiveMediaType.podcast);

      currentEpisode.value = episode;
      isBuffering.value = true;
      position.value = Duration.zero;

      final isDownloaded = await isEpisodeDownloaded(episode.id);
      if (isDownloaded) {
        final file = await getEpisodeFile(episode.id);
        AppLogger.info('Playing episode OFFLINE from: ${file.path}', tag: 'PodcastService');
        await _player.setFilePath(file.path);
      } else {
        AppLogger.info('Streaming episode ONLINE from: ${episode.audioUrl}', tag: 'PodcastService');
        await _player.setUrl(episode.audioUrl);
      }

      await _player.setSpeed(speed.value);
      await _player.play();
      MediaNotificationService.instance.show(
        type: ActiveMediaType.podcast,
        title: episode.title,
        subtitle: episode.channelTitle.isNotEmpty ? episode.channelTitle : 'بودكاست إسلامي',
        isPlaying: true,
        position: Duration.zero,
        duration: duration.value,
      );
    } catch (e) {
      isBuffering.value = false;
      AppLogger.error('Failed to play podcast episode: ${episode.title}', tag: 'PodcastService', error: e);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      if (MediaNotificationService.instance.activeType == ActiveMediaType.podcast) {
        await MediaNotificationService.instance.updatePlaybackState(false);
      }
    } else {
      await _player.play();
      if (currentEpisode.value != null) {
        await MediaNotificationService.instance.show(
          type: ActiveMediaType.podcast,
          title: currentEpisode.value!.title,
          subtitle: currentEpisode.value!.channelTitle.isNotEmpty ? currentEpisode.value!.channelTitle : 'بودكاست إسلامي',
          isPlaying: true,
          position: position.value,
          duration: duration.value,
        );
      }
    }
  }

  Future<void> seek(Duration newPosition) async {
    await _player.seek(newPosition);
  }

  Future<void> seekForward10() async {
    final target = position.value + const Duration(seconds: 10);
    final maxDur = duration.value;
    if (maxDur > Duration.zero && target < maxDur) {
      await seek(target);
    } else if (maxDur > Duration.zero) {
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
    if (MediaNotificationService.instance.activeType == ActiveMediaType.podcast) {
      await MediaNotificationService.instance.dismiss();
    }
  }
}
