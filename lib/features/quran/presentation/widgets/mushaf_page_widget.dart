import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rafiki_app/features/quran/data/models/mushaf_page_model.dart';
import 'package:rafiki_app/features/quran/presentation/widgets/mushaf_frame_painter.dart';

class MushafPageWidget extends StatefulWidget {
  final MushafPage page;
  final double fontSize;
  final Color textColor;
  final Color primaryColor;
  final Color accentColor;
  final Color bgColor;
  final bool isDark;
  final ValueChanged<MushafAyah> onAyahTap;
  final VoidCallback onSearchTap;
  final VoidCallback onIndexTap;
  final VoidCallback onPageNumberTap;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.fontSize,
    required this.textColor,
    required this.primaryColor,
    required this.accentColor,
    required this.bgColor,
    required this.isDark,
    required this.onAyahTap,
    required this.onSearchTap,
    required this.onIndexTap,
    required this.onPageNumberTap,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  final List<TapGestureRecognizer> _recognizers = [];

  MushafPage get page => widget.page;
  double get fontSize => widget.fontSize;
  Color get textColor => widget.textColor;
  Color get primaryColor => widget.primaryColor;
  Color get accentColor => widget.accentColor;
  Color get bgColor => widget.bgColor;
  bool get isDark => widget.isDark;
  ValueChanged<MushafAyah> get onAyahTap => widget.onAyahTap;
  VoidCallback get onSearchTap => widget.onSearchTap;
  VoidCallback get onIndexTap => widget.onIndexTap;
  VoidCallback get onPageNumberTap => widget.onPageNumberTap;

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // ── Islamic Frame CustomPainter ──────────────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MushafFramePainter(
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  innerBgColor: bgColor,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // ── Page Content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header inside Islamic Frame
                _buildHeader(context),

                // 2. Middle Body (The verses with optional Surah Headers)
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _buildAyatContent(context),
                          ),
                        ),
                      ),

                      // Side Margin Hizb Medallion (e.g. نصف الحزب ۳۲)
                      if (page.hizbQuarterText != null)
                        Positioned(
                          top: 16,
                          right: 1,
                          child: _buildHizbMedallion(page.hizbQuarterText!),
                        ),
                    ],
                  ),
                ),

                // 3. Bottom Footer with page number
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search button
          IconButton(
            icon: Icon(Icons.search_rounded, size: 20, color: primaryColor),
            tooltip: 'بحث في الآيات',
            onPressed: onSearchTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // Left Cartouche: Surah Name
          _buildCartouche(
            text: page.primarySurahName.isNotEmpty ? 'سُورَةُ ${page.primarySurahName}' : '',
            width: 120,
          ),

          // Right Cartouche: Juz Name
          _buildCartouche(
            text: page.juzName,
            width: 130,
          ),

          // Index / Menu button
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 22, color: primaryColor),
            tooltip: 'فهرس المصحف والأجزاء',
            onPressed: onIndexTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCartouche({required String text, required double width}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 0.9),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? accentColor : primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ── 2. Middle Body ─────────────────────────────────────────────────────────
  Widget _buildAyatContent(BuildContext context) {
    final List<Widget> widgets = [];
    final List<MushafAyah> currentGroup = [];

    for (int i = 0; i < page.ayahs.length; i++) {
      final ayah = page.ayahs[i];

      if (ayah.isFirstInSurah) {
        // If there were pending ayahs before this new Surah, render them
        if (currentGroup.isNotEmpty) {
          widgets.add(_buildAyatParagraph(currentGroup));
          currentGroup.clear();
        }

        // Render the ornate Surah Header Cartouche
        widgets.add(_buildSurahHeaderBanner(ayah));

        // Render Bismillah (except for Surah 9 At-Tawbah and Surah 1 Al-Fatiha)
        if (ayah.surahNumber != 9 && ayah.surahNumber != 1) {
          widgets.add(_buildBismillah());
        }
      }

      currentGroup.add(ayah);
    }

    if (currentGroup.isNotEmpty) {
      widgets.add(_buildAyatParagraph(currentGroup));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  /// Authentic Islamic Surah Header Banner (ترويسة السورة)
  Widget _buildSurahHeaderBanner(MushafAyah ayah) {
    final type = ayah.surahRevelationType.toLowerCase() == 'meccan' ? 'مَكِّيَّة' : 'مَدَنِيَّة';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withValues(alpha: 0.25)
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner dashed border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 0.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آيَاتُهَا ${toArabicDigits(ayah.surahTotalAyahs)}',
                  style: TextStyle(
                    color: isDark ? accentColor : primaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'سُورَةُ ${ayah.surahName}',
                  style: TextStyle(
                    color: isDark ? textColor : primaryColor,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: isDark ? accentColor : primaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? accentColor : primaryColor,
            fontSize: fontSize + 1.5,
            fontWeight: FontWeight.w700,
            height: 1.8,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Paragraph of continuous verses with authentic circular floral Ayah End Medallions
  Widget _buildAyatParagraph(List<MushafAyah> ayahs) {
    _clearRecognizers();
    final List<InlineSpan> spans = [];

    for (final ayah in ayahs) {
      // If this ayah starts a Hizb quarter, add the Islamic star
      if (ayah.isHizbQuarterStart) {
        spans.add(
          TextSpan(
            text: ' ۞ ',
            style: TextStyle(
              color: accentColor,
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      // Verse text (tappable for Tafsir)
      final textRec = TapGestureRecognizer()..onTap = () => onAyahTap(ayah);
      _recognizers.add(textRec);
      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            height: 2.25,
            letterSpacing: 0.2,
          ),
          recognizer: textRec,
        ),
      );

      // Authentic Quranic Ayah End: ﴿٧٧﴾ (Fast pure-text rendering)
      final badgeRec = TapGestureRecognizer()..onTap = () => onAyahTap(ayah);
      _recognizers.add(badgeRec);
      spans.add(
        TextSpan(
          text: '﴿${toArabicDigits(ayah.numberInSurah)}﴾',
          style: TextStyle(
            color: isDark ? accentColor : primaryColor,
            fontSize: fontSize * 0.88,
            fontWeight: FontWeight.w700,
          ),
          recognizer: badgeRec,
        ),
      );

      spans.add(const TextSpan(text: ' '));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  /// Side Margin Medallion for Hizb Quarter (e.g. نصف الحزب ۳۲)
  Widget _buildHizbMedallion(String text) {
    final parts = text.split(' ');
    final line1 = parts.isNotEmpty ? parts.first : '';
    final line2 = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withValues(alpha: 0.35) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_low_rounded, color: accentColor, size: 10),
          const SizedBox(height: 2),
          Text(
            line1,
            style: TextStyle(
              color: isDark ? accentColor : primaryColor,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          if (line2.isNotEmpty)
            Text(
              line2,
              style: TextStyle(
                color: isDark ? textColor : primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ── 3. Bottom Footer ───────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: GestureDetector(
          onTap: onPageNumberTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded, size: 12, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  toArabicDigits(page.pageNumber),
                  style: TextStyle(
                    color: isDark ? accentColor : primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
