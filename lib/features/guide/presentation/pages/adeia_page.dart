import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Adeia  –  الأدعية والأذكار  (Max-Level Premium UI)
// ─────────────────────────────────────────────────────────────────────────────

class Adeia extends StatefulWidget {
  const Adeia({super.key});

  @override
  State<Adeia> createState() => _AdeiaState();
}

class _AdeiaState extends State<Adeia> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entryCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  // ── Palette ──────────────────────────────────────────────────────────────────
  static const Color _bgDeep   = Color(0xff020A12);
  static const Color _bgMid    = Color(0xff071829);
  static const Color _gold     = Color(0xffC9A84C);
  static const Color _goldGlow = Color(0xffF5D882);
  static const Color _goldDark = Color(0xff8B6914);
  static const Color _textMain = Color(0xffEEE8D5);
  static const Color _textSub  = Color(0xff7A9AAD);

  int _selectedCategory = 0;

  // ── Categories ────────────────────────────────────────────────────────────────
  static const List<_Category> _categories = [
    _Category(label: "الكل",       icon: Icons.auto_awesome_rounded),
    _Category(label: "الصباح",     icon: Icons.wb_sunny_outlined),
    _Category(label: "المساء",     icon: Icons.nights_stay_outlined),
    _Category(label: "الصلاة",     icon: Icons.mosque_outlined),
    _Category(label: "السفر",      icon: Icons.flight_takeoff_rounded),
    _Category(label: "المنزل",     icon: Icons.home_outlined),
    _Category(label: "القرآن",     icon: Icons.menu_book_rounded),
    _Category(label: "الرزق",      icon: Icons.eco_outlined),
    _Category(label: "الكرب",      icon: Icons.favorite_border_rounded),
    _Category(label: "المناسبات",  icon: Icons.celebration_outlined),
  ];

  // ── Full duas database ────────────────────────────────────────────────────────
  static const List<_DuaData> _allDuas = [

    // ═══════════════════════════ أذكار الصباح ════════════════════════════════
    _DuaData(
      category: "الصباح",
      title: "سيد الاستغفار",
      dua:
      "اللَّهُمَّ أَنْتَ رَبِّي لا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.",
      fadl:
      "من قالها موقناً بها حين يُمسي فمات من ليلته دخل الجنة، وكذلك حين يُصبح.",
      source: "رواه البخاري",
      when: "يُقال صباحاً ومساءً",
      repeat: 1,
      icon: Icons.star_rounded,
      accentA: Color(0xff7A4800),
      accentB: Color(0xffF0A030),
      isFeatured: true,
    ),
    _DuaData(
      category: "الصباح",
      title: "دعاء الاستيقاظ",
      dua:
      "الحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.",
      fadl: "من قالها عند استيقاظه كان من الذاكرين الله.",
      source: "رواه البخاري",
      when: "عند الاستيقاظ من النوم",
      repeat: 1,
      icon: Icons.wb_sunny_outlined,
      accentA: Color(0xff7A4800),
      accentB: Color(0xffF0A030),
    ),
    _DuaData(
      category: "الصباح",
      title: "أذكار الصباح – التسبيح",
      dua:
      "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.",
      fadl:
      "من قالها مائة مرة حُطَّت خطاياه وإن كانت مثل زَبَد البحر.",
      source: "رواه البخاري ومسلم",
      when: "في الصباح",
      repeat: 100,
      icon: Icons.wb_sunny_outlined,
      accentA: Color(0xff7A4800),
      accentB: Color(0xffF0A030),
    ),
    _DuaData(
      category: "الصباح",
      title: "دعاء الصباح الجامع",
      dua:
      "اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ.",
      fadl: "من أذكار الصباح الثابتة عن النبي ﷺ.",
      source: "رواه أبو داود والترمذي",
      when: "في الصباح",
      repeat: 1,
      icon: Icons.wb_sunny_outlined,
      accentA: Color(0xff7A4800),
      accentB: Color(0xffF0A030),
    ),
    _DuaData(
      category: "الصباح",
      title: "الاستعاذة الصباحية",
      dua:
      "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
      fadl: "لم يضره شيء حتى يُمسي.",
      source: "رواه مسلم",
      when: "في الصباح",
      repeat: 3,
      icon: Icons.shield_outlined,
      accentA: Color(0xff7A4800),
      accentB: Color(0xffF0A030),
    ),

    // ═══════════════════════════ أذكار المساء ════════════════════════════════
    _DuaData(
      category: "المساء",
      title: "دعاء المساء الجامع",
      dua:
      "اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ.",
      fadl: "من أذكار المساء الثابتة عن النبي ﷺ.",
      source: "رواه أبو داود والترمذي",
      when: "في المساء",
      repeat: 1,
      icon: Icons.nights_stay_outlined,
      accentA: Color(0xff1A2560),
      accentB: Color(0xff6C82FF),
    ),
    _DuaData(
      category: "المساء",
      title: "دعاء النوم",
      dua: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.",
      fadl: "من أذكار النوم المحفوظة عن النبي ﷺ.",
      source: "رواه البخاري",
      when: "عند الأخذ مضجعاً للنوم",
      repeat: 1,
      icon: Icons.bedtime_outlined,
      accentA: Color(0xff1A2560),
      accentB: Color(0xff6C82FF),
    ),
    _DuaData(
      category: "المساء",
      title: "التسبيح عند النوم",
      dua:
      "سُبْحَانَ اللَّهِ، وَالحَمْدُ لِلَّهِ، وَاللَّهُ أَكْبَرُ.",
      fadl:
      "قال النبي ﷺ لعليٍّ وفاطمة: سبِّحا ثلاثاً وثلاثين وكبِّرا وأحمدا، خيرٌ لكما من خادم.",
      source: "رواه البخاري ومسلم",
      when: "عند النوم",
      repeat: 33,
      icon: Icons.bedtime_outlined,
      accentA: Color(0xff1A2560),
      accentB: Color(0xff6C82FF),
    ),
    _DuaData(
      category: "المساء",
      title: "آية الكرسي قبل النوم",
      dua:
      "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ.",
      fadl:
      "من قرأها حين يأخذ مضجعه لم يزل عليه من الله حافظ ولا يقربه شيطان حتى يُصبح.",
      source: "رواه البخاري",
      when: "قبل النوم",
      repeat: 1,
      icon: Icons.menu_book_rounded,
      accentA: Color(0xff1A2560),
      accentB: Color(0xff6C82FF),
      isFeatured: true,
    ),

    // ═══════════════════════════ أذكار الصلاة ════════════════════════════════
    _DuaData(
      category: "الصلاة",
      title: "دعاء الاستفتاح",
      dua:
      "اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنَ الْخَطَايَا كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْ خَطَايَايَ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ.",
      fadl: "يُقال في بداية الصلاة بعد تكبيرة الإحرام.",
      source: "رواه البخاري ومسلم",
      when: "بعد تكبيرة الإحرام",
      repeat: 1,
      icon: Icons.mosque_outlined,
      accentA: Color(0xff0D5C61),
      accentB: Color(0xff12C4A0),
    ),
    _DuaData(
      category: "الصلاة",
      title: "دعاء دخول المسجد",
      dua:
      "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ.",
      fadl: "من دخل المسجد بهذا الدعاء نال رحمة الله.",
      source: "رواه مسلم",
      when: "عند الدخول بالقدم اليمنى",
      repeat: 1,
      icon: Icons.mosque_outlined,
      accentA: Color(0xff0D5C61),
      accentB: Color(0xff12C4A0),
    ),
    _DuaData(
      category: "الصلاة",
      title: "دعاء الخروج من المسجد",
      dua:
      "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ.",
      fadl: "يُستحب قوله عند الخروج.",
      source: "رواه مسلم",
      when: "عند الخروج بالقدم اليسرى",
      repeat: 1,
      icon: Icons.exit_to_app_rounded,
      accentA: Color(0xff0D5C61),
      accentB: Color(0xff12C4A0),
    ),
    _DuaData(
      category: "الصلاة",
      title: "ذكر بعد الصلاة",
      dua:
      "أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.",
      fadl: "يُقال عقب كل صلاة مكتوبة.",
      source: "رواه مسلم",
      when: "بعد السلام من الصلاة",
      repeat: 3,
      icon: Icons.mosque_outlined,
      accentA: Color(0xff0D5C61),
      accentB: Color(0xff12C4A0),
    ),
    _DuaData(
      category: "الصلاة",
      title: "تسبيح بعد الصلاة",
      dua:
      "سُبْحَانَ اللَّهِ، الحَمْدُ لِلَّهِ، اللَّهُ أَكْبَرُ.",
      fadl:
      "من سبَّح دبر كل صلاة ثلاثاً وثلاثين وحمِد ثلاثاً وثلاثين وكبَّر ثلاثاً وثلاثين غُفرت ذنوبه.",
      source: "رواه مسلم",
      when: "دبر كل صلاة مكتوبة",
      repeat: 33,
      icon: Icons.mosque_outlined,
      accentA: Color(0xff0D5C61),
      accentB: Color(0xff12C4A0),
    ),

    // ═══════════════════════════ أدعية السفر ════════════════════════════════
    _DuaData(
      category: "السفر",
      title: "دعاء الركوب",
      dua:
      "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ.",
      fadl: "من ركب دابة أو وسيلة نقل وقال هذا الدعاء كان في أمان.",
      source: "رواه أبو داود والترمذي، وصححه الألباني",
      when: "عند الركوب في أي وسيلة نقل",
      repeat: 1,
      icon: Icons.flight_takeoff_rounded,
      accentA: Color(0xff2C3E8C),
      accentB: Color(0xff7B8FFF),
      isFeatured: true,
    ),
    _DuaData(
      category: "السفر",
      title: "دعاء الوداع",
      dua:
      "أَسْتَوْدِعُكَ اللَّهَ الَّذِي لَا تَضِيعُ وَدَائِعُهُ.",
      fadl: "يقوله المُودَّع لمن يودِّعه.",
      source: "رواه ابن ماجه",
      when: "عند توديع المسافر",
      repeat: 1,
      icon: Icons.waving_hand_outlined,
      accentA: Color(0xff2C3E8C),
      accentB: Color(0xff7B8FFF),
    ),
    _DuaData(
      category: "السفر",
      title: "دعاء العودة من السفر",
      dua:
      "آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ.",
      fadl: "كان النبي ﷺ يقوله عند رجوعه من كل سفر.",
      source: "رواه البخاري ومسلم",
      when: "عند العودة من السفر",
      repeat: 1,
      icon: Icons.home_rounded,
      accentA: Color(0xff2C3E8C),
      accentB: Color(0xff7B8FFF),
    ),

    // ═══════════════════════════ أدعية المنزل ════════════════════════════════
    _DuaData(
      category: "المنزل",
      title: "دعاء دخول المنزل",
      dua:
      "بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى رَبِّنَا تَوَكَّلْنَا.",
      fadl: "يقوله أهل البيت عند الدخول ليبارك الله لهم.",
      source: "رواه أبو داود",
      when: "عند الدخول إلى البيت",
      repeat: 1,
      icon: Icons.home_outlined,
      accentA: Color(0xff1A5C30),
      accentB: Color(0xff2ECC71),
    ),
    _DuaData(
      category: "المنزل",
      title: "دعاء الخروج من المنزل",
      dua:
      "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.",
      fadl:
      "يُقال له: كُفيتَ ووُقيتَ وتنحَّى عنه الشيطان.",
      source: "رواه أبو داود والترمذي",
      when: "عند الخروج من البيت",
      repeat: 1,
      icon: Icons.directions_walk_rounded,
      accentA: Color(0xff1A5C30),
      accentB: Color(0xff2ECC71),
    ),
    _DuaData(
      category: "المنزل",
      title: "دعاء دخول الخلاء",
      dua:
      "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ.",
      fadl: "ستر بينه وبين الجن.",
      source: "رواه البخاري ومسلم",
      when: "قبل دخول دورة المياه",
      repeat: 1,
      icon: Icons.bathroom_outlined,
      accentA: Color(0xff1A5C30),
      accentB: Color(0xff2ECC71),
    ),
    _DuaData(
      category: "المنزل",
      title: "دعاء الخروج من الخلاء",
      dua: "غُفْرَانَكَ.",
      fadl: "كان النبي ﷺ يقول هذا الدعاء عند الخروج.",
      source: "رواه أبو داود والترمذي",
      when: "عند الخروج من دورة المياه",
      repeat: 1,
      icon: Icons.bathroom_outlined,
      accentA: Color(0xff1A5C30),
      accentB: Color(0xff2ECC71),
    ),
    _DuaData(
      category: "المنزل",
      title: "دعاء الطعام",
      dua: "اللَّهُمَّ بَارِكْ لَنَا فِيهِ وَأَطْعِمْنَا خَيْرًا مِنْهُ.",
      fadl: "يُقال عند تناول الطعام والشراب.",
      source: "رواه الترمذي",
      when: "عند الأكل",
      repeat: 1,
      icon: Icons.restaurant_outlined,
      accentA: Color(0xff1A5C30),
      accentB: Color(0xff2ECC71),
    ),

    // ═══════════════════════════ أدعية القرآن ════════════════════════════════
    _DuaData(
      category: "القرآن",
      title: "دعاء قبل تلاوة القرآن",
      dua:
      "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ، بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ.",
      fadl: "أمر الله به عند قراءة القرآن في سورة النحل.",
      source: "سورة النحل: 98",
      when: "قبل الشروع في تلاوة القرآن",
      repeat: 1,
      icon: Icons.menu_book_rounded,
      accentA: Color(0xff4A0A6B),
      accentB: Color(0xffA855F7),
      isFeatured: true,
    ),
    _DuaData(
      category: "القرآن",
      title: "دعاء ختم القرآن",
      dua:
      "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ.",
      fadl: "يُقال عند الفراغ من قراءة القرآن.",
      source: "من آداب ختم القرآن",
      when: "عند الفراغ من التلاوة",
      repeat: 1,
      icon: Icons.menu_book_rounded,
      accentA: Color(0xff4A0A6B),
      accentB: Color(0xffA855F7),
    ),

    // ═══════════════════════════ أدعية الرزق ════════════════════════════════
    _DuaData(
      category: "الرزق",
      title: "دعاء الرزق الحلال",
      dua:
      "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ.",
      fadl: "دعاء جامع للاستغناء عن الحرام وطلب الرزق الحلال.",
      source: "رواه الترمذي",
      when: "يُقرأ صباحاً ومساءً",
      repeat: 1,
      icon: Icons.eco_outlined,
      accentA: Color(0xff6B3000),
      accentB: Color(0xffF0953A),
      isFeatured: true,
    ),
    _DuaData(
      category: "الرزق",
      title: "دعاء البركة في الرزق",
      dua:
      "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا.",
      fadl: "دعاء من أذكار الصباح الجامعة.",
      source: "رواه ابن ماجه",
      when: "في الصباح",
      repeat: 1,
      icon: Icons.eco_outlined,
      accentA: Color(0xff6B3000),
      accentB: Color(0xffF0953A),
    ),
    _DuaData(
      category: "الرزق",
      title: "الاستغفار لجلب الرزق",
      dua: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ.",
      fadl:
      "من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً ورزقه من حيث لا يحتسب.",
      source: "رواه أبو داود",
      when: "في كل وقت",
      repeat: 100,
      icon: Icons.eco_outlined,
      accentA: Color(0xff6B3000),
      accentB: Color(0xffF0953A),
    ),

    // ═══════════════════════════ أدعية الكرب ════════════════════════════════
    _DuaData(
      category: "الكرب",
      title: "دعاء الكرب العظيم",
      dua:
      "لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ.",
      fadl:
      "قال النبي ﷺ: دعاء ذي النون إذ دعا وهو في بطن الحوت، لم يدعُ به مسلم في شيء قط إلا استجاب الله له.",
      source: "رواه البخاري ومسلم",
      when: "عند الشدة والكرب",
      repeat: 1,
      icon: Icons.favorite_border_rounded,
      accentA: Color(0xff5C0A30),
      accentB: Color(0xffE8417A),
      isFeatured: true,
    ),
    _DuaData(
      category: "الكرب",
      title: "دعاء يونس عليه السلام",
      dua:
      "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ.",
      fadl:
      "ما دعا به مسلم في كربة إلا فرَّج الله عنه كربته.",
      source: "رواه الترمذي وصححه",
      when: "عند الضيق وطلب الفرج",
      repeat: 1,
      icon: Icons.favorite_border_rounded,
      accentA: Color(0xff5C0A30),
      accentB: Color(0xffE8417A),
    ),
    _DuaData(
      category: "الكرب",
      title: "دعاء التوبة والمغفرة",
      dua:
      "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ.",
      fadl:
      "كان النبي ﷺ يقولها في المجلس مائة مرة.",
      source: "رواه أبو داود والترمذي",
      when: "في كل وقت وخاصة بعد المعاصي",
      repeat: 100,
      icon: Icons.volunteer_activism_outlined,
      accentA: Color(0xff5C0A30),
      accentB: Color(0xffE8417A),
    ),
    _DuaData(
      category: "الكرب",
      title: "الحسبلة عند الهم",
      dua:
      "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.",
      fadl:
      "من قالها سبعاً كفاه الله ما أهمه.",
      source: "رواه أبو داود",
      when: "عند الهم والغم",
      repeat: 7,
      icon: Icons.favorite_border_rounded,
      accentA: Color(0xff5C0A30),
      accentB: Color(0xffE8417A),
    ),

    // ═══════════════════════════ أدعية المناسبات ════════════════════════════
    _DuaData(
      category: "المناسبات",
      title: "دعاء المريض",
      dua:
      "اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ، اشْفِهِ وَأَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا.",
      fadl: "كان النبي ﷺ يرقي بهذا الدعاء.",
      source: "رواه البخاري ومسلم",
      when: "عند زيارة المريض أو الرقية",
      repeat: 3,
      icon: Icons.healing_outlined,
      accentA: Color(0xff3D5A1A),
      accentB: Color(0xff8BC34A),
    ),
    _DuaData(
      category: "المناسبات",
      title: "دعاء الزواج والتهنئة",
      dua:
      "بَارَكَ اللَّهُ لَكَ وَبَارَكَ عَلَيْكَ وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ.",
      fadl: "دعاء النبي ﷺ لمن تزوج.",
      source: "رواه أبو داود والترمذي",
      when: "عند تهنئة المتزوجين",
      repeat: 1,
      icon: Icons.celebration_outlined,
      accentA: Color(0xff3D5A1A),
      accentB: Color(0xff8BC34A),
    ),
    _DuaData(
      category: "المناسبات",
      title: "دعاء رؤية المبتلى",
      dua:
      "الحَمْدُ لِلَّهِ الَّذِي عَافَانِي مِمَّا ابْتَلَاكَ بِهِ وَفَضَّلَنِي عَلَى كَثِيرٍ مِمَّنْ خَلَقَ تَفْضِيلًا.",
      fadl: "لم يُصَب بذلك البلاء كائناً ما كان.",
      source: "رواه الترمذي",
      when: "عند رؤية مبتلى بمرض أو بلاء",
      repeat: 1,
      icon: Icons.remove_red_eye_outlined,
      accentA: Color(0xff3D5A1A),
      accentB: Color(0xff8BC34A),
    ),
    _DuaData(
      category: "المناسبات",
      title: "دعاء المطر",
      dua:
      "اللَّهُمَّ صَيِّبًا نَافِعًا.",
      fadl: "كان النبي ﷺ يقوله إذا رأى المطر.",
      source: "رواه البخاري",
      when: "عند نزول المطر",
      repeat: 1,
      icon: Icons.water_drop_outlined,
      accentA: Color(0xff3D5A1A),
      accentB: Color(0xff8BC34A),
    ),
    _DuaData(
      category: "المناسبات",
      title: "دعاء الهلال الجديد",
      dua:
      "اللَّهُ أَكْبَرُ، اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْيُمْنِ وَالْإِيمَانِ وَالسَّلَامَةِ وَالْإِسْلَامِ، رَبِّي وَرَبُّكَ اللَّهُ.",
      fadl: "كان النبي ﷺ يقوله عند رؤية الهلال.",
      source: "رواه الترمذي",
      when: "عند رؤية هلال الشهر الجديد",
      repeat: 1,
      icon: Icons.nightlight_round_outlined,
      accentA: Color(0xff3D5A1A),
      accentB: Color(0xff8BC34A),
    ),
  ];

  List<_DuaData> get _filtered {
    if (_selectedCategory == 0) return _allDuas;
    final label = _categories[_selectedCategory].label;
    return _allDuas.where((d) => d.category == label).toList();
  }

  late final List<_StarDot> _stars;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final rng = Random(77);
    _stars = List.generate(45, (_) => _StarDot(
      x: rng.nextDouble(), y: rng.nextDouble(),
      r: 0.4 + rng.nextDouble() * 1.2,
      opacity: 0.06 + rng.nextDouble() * 0.22,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _bgCtrl.stop();
      _pulseCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgDeep,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Background
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.3 - _bgCtrl.value * 0.5, -0.4 + _bgCtrl.value * 0.3),
                      radius: 1.6,
                      colors: const [Color(0xff0A1F30), Color(0xff040E1A), _bgDeep],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _StaticStarPainter(_stars))),
            Positioned(top: -10, right: -30,
                child: _CrescentWidget(color: _gold.withValues(alpha: 0.06), bgColor: _bgDeep, size: 230)),
            Positioned(top: 120, left: -80,
                child: _GlowBlob(color: const Color(0xff0D5C61).withValues(alpha: 0.13), size: 300)),
            Positioned(bottom: 100, right: -70,
                child: _GlowBlob(color: const Color(0xffA855F7).withValues(alpha: 0.09), size: 250)),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _FadeSlide(animation: _entryCtrl, delay: 0.0,
                      child: _buildHeader(filtered.length)),
                  const SizedBox(height: 10),
                  // Category chips
                  _FadeSlide(animation: _entryCtrl, delay: 0.08,
                      child: _buildCategoryRow()),
                  const SizedBox(height: 14),
                  // List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _FadeSlide(
                          animation: _entryCtrl,
                          delay: (0.12 + i * 0.05).clamp(0.0, 0.88),
                          child: _DuaCard(dua: filtered[i]),
                        ),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
      leading: Directionality(
        textDirection: TextDirection.ltr,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [_goldDark, _gold, _goldGlow, _gold],
          stops: [0, 0.3, 0.6, 1],
        ).createShader(r),
        child: const Text(
          "الأدعية والأذكار",
          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [_goldDark.withValues(alpha: 0.22), _bgMid.withValues(alpha: 0.30)],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.24), width: 1),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_goldDark, _gold]),
                      boxShadow: [BoxShadow(
                        color: _gold.withValues(alpha: 0.25 + 0.2 * _pulseCtrl.value),
                        blurRadius: 14 + 8 * _pulseCtrl.value,
                      )],
                    ),
                    child: child,
                  ),
                  child: const Center(child: Text("🤲", style: TextStyle(fontSize: 21))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("أدعية مأثورة مباركة",
                          style: TextStyle(color: _textMain, fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text("$count دعاء • اضغط لعرض التفاصيل ونسخ الدعاء",
                          style: const TextStyle(color: _textSub, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: selected
                    ? const LinearGradient(colors: [_goldDark, _gold])
                    : null,
                color: selected ? null : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: selected ? _goldGlow.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: selected
                    ? [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 12)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: 13,
                      color: selected ? Colors.black87 : _textSub),
                  const SizedBox(width: 5),
                  Text(cat.label,
                      style: TextStyle(
                        color: selected ? Colors.black87 : _textSub,
                        fontSize: 12, fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DuaData
// ─────────────────────────────────────────────────────────────────────────────

class _DuaData {
  final String category;
  final String title;
  final String dua;
  final String fadl;
  final String source;
  final String when;
  final int repeat;
  final IconData icon;
  final Color accentA;
  final Color accentB;
  final bool isFeatured;

  const _DuaData({
    required this.category,
    required this.title,
    required this.dua,
    required this.fadl,
    required this.source,
    required this.when,
    required this.repeat,
    required this.icon,
    required this.accentA,
    required this.accentB,
    this.isFeatured = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DuaCard
// ─────────────────────────────────────────────────────────────────────────────

class _DuaCard extends StatefulWidget {
  final _DuaData dua;
  const _DuaCard({required this.dua});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _copied = false;

  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0, upperBound: 1,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.dua.dua));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _share() async {
    final d = widget.dua;
    final text = "📿 ${d.title}\n\n${d.dua}\n\n✦ الفضل: ${d.fadl}\n📚 ${d.source}";
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم نسخ الدعاء مع التفاصيل ✓",
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: const Color(0xff1A5C30),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) { _pressCtrl.reverse(); setState(() => _expanded = !_expanded); HapticFeedback.selectionClick(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: [
                    d.accentA.withValues(alpha: _expanded ? 0.32 : 0.18),
                    Colors.white.withValues(alpha: 0.03),
                    d.accentB.withValues(alpha: 0.07),
                  ],
                  stops: const [0, 0.5, 1],
                ),
                border: Border.all(
                  color: d.accentB.withValues(alpha: _expanded ? 0.42 : 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.accentA.withValues(alpha: _expanded ? 0.28 : 0.12),
                    blurRadius: _expanded ? 34 : 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shimmer top line
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [Colors.transparent, d.accentB.withValues(alpha: 0.65),
                          d.accentB.withValues(alpha: 0.90), d.accentB.withValues(alpha: 0.50), Colors.transparent],
                        stops: const [0, 0.2, 0.5, 0.8, 1],
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        // Icon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [d.accentA, d.accentB],
                                ),
                                boxShadow: [BoxShadow(
                                  color: d.accentB.withValues(alpha: 0.45),
                                  blurRadius: 16, offset: const Offset(0, 4),
                                )],
                              ),
                              child: Icon(d.icon, color: Colors.white, size: 22),
                            ),
                            // Featured star
                            if (d.isFeatured)
                              Positioned(
                                top: -3, left: -3,
                                child: Container(
                                  width: 18, height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [Color(0xff8B6914), Color(0xffF5D882)]),
                                  ),
                                  child: const Icon(Icons.star_rounded, color: Colors.black87, size: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: d.accentB.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(d.category,
                                        style: TextStyle(color: d.accentB, fontSize: 9.5, fontWeight: FontWeight.w700)),
                                  ),
                                  if (d.repeat > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text("× ${d.repeat}",
                                          style: const TextStyle(color: Color(0xff7A9AAD), fontSize: 9.5, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(d.title,
                                  style: const TextStyle(
                                      color: Color(0xffEEE8D5),
                                      fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.2)),
                              const SizedBox(height: 3),
                              Text(d.when,
                                  style: TextStyle(color: d.accentB.withValues(alpha: 0.70), fontSize: 10.5, height: 1.4)),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: d.accentB.withValues(alpha: 0.12),
                              border: Border.all(color: d.accentB.withValues(alpha: 0.25)),
                            ),
                            child: Icon(Icons.keyboard_arrow_down_rounded, color: d.accentB, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded body
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeOutCubic,
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, d.accentB.withValues(alpha: 0.28), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dua text in decorative frame
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(color: d.accentB.withValues(alpha: 0.18)),
                            ),
                            child: Column(
                              children: [
                                Text("بِسْمِ ٱللَّهِ",
                                    style: TextStyle(color: d.accentB.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Text(
                                  d.dua,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    color: Color(0xffEEE8D5),
                                    fontSize: 17,
                                    height: 2.1,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Details section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.auto_awesome_rounded,
                                label: "الفضل",
                                value: d.fadl,
                                accentB: d.accentB,
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.menu_book_rounded,
                                label: "المصدر",
                                value: d.source,
                                accentB: d.accentB,
                              ),
                              if (d.repeat > 1) ...[
                                const SizedBox(height: 8),
                                _DetailRow(
                                  icon: Icons.repeat_rounded,
                                  label: "التكرار",
                                  value: "${d.repeat} مرة",
                                  accentB: d.accentB,
                                ),
                              ],
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.schedule_rounded,
                                label: "الوقت",
                                value: d.when,
                                accentB: d.accentB,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              // Copy button
                              Expanded(
                                child: GestureDetector(
                                  onTap: _copy,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        colors: _copied
                                            ? [const Color(0xff1A5C30), const Color(0xff2ECC71)]
                                            : [d.accentA.withValues(alpha: 0.55), d.accentB.withValues(alpha: 0.40)],
                                      ),
                                      border: Border.all(
                                          color: _copied
                                              ? const Color(0xff2ECC71).withValues(alpha: 0.6)
                                              : d.accentB.withValues(alpha: 0.40)),
                                      boxShadow: _copied
                                          ? [BoxShadow(color: const Color(0xff2ECC71).withValues(alpha: 0.30), blurRadius: 16)]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                                            color: Colors.white, size: 15),
                                        const SizedBox(width: 7),
                                        Text(_copied ? "تم النسخ ✓" : "نسخ الدعاء",
                                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Share button
                              GestureDetector(
                                onTap: _share,
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.07),
                                    border: Border.all(color: d.accentB.withValues(alpha: 0.30)),
                                  ),
                                  child: Icon(Icons.ios_share_rounded, color: d.accentB, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DetailRow
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentB;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: accentB.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentB, size: 15),
          const SizedBox(width: 9),
          Container(
            width: 2, height: 15,
            decoration: BoxDecoration(
              color: accentB.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: [
                  TextSpan(text: "$label: ",
                      style: TextStyle(color: accentB, fontSize: 11, fontWeight: FontWeight.w700)),
                  TextSpan(text: value,
                      style: const TextStyle(color: Color(0xff9BBFCE), fontSize: 11.5, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _Category
// ─────────────────────────────────────────────────────────────────────────────

class _Category {
  final String label;
  final IconData icon;
  const _Category({required this.label, required this.icon});
}

// ─────────────────────────────────────────────────────────────────────────────
//  _FadeSlide
// ─────────────────────────────────────────────────────────────────────────────

class _FadeSlide extends StatefulWidget {
  final AnimationController animation;
  final double delay;
  final Widget child;
  const _FadeSlide({required this.animation, required this.delay, required this.child});

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide> {
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    final start = widget.delay.clamp(0.0, 0.88);
    final end   = (widget.delay + 0.36).clamp(0.0, 1.0);
    _curved = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers: GlowBlob, Crescent, Stars
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.7)],
    ),
  );
}

class _CrescentWidget extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final double size;
  const _CrescentWidget({required this.color, required this.bgColor, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _CrescentPainter(color, bgColor)),
  );
}

class _CrescentPainter extends CustomPainter {
  final Color color;
  final Color bgColor;
  const _CrescentPainter(this.color, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.width * 0.44;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(Offset(c.dx + r * 0.32, c.dy - r * 0.08), r * 0.80, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => old.color != color || old.bgColor != bgColor;
}

class _StarDot {
  final double x, y, r, opacity;
  const _StarDot({required this.x, required this.y, required this.r, required this.opacity});
}

class _StaticStarPainter extends CustomPainter {
  final List<_StarDot> stars;
  const _StaticStarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height),
          s.r, Paint()..color = Colors.white.withValues(alpha: s.opacity));
    }
  }

  @override
  bool shouldRepaint(_StaticStarPainter old) => false;
}