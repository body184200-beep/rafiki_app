import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';
import 'package:rafiki_app/features/guide/data/services/podcast_service.dart';

class PrayerPodcastPage extends StatefulWidget {
  const PrayerPodcastPage({super.key});

  @override
  State<PrayerPodcastPage> createState() => _PrayerPodcastPageState();
}

class _PrayerPodcastPageState extends State<PrayerPodcastPage> {
  final PodcastService _podcastService = PodcastService.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<PodcastChannel> _channels = [];
  List<PodcastEpisode> _episodes = [];
  PodcastChannel? _selectedChannel;
  bool _isLoading = true;
  String _searchQuery = '';
  List<PodcastChannel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final channels = await _podcastService.loadFeaturedChannels();

    if (!mounted) return;

    setState(() {
      _channels = channels;
      if (channels.isNotEmpty) {
        _selectedChannel = channels.first;
        _episodes = channels.first.episodes;
      }
      _isLoading = false;
    });

    if (channels.isNotEmpty) {
      _selectChannel(channels.first);
    }
  }

  Future<void> _selectChannel(PodcastChannel channel) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChannel = channel;
      _episodes = channel.episodes;
      _isLoading = channel.episodes.isEmpty;
    });

    final episodes = await _podcastService.fetchEpisodesForChannel(
      channel.id,
      channelTitle: channel.title,
      artworkUrl: channel.artworkUrl,
    );

    if (mounted && _selectedChannel?.id == channel.id) {
      setState(() {
        _episodes = episodes;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged(String val) async {
    final q = val.trim();
    setState(() {
      _searchQuery = q;
    });

    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _podcastService.searchPodcasts(q);

    if (mounted && _searchQuery == q) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF090D14);
    const surface = Color(0xFF101622);
    const cardColor = Color(0xFF151C2C);
    const accent = Color(0xFF4ECCA3);
    const gold = Color(0xFFE5A93C);
    const textPri = Color(0xFFF1F5F9);
    const textSec = Color(0xFF8C9BAE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: textPri, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          children: [
            Text(
              'بودكاست إسلامي 🎙️',
              style: TextStyle(
                color: textPri,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'سلاسل صوتية وبرامج دينية لنخبة من الدعاة',
              style: TextStyle(color: textSec, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 1. Search Box ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2B42)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: textPri, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'ابحث عن بودكاست، داعية، أو موضوع إسلامي...',
                  hintStyle: const TextStyle(color: Color(0xFF5F6E84), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: accent, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: textSec, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── 2. Channels Carousel (Only shown when not searching) ───────────
          if (_searchQuery.isEmpty) ...[
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _channels.length,
                itemBuilder: (context, index) {
                  final ch = _channels[index];
                  final isSelected = ch.id == _selectedChannel?.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => _selectChannel(ch),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.withValues(alpha: 0.18) : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accent : const Color(0xFF1E283C),
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.podcasts_rounded,
                              size: 15,
                              color: isSelected ? accent : textSec,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ch.title,
                              style: TextStyle(
                                color: isSelected ? accent : textSec,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── 3. Selected Channel Banner ────────────────────────────────────
            if (_selectedChannel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.15),
                        surface,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: cardColor,
                          child: _selectedChannel!.artworkUrl.isNotEmpty
                              ? Image.network(
                                  _selectedChannel!.artworkUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.podcasts_rounded, color: accent),
                                )
                              : const Icon(Icons.podcasts_rounded, color: accent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedChannel!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textPri,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedChannel!.artist.isNotEmpty ? _selectedChannel!.artist : 'سلسلة إسلامية صوتية',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: gold, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_episodes.length} حلقة',
                          style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],

          // ── 4. Main Body: Episodes or Search Results ───────────────────────
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(accent, textPri, textSec, surface)
                : _buildEpisodeList(accent, gold, textPri, textSec, cardColor),
          ),

          // ── 5. Bottom Mini Audio Player ────────────────────────────────────
          _buildMiniPlayer(accent, gold, textPri, textSec, surface),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Color accent, Color textPri, Color textSec, Color surface) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4ECCA3)));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: textSec.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            Text('لم يتم العثور على بودكاست لـ "$_searchQuery"', style: TextStyle(color: textPri, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final ch = _searchResults[index];
        return Card(
          color: surface,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF1E283C)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.black26,
                child: ch.artworkUrl.isNotEmpty
                    ? Image.network(ch.artworkUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.podcasts))
                    : const Icon(Icons.podcasts),
              ),
            ),
            title: Text(ch.title, maxLines: 1, style: TextStyle(color: textPri, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(ch.artist, maxLines: 1, style: TextStyle(color: textSec, fontSize: 12)),
            trailing: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF4ECCA3), size: 14),
            onTap: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
              _selectChannel(ch);
            },
          ),
        );
      },
    );
  }

  Widget _buildEpisodeList(Color accent, Color gold, Color textPri, Color textSec, Color cardColor) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4ECCA3)),
            SizedBox(height: 12),
            Text('جارٍ جلب الحلقات الصوتية...', style: TextStyle(color: Color(0xFF8C9BAE), fontSize: 12.5)),
          ],
        ),
      );
    }

    if (_episodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off_rounded, color: textSec.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            Text('لا توجد حلقات صوتية متوفرة حالياً', style: TextStyle(color: textPri, fontSize: 14)),
          ],
        ),
      );
    }

    return ValueListenableBuilder<PodcastEpisode?>(
      valueListenable: _podcastService.currentEpisode,
      builder: (context, activeEp, _) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: _episodes.length,
          itemBuilder: (context, index) {
            final ep = _episodes[index];
            final isPlaying = activeEp?.id == ep.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isPlaying ? accent.withValues(alpha: 0.12) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlaying ? accent : const BorderSide(color: Color(0xFF1E273A)).color,
                  width: isPlaying ? 1.4 : 0.8,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showEpisodeDetails(ep),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Play/Pause Action
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (isPlaying) {
                              _podcastService.togglePlayPause();
                            } else {
                              _podcastService.playEpisode(ep);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isPlaying ? [accent, gold] : [const Color(0xFF1F2B42), const Color(0xFF2C3E5E)],
                              ),
                              boxShadow: isPlaying
                                  ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                                  : null,
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _podcastService.isPlaying,
                              builder: (_, playing, __) {
                                final thisIsPlaying = isPlaying && playing;
                                return Icon(
                                  thisIsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: isPlaying ? const Color(0xFF090D14) : accent,
                                  size: 26,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ep.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? accent : textPri,
                                  fontSize: 13.5,
                                  fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: gold),
                                  const SizedBox(width: 4),
                                  Text(
                                    ep.formattedDuration,
                                    style: TextStyle(color: gold.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  if (isPlaying) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'يعمل الآن',
                                        style: TextStyle(color: Color(0xFF090D14), fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Info / More icon
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6B7C96), size: 20),
                          onPressed: () => _showEpisodeDetails(ep),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 5. Bottom Mini Player ──────────────────────────────────────────────────
  Widget _buildMiniPlayer(Color accent, Color gold, Color textPri, Color textSec, Color surface) {
    return ValueListenableBuilder<PodcastEpisode?>(
      valueListenable: _podcastService.currentEpisode,
      builder: (context, ep, _) {
        if (ep == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: surface,
            border: const Border(top: BorderSide(color: Color(0xFF223048), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Line
              ValueListenableBuilder<Duration>(
                valueListenable: _podcastService.position,
                builder: (_, pos, __) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _podcastService.duration,
                    builder: (_, dur, __) {
                      final progress = (dur.inMilliseconds > 0)
                          ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0;
                      return LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      );
                    },
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Rewind 10s
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Color(0xFF90A0B8), size: 24),
                      onPressed: () => _podcastService.seekBackward10(),
                    ),

                    // Play/Pause
                    ValueListenableBuilder<bool>(
                      valueListenable: _podcastService.isPlaying,
                      builder: (_, playing, __) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: _podcastService.isBuffering,
                          builder: (_, buffering, __) {
                            if (buffering) {
                              return const SizedBox(
                                width: 36,
                                height: 36,
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4ECCA3)),
                                ),
                              );
                            }
                            return IconButton(
                              icon: Icon(
                                playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: accent,
                                size: 36,
                              ),
                              onPressed: () => _podcastService.togglePlayPause(),
                            );
                          },
                        );
                      },
                    ),

                    // Forward 10s
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Color(0xFF90A0B8), size: 24),
                      onPressed: () => _podcastService.seekForward10(),
                    ),

                    const SizedBox(width: 8),

                    // Episode title & channel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEpisodeDetails(ep),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ep.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textPri, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ep.channelTitle.isNotEmpty ? ep.channelTitle : 'بودكاست إسلامي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: gold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Close stop button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF708098), size: 20),
                      onPressed: () => _podcastService.stop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 6. Full Episode Details & Playback Sheet ───────────────────────────────
  void _showEpisodeDetails(PodcastEpisode ep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const modalBg = Color(0xFF101726);
        const accent = Color(0xFF4ECCA3);
        const gold = Color(0xFFE5A93C);

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: modalBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF223048), width: 1.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF324462),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Channel
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.podcasts_rounded, color: accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ep.channelTitle.isNotEmpty ? ep.channelTitle : 'بودكاست ديني',
                                  style: const TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ep.formattedDuration,
                                  style: const TextStyle(color: Color(0xFF8C9BAE), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Episode Title
                      Text(
                        ep.title,
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Player Controls Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF243350)),
                        ),
                        child: Column(
                          children: [
                            // Scrubber Slider
                            ValueListenableBuilder<PodcastEpisode?>(
                              valueListenable: _podcastService.currentEpisode,
                              builder: (_, activeEp, __) {
                                final isThisActive = activeEp?.id == ep.id;

                                return ValueListenableBuilder<Duration>(
                                  valueListenable: _podcastService.position,
                                  builder: (_, pos, __) {
                                    return ValueListenableBuilder<Duration>(
                                      valueListenable: _podcastService.duration,
                                      builder: (_, dur, __) {
                                        final maxMs = dur.inMilliseconds.toDouble();
                                        final curMs = isThisActive ? pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0) : 0.0;

                                        return Column(
                                          children: [
                                            SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 3.5,
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                                activeTrackColor: accent,
                                                inactiveTrackColor: const Color(0xFF263754),
                                                thumbColor: accent,
                                              ),
                                              child: Slider(
                                                value: curMs,
                                                min: 0.0,
                                                max: maxMs > 0 ? maxMs : 1.0,
                                                onChanged: isThisActive
                                                    ? (val) {
                                                        _podcastService.seek(Duration(milliseconds: val.toInt()));
                                                      }
                                                    : null,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    isThisActive ? TimeFormat.hhmmss(pos) : '00:00:00',
                                                    style: const TextStyle(color: Color(0xFF8C9BAE), fontSize: 11),
                                                  ),
                                                  Text(
                                                    isThisActive && dur > Duration.zero ? TimeFormat.hhmmss(dur) : ep.formattedDuration,
                                                    style: const TextStyle(color: Color(0xFF8C9BAE), fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // Control Buttons: -10s, Play/Pause, +10s, Speed
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Playback Speed
                                ValueListenableBuilder<double>(
                                  valueListenable: _podcastService.speed,
                                  builder: (_, sp, __) {
                                    return TextButton(
                                      onPressed: () {
                                        final next = sp == 1.0
                                            ? 1.25
                                            : sp == 1.25
                                                ? 1.5
                                                : sp == 1.5
                                                    ? 2.0
                                                    : 1.0;
                                        _podcastService.setPlaybackSpeed(next);
                                      },
                                      child: Text(
                                        '${sp}x',
                                        style: const TextStyle(color: Color(0xFF8C9BAE), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    );
                                  },
                                ),

                                // -10s
                                IconButton(
                                  icon: const Icon(Icons.replay_10_rounded, color: Color(0xFFF1F5F9), size: 28),
                                  onPressed: () => _podcastService.seekBackward10(),
                                ),

                                // Play / Pause Big
                                ValueListenableBuilder<PodcastEpisode?>(
                                  valueListenable: _podcastService.currentEpisode,
                                  builder: (_, activeEp, __) {
                                    final isThisEp = activeEp?.id == ep.id;

                                    return ValueListenableBuilder<bool>(
                                      valueListenable: _podcastService.isPlaying,
                                      builder: (_, playing, __) {
                                        final isActivelyPlaying = isThisEp && playing;

                                        return Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(colors: [accent, gold]),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accent.withValues(alpha: 0.4),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              isActivelyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: const Color(0xFF090D14),
                                              size: 36,
                                            ),
                                            onPressed: () {
                                              if (isThisEp) {
                                                _podcastService.togglePlayPause();
                                              } else {
                                                _podcastService.playEpisode(ep);
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                // +10s
                                IconButton(
                                  icon: const Icon(Icons.forward_10_rounded, color: Color(0xFFF1F5F9), size: 28),
                                  onPressed: () => _podcastService.seekForward10(),
                                ),

                                const SizedBox(width: 32),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Episode Description
                      if (ep.description.isNotEmpty) ...[
                        const Text(
                          'عن هذه الحلقة:',
                          style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A2A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E283C)),
                          ),
                          child: Text(
                            ep.description,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
