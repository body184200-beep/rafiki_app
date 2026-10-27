import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';

class QuranReciter {
  final int id;
  final String name;
  final String serverUrl;
  final String riwaya;
  final int surahTotal;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.serverUrl,
    this.riwaya = 'حفص عن عاصم - مرتل',
    this.surahTotal = 114,
  });

  factory QuranReciter.fromJson(Map<String, dynamic> json) {
    final moshafs = json['moshafs'] as List? ?? [];
    // Pick the moshaf with surah_total == 114
    final completeMoshaf = moshafs.firstWhere(
      (m) => m['surah_total'] == 114,
      orElse: () => moshafs.isNotEmpty ? moshafs.first : {},
    );

    return QuranReciter(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      serverUrl: completeMoshaf['server'] as String? ?? '',
      riwaya: completeMoshaf['name'] as String? ?? 'حفص عن عاصم',
      surahTotal: completeMoshaf['surah_total'] as int? ?? 114,
    );
  }
}

/// كبار قراء العالم الإسلامي المسجلين للقرآن كاملاً (١١٤ سورة)
const List<QuranReciter> kDefaultReciters = [
  QuranReciter(
    id: 54,
    name: 'مشاري بن راشد العفاسي',
    serverUrl: 'https://server8.mp3quran.net/afs/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 112,
    name: 'ماهر المعيقلي',
    serverUrl: 'https://server12.mp3quran.net/maher/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 64,
    name: 'عبد الباسط عبد الصمد (مرتل)',
    serverUrl: 'https://server7.mp3quran.net/basit/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 104,
    name: 'محمود خليل الحصري',
    serverUrl: 'https://server13.mp3quran.net/husr/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 102,
    name: 'محمد صديق المنشاوي (مرتل)',
    serverUrl: 'https://server10.mp3quran.net/minsh/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 31,
    name: 'سعد الغامدي',
    serverUrl: 'https://server7.mp3quran.net/s_gmd/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 124,
    name: 'ياسر الدوسري',
    serverUrl: 'https://server11.mp3quran.net/yasser/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 120,
    name: 'ناصر القطامي',
    serverUrl: 'https://server6.mp3quran.net/qtm/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 9,
    name: 'أحمد بن علي العجمي',
    serverUrl: 'https://server10.mp3quran.net/ajm/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 86,
    name: 'فارس عباد',
    serverUrl: 'https://server8.mp3quran.net/frs_a/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 4,
    name: 'أبو بكر الشاطري',
    serverUrl: 'https://server11.mp3quran.net/shatri/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 57,
    name: 'عبد الرحمن السديس',
    serverUrl: 'https://server11.mp3quran.net/sds/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 33,
    name: 'سعود الشريم',
    serverUrl: 'https://server7.mp3quran.net/shur/',
    riwaya: 'حفص عن عاصم',
  ),
  QuranReciter(
    id: 105,
    name: 'محمود علي البنا',
    serverUrl: 'https://server10.mp3quran.net/bna/',
    riwaya: 'حفص عن عاصم',
  ),
];

class QuranAudioService {
  QuranAudioService._();
  static final QuranAudioService instance = QuranAudioService._();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  QuranReciter _selectedReciter = kDefaultReciters.first;
  QuranReciter get selectedReciter => _selectedReciter;
  set selectedReciter(QuranReciter r) => _selectedReciter = r;

  int? _currentSurahNumber;
  int? get currentSurahNumber => _currentSurahNumber;

  String? _currentSurahName;
  String? get currentSurahName => _currentSurahName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPlayingOffline = false;
  bool get isPlayingOffline => _isPlayingOffline;

  final StreamController<QuranReciter> _reciterCtrl = StreamController<QuranReciter>.broadcast();
  Stream<QuranReciter> get onReciterChanged => _reciterCtrl.stream;

  final StreamController<int?> _surahChangeCtrl = StreamController<int?>.broadcast();
  Stream<int?> get onSurahChanged => _surahChangeCtrl.stream;

  List<QuranReciter> _allReciters = List.from(kDefaultReciters);
  List<QuranReciter> get allReciters => _allReciters;

  // ── Offline Storage Directory ──────────────────────────────────────────────
  Directory? _cachedAudioDir;

  Future<Directory> _getAudioDir() async {
    if (_cachedAudioDir != null) return _cachedAudioDir!;
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/quran_offline_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    _cachedAudioDir = audioDir;
    return audioDir;
  }

  Future<File> getSurahFile(int reciterId, int surahNumber) async {
    final audioDir = await _getAudioDir();
    final pad = surahNumber.toString().padLeft(3, '0');
    return File('${audioDir.path}/reciter_${reciterId}_surah_$pad.mp3');
  }

  Future<bool> isSurahDownloaded(int reciterId, int surahNumber) async {
    try {
      final file = await getSurahFile(reciterId, surahNumber);
      return await file.exists() && (await file.length()) > 1000;
    } catch (_) {
      return false;
    }
  }

  /// Bulk query all downloaded surahs for a given reciter in a single filesystem pass (~2ms)
  Future<Set<int>> getDownloadedSurahs(int reciterId) async {
    try {
      final audioDir = await _getAudioDir();
      if (!await audioDir.exists()) return {};
      final entities = audioDir.listSync();
      final prefix = 'reciter_${reciterId}_surah_';
      final Set<int> downloaded = {};
      for (final entity in entities) {
        if (entity is File) {
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.last
              : entity.path.split(Platform.isWindows ? r'\' : '/').last;
          if (name.startsWith(prefix) && name.endsWith('.mp3')) {
            final numPart = name.substring(prefix.length, name.length - 4);
            final surahNum = int.tryParse(numPart);
            if (surahNum != null) {
              try {
                if (entity.lengthSync() > 1000) {
                  downloaded.add(surahNum);
                }
              } catch (_) {}
            }
          }
        }
      }
      return downloaded;
    } catch (_) {
      return {};
    }
  }

  /// Downloads Surah MP3 to device storage for 100% offline playback
  Future<bool> downloadSurah({
    required QuranReciter reciter,
    required int surahNumber,
    required ValueChanged<double> onProgress,
  }) async {
    http.Client? client;
    try {
      final url = getSurahAudioUrl(reciter, surahNumber);
      final file = await getSurahFile(reciter.id, surahNumber);
      final tempFile = File('${file.path}.download');

      if (await tempFile.exists()) await tempFile.delete();

      client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
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

        if (await tempFile.exists() && (await tempFile.length()) > 1000) {
          if (await file.exists()) await file.delete();
          await tempFile.rename(file.path);
          onProgress(1.0);
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to download Surah $surahNumber: $e', tag: 'QuranAudio');
    } finally {
      client?.close();
    }
    return false;
  }

  Future<void> deleteDownloadedSurah(int reciterId, int surahNumber) async {
    try {
      final file = await getSurahFile(reciterId, surahNumber);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Fetches the live list of reciters from MP3Quran API v3
  /// Filtering strictly for complete Qurans (surah_total == 114)
  Future<List<QuranReciter>> fetchReciters() async {
    try {
      final uri = Uri.parse('https://mp3quran.net/api/v3/reciters?language=ar');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data['reciters'] as List? ?? [];

        final List<QuranReciter> completeList = [];
        for (final item in list) {
          final moshafs = item['moshafs'] as List? ?? [];
          final has114 = moshafs.any((m) => m['surah_total'] == 114);
          if (has114) {
            completeList.add(QuranReciter.fromJson(item));
          }
        }

        if (completeList.isNotEmpty) {
          _allReciters = completeList;
          return completeList;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch reciters from MP3Quran API: $e', tag: 'QuranAudio');
    }
    return _allReciters;
  }

  String getSurahAudioUrl(QuranReciter reciter, int surahNumber) {
    var server = reciter.serverUrl.trim();
    if (!server.endsWith('/')) server = '$server/';
    final numPadded = surahNumber.toString().padLeft(3, '0');
    return '$server$numPadded.mp3';
  }

  /// Plays Surah with Automatic Offline Fallback:
  /// 1. Checks if local file exists -> plays directly from storage without internet!
  /// 2. If not downloaded -> streams from internet.
  Future<void> playSurah({
    required QuranReciter reciter,
    required int surahNumber,
    required String surahName,
  }) async {
    try {
      _isLoading = true;
      _selectedReciter = reciter;
      _currentSurahNumber = surahNumber;
      _currentSurahName = surahName;

      _reciterCtrl.add(reciter);
      _surahChangeCtrl.add(surahNumber);

      final isDownloaded = await isSurahDownloaded(reciter.id, surahNumber);
      if (isDownloaded) {
        final file = await getSurahFile(reciter.id, surahNumber);
        _isPlayingOffline = true;
        AppLogger.info('Playing Surah $surahNumber OFFLINE from: ${file.path}', tag: 'QuranAudio');
        await _player.setFilePath(file.path);
      } else {
        _isPlayingOffline = false;
        final url = getSurahAudioUrl(reciter, surahNumber);
        AppLogger.info('Streaming Surah $surahNumber ONLINE from: $url', tag: 'QuranAudio');
        await _player.setUrl(url);
      }

      _isLoading = false;
      await _player.play();
    } catch (e) {
      _isLoading = false;
      AppLogger.error('Error playing Quran audio', tag: 'QuranAudio', error: e);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSurahNumber = null;
    _currentSurahName = null;
    _surahChangeCtrl.add(null);
  }
}
