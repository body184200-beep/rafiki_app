import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/gamification/data/services/loot_box_engine.dart';
import 'package:rafiki_app/features/gamification/data/models/loot_box_model.dart';
import 'package:rafiki_app/features/gamification/data/services/reward_engine.dart';
import 'package:rafiki_app/features/gamification/presentation/controllers/reward_controller.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF07090F);
  static const surface   = Color(0xFF0D1120);
  static const gold      = Color(0xFFD4A843);
  static const goldLight = Color(0xFFF0C870);
  static const onCard    = Color(0xFFF5EDD8);
  static const muted     = Color(0xFF4A5568);
  
  static const silver    = Color(0xFFC0C0C0);
  static const bronze    = Color(0xFFCD7F32);
  static const legendary = Color(0xFF9B59B6);
  static const epic      = Color(0xFFE74C3C);
}

class LootBoxScreen extends StatefulWidget {
  const LootBoxScreen({super.key});

  @override
  State<LootBoxScreen> createState() => _LootBoxScreenState();
}

class _LootBoxScreenState extends State<LootBoxScreen> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Future<void> _initFuture;
  late final RewardController _rewardController;

  @override
  void initState() {
    super.initState();
    _rewardController = sl<RewardController>();
    _initFuture = _initEngines();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  Future<void> _initEngines() async {
    await sl<LootBoxEngine>().initialize();
    await sl<RewardEngine>().initialize();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: isError ? Colors.red.shade900 : _C.surface,
        ),
      );
  }

  Future<void> _forgeChest() async {
    HapticFeedback.mediumImpact();
    try {
      await sl<LootBoxEngine>().forgeChest();
      _showSnack('تم صياغة صندوق جديد بنجاح! ✨');
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openChest(String chestId) async {
    HapticFeedback.heavyImpact();
    try {
      final rewards = await sl<LootBoxEngine>().openChest(chestId);
      
      // Process new discoveries
      final newDiscoveries = await sl<RewardEngine>().processRewards(rewards);

      if (!mounted) return;

      if (newDiscoveries.isNotEmpty) {
        // Run first-time discovery flow (Haptics, Sound, Celebration Dialog)
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.click);
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _CelebrationDialog(newDiscoveries: newDiscoveries),
        );
      }

      // Show standard rewards dialog
      _showRewardsDialog(rewards);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showRewardsDialog(List<RewardItem> rewards) {
    showDialog(
      context: context,
      builder: (ctx) => _RewardsListDialog(rewards: rewards),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _C.bg,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _C.gold),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'نظام المكافآت',
            style: TextStyle(
              color: _C.gold,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _C.gold),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('حدث خطأ أثناء تحميل المكافآت.', style: TextStyle(color: Colors.red)),
              );
            }
            return AnimatedBuilder(
              animation: _rewardController,
              builder: (context, _) => _buildContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    final keysValue = sl<LootBoxEngine>().keys.value;
    final chestsValue = sl<LootBoxEngine>().unopenedChests.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (ctx, child) => Opacity(
            opacity: _entryCtrl.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _entryCtrl.value)),
              child: child,
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildKeyBalance(keysValue),
                      const SizedBox(height: 24),
                      _buildForgeButton(keysValue),
                      const SizedBox(height: 32),
                      _buildEncyclopediaProgress(),
                    ],
                  ),
                ),
              ),
              
              // Chests Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'الصناديق المتاحة',
                    style: TextStyle(color: _C.goldLight, fontSize: 18, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (chestsValue.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'لا توجد صناديق مغلقة.\nصلواتك وأذكارك تمنحك المفاتيح!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _C.muted, fontSize: 14, fontFamily: 'Tajawal'),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildChestCard(chestsValue[i]),
                      childCount: chestsValue.length,
                    ),
                  ),
                ),

              // Encyclopedia & Filters Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الموسوعة والمعرض (الجوائز المستحقة)',
                        style: TextStyle(color: _C.goldLight, fontSize: 20, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'استكشف أوسمتك وجوائزك التي قمت بفتحها من الصناديق',
                        style: TextStyle(color: _C.muted, fontSize: 13, fontFamily: 'Tajawal'),
                      ),
                      const SizedBox(height: 16),
                      _buildFiltersAndSorting(),
                    ],
                  ),
                ),
              ),

              // Grid items
              _buildEncyclopediaGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: _C.gold.withValues(alpha: 0.3))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.star_rounded, color: _C.gold, size: 16),
            ),
            Expanded(child: Container(height: 1, color: _C.gold.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "نظام المكافآت",
          style: TextStyle(color: _C.goldLight, fontSize: 26, fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text("كل طاعة تفتح لك باباً للخير", style: TextStyle(color: _C.muted, fontSize: 13, fontFamily: 'Tajawal')),
      ],
    );
  }

  Widget _buildKeyBalance(int keys) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.vpn_key_rounded, color: _C.gold, size: 48),
          const SizedBox(height: 12),
          Text(
            keys.toString(),
            style: const TextStyle(color: _C.onCard, fontSize: 42, fontWeight: FontWeight.bold, height: 1.0),
          ),
          const Text("مفتاح", style: TextStyle(color: _C.muted, fontSize: 14, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildForgeButton(int keys) {
    final canForge = keys >= 5;
    return InkWell(
      onTap: canForge ? _forgeChest : null,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: canForge
                ? [_C.gold, _C.bronze]
                : [_C.surface, _C.surface],
          ),
          border: Border.all(color: canForge ? Colors.transparent : _C.muted),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: canForge ? _C.bg : _C.muted, size: 20),
              const SizedBox(width: 8),
              Text(
                'صياغة صندوق (5 مفاتيح)',
                style: TextStyle(
                  color: canForge ? _C.bg : _C.muted,
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChestCard(Chest chest) {
    Color chestColor = _C.bronze;
    String chestName = 'خشبي';
    IconData icon = Icons.inventory_2_rounded;

    if (chest.type == ChestType.silver) { chestColor = _C.silver; chestName = 'فضي'; }
    else if (chest.type == ChestType.gold) { chestColor = _C.goldLight; chestName = 'ذهبي'; icon = Icons.all_inbox_rounded; }
    else if (chest.type == ChestType.legendary) { chestColor = _C.legendary; chestName = 'أسطوري'; icon = Icons.diamond_rounded; }

    return GestureDetector(
      onTap: () => _openChest(chest.id),
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chestColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: chestColor.withValues(alpha: 0.1), blurRadius: 12),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: chestColor, size: 54),
            const SizedBox(height: 12),
            Text('صندوق $chestName', style: const TextStyle(color: _C.onCard, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('انقر للفتح', style: TextStyle(color: _C.muted, fontSize: 11, fontFamily: 'Tajawal')),
          ],
        ),
      ),
    );
  }

  Widget _buildEncyclopediaProgress() {
    final discovered = _rewardController.discoveredCount;
    final total = _rewardController.totalCount;
    final remaining = _rewardController.remainingCount;
    final pct = _rewardController.progressPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تم اكتشاف: $discovered / $total',
                style: const TextStyle(color: _C.onCard, fontSize: 15, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: _C.goldLight, fontSize: 15, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: _C.bg,
              valueColor: const AlwaysStoppedAnimation<Color>(_C.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'العناصر المتبقية للاكتشاف: $remaining',
            style: const TextStyle(color: _C.muted, fontSize: 12, fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSorting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: RewardFilter.values.map((f) {
              final isSelected = _rewardController.filter == f;
              String label = 'الكل';
              if (f == RewardFilter.locked) label = 'مغلق';
              if (f == RewardFilter.unlocked) label = 'مفتوح';
              if (f == RewardFilter.common) label = 'شائع';
              if (f == RewardFilter.rare) label = 'نادر';
              if (f == RewardFilter.epic) label = 'ملحمي';
              if (f == RewardFilter.legendary) label = 'أسطوري';

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                  selected: isSelected,
                  selectedColor: _C.gold,
                  checkmarkColor: _C.bg,
                  labelStyle: TextStyle(color: isSelected ? _C.bg : _C.onCard),
                  backgroundColor: _C.surface,
                  onSelected: (_) => _rewardController.setFilter(f),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Sort drop down
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ترتيب حسب:', style: TextStyle(color: _C.muted, fontSize: 13, fontFamily: 'Tajawal')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.gold.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RewardSort>(
                  value: _rewardController.sort,
                  dropdownColor: _C.surface,
                  style: const TextStyle(color: _C.onCard, fontFamily: 'Tajawal', fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: RewardSort.unlockedFirst, child: Text('المفتوح أولاً')),
                    DropdownMenuItem(value: RewardSort.lockedFirst, child: Text('المغلق أولاً')),
                    DropdownMenuItem(value: RewardSort.discoveryDate, child: Text('تاريخ الاكتشاف')),
                    DropdownMenuItem(value: RewardSort.rarity, child: Text('الندرة')),
                    DropdownMenuItem(value: RewardSort.name, child: Text('الاسم')),
                  ],
                  onChanged: (val) {
                    if (val != null) _rewardController.setSort(val);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEncyclopediaGrid() {
    final items = _rewardController.items;
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'لا توجد عناصر تطابق الفلترة الحالية.',
              style: TextStyle(color: _C.muted, fontFamily: 'Tajawal', fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Adjusted to 2 columns to give space for progress bars & unlock methods
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62, // Rectangular card to fit locked conditions
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final item = items[i];
            return _EncyclopediaCard(
              key: ValueKey(item.def.id),
              item: item,
              onTap: () => _onItemTapped(item),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  void _onItemTapped(EncyclopediaItemDisplay item) async {
    // 1. Locked (not discovered and progress < 1.0)
    if (!item.discovered && item.progress < 1.0) {
      _showSnack('اكتشف هذه المكافأة أولاً. 🔒', isError: true);
      return;
    }

    // 2. Claimable (not discovered but progress >= 1.0)
    if (!item.discovered && item.progress >= 1.0) {
      final success = await _rewardController.claimReward(item.def.id);
      if (success) {
        _showSnack('تهانينا! تم استلام المكافأة 🎉');
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => _DetailDialog(
              item: EncyclopediaItemDisplay(
                def: item.def,
                discovered: true,
                discoveredAt: DateTime.now(),
                timesObtained: 1,
                obtainMethod: item.obtainMethod,
                progress: 1.0,
                progressText: item.progressText,
                isSecret: item.isSecret,
              ),
            ),
          );
        }
      } else {
        _showSnack('حدث خطأ أثناء استلام المكافأة.', isError: true);
      }
      return;
    }

    // 3. Discovered / Claimed (already discovered)
    showDialog(
      context: context,
      builder: (ctx) => _DetailDialog(item: item),
    );
  }
}

// ─── ENCYCLOPEDIA CARD (LAZY / CACHED VISUALS) ────────────────────────────────
class _EncyclopediaCard extends StatelessWidget {
  final EncyclopediaItemDisplay item;
  final VoidCallback onTap;

  const _EncyclopediaCard({super.key, required this.item, required this.onTap});

  Color _rarityColor(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return Colors.blue;
      case RewardRarity.rare: return _C.silver;
      case RewardRarity.epic: return _C.epic;
      case RewardRarity.legendary: return _C.gold;
    }
  }

  String _rarityName(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return 'شائع';
      case RewardRarity.rare: return 'نادر';
      case RewardRarity.epic: return 'ملحمي';
      case RewardRarity.legendary: return 'أسطوري';
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.star_rounded;
    Color color = _rarityColor(item.def.rarity);

    if (item.def.type == RewardType.badge) { icon = Icons.military_tech_rounded; }
    else if (item.def.type == RewardType.frame) { icon = Icons.crop_free_rounded; }
    else if (item.def.type == RewardType.theme) { icon = Icons.format_paint_rounded; }
    else if (item.def.type == RewardType.artifact) { icon = Icons.diamond_rounded; }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.discovered ? color.withValues(alpha: 0.4) : _C.muted.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon representation
                Opacity(
                  opacity: item.discovered ? 1.0 : 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: item.discovered ? color.withValues(alpha: 0.2) : Colors.transparent),
                    ),
                    child: Icon(icon, color: item.discovered ? color : _C.muted, size: 40),
                  ),
                ),
                
                // Name
                Text(
                  item.discovered ? item.def.name : 'مكافأة مجهولة',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.discovered ? _C.onCard : _C.muted,
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Rarity Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _rarityName(item.def.rarity),
                    style: TextStyle(color: color, fontSize: 10, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                ),

                // Obtain Method / Instruction
                Text(
                  item.obtainMethod,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.discovered ? _C.muted : _C.goldLight.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontFamily: 'Tajawal',
                  ),
                ),

                // Cumulative Progress Bar
                if (!item.discovered && item.progress < 1.0)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 5,
                          backgroundColor: _C.bg,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.progressText,
                        style: TextStyle(color: _C.muted, fontSize: 9.5, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else if (item.discovered)
                  const Text(
                    '✓ تم الاكتشاف',
                    style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    'جاهز للاستلام 🎁',
                    style: TextStyle(color: _C.goldLight, fontSize: 11, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            if (!item.discovered)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.lock_rounded, color: _C.muted.withValues(alpha: 0.8), size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── CELEBRATION UNLOCK DIALOG ──────────────────────────────────────────────
class _CelebrationDialog extends StatefulWidget {
  final List<DiscoveryRecord> newDiscoveries;

  const _CelebrationDialog({required this.newDiscoveries});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  Color _rarityColor(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return Colors.blue;
      case RewardRarity.rare: return _C.silver;
      case RewardRarity.epic: return _C.epic;
      case RewardRarity.legendary: return _C.gold;
    }
  }

  String _rarityName(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return 'شائع';
      case RewardRarity.rare: return 'نادر';
      case RewardRarity.epic: return 'ملحمي';
      case RewardRarity.legendary: return 'أسطوري';
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.newDiscoveries.first;
    final def = allPossibleRewards.firstWhere((r) => r.id == record.rewardId);

    IconData icon = Icons.star_rounded;
    if (def.type == RewardType.badge) icon = Icons.military_tech_rounded;
    if (def.type == RewardType.frame) icon = Icons.crop_free_rounded;
    if (def.type == RewardType.theme) icon = Icons.format_paint_rounded;
    if (def.type == RewardType.artifact) icon = Icons.diamond_rounded;

    final rarityColor = _rarityColor(def.rarity);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sunburst
            AnimatedBuilder(
              animation: _rotationCtrl,
              builder: (ctx, child) => Transform.rotate(
                angle: _rotationCtrl.value * 2 * pi,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        rarityColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.9],
                    ),
                  ),
                ),
              ),
            ),
            
            // Container
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: rarityColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: rarityColor.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎉 تم اكتشاف عنصر جديد!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _C.goldLight,
                      fontSize: 22,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Big animated icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: rarityColor, size: 64),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    def.name,
                    style: const TextStyle(color: _C.onCard, fontSize: 18, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rarity label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _rarityName(def.rarity),
                      style: TextStyle(color: rarityColor, fontSize: 12, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    def.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _C.muted, fontSize: 13, fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rarityColor,
                        foregroundColor: _C.bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'رائع!',
                        style: TextStyle(fontSize: 16, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REWARD DETAIL DIALOG ──────────────────────────────────────────────────
class _DetailDialog extends StatelessWidget {
  final EncyclopediaItemDisplay item;

  const _DetailDialog({required this.item});

  Color _rarityColor(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return Colors.blue;
      case RewardRarity.rare: return _C.silver;
      case RewardRarity.epic: return _C.epic;
      case RewardRarity.legendary: return _C.gold;
    }
  }

  String _rarityName(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return 'شائع';
      case RewardRarity.rare: return 'نادر';
      case RewardRarity.epic: return 'ملحمي';
      case RewardRarity.legendary: return 'أسطوري';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(item.def.rarity);
    IconData icon = Icons.star_rounded;
    if (item.def.type == RewardType.badge) icon = Icons.military_tech_rounded;
    if (item.def.type == RewardType.frame) icon = Icons.crop_free_rounded;
    if (item.def.type == RewardType.theme) icon = Icons.format_paint_rounded;
    if (item.def.type == RewardType.artifact) icon = Icons.diamond_rounded;

    String dateStr = 'غير متوفر';
    if (item.discoveredAt != null) {
      final d = item.discoveredAt!;
      dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: rarityColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: rarityColor, size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                item.def.name,
                style: const TextStyle(color: _C.onCard, fontSize: 18, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _rarityName(item.def.rarity),
                  style: TextStyle(color: rarityColor, fontSize: 11, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.def.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.onCard, fontSize: 14, fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 20),
              const Divider(color: _C.muted, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تاريخ أول اكتشاف:', style: TextStyle(color: _C.muted, fontSize: 12, fontFamily: 'Tajawal')),
                  Text(dateStr, style: const TextStyle(color: _C.onCard, fontSize: 12, fontFamily: 'Tajawal')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('عدد مرات الحصول عليها:', style: TextStyle(color: _C.muted, fontSize: 12, fontFamily: 'Tajawal')),
                  Text(item.timesObtained.toString(), style: const TextStyle(color: _C.onCard, fontSize: 12, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: _C.gold, fontSize: 14, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── REWARDS LIST DIALOG ────────────────────────────────────────────────────
class _RewardsListDialog extends StatelessWidget {
  final List<RewardItem> rewards;

  const _RewardsListDialog({required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _C.gold.withValues(alpha: 0.3)),
        ),
        title: const Text(
          'مكافآت الصندوق',
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.goldLight, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rewards.map((r) {
            IconData icon = Icons.monetization_on_rounded;
            Color color = _C.gold;
            if (r.type == RewardType.badge) { icon = Icons.military_tech_rounded; color = _C.silver; }
            if (r.type == RewardType.frame) { icon = Icons.crop_free_rounded; color = _C.bronze; }
            if (r.type == RewardType.theme) { icon = Icons.format_paint_rounded; color = _C.legendary; }
            if (r.type == RewardType.artifact) { icon = Icons.diamond_rounded; color = Colors.cyan; }

            return ListTile(
              leading: Icon(icon, color: color, size: 32),
              title: Text(r.name, style: const TextStyle(color: _C.onCard, fontFamily: 'Tajawal')),
              trailing: r.amount > 1 ? Text('+${r.amount}', style: const TextStyle(color: _C.goldLight, fontWeight: FontWeight.bold)) : null,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('استلام', style: TextStyle(color: _C.gold, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
