import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioView extends StatefulWidget {
  const QuranAudioView({
    super.key,
    required this.surahs,
    required this.surfaceColor,
    required this.accentColor,
    required this.goldColor,
    required this.textColor,
    required this.textMutedColor,
  });

  final List<Map<String, dynamic>> surahs;
  final Color surfaceColor;
  final Color accentColor;
  final Color goldColor;
  final Color textColor;
  final Color textMutedColor;

  @override
  State<QuranAudioView> createState() => _QuranAudioViewState();
}

class _QuranAudioViewState extends State<QuranAudioView> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _stateSub;
  int? _playingNumber;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(Map<String, dynamic> surah) async {
    final number = surah['number'] as int;
    HapticFeedback.selectionClick();
    if (_playingNumber == number && _player.playing) {
      await _player.pause();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _busy = true;
      _playingNumber = number;
    });
    final padded = number.toString().padLeft(3, '0');
    final uri = Uri.parse('https://server8.mp3quran.net/afs/$padded.mp3');
    try {
      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل السورة الآن')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: widget.surahs.length,
      itemBuilder: (context, index) {
        final surah = widget.surahs[index];
        final number = surah['number'] as int;
        final playing = _playingNumber == number && _player.playing;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: CircleAvatar(
                backgroundColor: widget.goldColor.withValues(alpha: 0.16),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: widget.goldColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                surah['name'] as String? ?? '',
                style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'مشاري العفاسي',
                style: TextStyle(color: widget.textMutedColor, fontSize: 12),
              ),
              trailing: _busy && _playingNumber == number
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.accentColor,
                      ),
                    )
                  : Icon(
                      playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: widget.accentColor,
                      size: 32,
                    ),
              onTap: () => _toggle(surah),
            ),
          ),
        );
      },
    );
  }
}
