import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rafiki_app/features/quran/data/models/mushaf_page_model.dart';
import 'package:rafiki_app/features/quran/data/services/quran_audio_service.dart';

class QuranAudioView extends StatefulWidget {
  final List<Map<String, dynamic>> surahs;
  final Color surfaceColor;
  final Color accentColor;
  final Color goldColor;
  final Color textColor;
  final Color textMutedColor;

  const QuranAudioView({
    super.key,
    required this.surahs,
    required this.surfaceColor,
    required this.accentColor,
    required this.goldColor,
    required this.textColor,
    required this.textMutedColor,
  });

  @override
  State<QuranAudioView> createState() => _QuranAudioViewState();
}

class _QuranAudioViewState extends State<QuranAudioView> {
  final QuranAudioService _audioService = QuranAudioService.instance;
  late QuranReciter _currentReciter;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<int, bool> _downloadedSurahs = {};
  final Map<int, double> _downloadProgress = {};
  bool _showOnlyDownloaded = false;

  @override
  void initState() {
    super.initState();
    _currentReciter = _audioService.selectedReciter;
    _checkAllDownloaded();
    _audioService.fetchReciters().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAllDownloaded() async {
    final downloaded = await _audioService.getDownloadedSurahs(_currentReciter.id);
    if (mounted) {
      setState(() {
        _downloadedSurahs.clear();
        for (final num in downloaded) {
          _downloadedSurahs[num] = true;
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSurahs {
    var list = widget.surahs;
    if (_showOnlyDownloaded) {
      list = list.where((s) => _downloadedSurahs[s['number'] as int] == true).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final eng = (s['englishName'] as String? ?? '').toLowerCase();
      final numStr = s['number'].toString();
      return name.contains(q) || eng.contains(q) || numStr == q;
    }).toList();
  }

  Future<void> _startDownload(Map<String, dynamic> surah) async {
    HapticFeedback.lightImpact();
    final surahNum = surah['number'] as int;
    final surahName = surah['name'] as String;

    setState(() => _downloadProgress[surahNum] = 0.05);

    final success = await _audioService.downloadSurah(
      reciter: _currentReciter,
      surahNumber: surahNum,
      onProgress: (p) {
        if (mounted) {
          setState(() => _downloadProgress[surahNum] = p);
        }
      },
    );

    if (mounted) {
      setState(() {
        _downloadProgress.remove(surahNum);
        if (success) {
          _downloadedSurahs[surahNum] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم تحميل سورة $surahName بنجاح! يمكنك الاستماع إليها الآن بدون إنترنت.'
                : 'تعذر تحميل سورة $surahName، يرجى التحقق من الاتصال بالإنترنت.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteDownload(int surahNum, String surahName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: widget.surfaceColor,
          title: Text('حذف سورة $surahName المحملة', style: TextStyle(color: widget.textColor, fontSize: 16)),
          content: Text(
            'هل تريد حذف الملف الصوتي لسورة $surahName من هاتفك لتوفير المساحة؟',
            style: TextStyle(color: widget.textMutedColor, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(color: widget.textMutedColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                await _audioService.deleteDownloadedSurah(_currentReciter.id, surahNum);
                setState(() => _downloadedSurahs.remove(surahNum));
              },
              child: const Text('حذف من الهاتف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final reciters = _audioService.allReciters.where((r) {
              if (filter.isEmpty) return true;
              return r.name.toLowerCase().contains(filter.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: widget.goldColor.withValues(alpha: 0.4), width: 1.2)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.goldColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'اختر القارئ (المصحف كاملاً ١١٤ سورة)',
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: widget.textMutedColor, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search Reciter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.goldColor.withValues(alpha: 0.25)),
                      ),
                      child: TextField(
                        onChanged: (val) => setModalState(() => filter = val),
                        style: TextStyle(color: widget.textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن اسم القارئ...',
                          hintStyle: TextStyle(color: widget.textMutedColor, fontSize: 12),
                          prefixIcon: Icon(Icons.search_rounded, color: widget.goldColor, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: reciters.length,
                      itemBuilder: (_, i) {
                        final r = reciters[i];
                        final isSel = r.id == _currentReciter.id;
                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel
                                  ? widget.accentColor.withValues(alpha: 0.25)
                                  : widget.goldColor.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isSel ? widget.accentColor : widget.goldColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              Icons.record_voice_over_rounded,
                              color: isSel ? widget.accentColor : widget.goldColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            r.name,
                            style: TextStyle(
                              color: isSel ? widget.accentColor : widget.textColor,
                              fontSize: 14,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${r.riwaya} • القرآن كاملاً ١١٤ سورة',
                            style: TextStyle(color: widget.textMutedColor, fontSize: 11),
                          ),
                          trailing: isSel
                              ? Icon(Icons.check_circle_rounded, color: widget.accentColor, size: 20)
                              : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _currentReciter = r;
                              _audioService.selectedReciter = r;
                              _downloadedSurahs.clear();
                            });
                            _checkAllDownloaded();
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onPlaySurah(Map<String, dynamic> surah) {
    HapticFeedback.selectionClick();
    final surahNum = surah['number'] as int;
    final surahName = surah['name'] as String;

    if (_audioService.currentSurahNumber == surahNum && _audioService.player.playing) {
      _audioService.togglePlayPause();
    } else {
      _audioService.playSurah(
        reciter: _currentReciter,
        surahNumber: surahNum,
        surahName: surahName,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final downloadedCount = _downloadedSurahs.length;

    return Column(
      children: [
        // ── Reciter Info Card ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.goldColor.withValues(alpha: 0.35), width: 0.9),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [widget.accentColor.withValues(alpha: 0.3), widget.goldColor.withValues(alpha: 0.2)],
                    ),
                    border: Border.all(color: widget.goldColor.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Icon(Icons.record_voice_over_rounded, color: widget.goldColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentReciter.name,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.offline_pin_rounded, size: 12, color: widget.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'المصحف كاملاً • محمل $downloadedCount سورة بدون نت',
                            style: TextStyle(color: widget.textMutedColor, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showReciterPicker,
                  style: TextButton.styleFrom(
                    backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                    foregroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('تغيير', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),

        // ── Search & Offline Filter Chips ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.goldColor.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: widget.textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة للاستماع...',
                      hintStyle: TextStyle(color: widget.textMutedColor, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: widget.goldColor, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: widget.textMutedColor, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Offline Only toggle chip
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showOnlyDownloaded ? Icons.offline_pin_rounded : Icons.offline_bolt_outlined,
                      size: 14,
                      color: _showOnlyDownloaded ? widget.accentColor : widget.textMutedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'المحملة فقط',
                      style: TextStyle(
                        fontSize: 11,
                        color: _showOnlyDownloaded ? widget.accentColor : widget.textMutedColor,
                        fontWeight: _showOnlyDownloaded ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                selected: _showOnlyDownloaded,
                onSelected: (val) => setState(() => _showOnlyDownloaded = val),
                backgroundColor: widget.surfaceColor,
                selectedColor: widget.accentColor.withValues(alpha: 0.16),
                side: BorderSide(
                  color: _showOnlyDownloaded ? widget.accentColor : widget.goldColor.withValues(alpha: 0.25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Surahs List ──────────────────────────────────────────────────────
        Expanded(
          child: _filteredSurahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, color: widget.textMutedColor, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _showOnlyDownloaded
                            ? 'لم تقم بتحميل أي سورة بعد للعمل بدون إنترنت.\nاضغط على زر ⬇️ بجانب أي سورة لتنزيلها والاستماع لها في أي وقت بدون نت.'
                            : 'لا توجد نتائج مطابقة',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: widget.textMutedColor, fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<PlayerState>(
                  stream: _audioService.player.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    final curSurah = _audioService.currentSurahNumber;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (_, i) {
                        final surah = _filteredSurahs[i];
                        final sNum = surah['number'] as int;
                        final sName = surah['name'] as String;
                        final isMeccan = (surah['revelationType'] ?? '').toString().toLowerCase() == 'meccan';
                        final ayahsCount = (surah['ayahs'] as List?)?.length ?? 0;
                        final isCurrentSurah = curSurah == sNum;
                        final isCurrentPlaying = isCurrentSurah && isPlaying;

                        final isDownloaded = _downloadedSurahs[sNum] == true;
                        final isDownloading = _downloadProgress.containsKey(sNum);
                        final downloadPercent = _downloadProgress[sNum] ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrentSurah
                                ? widget.accentColor.withValues(alpha: 0.12)
                                : widget.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrentSurah
                                  ? widget.accentColor
                                  : widget.goldColor.withValues(alpha: 0.18),
                              width: isCurrentSurah ? 1.2 : 0.8,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrentSurah
                                    ? widget.accentColor
                                    : widget.goldColor.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: isCurrentSurah ? widget.accentColor : widget.goldColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  toArabicDigits(sNum),
                                  style: TextStyle(
                                    color: isCurrentSurah ? Colors.white : widget.goldColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  sName,
                                  style: TextStyle(
                                    color: isCurrentSurah ? widget.accentColor : widget.textColor,
                                    fontSize: 15,
                                    fontWeight: isCurrentSurah ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                ),
                                if (isDownloaded) ...[
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'محفوظة على الهاتف - تعمل بدون إنترنت',
                                    child: Icon(Icons.offline_pin_rounded, color: Colors.greenAccent, size: 16),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${isMeccan ? "مكية" : "مدنية"} • ${toArabicDigits(ayahsCount)} آية ${isDownloaded ? "• بدون نت ✓" : ""}',
                              style: TextStyle(
                                color: isDownloaded ? Colors.greenAccent.withValues(alpha: 0.8) : widget.textMutedColor,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Download / Offline status button
                                if (isDownloading)
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: downloadPercent,
                                          strokeWidth: 2.2,
                                          color: widget.accentColor,
                                        ),
                                        Text(
                                          '${(downloadPercent * 100).round()}%',
                                          style: TextStyle(fontSize: 8, color: widget.accentColor, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (isDownloaded)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    color: widget.textMutedColor,
                                    tooltip: 'حذف السورة المحملة لتوفير المساحة',
                                    onPressed: () => _confirmDeleteDownload(sNum, sName),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded, size: 20),
                                    color: widget.goldColor,
                                    tooltip: 'تحميل السورة للاستماع بدون نت',
                                    onPressed: () => _startDownload(surah),
                                  ),

                                // Play / Pause button
                                IconButton(
                                  icon: Icon(
                                    isCurrentPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                    color: isCurrentSurah ? widget.accentColor : widget.goldColor,
                                    size: 34,
                                  ),
                                  onPressed: () => _onPlaySurah(surah),
                                ),
                              ],
                            ),
                            onTap: () => _onPlaySurah(surah),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),

        // ── Persistent Mini Audio Player ─────────────────────────────────────
        _buildBottomMiniPlayer(),
      ],
    );
  }

  Widget _buildBottomMiniPlayer() {
    return StreamBuilder<PlayerState>(
      stream: _audioService.player.playerStateStream,
      builder: (context, snapState) {
        final curSurahNum = _audioService.currentSurahNumber;
        if (curSurahNum == null) return const SizedBox.shrink();

        final isPlaying = snapState.data?.playing ?? false;
        final isOfflinePlaying = _audioService.isPlayingOffline;

        return StreamBuilder<Duration>(
          stream: _audioService.player.positionStream,
          builder: (context, snapPos) {
            final position = snapPos.data ?? Duration.zero;
            final duration = _audioService.player.duration ?? Duration.zero;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                border: Border(top: BorderSide(color: widget.goldColor.withValues(alpha: 0.4), width: 1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress line
                  SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      trackHeight: 3,
                      activeTrackColor: widget.accentColor,
                      inactiveTrackColor: widget.goldColor.withValues(alpha: 0.2),
                      thumbColor: widget.goldColor,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble().clamp(0.0, (duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0)),
                      max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                      onChanged: (val) {
                        _audioService.seek(Duration(seconds: val.round()));
                      },
                    ),
                  ),

                  Row(
                    children: [
                      // Audio Icon with Offline Indicator
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isOfflinePlaying
                              ? Colors.greenAccent.withValues(alpha: 0.15)
                              : widget.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOfflinePlaying ? Icons.offline_pin_rounded : Icons.audiotrack_rounded,
                          color: isOfflinePlaying ? Colors.greenAccent : widget.accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Surah & Reciter info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _audioService.currentSurahName ?? 'سورة',
                                  style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isOfflinePlaying) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'بدون نت',
                                      style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${_currentReciter.name} • ${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: TextStyle(color: widget.textMutedColor, fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                          color: widget.accentColor,
                          size: 32,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _audioService.togglePlayPause();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: widget.textMutedColor, size: 20),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _audioService.stop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
