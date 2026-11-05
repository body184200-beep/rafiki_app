import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';
import 'package:rafiki_app/features/guide/data/services/podcast_service.dart';

class PrayerPodcastPage extends StatefulWidget {
  const PrayerPodcastPage({super.key});

  @override
  State<PrayerPodcastPage> createState() => _PrayerPodcastPageState();
}

class _PrayerPodcastPageState extends State<PrayerPodcastPage> with SingleTickerProviderStateMixin {
  final PodcastService _podcastService = PodcastService.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  late final TabController _tabCtrl;
  StreamSubscription? _episodesSub;

  List<PodcastChannel> _channels = [];
  List<PodcastEpisode> _episodes = [];
  List<PodcastEpisode> _downloadedEpisodes = [];
  final Set<int> _downloadedIds = {};
  final Map<int, double> _downloadProgress = {};

  PodcastChannel? _selectedChannel;
  bool _isLoading = true;
  String _searchQuery = '';
  List<PodcastChannel> _searchResults = [];
  List<PodcastEpisode> _matchingEpisodes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadInitialData();
    _episodesSub = _podcastService.onEpisodesUpdated.listen((channelId) {
      if (!mounted) return;
      setState(() {
        if (_selectedChannel == null) {
          _episodes = _podcastService.getAllEpisodes();
        } else if (_selectedChannel!.id == channelId) {
          _episodes = _podcastService.getCachedEpisodesForChannel(channelId);
        }
      });
    });
  }

  @override
  void dispose() {
    _episodesSub?.cancel();
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final channels = await _podcastService.loadFeaturedChannels();
    await _refreshDownloads();

    if (!mounted) return;

    final allEpisodes = _podcastService.getAllEpisodes();

    setState(() {
      _channels = channels;
      _selectedChannel = null; // null = جميع الحلقات (كل السلاسل)
      _episodes = allEpisodes;
      _isLoading = false;
    });

    // Refresh live channels in background
    for (final c in channels) {
      _podcastService.fetchEpisodesForChannel(c.id, channelTitle: c.title, artworkUrl: c.artworkUrl);
    }
  }

  Future<void> _refreshDownloads() async {
    final downloaded = await _podcastService.getDownloadedEpisodes();
    final ids = await _podcastService.getDownloadedEpisodeIds();
    if (mounted) {
      setState(() {
        _downloadedEpisodes = downloaded;
        _downloadedIds.clear();
        _downloadedIds.addAll(ids);
      });
    }
  }

  Future<void> _selectChannel(PodcastChannel? channel) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChannel = channel;
      if (channel == null) {
        _episodes = _podcastService.getAllEpisodes();
        _isLoading = false;
      } else {
        final cached = _podcastService.getCachedEpisodesForChannel(channel.id);
        _episodes = cached.isNotEmpty ? cached : channel.episodes;
        _isLoading = _episodes.isEmpty;
      }
    });

    _tabCtrl.animateTo(1); // switch to Episodes tab
    if (channel != null) {
      await _loadEpisodesForChannel(channel);
    }
  }

  Future<void> _loadEpisodesForChannel(PodcastChannel channel) async {
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
        _matchingEpisodes = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _podcastService.searchPodcasts(q);
    final allEps = _podcastService.getAllEpisodes();
    final matching = allEps.where((e) {
      return e.title.toLowerCase().contains(q.toLowerCase()) ||
          e.channelTitle.toLowerCase().contains(q.toLowerCase()) ||
          e.description.toLowerCase().contains(q.toLowerCase());
    }).toList();

    if (mounted && _searchQuery == q) {
      setState(() {
        _searchResults = results;
        _matchingEpisodes = matching;
        _isSearching = false;
      });
    }
  }

  Future<void> _startDownload(PodcastEpisode episode) async {
    HapticFeedback.lightImpact();
    setState(() => _downloadProgress[episode.id] = 0.05);

    final success = await _podcastService.downloadEpisode(
      episode: episode,
      onProgress: (p) {
        if (mounted) {
          setState(() => _downloadProgress[episode.id] = p);
        }
      },
    );

    if (mounted) {
      setState(() => _downloadProgress.remove(episode.id));
      await _refreshDownloads();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم تحميل حلقة "${episode.title}" بنجاح! يمكنك الاستماع إليها الآن دون اتصال بالإنترنت.'
                : 'تعذر تحميل الحلقة، يرجى التأكد من اتصال الإنترنت.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteDownload(PodcastEpisode episode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحلقة المحمّلة'),
          content: Text('هل تريد حذف حلقة "${episode.title}" من ذاكرة الهاتف؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _podcastService.deleteDownloadedEpisode(episode.id);
      await _refreshDownloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final bg = isLight ? const Color(0xFFF8F6F0) : const Color(0xFF090D14);
        final surface = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF101622);
        final cardColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF151C2C);
        final accent = isLight ? const Color(0xFF0F4A39) : const Color(0xFF4ECCA3);
        final gold = isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C);
        final textPri = isLight ? const Color(0xFF111827) : const Color(0xFFF1F5F9);
        final textSec = isLight ? const Color(0xFF6B7280) : const Color(0xFF8C9BAE);
        final border = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1F2B42);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 20),
                tooltip: 'رجوع',
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Column(
                children: [
                  Text(
                    'بودكاست إسلامي 🎙️',
                    style: TextStyle(
                      color: textPri,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'سلاسل صوتية وبرامج دينية لنخبة من كبار الدعاة',
                    style: TextStyle(color: textSec, fontSize: 11),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                // ── Search Bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: textPri, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن بودكاست أو داعية أو موضوع إسلامي...',
                        hintStyle: TextStyle(color: textSec, fontSize: 12.5),
                        prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, color: textSec, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),

                // ── Tab Bar (All Series / Episodes / Downloads) ─────────────
                if (_searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent, width: 1.2),
                        ),
                        labelColor: accent,
                        unselectedLabelColor: textSec,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: [
                          Tab(text: 'جميع السلاسل (${_channels.length})'),
                          Tab(
                            text: _selectedChannel == null
                                ? 'جميع الحلقات (${_episodes.length})'
                                : 'الحلقات (${_episodes.length})',
                          ),
                          Tab(
                            text: 'المحمّلة (${_downloadedEpisodes.length})',
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Main Content Area ───────────────────────────────────────
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults(accent, gold, textPri, textSec, surface, cardColor, border)
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            // Tab 1: All Series / Channels
                            _buildAllChannelsGrid(accent, gold, textPri, textSec, surface, border),
                            // Tab 2: Episodes of Selected Channel
                            _buildEpisodeList(accent, gold, textPri, textSec, cardColor, border),
                            // Tab 3: Downloaded Episodes
                            _buildDownloadsList(accent, gold, textPri, textSec, cardColor, border),
                          ],
                        ),
                ),

                // ── Mini Player at Bottom ───────────────────────────────────
                _buildMiniPlayer(accent, gold, textPri, textSec, surface),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 1: All Channels ───────────────────────────────────────────────────
  Widget _buildAllChannelsGrid(
    Color accent,
    Color gold,
    Color textPri,
    Color textSec,
    Color surface,
    Color border,
  ) {
    if (_channels.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _channels.length,
      itemBuilder: (context, i) {
        final ch = _channels[i];
        final isSelected = ch.id == _selectedChannel?.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectChannel(ch),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.08) : surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accent : border,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: border,
                        child: ch.artworkUrl.isNotEmpty
                            ? Image.network(
                                ch.artworkUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.podcasts_rounded, color: accent, size: 28),
                              )
                            : Icon(Icons.podcasts_rounded, color: accent, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPri,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ch.artist.isNotEmpty ? ch.artist : 'سلسلة بودكاست إسلامي',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${ch.episodeCount > 0 ? ch.episodeCount : ch.episodes.length} حلقة متوفرة',
                              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isSelected ? accent : textSec.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: Episodes List ──────────────────────────────────────────────────
  Widget _buildEpisodeList(
    Color accent,
    Color gold,
    Color textPri,
    Color textSec,
    Color cardColor,
    Color border,
  ) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    final totalCount = _podcastService.getAllEpisodes().length;

    return Column(
      children: [
        // ── Series Filter Chips (Horizontal Scrollable) ─────────────────────
        Container(
          height: 40,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // All Episodes Chip
              ChoiceChip(
                label: Text(
                  'الكل ($totalCount)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _selectedChannel == null ? FontWeight.bold : FontWeight.w500,
                    color: _selectedChannel == null ? accent : textSec,
                  ),
                ),
                selected: _selectedChannel == null,
                selectedColor: accent.withValues(alpha: 0.16),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: _selectedChannel == null ? accent : border,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedChannel = null;
                    _episodes = _podcastService.getAllEpisodes();
                  });
                },
              ),
              const SizedBox(width: 8),

              // Individual Series Chips
              ..._channels.map((ch) {
                final isSelected = _selectedChannel?.id == ch.id;
                final count = ch.episodeCount > 0 ? ch.episodeCount : ch.episodes.length;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(
                      '${ch.title} ($count)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? accent : textSec,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: accent.withValues(alpha: 0.16),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: isSelected ? accent : border,
                    ),
                    onSelected: (_) => _selectChannel(ch),
                  ),
                );
              }),
            ],
          ),
        ),

        // Channel or All Episodes Header Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChannel != null
                          ? _selectedChannel!.title
                          : '🎙️ جميع الحلقات (${_episodes.length} حلقة)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textPri, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedChannel != null
                          ? _selectedChannel!.artist
                          : 'استمع إلى جميع الحلقات والتسجيلات لكل السلاسل بدون استثناء',
                      style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (_selectedChannel != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedChannel = null;
                      _episodes = _podcastService.getAllEpisodes();
                    });
                  },
                  icon: const Icon(Icons.all_inclusive_rounded, size: 16),
                  label: const Text('عرض الكل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),

        // Episodes ListView
        Expanded(
          child: _episodes.isEmpty
              ? Center(
                  child: Text('لا توجد حلقات متوفرة حالياً', style: TextStyle(color: textSec)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _episodes.length,
                  itemBuilder: (context, index) {
                    final ep = _episodes[index];
                    return _buildEpisodeCard(ep, accent, gold, textPri, textSec, cardColor, border);
                  },
                ),
        ),
      ],
    );
  }

  // ── Tab 3: Downloads List ─────────────────────────────────────────────────
  Widget _buildDownloadsList(
    Color accent,
    Color gold,
    Color textPri,
    Color textSec,
    Color cardColor,
    Color border,
  ) {
    if (_downloadedEpisodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_for_offline_outlined, size: 52, color: textSec.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'لا توجد حلقات محملة حالياً',
              style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'يمكنك تنزيل أي حلقة للاستماع إليها لاحقاً بدون إنترنت',
              style: TextStyle(color: textSec, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: _downloadedEpisodes.length,
      itemBuilder: (context, index) {
        final ep = _downloadedEpisodes[index];
        return _buildEpisodeCard(ep, accent, gold, textPri, textSec, cardColor, border, isDownloadTab: true);
      },
    );
  }

  // ── Single Episode Card ───────────────────────────────────────────────────
  Widget _buildEpisodeCard(
    PodcastEpisode ep,
    Color accent,
    Color gold,
    Color textPri,
    Color textSec,
    Color cardColor,
    Color border, {
    bool isDownloadTab = false,
  }) {
    final isDownloaded = _downloadedIds.contains(ep.id);
    final progress = _downloadProgress[ep.id];
    final isDownloading = progress != null;

    return ValueListenableBuilder<PodcastEpisode?>(
      valueListenable: _podcastService.currentEpisode,
      builder: (context, current, _) {
        final isSelected = current?.id == ep.id;

        return ValueListenableBuilder<bool>(
          valueListenable: _podcastService.isPlaying,
          builder: (context, isPlaying, _) {
            final isCurrentPlaying = isSelected && isPlaying;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? accent.withValues(alpha: 0.1) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accent : border,
                  width: isSelected ? 1.4 : 0.8,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Play / Pause Circle
                    GestureDetector(
                      onTap: () {
                        if (isSelected) {
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
                          color: isSelected ? accent : accent.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isSelected ? Colors.white : accent,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Episode details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ep.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? accent : textPri,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedChannel == null && ep.channelTitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              ep.channelTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (ep.durationMs > 0) ...[
                                Icon(Icons.access_time_rounded, size: 12, color: textSec),
                                const SizedBox(width: 4),
                                Text(
                                  TimeFormat.hhmmss(Duration(milliseconds: ep.durationMs)),
                                  style: TextStyle(color: textSec, fontSize: 11),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (isDownloaded)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                      SizedBox(width: 3),
                                      Text(
                                        'محفوظ بدون إنترنت',
                                        style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Download / Delete button
                    if (isDownloading)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2.5,
                              color: accent,
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else if (isDownloaded)
                      IconButton(
                        icon: const Icon(Icons.offline_pin_rounded, color: Color(0xFF10B981), size: 24),
                        tooltip: 'محمل على هاتفك (انقر للحذف)',
                        onPressed: () => _deleteDownload(ep),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.download_rounded, color: textSec, size: 22),
                        tooltip: 'تنزيل على الهاتف',
                        onPressed: () => _startDownload(ep),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Search Results ────────────────────────────────────────────────────────
  Widget _buildSearchResults(
    Color accent,
    Color gold,
    Color textPri,
    Color textSec,
    Color surface,
    Color cardColor,
    Color border,
  ) {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (_searchResults.isEmpty && _matchingEpisodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: textSec.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            Text('لم يتم العثور على نتائج لـ "$_searchQuery"', style: TextStyle(color: textPri, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'السلاسل والبرامج (${_searchResults.length})',
              style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ..._searchResults.map(
            (ch) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ch.artworkUrl.isNotEmpty
                      ? Image.network(
                          ch.artworkUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.podcasts_rounded, color: accent),
                        )
                      : Icon(Icons.podcasts_rounded, color: accent),
                ),
                title: Text(
                  ch.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textPri, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ch.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSec, fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: textSec),
                onTap: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
                  _selectChannel(ch);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_matchingEpisodes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'الحلقات المطابقة (${_matchingEpisodes.length})',
              style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ..._matchingEpisodes.map(
            (ep) => _buildEpisodeCard(ep, accent, gold, textPri, textSec, cardColor, border),
          ),
        ],
      ],
    );
  }

  // ── Bottom Mini Player ────────────────────────────────────────────────────
  Widget _buildMiniPlayer(Color accent, Color gold, Color textPri, Color textSec, Color surface) {
    return ValueListenableBuilder<PodcastEpisode?>(
      valueListenable: _podcastService.currentEpisode,
      builder: (context, current, _) {
        if (current == null) return const SizedBox.shrink();

        return _PodcastPlayerBar(
          episode: current,
          accent: accent,
          gold: gold,
          textPri: textPri,
          textSec: textSec,
          surface: surface,
        );
      },
    );
  }
}

class _PodcastPlayerBar extends StatefulWidget {
  final PodcastEpisode episode;
  final Color accent;
  final Color gold;
  final Color textPri;
  final Color textSec;
  final Color surface;

  const _PodcastPlayerBar({
    required this.episode,
    required this.accent,
    required this.gold,
    required this.textPri,
    required this.textSec,
    required this.surface,
  });

  @override
  State<_PodcastPlayerBar> createState() => _PodcastPlayerBarState();
}

class _PodcastPlayerBarState extends State<_PodcastPlayerBar> {
  final PodcastService _podcastService = PodcastService.instance;
  double? _dragSeconds;

  String _formatDuration(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _cycleSpeed() {
    HapticFeedback.selectionClick();
    final current = _podcastService.speed.value;
    final speeds = [1.0, 1.25, 1.5, 2.0];
    int nextIdx = 0;
    for (int i = 0; i < speeds.length; i++) {
      if ((speeds[i] - current).abs() < 0.05) {
        nextIdx = (i + 1) % speeds.length;
        break;
      }
    }
    _podcastService.setPlaybackSpeed(speeds[nextIdx]);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.episode;

    return Container(
      decoration: BoxDecoration(
        color: widget.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: widget.accent.withValues(alpha: 0.35), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Row: Artwork / Title / Speed / Close ──────────────────
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: widget.accent.withValues(alpha: 0.15),
                      child: current.artworkUrl.isNotEmpty
                          ? Image.network(
                              current.artworkUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.podcasts_rounded, color: widget.accent, size: 20),
                            )
                          : Icon(Icons.podcasts_rounded, color: widget.accent, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.textPri,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          current.channelTitle.isNotEmpty ? current.channelTitle : 'بودكاست صوتي',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Speed Control Chip
                  ValueListenableBuilder<double>(
                    valueListenable: _podcastService.speed,
                    builder: (_, spd, __) {
                      final label = spd == 1.0
                          ? '1x'
                          : spd == 1.25
                              ? '1.25x'
                              : spd == 1.5
                                  ? '1.5x'
                                  : '${spd.toStringAsFixed(1)}x';
                      return InkWell(
                        onTap: _cycleSpeed,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: widget.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Close / Stop Button
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: widget.textSec, size: 20),
                    tooltip: 'إيقاف وإغلاق المشغل',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _podcastService.stop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // ── Middle Row: Progress Slider with Times ─────────────────────
              ValueListenableBuilder<Duration>(
                valueListenable: _podcastService.position,
                builder: (_, pos, __) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _podcastService.duration,
                    builder: (_, dur, __) {
                      final effectivePosSeconds = _dragSeconds ?? pos.inSeconds.toDouble();
                      final maxSeconds = max(1.0, dur.inSeconds.toDouble());
                      final clampedSeconds = effectivePosSeconds.clamp(0.0, maxSeconds);

                      final posText = _dragSeconds != null
                          ? _formatDuration(Duration(seconds: _dragSeconds!.round()))
                          : _formatDuration(pos);
                      final durText = _formatDuration(dur);

                      return Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Text(
                              posText,
                              style: TextStyle(
                                color: widget.textSec,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: widget.accent,
                                  inactiveTrackColor: widget.textSec.withValues(alpha: 0.22),
                                  thumbColor: widget.gold,
                                  overlayColor: widget.accent.withValues(alpha: 0.15),
                                ),
                                child: Slider(
                                  value: clampedSeconds,
                                  min: 0.0,
                                  max: maxSeconds,
                                  onChanged: dur.inSeconds > 0
                                      ? (val) {
                                          setState(() => _dragSeconds = val);
                                        }
                                      : null,
                                  onChangeEnd: dur.inSeconds > 0
                                      ? (val) {
                                          HapticFeedback.selectionClick();
                                          _podcastService.seek(Duration(seconds: val.round()));
                                          setState(() => _dragSeconds = null);
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              durText,
                              style: TextStyle(
                                color: widget.textSec,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Bottom Row: Controls (Rewind 10s, Play/Pause, Forward 10s) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 10s Backward (Rewind)
                  IconButton(
                    icon: Icon(Icons.replay_10_rounded, color: widget.textPri, size: 28),
                    tooltip: 'تأخير ١٠ ثوانٍ',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _podcastService.seekBackward10();
                    },
                  ),

                  const SizedBox(width: 16),

                  // Play / Pause / Buffering
                  ValueListenableBuilder<bool>(
                    valueListenable: _podcastService.isBuffering,
                    builder: (_, isBuffering, __) {
                      if (isBuffering) {
                        return Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: widget.accent,
                          ),
                        );
                      }

                      return ValueListenableBuilder<bool>(
                        valueListenable: _podcastService.isPlaying,
                        builder: (_, isPlaying, __) {
                          return IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: widget.accent,
                              size: 44,
                            ),
                            tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _podcastService.togglePlayPause();
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // 10s Forward
                  IconButton(
                    icon: Icon(Icons.forward_10_rounded, color: widget.textPri, size: 28),
                    tooltip: 'تقديم ١٠ ثوانٍ',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _podcastService.seekForward10();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
