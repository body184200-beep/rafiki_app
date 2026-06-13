import 'dart:math';
import 'package:flutter/material.dart';

class Anbiaa extends StatefulWidget {
  const Anbiaa({super.key});

  @override
  State<Anbiaa> createState() => _AnbiaaState();
}

class _AnbiaaState extends State<Anbiaa> with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  // ألوان الثيم
  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);
  static const Color kGoldDim = Color(0xFF8a6f30);
  static const Color kInk = Color(0xFF0e0c18);
  static const Color kInkMid = Color(0xFF1a1628);
  static const Color kInkSoft = Color(0xFF241f38);
  static const Color kParchment = Color(0xFFf5edd6);
  static const Color kParchmentDim = Color(0xFFe8d9b5);

  final List<Map<String, String>> prophets = [
    {
      "name": "آدم عليه السلام",
      "icon": "🌍",
      "story": """🌍 1. الإعلان الإلهي وقلق الملائكة
قبل خلق آدم، أعلن الله تعالى للملائكة عن مخلوق جديد: ﴿إِنِّي جَاعِلٌ فِي الْأَرْضِ خَلِيفَةً﴾
فقالت الملائكة: ﴿أَتَجْعَلُ فِيهَا مَن يُفْسِدُ فِيهَا وَيَسْفِكُ الدِّمَاءَ﴾
فجاء الرد القاطع: ﴿إِنِّي أَعْلَمُ مَا لَا تَعْلَمُونَ﴾

🧱 2. مراحل الخلق
مرّ خلق آدم بخمس مراحل: التراب، الطين اللازب، الحمأ المسنون، الصلصال كالفخار، ثم نفخ الروح.
بقي جسدًا طينيًا أربعين عامًا، وكان إبليس يطوف به يتحسسه.

💫 3. بثّ الروح وأولى الكلمات
حين بدأت الروح تسري في جسد آدم عطس، فألهمه الله: "الحمد لله"
فقال الله: "رحمك ربك يا آدم".
ثم علّمه الله أسماء كل شيء وفضّله بالعلم على الملائكة.

👑 4. السجود وكبر إبليس
أمر الله الملائكة وإبليس بالسجود لآدم. فسجدت الملائكة فورًا.
لكن إبليس تكبر: ﴿أَنَا خَيْرٌ مِّنْهُ خَلَقْتَنِي مِن نَّارٍ وَخَلَقْتَهُ مِن طِينٍ﴾
فطرده الله من رحمته.

🌿 5. الجنة وحيلة إبليس
وسوس لهما إبليس حتى أكلا من الشجرة المنهي عنها.
فتابا: ﴿رَبَّنَا ظَلَمْنَا أَنفُسَنَا﴾ فقبل الله توبتهما وأهبطهما إلى الأرض.

⚔️ 6. قابيل وهابيل وأول جريمة
قتل قابيل أخاه هابيل فكانت أول جريمة قتل. تعلّم الدفن من الغراب وندم شديدًا.

☁️ 7. الوفاة والجنازة الأولى
غسّلته الملائكة وكفّنته وصلّت عليه ودفنته — أول وفاة وأول جنازة في تاريخ البشر."""
    },
    {
      "name": "إدريس عليه السلام",
      "icon": "✍️",
      "story": """📜 1. نسبه وألقابه
هو إدريس بن يارد، وينتهي نسبه إلى شيث بن آدم.
سُمّي "إدريس" من "الدراسة" لكثرة اشتغاله بالعلم.

🌍 2. الرسالة والهجرة
بعد وفاة شيث ظهر الفساد، فآتاه الله النبوة وأنزل عليه ثلاثين صحيفة.
هاجر إلى مصر ورأى النيل فقال: "منف" أي الأرض الممتعة.

✨ 3. أولوياته الحضارية
• أول من خطّ بالقلم ودوّن العلوم
• أول من خاط الثياب من الصوف والقطن
• أول من نظّم القتال في سبيل الله
• علّمه الله أسرار النجوم والحساب
• بنى أتباعه أكثر من مائة مدينة

☁️ 4. الرفع إلى السماء الرابعة
﴿وَرَفَعْنَاهُ مَكَانًا عَلِيًّا﴾
رفعه ملاك بين جناحيه، وفي السماء الرابعة قُبضت روحه.

🤝 5. شهادة النبي ﷺ
في ليلة الإسراء والمعراج وجد النبيُّ ﷺ إدريسَ في السماء الرابعة.
فقال إدريس: "مرحبًا بالأخ الصالح والنبي الصالح"."""
    },
    {
      "name": "نوح عليه السلام",
      "icon": "🌊",
      "story": """🌊 1. بداية الشرك
بعد موت خمسة رجال صالحين صنع الناس لهم تماثيل بوسوسة الشيطان فعبدوها — أول شرك في تاريخ البشرية.

⚔️ 2. الدعوة والصبر (٩٥٠ سنة)
لبث نوح في قومه ألف سنة إلا خمسين عامًا. دعاهم ليلًا ونهارًا سرًا وعلانية.
كانوا يضعون أصابعهم في آذانهم ولم يؤمن معه إلا عدد قليل.

🚢 3. بناء السفينة في الصحراء
أمر الله نوحًا ببناء السفينة في صحراء لا ماء فيها.
سخر منه قومه: "أصبحت نجارًا بعد أن كنت نبيًا؟!"

🌧️ 4. الطوفان العظيم
فتح الله السماء وفجّر الأرض عيونًا حتى غطى الماء الجبال.
غرق الابن العاصي والزوجة الكافرة مع القوم.

🏔️ 5. نهاية الطوفان
﴿يَا أَرْضُ ابْلَعِي مَاءَكِ وَيَا سَمَاءُ أَقْلِعِي﴾
ورست السفينة على جبل الجودي.
نسل نوح (سام، حام، يافث) هم أصل البشرية الثانية."""
    },
    {
      "name": "هود عليه السلام",
      "icon": "🏛️",
      "story": """🌍 1. قوم عاد وقوتهم
عاشوا في الأحقاف — عمالقة شداد بنوا القصور وقالوا: ﴿مَنْ أَشَدُّ مِنَّا قُوَّةً﴾
﴿إِرَمَ ذَاتِ الْعِمَادِ * الَّتِي لَمْ يُخْلَقْ مِثْلُهَا فِي الْبِلَادِ﴾

🪨 2. دعوة هود وعناد القوم
قالوا: ﴿إِنَّا لَنَرَاكَ فِي سَفَاهَةٍ﴾
فرد: ﴿يَا قَوْمِ لَيْسَ بِي سَفَاهَةٌ وَلَٰكِنِّي رَسُولٌ مِّن رَّبِّ الْعَالَمِينَ﴾

🌵 3. القحط والوفد
ثلاث سنوات قحط. أرسلوا وفدًا للاستسقاء فاختاروا السحابة السوداء ظنًا أنها الخير.

🌪️ 4. الريح العقيم
﴿رِيحٌ فِيهَا عَذَابٌ أَلِيمٌ﴾
سبع ليالٍ وثمانية أيام. تقتلع العمالقة كجذوع نخل خاوية.
نجا هود والمؤمنون وهاجر إلى حضرموت."""
    },
    {
      "name": "صالح عليه السلام",
      "icon": "🐪",
      "story": """🌍 1. قوم ثمود والحضارة الصخرية
عاشوا في الحجر ينحتون من الجبال بيوتًا.
﴿وَتَنْحِتُونَ مِنَ الْجِبَالِ بُيُوتًا فَارِهِينَ﴾

🐪 2. ناقة الله آية ومعجزة
خرجت الناقة من صخرة صمّاء معجزة من الله.
حذّرهم صالح: ﴿هَٰذِهِ نَاقَةُ اللَّهِ لَكُمْ آيَةً﴾

⚔️ 3. عقر الناقة
تجرأ أشقياء القوم فعقروا الناقة.
فأنذرهم: "تمتعوا ثلاثة أيام ثم يأتيكم العذاب."

🌩️ 4. الصيحة والهلاك
في اليوم الرابع جاءتهم صيحة رهيبة فأهلكتهم.
نجا صالح والمؤمنون معه ورحلوا إلى فلسطين."""
    },
    {
      "name": "إبراهيم عليه السلام",
      "icon": "🔥",
      "story": """🌍 1. النشأة في بيت الأصنام
وُلد في بابل في عهد الطاغية النمرود. أبوه آزر كان نحات الأصنام الرسمي.

🧠 2. يقظة الفطرة
ناظر عبّاد الكواكب بعقله قبل الوحي:
﴿لَا أُحِبُّ الْآفِلِينَ﴾ ← ﴿إِنِّي وَجَّهْتُ وَجْهِيَ لِلَّذِي فَطَرَ السَّمَاوَاتِ وَالْأَرْضَ حَنِيفًا﴾

🪓 3. تحطيم الأصنام
حطّم الأصنام بالفأس وترك الكبير. قال للمُستجوبين:
﴿بَلْ فَعَلَهُ كَبِيرُهُمْ هَٰذَا فَاسْأَلُوهُمْ إِن كَانُوا يَنطِقُونَ﴾

🔥 4. النار كانت بردًا وسلامًا
قال في الهواء: "حسبي الله ونعم الوكيل."
﴿يَا نَارُ كُونِي بَرْدًا وَسَلَامًا عَلَىٰ إِبْرَاهِيمَ﴾

💧 5. زمزم والذبح والكعبة
معجزة زمزم في مكة القاحلة.
الذبح العظيم: ﴿وَفَدَيْنَاهُ بِذِبْحٍ عَظِيمٍ﴾
ثم بنى الكعبة مع إسماعيل: ﴿رَبَّنَا تَقَبَّلْ مِنَّا﴾"""
    },
    {
      "name": "لوط عليه السلام",
      "icon": "🏙️",
      "story": """🧬 1. النسب والهجرة
ابن أخ إبراهيم. آمن به وهاجر معه إلى الشام.
ثم استقر في سدوم بغور الأردن.

⚠️ 2. فساد قوم لوط
﴿أَتَأْتُونَ الْفَاحِشَةَ مَا سَبَقَكُم بِهَا مِنْ أَحَدٍ مِّنَ الْعَالَمِينَ﴾
ردّوا دعوته بالسخرية والتهديد والطرد.

👼 3. الملائكة والحصار
جاءت الملائكة في هيئة شباب حسان. زوجته الخائنة أخبرت القوم فحاصروا البيت.

⚡ 4. إعمى القوم والنجاة
ضرب جبريل وجوههم فعموا فورًا.
أُمر لوط بالخروج ليلًا. التفتت زوجته فهلكت.

🌋 5. الخسف والتدمير
رفع جبريل المدن وقلبها. ثم أمطار حجارة سجيل.
تحوّلت ديارهم إلى البحر الميت الذي لا يعيش فيه كائن حتى اليوم."""
    },
    {
      "name": "إسماعيل عليه السلام",
      "icon": "🕋",
      "story": """🌿 1. الميلاد والبشارة
ولد لإبراهيم وهاجر بعد سنين من انتظار الذرية.
﴿فَبَشَّرْنَاهُ بِغُلَامٍ حَلِيمٍ﴾

💧 2. معجزة زمزم
تركهما إبراهيم في وادٍ قاحل بمكة. سعت هاجر بين الصفا والمروة سبعة أشواط.
انبجس ماء زمزم فسكنت قبيلة جرهم حوله.
نشأ إسماعيل بينهم وتعلّم العربية الفصحى.

🔪 3. الذبح العظيم
رأى إبراهيم في المنام ذبح ابنه.
فقال إسماعيل: ﴿يَا أَبَتِ افْعَلْ مَا تُؤْمَرُ﴾
فدى الله إسماعيل بكبشٍ من الجنة — أصل عيد الأضحى.

🕋 4. بناء الكعبة
إسماعيل ينقل الحجارة وإبراهيم يبني يقولان: ﴿رَبَّنَا تَقَبَّلْ مِنَّا﴾
من نسله جاء النبي محمد ﷺ.
توفي بمكة عن 137 عامًا ودُفن في حِجر إسماعيل."""
    },
    {
      "name": "إسحاق عليه السلام",
      "icon": "⭐",
      "story": """😲 1. البشارة المعجزة
بشّرت الملائكة سارة بإسحاق وهي عجوز تسعينية عاقرة.
قالت بدهشة: "أألد وأنا عجوز؟!" — ﴿أَتَعْجَبِينَ مِنْ أَمْرِ اللَّهِ﴾

👶 2. الولادة والنشأة
وُلد وإبراهيم في المئة من عمره.
﴿وَبَشَّرُوهُ بِغُلَامٍ عَلِيمٍ﴾
نشأ في بيت النبوة وتعلّم التوحيد والحكمة.

👶👶 3. التوأم التاريخي
تزوج من رِفقة ودعا الله فرزقه توأمًا:
- العيص: من نسله شعوب الروم
- يعقوب (إسرائيل): أصل بني إسرائيل وخط الأنبياء الكبار

⚰️ 4. الوفاة
عاش 180 سنة وتوفي في الخليل بفلسطين.
دُفن في مغارة المكفيلة بجوار إبراهيم وسارة."""
    },
    {
      "name": "يعقوب عليه السلام",
      "icon": "🌙",
      "story": """👶 1. الميلاد واللقب
وُلد توأمًا مع العيص خارجًا ممسكًا بعقب أخيه — فسُمي "يعقوب".
لقبه الآخر "إسرائيل" أي صفوة الله.

💍 2. سنوات حرّان والزوجات
خدم خاله لابان أربعة عشر عامًا للزواج من ليئة وراحيل مع جاريتيهما.
أنجب اثني عشر ولدًا هم أصل بني إسرائيل.

🌑 3. المحنة الكبرى: فراق يوسف
ألقى الإخوة يوسف في البئر وأتوا أباهم بقميصه الملطخ بالدم.
قال يعقوب: ﴿فَصَبْرٌ جَمِيلٌ﴾ وبكى سنوات حتى ابيضّت عيناه.

👕 4. معجزة القميص والفرج
شمّ ريح يوسف من بعيد. ووُضع قميصه على وجهه فعاد بصيرًا فورًا.
دخل مصر مع 72 شخصًا واستقبله يوسف ملكًا.
عاش 147 سنة ودُفن في الخليل."""
    },
    {
      "name": "يوسف عليه السلام",
      "icon": "👑",
      "story": """🌌 1. الرؤيا الكونية
رأى وهو طفل أحد عشر كوكبًا والشمس والقمر يسجدون له.
حذّره أبوه: ﴿يَا بُنَيَّ لَا تَقْصُصْ رُؤْيَاكَ عَلَىٰ إِخْوَتِكَ﴾

😡 2. مؤامرة الإخوة
ألقوه في البئر وباعوه بثمن بخس. وأتوا أباهم بقميصه الملطخ بدم كذب.

🏛️ 3. الفتنة والسجن
راودته امرأة العزيز فأبى: ﴿مَعَاذَ اللَّهِ﴾
فسجن مظلومًا. فسّر رؤيا الساقي والخباز وكلاهما تحقق.

👑 4. تفسير رؤيا الملك
سبع بقرات سمان وسبع عجاف — سبع سنين خير ثم سبع مجاعة.
فجعله الملك على خزائن مصر.

💔 5. اللقاء الكبير
جاء إخوته لشراء الطعام فعرفهم. فكشف عن هويته:
﴿أَنَا يُوسُفُ وَهَٰذَا أَخِي﴾ وعفا: ﴿لَا تَثْرِيبَ عَلَيْكُمُ الْيَوْمَ﴾

🌟 6. أحسن القصص
تحقق تأويل الرؤيا بعد عشرين عامًا.
سمّاها الله: ﴿أَحْسَنَ الْقَصَصِ﴾"""
    },
    {
      "name": "شعيب عليه السلام",
      "icon": "⚖️",
      "story": """🕋 1. النسب وأرض مدين
من ذرية إبراهيم. بُعث في مدين مدينة تجارية كبرى.
لُقّب بـ"خطيب الأنبياء" لبلاغته.

💰 2. فساد قوم مدين
عبدوا شجرة الأيكة. والأخطر: الغش الاقتصادي المنظّم.
ينقصون الكيل والميزان ويأخذون أموال الناس بالباطل.

📢 3. الدعوة الاقتصادية
﴿أَوْفُوا الْكَيْلَ وَالْمِيزَانَ وَلَا تَبْخَسُوا النَّاسَ أَشْيَاءَهُمْ﴾
"الربح الحلال القليل خير من الأموال الحرام الكثيرة."

🐑 4. لقاء موسى
استقبل موسى الهارب من مصر. زوّجه ابنته مقابل ثماني سنوات رعي.

⚡ 5. عذاب يوم الظُلّة
سبعة أيام حرٍّ قاتل. ظهرت سحابة فاجتمعوا تحتها ظنًا أنها رحمة.
فأمطرت نارًا وجاءت صيحة وزلزال فهلكوا."""
    },
    {
      "name": "أيوب عليه السلام",
      "icon": "🌿",
      "story": """🏡 1. النعمة الكاملة
من نسل إبراهيم. عاش في حوران بالشام بأموال وأبناء وصحة.
كان رحيمًا بالفقراء شاكرًا لله في كل حال.

⚡ 2. الابتلاء الثلاثي
جفّت أراضيه وهلكت مواشيه. ثم ماتت أبناؤه دفعةً واحدة.
ثم أُصيب بمرض شديد استمر ثمانية عشر عامًا.

👩 3. وفاء زوجته "رحمة"
تركت الراحة وخدمته طوال سنوات المرض. باعت ضفيرتيها مقابل طعامه.

🤲 4. الدعاء العظيم
﴿أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ﴾

💦 5. معجزة الشفاء
﴿ارْكُضْ بِرِجْلِكَ﴾ فتفجّر نبع ماء بارد. اغتسل منه فاختفى المرض.
جاءت زوجته فلم تعرفه — فابتسم: "أنا أيوب."

🌧️ 6. الجائزة الإلهية
أعاد الله له أمواله وأرزقه أبناءً جُددًا.
﴿إِنَّا وَجَدْنَاهُ صَابِرًا ۚ نِّعْمَ الْعَبْدُ﴾"""
    },
    {
      "name": "ذو الكفل عليه السلام",
      "icon": "🌙",
      "story": """🌿 1. من هو؟
بشر بن أيوب. سُمّي "ذا الكفل" لأنه تكفّل بعهدٍ عسير ووفى به.

📜 2. الشروط الثلاثة
تكفّل بثلاثة شروط لا يطيقها إلا قليل:
• صيام النهار دائمًا
• قيام الليل دائمًا
• ألا يغضب أبدًا
وعيّنه النبي اليسع خليفةً.

👹 3. مكر إبليس
أرسل إبليس شيطانًا يطرق بابه ثلاث ليالٍ وقت راحته بشكاوى كاذبة.
حتى تسلّق الجدار ودخل من نافذة صغيرة.

✨ 4. الانتصار الهادئ
قال له بابتسامة: "أأنت عدو الله إبليس؟"
فقال الشيطان: "نعم... لم أستطع إغضابك!"

🌟 5. الثناء الإلهي
﴿وَإِسْمَاعِيلَ وَإِدْرِيسَ وَذَا الْكِفْلِ ۖ كُلٌّ مِّنَ الصَّابِرِينَ﴾
﴿وَكُلٌّ مِّنَ الْأَخْيَارِ﴾"""
    },
    {
      "name": "موسى عليه السلام",
      "icon": "⚡",
      "story": """🍼 1. الطفل الذي تربّى في بيت عدوه
وُلد في زمن ذبح فرعون الأبناء. ألقته أمه في النيل في صندوق.
وصل القصر فاحتضنته آسية زوجة فرعون — وأرضعته أمه الحقيقية فيه.

💥 2. الحادثة والهروب
قتل رجلًا قبطيًا خطأً فهرب إلى مدين.
ساعد ابنتَي شعيب فتزوج إحداهما ومكث عشر سنوات.

🔥 3. ليلة الوادي المقدس
رأى نارًا فوق جبل الطور. فسمع: "يا موسى... إني أنا ربك."
معجزة العصا والثعبان، واليد تضيء كالقمر.
التكليف: "اذهب إلى فرعون."

⚡ 4. مواجهة فرعون والسحرة
ابتلعت عصاه كل سحر السحرة. فسجدوا مؤمنين.
فرعون أعدمهم.

🌊 5. شقّ البحر والغرق
ضرب موسى البحر فانشق. عبر المؤمنون بسلام.
غرق فرعون وقال: "آمنت!" — ﴿الْيَوْمَ نُنَجِّيكَ بِبَدَنِكَ﴾"""
    },
    {
      "name": "هارون عليه السلام",
      "icon": "🎙️",
      "story": """👶 1. النشأة والفارق
أخو موسى الأكبر بثلاث سنوات. وُلد في سنة العفو.
كان هادئًا فصيح اللسان محبوبًا بين الناس.

🤝 2. نبيّ بدعاء أخيه
طلب موسى: ﴿وَأَخِي هَارُونُ هُوَ أَفْصَحُ مِنِّي لِسَانًا﴾
فأوحى الله إلى هارون بالنبوة أيضًا.

🐄 3. محنة العجل الذهبي
لما صعد موسى للطور صنع السامري عجلًا ذهبيًا.
وقف هارون يرفض وينذر لكنهم هددوه بالقتل.
قال لأخيه: "أنا خفت يحصل انقسام بين الناس."

⛰️ 4. الوفاة فوق الجبل
صعدا معًا إلى جبل عالٍ. وجد هارون سريرًا فنام عليه ثم قبضت روحه.
توفي قبل موسى بثلاث سنوات.
مقامه اليوم في منطقة البتراء بالأردن."""
    },
    {
      "name": "داوود عليه السلام",
      "icon": "🎶",
      "story": """🐑 1. الراعي الذي هزم العملاق
شاب بسيط من بيت لحم. وحده تجرأ ومشى نحو العملاق جالوت بمقلاع وثلاثة أحجار.
الحجرة الأولى اخترقت خوذته — فسقط جالوت ميتًا.

👑 2. الملك النبي
جمع الله له: المُلك، النبوة، القوة، العبادة.
الحديد يلين في يده كالعجين. كان يصنع الدروع ويأكل من عمل يده.

🎶 3. صوت الكون
أنزل الله عليه الزبور. إذا قرأه تجمعت الطيور وردّدت الجبال التسبيح معه.
﴿وَسَخَّرْنَا مَعَ دَاوُدَ الْجِبَالَ يُسَبِّحْنَ وَالطَّيْرَ﴾

🌙 4. عبادته
يصوم يومًا ويفطر يومًا.
قال النبي ﷺ: "أحب الصيام إلى الله صيام داود."

☠️ 5. الوفاة
وجد رجلًا داخل القصر فقال: "من أنت؟"
قال: "أنا الذي لا تمنعه الأبواب."
فعرف داود وقال: "مرحبًا بأمر الله." ودُفن في القدس."""
    },
    {
      "name": "سليمان عليه السلام",
      "icon": "🧞",
      "story": """🧒 1. حكمة الصبي
ابن داود. وهو صغير حكم في نزاع الشاتين على الرضيع بحكمة ذهلت أباه.

👑 2. الملك المعجز
الريح تسمع أمره — مسيرة شهر في ساعات.
الجن يبنون القصور ويغوصون في البحار.
يفهم لغة الطيور والحيوانات.

🐜 3. النملة الصغيرة
سمع نملة تحذر زميلاتها فأوقف جيشه كله حتى تدخل النمل بيوتها بأمان.

🐦 4. الهدهد وبلقيس
أخبره الهدهد عن ملكة اليمن التي تعبد الشمس.
أرسل إليها فجاءت. حضر عرشها في طرفة عين. ورأت قصره الزجاجي.
فأسلمت: ﴿رَبِّ إِنِّي ظَلَمْتُ نَفْسِي وَأَسْلَمْتُ مَعَ سُلَيْمَانَ لِلَّهِ﴾

🪵 5. الوفاة العجيبة
توفي واقفًا متكئًا على عصاه يصلي. جاءت دودة وأكلت العصا فانكسرت وسقط.
ظل الجن يعملون شهورًا يظنونه حيًا — فتبيّن: الجن لا يعلمون الغيب."""
    },
    {
      "name": "إلياس عليه السلام",
      "icon": "🔥",
      "story": """🏛️ 1. المدينة الوثنية
من ذرية هارون. بُعث في بعلبك حيث عبد القومُ صنمًا ذهبيًا يُسمى "بعل".
الملك الجائر وزوجته فرضا السجود للصنم وقتلا كل من يوحّد.

📢 2. الشجاعة والاختباء
وقف إلياس في المدينة: "كيف تتركون الله وتعبدون بعل؟!"
فهدده الملك بالقتل. فأمره الله بالاختباء في الجبال.
كانت الطيور تأتيه يوميًا بالخبز واللحم.

🌧️ 3. ثلاث سنوات جفاف
حبس الله المطر ثلاث سنوات. لكن الصنم لم ينفعهم.

🔥 4. معجزة النار والإيمان
تحدى كهنة الصنم — دعوا يومًا كاملًا فلم تأتِ نار.
دعا إلياس لحظةً فنزلت نار من السماء فسجد الحاضرون مؤمنين.

🌌 5. الرفع الغامض
نزلت مركبة نورية فصعد فيها إلياس واختفى.
ترك رداءه لليسع — إشارة انتقال الرسالة."""
    },
    {
      "name": "اليسع عليه السلام",
      "icon": "🌊",
      "story": """🛌 1. المرض والشفاء
من نسل يوسف بن يعقوب. أصابه مرض خطير.
فمرّ به إلياس ودعا له فشفاه الله فورًا.

🤝 2. التلميذ الوفي
آمن بإلياس وأصبح تلميذه الملازم في الجبال والعبادة والدعوة.

🌌 3. انتقال الرسالة
حين رُفع إلياس سقط رداؤه إلى اليسع.
فتولى قيادة بني إسرائيل بعده.

💧 4. المعجزات الثلاث
• نبع ماء مالح تحول إلى عذب
• زيت قليل لامرأة فقيرة ملأ كل الأواني
• طفل ميت أعاده الله للحياة بدعائه

⚖️ 5. اختيار الخليفة
أراد خليفةً فوضع الشروط الصعبة (صيام، قيام الليل، لا غضب).
فتقدم الشاب الصالح ذو الكفل ووفّى بها.
﴿وَكُلًّا فَضَّلْنَا عَلَى الْعَالَمِينَ﴾"""
    },
    {
      "name": "يونس عليه السلام",
      "icon": "🐋",
      "story": """📜 1. نينوى والدعوة الصعبة
بُعث في نينوى بالعراق لأكثر من مائة ألف نسمة.
سنوات من الدعوة وهم يرفضون.

⚠️ 2. الرحيل الغاضب
قال لهم: "العذاب آتٍ خلال ثلاثة أيام!" ثم خرج مغاضبًا قبل إذن الله.

😱 3. توبة أهل نينوى
اسودّ السماء وبدأ العذاب يظهر. فخرج الناس كلهم إلى الصحراء يبكون مع حيواناتهم.
فاستجاب الله لهم ورفع العذاب.

🌊 4. بطن الحوت
في البحر جاءت عاصفة فأُلقي في الماء فابتلعه حوت ضخم.
في ظلمات ثلاث دعا:
﴿لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ﴾

🌿 5. النجاة والعودة
قذفه الحوت على الشاطئ ضعيفًا. فأنبت الله له شجرة اليقطين.
ثم عاد لنينوى فوجد قومه كلهم قد آمنوا."""
    },
    {
      "name": "زكريا عليه السلام",
      "icon": "🕌",
      "story": """👴 1. الحبر النجّار
نبيّ وإمام أهل زمانه. كان نجّارًا يأكل من عمل يده.
وكفل السيدة مريم في المحراب.

🍇 2. رزق مريم العجيب
كان يزورها فيجد فواكه في غير أوانها.
فسألها: "أنّى لكِ هذا؟" فقالت: "هو من عند الله."

🤲 3. الدعاء السري
﴿رَبِّ إِنِّي وَهَنَ الْعَظْمُ مِنِّي وَاشْتَعَلَ الرَّأْسُ شَيْبًا...﴾
يطلب وليًا يرث النبوة — وهو في الكِبَر وزوجته عاقر.

👼 4. البشارة بيحيى
نادته الملائكة وهو قائم يصلي:
يحيى — ﴿لَمْ نَجْعَل لَهُ مِن قَبْلُ سَمِيًّا﴾

🤫 5. آية الصمت
طلب علامة فجُعل آيته ألا يتكلم مع الناس ثلاثة أيام إلا إشارة.
فخرج يسبّح ويشير للناس أن يذكروا الله."""
    },
    {
      "name": "يحيى عليه السلام",
      "icon": "🕊️",
      "story": """👶 1. المعجزة والاسم الإلهي
وُلد لوالدين كبيرين بمعجزة.
وأُعطي اسمًا لم يُسمَّ به أحد قبله.
﴿وَآتَيْنَاهُ الْحُكْمَ صَبِيًّا﴾ — حكمة الأنبياء وهو طفل.

🌿 2. الزهد الكامل
كان يأكل من نبات الأرض ويلبس الخشن.
لم يلعب كالأطفال. رحيم حتى بالحيوانات.

🌸 3. الصفات الإلهية
﴿وَحَنَانًا مِّن لَّدُنَّا وَزَكَاةً﴾
﴿وَبَرًّا بِوَالِدَيْهِ وَلَمْ يَكُن جَبَّارًا عَصِيًّا﴾
﴿وَسَيِّدًا وَحَصُورًا﴾

🤝 4. اللقاء مع عيسى
التقى بعيسى ابن مريم وكانا متحابَين في الحق.
يتعاونان في دعوة التوحيد.

⚖️ 5. الشهادة
وقف ضد زواج محرم أراده الملك الجائر.
قال كلمة الحق فاستشهد ظلمًا.
﴿وَسَلَامٌ عَلَيْهِ يَوْمَ وُلِدَ وَيَوْمَ يَمُوتُ وَيَوْمَ يُبْعَثُ حَيًّا﴾"""
    },
    {
      "name": "عيسى عليه السلام",
      "icon": "🌟",
      "story": """🕊️ 1. الميلاد المعجز
أمه مريم الطاهرة العفيفة. بشّرها جبريل في هيئة بشر.
حملت بغير أب بإذن الله — "كن فيكون".
وضعت تحت نخلة بالتوجيه الإلهي.

👶 2. النطق في المهد
اتّهمها قومها فأشارت إليه فتكلم طفلًا:
"إني عبدُ الله آتاني الكتاب وجعلني نبيًا."

🌍 3. المعجزات بإذن الله
• إحياء الموتى
• إبراء الأكمه والأبرص
• خلق طير من الطين فيه الروح بإذن الله
• نزول المائدة السماوية

⚡ 4. الرفع إلى السماء
سعى اليهود لقتله. فرفعه الله إليه ونجّاه.
﴿وَمَا قَتَلُوهُ وَمَا صَلَبُوهُ وَلَٰكِن شُبِّهَ لَهُمْ﴾

🌍 5. العودة في آخر الزمان
سيعود عيسى ابن مريم في آخر الزمان.
يكسر الصليب، يقتل المسيح الدجال، ويملأ الأرض عدلًا وسلامًا."""
    },
    {
      "name": "محمد ﷺ",
      "icon": "🌙",
      "story": """🌟 1. الميلاد في عام الفيل
من بني هاشم ونسبه يصل لإسماعيل بن إبراهيم.
وُلد يتيم الأب في مكة عام الفيل.

🌿 2. الطفولة المباركة
أُرسل إلى البادية مع حليمة السعدية فحلّت البركة في بيتها.
شُق صدره الشريف وطُهّر قلبه.
فقد أمه ثم جده ثم عمه أبا طالب.

📖 3. ليلة اقرأ
في غار حراء نزل جبريل: "اقرأ."
عاد يرتجف فثبّتته خديجة. وبشّره ورقة بالنبوة.

🔥 4. سنوات الأذى
الدعوة السرية ثم الجهرية. تعذيب المستضعفين.
الهجرة إلى الحبشة. حصار الشِّعب ثلاث سنوات.
عام الحزن: وفاة أبي طالب وخديجة.

🚀 5. الإسراء والمعراج
رحلة إلى القدس ثم السماوات. لقاء الأنبياء. وفُرضت الصلاة.

🏙️ 6. بناء الدولة
الهجرة إلى المدينة. المؤاخاة. وثيقة المدينة.
انتصار بدر، ابتلاء أحد، تخطيط الخندق.

🕋 7. فتح مكة
دخل فاتحًا: "اذهبوا فأنتم الطلقاء."
تحطمت الأصنام وأشرقت مكة بالتوحيد.

🕊️ 8. الوداع والوفاة
﴿الْيَوْمَ أَكْمَلْتُ لَكُمْ دِينَكُمْ﴾
توفي ﷺ عن 63 عامًا ودُفن في المدينة المنورة.
وبقيت رسالته نورًا وهداية للعالمين."""
    },
  ];

  List<Map<String, String>> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = List.from(prophets);

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerController.forward();

    searchController.addListener(() {
      final q = searchController.text.trim().toLowerCase();
      setState(() {
        filtered = q.isEmpty
            ? List.from(prophets)
            : prophets.where((p) =>
        p["name"]!.toLowerCase().contains(q) ||
            p["story"]!.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _openStory(Map<String, String> prophet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorySheet(prophet: prophet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kInk,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF12103a), Color(0xFF0e0c18), Color(0xFF0a0814)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ───── HEADER ─────
                FadeTransition(
                  opacity: _headerFade,
                  child: _buildHeader(),
                ),

                // ───── SEARCH ─────
                _buildSearch(),

                // ───── COUNTER ─────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${filtered.length} من ${prophets.length} نبي',
                      style: TextStyle(
                        color: kGoldDim.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),

                // ───── GRID ─────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _ProphetCard(
                        prophet: filtered[index],
                        index: index,
                        onTap: () => _openStory(filtered[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kGold.withOpacity(0.15), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ornament
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 50, height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, kGoldDim]),
                  )),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('✦', style: TextStyle(color: kGoldDim, fontSize: 14)),
              ),
              Container(width: 50, height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kGoldDim, Colors.transparent]),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'قِصَصُ الأَنْبِيَاء',
            style: TextStyle(
              color: kGoldLight,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stories of the Prophets',
            style: TextStyle(
              color: kGold.withOpacity(0.45),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: kGold.withOpacity(0.06),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: kGold.withOpacity(0.2)),
        ),
        child: TextField(
          controller: searchController,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(color: kParchment, fontSize: 15),
          cursorColor: kGold,
          decoration: InputDecoration(
            hintText: 'ابحث عن نبي...',
            hintStyle: TextStyle(color: kGold.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: kGoldDim, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'لم يُعثر على نبي بهذا الاسم',
            style: TextStyle(color: kGold.withOpacity(0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROPHET CARD WIDGET
// ─────────────────────────────────────────
class _ProphetCard extends StatefulWidget {
  final Map<String, String> prophet;
  final int index;
  final VoidCallback onTap;

  const _ProphetCard({
    required this.prophet,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ProphetCard> createState() => _ProphetCardState();
}

class _ProphetCardState extends State<_ProphetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeSlide;
  bool _pressed = false;

  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);
  static const Color kGoldDim = Color(0xFF8a6f30);
  static const Color kInkSoft = Color(0xFF241f38);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeSlide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(_fadeSlide),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: kGold.withOpacity(0.05),
                border: Border.all(color: kGold.withOpacity(0.18), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // subtle top shine
                    Positioned(
                      top: -30,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              kGold.withOpacity(0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // icon circle
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kGold.withOpacity(0.1),
                              border: Border.all(
                                  color: kGold.withOpacity(0.25), width: 1),
                            ),
                            child: Center(
                              child: Text(
                                widget.prophet["icon"]!,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.prophet["name"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kGoldLight,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.prophet["story"]!
                                .replaceAll(RegExp(r'[\n\r]'), ' ')
                                .substring(0,
                                min(60, widget.prophet["story"]!.length)) +
                                '...',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kGold.withOpacity(0.4),
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: kGold.withOpacity(0.1),
                              border: Border.all(
                                  color: kGold.withOpacity(0.2), width: 0.8),
                            ),
                            child: Text(
                              'اقرأ القصة',
                              style: TextStyle(
                                color: kGold.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// STORY BOTTOM SHEET
// ─────────────────────────────────────────
class _StorySheet extends StatelessWidget {
  final Map<String, String> prophet;

  const _StorySheet({required this.prophet});

  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);
  static const Color kGoldDim = Color(0xFF8a6f30);
  static const Color kInkMid = Color(0xFF1a1628);
  static const Color kParchment = Color(0xFFf5edd6);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: kInkMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kGold.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: kGold.withOpacity(0.15)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGold.withOpacity(0.12),
                      border: Border.all(color: kGold.withOpacity(0.3), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        prophet["icon"]!,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prophet["name"]!,
                    style: const TextStyle(
                      color: kGoldLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ornament
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.transparent, kGoldDim]),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('✦',
                            style: TextStyle(color: kGoldDim, fontSize: 12)),
                      ),
                      Container(
                        width: 60,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [kGoldDim, Colors.transparent]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // scrollable story
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Text(
                  prophet["story"]!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: kParchment.withOpacity(0.85),
                    fontSize: 15,
                    height: 2.0,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),

            // close button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kGold.withOpacity(0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: kGold.withOpacity(0.1),
                    foregroundColor: kGoldLight,
                    side: BorderSide(color: kGold.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'إغلاق القصة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}