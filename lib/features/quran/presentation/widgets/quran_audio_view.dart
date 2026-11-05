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
  List<DownloadedSurahItem> _allDownloadedList = [];
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
    final allDownloaded = await _audioService.getAllDownloadedSurahs();
    final downloaded = await _audioService.getDownloadedSurahs(_currentReciter.id);
    if (mounted) {
      setState(() {
        _allDownloadedList = allDownloaded;
        _downloadedSurahs.clear();
        for (final num in downloaded) {
          _downloadedSurahs[num] = true;
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSurahs {
    final list = widget.surahs;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final eng = (s['englishName'] as String? ?? '').toLowerCase();
      final numStr = s['number'].toString();
      return name.contains(q) || eng.contains(q) || numStr == q;
    }).toList();
  }

  List<DownloadedSurahItem> get _filteredDownloadedList {
    if (_searchQuery.trim().isEmpty) return _allDownloadedList;
    final q = _searchQuery.trim().toLowerCase();
    return _allDownloadedList.where((item) {
      final surah = widget.surahs.where((s) => s['number'] == item.surahNumber).firstOrNull;
      final sName = (surah?['name'] as String? ?? '').toLowerCase();
      final rName = item.reciterName.toLowerCase();
      return sName.contains(q) || rName.contains(q) || item.surahNumber.toString() == q;
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
      await _checkAllDownloaded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم تحميل سورة $surahName بنجاح بصوت ${_currentReciter.name}!'
                : 'تعذر تحميل سورة $surahName، يرجى التحقق من الاتصال بالإنترنت.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteDownload(int reciterId, int surahNum, String surahName) {
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
                await _audioService.deleteDownloadedSurah(reciterId, surahNum);
                await _checkAllDownloaded();
              },
              child: const Text('حذف من الهاتف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final reciters = _audioService.allReciters;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.textMutedColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded, color: widget.goldColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'اختر القارئ (المصحف المرتل كاملاً)',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
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
                              _audioService.setSelectedReciter(r);
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

  void _onPlaySurah(Map<String, dynamic> surah, {QuranReciter? specificReciter}) {
    HapticFeedback.selectionClick();
    final surahNum = surah['number'] as int;
    final surahName = surah['name'] as String;
    final reciter = specificReciter ?? _currentReciter;

    if (_audioService.currentSurahNumber == surahNum &&
        _audioService.selectedReciter.id == reciter.id &&
        _audioService.player.playing) {
      _audioService.togglePlayPause();
    } else {
      _audioService.playSurah(
        reciter: reciter,
        surahNumber: surahNum,
        surahName: surahName,
      );
      if (specificReciter != null && specificReciter.id != _currentReciter.id) {
        setState(() => _currentReciter = specificReciter);
      }
    }
    setState(() {});
  }

  void _onPlayDownloadedItem(DownloadedSurahItem item) {
    HapticFeedback.selectionClick();
    final surah = widget.surahs.where((s) => s['number'] == item.surahNumber).firstOrNull;
    final surahName = surah?['name'] as String? ?? 'سورة رقم ${item.surahNumber}';
    final reciter = _audioService.allReciters.where((r) => r.id == item.reciterId).firstOrNull ??
        QuranReciter(id: item.reciterId, name: item.reciterName, serverUrl: '');

    _onPlaySurah(
      surah ?? {'number': item.surahNumber, 'name': surahName},
      specificReciter: reciter,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentReciter.name,
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'القارئ الحالي',
                              style: TextStyle(color: widget.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_currentReciter.riwaya} • اضغط لتغيير القارئ',
                        style: TextStyle(color: widget.textMutedColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor.withValues(alpha: 0.15),
                    foregroundColor: widget.accentColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: widget.accentColor.withValues(alpha: 0.4)),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('تغيير', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showReciterPicker(context),
                ),
              ],
            ),
          ),
        ),

        // ── Search & Filter Controls ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
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
                      hintText: _showOnlyDownloaded ? 'بحث في السور المحملة...' : 'ابحث عن سورة للاستماع...',
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
                      'المحملة (${_allDownloadedList.length})',
                      style: TextStyle(
                        fontSize: 11,
                        color: _showOnlyDownloaded ? widget.accentColor : widget.textMutedColor,
                        fontWeight: _showOnlyDownloaded ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                selected: _showOnlyDownloaded,
                onSelected: (val) {
                  setState(() => _showOnlyDownloaded = val);
                  _checkAllDownloaded();
                },
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

        // ── Surahs List (All or Downloaded Across All Reciters) ───────────────
        Expanded(
          child: _showOnlyDownloaded
              ? _buildAllDownloadedView()
              : _buildCurrentReciterSurahsView(),
        ),
      ],
    );
  }

  // ── View 1: When "المحملة" is selected: Shows ALL downloads from any Sheikh!
  Widget _buildAllDownloadedView() {
    final list = _filteredDownloadedList;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: widget.textMutedColor, size: 40),
              const SizedBox(height: 12),
              Text(
                'لم يتم العثور على سور محملة',
                style: TextStyle(color: widget.textColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'اضغط على زر ⬇️ بجانب أي سورة لأي قارئ لتنزيلها والاستماع لها في أي وقت بدون إنترنت.',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.textMutedColor, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _audioService.player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final curSurah = _audioService.currentSurahNumber;
        final curReciterId = _audioService.selectedReciter.id;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            final surah = widget.surahs.where((s) => s['number'] == item.surahNumber).firstOrNull;
            final sName = surah?['name'] as String? ?? 'سورة رقم ${item.surahNumber}';
            final isCurrentSurah = curSurah == item.surahNumber && curReciterId == item.reciterId;
            final isCurrentPlaying = isCurrentSurah && isPlaying;
            final sizeMb = (item.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
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
                      toArabicDigits(item.surahNumber),
                      style: TextStyle(
                        color: isCurrentSurah ? Colors.white : widget.goldColor,
                        fontSize: 12,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_pin_rounded, color: Color(0xFF10B981), size: 11),
                          SizedBox(width: 3),
                          Text(
                            'بدون نت',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'القارئ: ${item.reciterName} • $sizeMb ميجابايت',
                    style: TextStyle(
                      color: widget.goldColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      tooltip: 'حذف السورة المحملة لتوفير المساحة',
                      onPressed: () => _confirmDeleteDownload(item.reciterId, item.surahNumber, sName),
                    ),

                    // Play button
                    IconButton(
                      icon: Icon(
                        isCurrentPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: isCurrentSurah ? widget.accentColor : widget.goldColor,
                        size: 34,
                      ),
                      onPressed: () => _onPlayDownloadedItem(item),
                    ),
                  ],
                ),
                onTap: () => _onPlayDownloadedItem(item),
              ),
            );
          },
        );
      },
    );
  }

  // ── View 2: When browsing all surahs for the current Sheikh
  Widget _buildCurrentReciterSurahsView() {
    final list = _filteredSurahs;

    if (list.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج مطابقة',
          style: TextStyle(color: widget.textMutedColor, fontSize: 13),
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _audioService.player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final curSurah = _audioService.currentSurahNumber;
        final curReciterId = _audioService.selectedReciter.id;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final surah = list[i];
            final sNum = surah['number'] as int;
            final sName = surah['name'] as String;
            final isMeccan = (surah['revelationType'] ?? '').toString().toLowerCase() == 'meccan';
            final ayahsCount = (surah['ayahs'] as List?)?.length ?? 0;
            final isCurrentSurah = curSurah == sNum && curReciterId == _currentReciter.id;
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
                      const Tooltip(
                        message: 'محفوظة على الهاتف - تعمل بدون إنترنت',
                        child: Icon(Icons.offline_pin_rounded, color: Color(0xFF10B981), size: 16),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${isMeccan ? "مكية" : "مدنية"} • ${toArabicDigits(ayahsCount)} آية ${isDownloaded ? "• بدون نت ✓" : ""}',
                  style: TextStyle(
                    color: isDownloaded ? const Color(0xFF10B981) : widget.textMutedColor,
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
                        onPressed: () => _confirmDeleteDownload(_currentReciter.id, sNum, sName),
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
    );
  }
}
