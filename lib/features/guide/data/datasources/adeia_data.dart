import 'package:flutter/material.dart';
import 'package:rafiki_app/features/guide/data/models/dua_model.dart';

const List<DuaCategory> duaCategories = [
    DuaCategory(label: "الكل",       icon: Icons.auto_awesome_rounded),
    DuaCategory(label: "الصباح",     icon: Icons.wb_sunny_outlined),
    DuaCategory(label: "المساء",     icon: Icons.nights_stay_outlined),
    DuaCategory(label: "الصلاة",     icon: Icons.mosque_outlined),
    DuaCategory(label: "السفر",      icon: Icons.flight_takeoff_rounded),
    DuaCategory(label: "المنزل",     icon: Icons.home_outlined),
    DuaCategory(label: "القرآن",     icon: Icons.menu_book_rounded),
    DuaCategory(label: "الرزق",      icon: Icons.eco_outlined),
    DuaCategory(label: "الكرب",      icon: Icons.favorite_border_rounded),
    DuaCategory(label: "المناسبات",  icon: Icons.celebration_outlined),
  ];

const List<DuaData> allDuas = [

    // ═══════════════════════════ أذكار الصباح ════════════════════════════════
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
    DuaData(
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
