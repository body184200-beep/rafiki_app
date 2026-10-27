import 'package:flutter/material.dart';

import 'package:rafiki_app/features/quran/data/models/mushaf_page_model.dart';

class MushafPageWidget extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'الفهرس',
                    onPressed: onIndexTap,
                    icon: Icon(Icons.list_rounded, color: primaryColor),
                  ),
                  Expanded(
                    child: Text(
                      page.juzName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'انتقال',
                    onPressed: onSearchTap,
                    icon: Icon(Icons.search_rounded, color: primaryColor),
                  ),
                ],
              ),
            ),
            if (page.hizbQuarterText != null)
              Text(
                page.hizbQuarterText!,
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                itemCount: page.ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = page.ayahs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ayah.isFirstInSurah) _surahBanner(ayah),
                      GestureDetector(
                        onTap: () => onAyahTap(ayah),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: ayah.text,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: fontSize,
                                    height: 2.05,
                                  ),
                                ),
                                TextSpan(
                                  text: '  ﴿${toArabicDigits(ayah.numberInSurah)}﴾  ',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: fontSize * 0.72,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            TextButton(
              onPressed: onPageNumberTap,
              child: Text(
                'صفحة ${toArabicDigits(page.pageNumber)}',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahBanner(MushafAyah ayah) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.7)),
        color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
      ),
      child: Text(
        ayah.surahName,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: accentColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
