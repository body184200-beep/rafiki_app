import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

typedef ProfilePage = Setting;

class _SettingState extends State<Setting> {
  String _userName = 'اسم المستخدم';
  String _gender = 'none'; // 'male', 'female', 'none'
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  String? _avatarBase64;

  int _azkarStreak = 0;
  int _prayerStreak = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    PrayerStreakEngine.instance.globalStreak.addListener(_onPrayerStreakChanged);
  }

  @override
  void dispose() {
    PrayerStreakEngine.instance.globalStreak.removeListener(_onPrayerStreakChanged);
    super.dispose();
  }

  void _onPrayerStreakChanged() async {
    final currentStreak = PrayerStreakEngine.instance.globalStreak.value;
    final prefs = await SharedPreferences.getInstance();
    final highest = prefs.getInt('highest_prayer_streak') ?? 0;
    if (currentStreak > highest) {
      await prefs.setInt('highest_prayer_streak', currentStreak);
      if (mounted) {
        setState(() {
          _prayerStreak = currentStreak;
        });
      }
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('username');
    final savedGender = prefs.getString('gender') ?? 'none';
    final savedNotifications = prefs.getBool('notifications_enabled') ?? true;
    final savedSounds = prefs.getBool('sounds_enabled') ?? true;
    final savedAvatar = prefs.getString('profile_avatar_base64');

    // ── 1. Prayer Streak (يبدأ من 0 ويزيد مع جدول الصلاة، ويثبت عند أعلى سكور) ──
    final currentPrayerStreak = PrayerStreakEngine.instance.globalStreak.value;
    int highestPrayerStreak = prefs.getInt('highest_prayer_streak') ?? 0;
    if (currentPrayerStreak > highestPrayerStreak) {
      highestPrayerStreak = currentPrayerStreak;
      await prefs.setInt('highest_prayer_streak', highestPrayerStreak);
    }
    final displayPrayerStreak = highestPrayerStreak;

    // ── 2. Azkar Streak (يبدأ من 0 ويزيد مع الأذكار، ويثبت عند أعلى سكور) ──────
    final azkarTotal = prefs.getInt('totalScore') ?? prefs.getInt('score') ?? 0;
    final azkarDaily = prefs.getInt('dailyScore') ?? 0;
    final currentAzkar = azkarTotal > 0 ? azkarTotal : azkarDaily;
    int highestAzkarStreak = prefs.getInt('highest_azkar_streak') ?? 0;
    if (currentAzkar > highestAzkarStreak) {
      highestAzkarStreak = currentAzkar;
      await prefs.setInt('highest_azkar_streak', highestAzkarStreak);
    }
    final displayAzkarStreak = highestAzkarStreak;

    // ── 3. Total Tasbihat (إجمالي التسبيحات في السبحة) ──────────────────────────
    int totalTasbihat = prefs.getInt('total_tasbihat_count') ?? 0;
    if (totalTasbihat == 0) {
      final raw = prefs.getString('deeds_adhkar_list');
      if (raw != null) {
        try {
          final List list = jsonDecode(raw);
          totalTasbihat = list.fold<int>(0, (sum, item) => sum + ((item['count'] as int?) ?? 0));
        } catch (_) {}
      }
    }
    final displayTotal = totalTasbihat;

    if (mounted) {
      setState(() {
        if (savedName != null && savedName.trim().isNotEmpty && savedName.trim() != 'عبد الرحمن أشرف') {
          _userName = savedName.trim();
        } else {
          _userName = 'اسم المستخدم';
        }
        _gender = savedGender;
        _notificationsEnabled = savedNotifications;
        _soundsEnabled = savedSounds;
        _avatarBase64 = savedAvatar;
        _prayerStreak = displayPrayerStreak;
        _azkarStreak = displayAzkarStreak;
        _totalPoints = displayTotal;
      });
    }
  }

  Future<void> _updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', trimmed);
    if (mounted) {
      setState(() => _userName = trimmed);
    }
  }

  Future<void> _updateGender(String g) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', g);
    if (mounted) {
      setState(() => _gender = g);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_avatar_base64', base64Str);
      if (mounted) {
        setState(() => _avatarBase64 = base64Str);
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  Future<void> _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_avatar_base64');
    if (mounted) {
      setState(() => _avatarBase64 = null);
    }
  }

  void _showAvatarOptionsSheet() {
    final isLight = ThemeProvider.instance.isLight;
    final sheetBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728);
    final sheetText = isLight ? const Color(0xFF111827) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45),
            width: 0.8,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFD1D5DB) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'تغيير الصورة الشخصية',
                style: TextStyle(
                  color: sheetText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3CD2A2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F4A39)),
                ),
                title: Text('اختيار من المعرض', style: TextStyle(color: sheetText, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D6E94)),
                ),
                title: Text('التقاط بالكاميرا', style: TextStyle(color: sheetText, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              if (_avatarBase64 != null) ...[
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  title: const Text('حذف الصورة الحالية', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final isLight = ThemeProvider.instance.isLight;
    final nameCtrl = TextEditingController(text: _userName);
    String selectedG = _gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45),
              width: 0.8,
            ),
          ),
          title: Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              color: isLight ? const Color(0xFF111827) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.right,
                style: TextStyle(color: isLight ? const Color(0xFF111827) : Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل اسمك...',
                  hintStyle: TextStyle(color: isLight ? const Color(0xFF9CA3AF) : const Color(0xFF6B87A8)),
                  filled: true,
                  fillColor: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF162035),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اللقب المفضل:',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isLight ? const Color(0xFF4B5563) : const Color(0xFF8DA3C4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDlgState(() => selectedG = 'male'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedG == 'male'
                              ? (isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2))
                              : (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF162035)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedG == 'male'
                                ? (isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2))
                                : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'أخي في الله',
                            style: TextStyle(
                              color: selectedG == 'male'
                                  ? (isLight ? Colors.white : const Color(0xFF070A12))
                                  : (isLight ? const Color(0xFF374151) : Colors.white),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDlgState(() => selectedG = 'female'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedG == 'female'
                              ? (isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2))
                              : (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF162035)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedG == 'female'
                                ? (isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2))
                                : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'أختي في الله',
                            style: TextStyle(
                              color: selectedG == 'female'
                                  ? (isLight ? Colors.white : const Color(0xFF070A12))
                                  : (isLight ? const Color(0xFF374151) : Colors.white),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(color: isLight ? const Color(0xFF6B7280) : const Color(0xFF8DA3C4)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _updateName(nameCtrl.text);
                _updateGender(selectedG);
              },
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final firstLetter = _userName.trim().isNotEmpty ? _userName.trim()[0].toUpperCase() : 'A';

        final bgColor = isLight ? const Color(0xFFF8F6F0) : const Color(0xFF080C16);
        final headerTextColor = isLight ? const Color(0xFF111827) : Colors.white;
        final backBtnBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728);
        final backBtnBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45);
        final backBtnIcon = isLight ? const Color(0xFF111827) : const Color(0xFF8DA3C4);

        final avatarBorderColor = isLight ? const Color(0xFFD4A853) : const Color(0xFF3CD2A2);
        final avatarBgColor = isLight ? const Color(0xFF0B4633) : const Color(0xFF0A141A);
        final avatarLetterColor = isLight ? const Color(0xFFF6E0A4) : const Color(0xFF3CD2A2);
        final cameraBadgeBg = isLight ? const Color(0xFF00796B) : const Color(0xFF3CD2A2);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Top Header ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 44), // balance back button
                      Text(
                        'الملف الشخصي',
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: backBtnBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: backBtnBorder, width: 0.8),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: backBtnIcon,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Avatar Circle & Camera Badge ──────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _showAvatarOptionsSheet,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: avatarBgColor,
                              border: Border.all(
                                color: avatarBorderColor,
                                width: isLight ? 3.0 : 2.2,
                              ),
                            ),
                            child: ClipOval(
                              child: _avatarBase64 != null
                                  ? Image.memory(
                                      base64Decode(_avatarBase64!),
                                      width: 106,
                                      height: 106,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          firstLetter,
                                          style: TextStyle(
                                            color: avatarLetterColor,
                                            fontSize: 44,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        firstLetter,
                                        style: TextStyle(
                                          color: avatarLetterColor,
                                          fontSize: 44,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cameraBadgeBg,
                                border: isLight ? Border.all(color: Colors.white, width: 1.5) : null,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── User Name ────────────────────────────────────────────────
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          color: isLight ? const Color(0xFF6B7280) : const Color(0xFF6B87A8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── 2x2 Stats Cards Grid ─────────────────────────────────────
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 1. Azkar Streak (Top-Right in RTL)
                      _statCard(
                        title: 'ستريك أذكار',
                        value: '$_azkarStreak',
                        unit: 'نقطة',
                        bgColor: isLight ? const Color(0xFFE8F5E9) : const Color(0xFF0C1A16),
                        borderColor: isLight ? const Color(0xFFC8E6C9) : const Color(0xFF184537),
                        valColor: isLight ? const Color(0xFF0D652D) : const Color(0xFF3CD2A2),
                        titleColor: isLight ? const Color(0xFF1B5E20) : const Color(0xFF86EFAC),
                      ),

                      // 2. Prayer Streak (Top-Left in RTL)
                      _statCard(
                        title: 'ستريك الصلاة',
                        value: '$_prayerStreak',
                        unit: 'نقطة',
                        bgColor: isLight ? const Color(0xFFE1F0F9) : const Color(0xFF0C1826),
                        borderColor: isLight ? const Color(0xFFBBDEFB) : const Color(0xFF17375A),
                        valColor: isLight ? const Color(0xFF0B638A) : const Color(0xFF38BDF8),
                        titleColor: isLight ? const Color(0xFF0D47A1) : const Color(0xFF93C5FD),
                      ),

                      // 3. Theme Toggle Card (Bottom-Right in RTL - مكان الإنجازات)
                      _themeToggleCard(isLight),

                      // 4. Total Tasbihat (Bottom-Left in RTL - إجمالي التسبيحات في السبحة)
                      _statCard(
                        title: 'إجمالي التسبيحات',
                        value: '$_totalPoints',
                        unit: 'تسبيحة',
                        bgColor: isLight ? const Color(0xFFEDE7F6) : const Color(0xFF171229),
                        borderColor: isLight ? const Color(0xFFD1C4E9) : const Color(0xFF35245C),
                        valColor: isLight ? const Color(0xFF5E35B1) : const Color(0xFFA78BFA),
                        titleColor: isLight ? const Color(0xFF4A148C) : const Color(0xFFC084FC),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Settings Section ─────────────────────────────────────────
                  _buildSettingsList(isLight),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String unit,
    required Color bgColor,
    required Color borderColor,
    required Color valColor,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                unit,
                style: TextStyle(
                  color: valColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: valColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  /// Theme switcher button placed in the 4th grid slot (previously achievements).
  /// Matching Image 1 with warm pastel sand/peach styling & gold star icon.
  Widget _themeToggleCard(bool isLight) {
    final bgColor = isLight ? const Color(0xFFFDF0D5) : const Color(0xFF261D0C);
    final borderColor = isLight ? const Color(0xFFF6DEAF) : const Color(0xFF503C15);
    final titleColor = isLight ? const Color(0xFF8D5B18) : const Color(0xFFFBBF24);
    final iconColor = isLight ? const Color(0xFFD4A843) : const Color(0xFFFBBF24);
    final title = isLight ? 'المظهر النهاري' : 'المظهر الليلي';
    final actionHint = isLight ? 'انقر لليلي' : 'انقر للنهاري';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ThemeProvider.instance.toggleTheme();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isLight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: iconColor,
                  size: 26,
                ),
                Row(
                  children: [
                    Text(
                      actionHint,
                      style: TextStyle(
                        color: titleColor.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      color: iconColor,
                      size: 28,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(bool isLight) {
    final headerColor = isLight ? const Color(0xFF4B5563) : const Color(0xFF8DA3C4);
    final tileBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728);
    final tileBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45);
    final titleColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF8DA3C4);
    final iconBoxBg = isLight ? const Color(0xFFE8F5E9) : const Color(0xFF162238);
    final iconBoxColor = isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2);
    final switchActiveColor = isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2);
    final chevronColor = isLight ? const Color(0xFF9CA3AF) : const Color(0xFF8DA3C4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'الإعدادات العامة',
            style: TextStyle(
              color: headerColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Notifications Toggle
        _settingsTile(
          tileBg: tileBg,
          tileBorder: tileBorder,
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          iconBoxBg: iconBoxBg,
          iconBoxColor: iconBoxColor,
          icon: Icons.notifications_active_outlined,
          title: 'تنبيهات الأذان والصلوات',
          subtitle: 'تذكير حي بالوقت المتبقي لكل صلاة',
          trailing: Switch(
            value: _notificationsEnabled,
            activeColor: switchActiveColor,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', val);
              setState(() => _notificationsEnabled = val);
            },
          ),
        ),

        const SizedBox(height: 10),

        // Sound Effects Toggle
        _settingsTile(
          tileBg: tileBg,
          tileBorder: tileBorder,
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          iconBoxBg: iconBoxBg,
          iconBoxColor: iconBoxColor,
          icon: Icons.volume_up_outlined,
          title: 'المؤثرات الصوتية',
          subtitle: 'أصوات التنبيه ونقر السبحة',
          trailing: Switch(
            value: _soundsEnabled,
            activeColor: switchActiveColor,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('sounds_enabled', val);
              setState(() => _soundsEnabled = val);
            },
          ),
        ),

        const SizedBox(height: 10),

        // Edit Profile / Gender Tile
        _settingsTile(
          tileBg: tileBg,
          tileBorder: tileBorder,
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          iconBoxBg: iconBoxBg,
          iconBoxColor: iconBoxColor,
          icon: Icons.person_outline_rounded,
          title: 'تعديل البيانات واللقب',
          subtitle: _gender == 'female' ? 'اللقب: أختي في الله' : (_gender == 'male' ? 'اللقب: أخي في الله' : 'انقر لتحديد اللقب'),
          trailing: Icon(Icons.chevron_left_rounded, color: chevronColor),
          onTap: _showEditProfileDialog,
        ),

        const SizedBox(height: 10),

        // Change Profile Picture Tile
        _settingsTile(
          tileBg: tileBg,
          tileBorder: tileBorder,
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          iconBoxBg: iconBoxBg,
          iconBoxColor: iconBoxColor,
          icon: Icons.add_a_photo_outlined,
          title: 'الصورة الشخصية',
          subtitle: _avatarBase64 != null ? 'تم تعيين صورة شخصية (انقر للتغيير)' : 'انقر لتعيين صورة شخصية',
          trailing: Icon(Icons.chevron_left_rounded, color: chevronColor),
          onTap: _showAvatarOptionsSheet,
        ),
      ],
    );
  }

  Widget _settingsTile({
    required Color tileBg,
    required Color tileBorder,
    required Color titleColor,
    required Color subtitleColor,
    required Color iconBoxBg,
    required Color iconBoxColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tileBorder, width: 0.8),
        ),
        child: Row(
          children: [
            trailing,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconBoxColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
