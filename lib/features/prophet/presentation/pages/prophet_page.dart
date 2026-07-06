import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static const bg         = Color(0xFF07090F);
  static const surface    = Color(0xFF0D1018);
  static const surfaceAlt = Color(0xFF111520);
  static const border     = Color(0xFF1E2435);
  static const gold       = Color(0xFFD4A843);
  static const goldLight  = Color(0xFFF0C870);
  static const goldDim    = Color(0xFF7A5E1A);
  static const emerald    = Color(0xFF1A6B50);
  static const emeraldLt  = Color(0xFF2DD4A0);
  static const onCard     = Color(0xFFF5EDD8);
  static const muted      = Color(0xFF4A5568);
  static const textBody   = Color(0xFFCBD5E1);
}

// ─── SECTION DATA ─────────────────────────────────────────────────────────────

class _Section {
  final IconData icon;
  final String title;
  final String subtitle;
  final String content;
  final Color accent;

  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.accent,
  });
}

const List<_Section> _sections = [
  _Section(
    icon: Icons.person_outline_rounded,
    title: "الاسم والنسب والألقاب",
    subtitle: "النسب الشريف والكنية والأسماء والأخلاق",
    accent: Color(0xFFD4A843),
    content: """أولاً: الاسم والنسب الشريف ﷺ
هو محمد بن عبد الله بن عبد المطلب (واسمه شيبة الحمد) بن هاشم (واسمه عمرو) بن عبد مناف (واسمه المغيرة) بن قصي (واسمه زيد) بن كلاب بن مرة بن كعب بن لؤي بن غالب بن فهر بن مالك بن النضر بن كنانة بن خزيمة بن مدركة بن إلياس بن مضر بن نزار بن معد بن عدنان. وينتهي نسب عدنان إلى نبي الله إسماعيل بن إبراهيم عليهما السلام.

ثانياً: الأسماء والكنية والألقاب
• الأسماء الثابتة: محمد، أحمد، الماحي (الذي يمحو الله به الكفر)، الحاشر (الذي يُحشر الناس على قدمه)، والعاقب (الذي ليس بعده نبي)، والمقفي، ونبي الرحمة، ونبي التوبة.
• الكنية: أبو القاسم (باسم ابنه الأكبر القاسم).
• أشهر الألقاب: الصادق الأمين (لقب به قبل البعثة لصدقه وأمانته)، المصطفى، حبيب الرحمن، سيد ولد آدم، شفيع الأمة، البشير النذير، والسراج المنير.

ثالثاً: الصفات الخَلْقية
• الوجه: أبيض مشرب بحمرة، مستدير كالقمر ليلة البدر، يتلألأ نوراً.
• العينان: واسعتان شديدتا السواد في بياض ناصع، وأهداب طويلة كثيفة.
• الشعر: شديد السواد، ليس بالجعد القطط ولا بالسبط (متموج)، يصل إلى شحمة أذنيه.
• الجسم: رَبْعة (متوسط الطول)، عريض المنكبين، ضخم المفاصل، متماسك البنية، قوي التركيب.
• الرائحة: أطيب الناس ريحاً، وعرقه كالمسك واللؤلؤ.

رابعاً: الصفات الخُلُقية
قالت عائشة رضي الله عنها: "كان خلقه القرآن"، وأهم صفاته:
• الصدق والأمانة: حفظت قريش ودائعها عنده حتى في خضم معاداته.
• الرحمة واللين: "وما أرسلناك إلا رحمة للعالمين". كان رفيقاً بالصغير والضعيف والحيوان.
• التواضع: يخصف نعله، ويرقع ثوبه، ويخدم أهله، ويجلس حيث ينتهي به المجلس.
• الشجاعة والنجدة: كان الصحابة إذا حمي البأس واحمرت الحداق يتقون بالنبي ﷺ.
• الجود والسخاء: كان أجود الناس، وكان كالريح المرسلة في رمضان لا يخشى الفقر.""",
  ),
  _Section(
    icon: Icons.child_care_rounded,
    title: "الولادة والنشأة والأقارب",
    subtitle: "الميلاد في مكة والأعمام والعمات",
    accent: Color(0xFF2DB589),
    content: """أولاً: الولادة وتاريخ ومكان الميلاد
• وُلد النبي محمد ﷺ في شعب بني هاشم بمكة المكرمة في عام الفيل (الموافق 12 ربيع الأول سنة 571م تقريباً)، يوم الاثنين فجراً.
• توفي والده عبد الله وهو جنين في بطن أمه، وتوفيت والدته آمنة بنت وهب بالأبواء وهو في سن 6 سنوات.
• تكفله جده عبد المطلب وحاطه برعايته حتى مات والنبي ﷺ في سن 8 سنوات، ثم كفله عمه أبو طالب وضمه لأولاده وحماه بقية حياته.

ثانياً: الرضاعة والنشأة في البادية
• أرضعته ثويبة مولاة أبي لهب أياماً، ثم أرسل إلى ديار بني سعد في البادية للنشأة في الفصاحة وقوة البدن، فأرضعته حليمة السعدية وعاش هناك حتى سن 4 سنوات.
• في بادية بني سعد حدثت له حادثة "شق الصدر"، حيث جاءه جبريل عليه السلام فشق صدره واستخرج قلبه وغسله في طست من ذهب بماء زمزم، ونزع منه علقة سوداء قائلاً: "هذا حظ الشيطان منك"، ثم أعاده مطهراً.

ثالثاً: أعمام وعمات النبي ﷺ
رُزق عبد المطلب بأولاد كثر، وأقارب النبي ﷺ من الأعمام والعمات هم:
• الأعمام (12 عمّاً):
  1. حمزة بن عبد المطلب (أسد الله وسيد الشهداء، أسلم).
  2. العباس بن عبد المطلب (أبو الفضل، أسلم وعاش طويلاً).
  3. أبو طالب (عبد مناف، ناصره وحماه ومات على غير الإسلام).
  4. أبو لهب (عبد العزى، عاداه ونزلت فيه سورة المسد).
  5. الحارث بن عبد المطلب (أكبر ولد عبد المطلب).
  6. الزبير بن عبد المطلب (شريفه وشاعره).
  7. الغيداق. 8. المقوم. 9. ضرار. 10. قثم. 11. المغيرة (حجل). 12. عبد الكعبة.
• العمات (6 عمات):
  1. صفية بنت عبد المطلب (أم الزبير بن العوام، أسلمت وهاجرت).
  2. عاتكة بنت عبد المطلب (صاحبة الرؤيا قبل بدر، اختلف في إسلامها).
  3. أروى بنت عبد المطلب. 4. أميمة بنت عبد المطلب (أم زينب بنت جحش).
  5. برة بنت عبد المطلب. 6. أم حكيم البيضاء (توأم والد النبي ﷺ).""",
  ),
  _Section(
    icon: Icons.favorite_border_rounded,
    title: "الزوجات (أمهات المؤمنين)",
    subtitle: "أزواجه الطاهرات وسيرتهن رضي الله عنهن",
    accent: Color(0xFFB85C5C),
    content: """تزوج النبي ﷺ إحدى عشرة امرأة بعقد نكاح ودخل بهن، وهن "أمهات المؤمنين":

① خديجة بنت خويلد
تزوجها بمكة وهو في سن 25 وهي في سن 40. أول من آمن به وواسته بمالها ونفسها، ولم يتزوج غيرها حتى ماتت رضي الله عنها بعد 25 سنة زواج.

② سودة بنت زمعة
تزوجها بمكة بعد وفاة خديجة لتكفل أيتامه. أول امرأة تزوجها بعد خديجة، وعرفت بالزهد والوفاء.

③ عائشة بنت أبي بكر
الزوجة البكر الوحيدة. أحب نسائه إليه، وأعلم نساء الأمة بالفقه والحديث والعلم.

④ حفصة بنت عمر
ابنة الفاروق عمر بن الخطاب. كانت صوامة قوامة، وعندها حفظ المصحف الأول المجموع في عهد أبي بكر وعمر.

⑤ زينب بنت خزيمة
لقبت بـ "أم المساكين" لرحمتها وكثرة إطعامها للفقراء. لم تلبث عنده إلا أشهراً يسيرة وتوفيت في حياته.

⑥ أم سلمة (هند بنت أبي أمية)
عرفت برجاحة العقل والحكمة البالغة. استشارها النبي ﷺ يوم الحديبية في نحلق الهدي فأنقذت الموقف.

⑦ زينب بنت جحش
ابنة عمته أميمة. تزوجها بأمر الله لإبطال بدعة التبني، وكانت صناع اليد تتصدق بكل ما تصنعه.

⑧ جويرية بنت الحارث
كانت من سبايا بني المصطلق، فتزوجها وأعتق المسلمون مئة بيت من قومها إكراماً لصهر الرسول.

⑨ أم حبيبة (رملة بنت أبي سفيان)
ثبتت على الإسلام بالحبشة رغم ارتداد زوجها وغربتها، وتزوجها النبي وهي هناك وأصدقها عنه النجاشي.

⑩ صفية بنت حيي بن أخطب
من نسل نبي الله هارون بن عمران. أعتقها النبي وتزوجها بعد فتح خيبر.

⑪ ميمونة بنت الحارث
آخر زوجة تزوجها النبي ﷺ في عمرة القضاء سنة 7 هـ.

• مارية القبطية: أهداها له المقوقس صاحب مصر، وكانت ملك يمين وحظية عنده، وولدت له ابنه إبراهيم، فأعتقها إيلادها.""",
  ),
  _Section(
    icon: Icons.people_outline_rounded,
    title: "الأولاد والبنات",
    subtitle: "ذريته الطاهرة الكريمة ﷺ",
    accent: Color(0xFF6B7FD4),
    content: """رُزق النبي ﷺ بسبعة أولاد (3 ذكور و4 بنات)، وكلهم من أم المؤمنين خديجة رضي الله عنها، خلا إبراهيم فإنه من مارية القبطية.

أولاً: الأبناء الذكور (توفوا جميعاً في الصغر لحكمة إلهية)
1. القاسم: وبه يُكنى ﷺ. ولد بمكة وتوفي فيها وعمره سنتان تقريباً.
2. عبد الله: ولد بمكة بعد البعثة ولقب بالطاهر والطيب، وتوفي صغيراً.
3. إبراهيم: ولد بالمدينة المنورة في السنة 8 هـ وتوفي رضيعاً (10 هـ)، وحزن عليه النبي وقال: "إن العين لتدمع، والقلب ليحزن، ولا نقول إلا ما يرضي ربنا، وإنا بفراقك يا إبراهيم لمحزونون".

ثانياً: البنات (أدركن الإسلام وهاجرن)
1. زينب: أكبر بناته. تزوجت ابن خالتها أبو العاص بن الربيع، وولدت له علي وأمامة.
2. رقية: تزوجت عثمان بن عفان وهاجرت معه للحبشة ثم المدينة، وتوفيت أثناء غزوة بدر.
3. أم كلثوم: تزوجها عثمان بن عفان بعد وفاة أختها رقية، فتوفيت في شعبان 9 هـ ولقب عثمان بـ "ذو النورين".
4. فاطمة الزهراء: أحب بناته إليه وسيدة نساء أهل الجنة. تزوجت علي بن أبي طالب رضي الله عنه وولدت له الحسن والحسين والمحسن وزينب وأم كلثوم، ومنها امتد النسل النبوي الشريف. توفيت بعد النبي ﷺ بستة أشهر.""",
  ),
  _Section(
    icon: Icons.record_voice_over_rounded,
    title: "الدعوة والبعثة والهجرة",
    subtitle: "٢٣ عاماً من إبلاغ الرسالة السماوية",
    accent: Color(0xFFD4A843),
    content: """مرت الدعوة الإسلامية بمراحل دقيقة امتدت لـ 23 عاماً لتأسيس أمة الإسلام:

أولاً: البعثة ونزول الوحي
لما بلغ النبي ﷺ سن 40 سنة، حُبب إليه الخلاء فكان يتحنث في غار حراء. وفي شهر رمضان، نزل عليه الملك جبريل عليه السلام بالوحي وأول ما نزل: ﴿اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ﴾. فرجع يرجف فهدأته خديجة وذهبت به لورقة بن نوفل الذي بشره بالنبوة.

ثانياً: مرحلة الدعوة بمكة (13 سنة)
• الدعوة السرية (3 سنوات): ركزت على إسلام المقربين والسابقين كخديجة وأبي بكر وعلي وزيد بن حارثة.
• الدعوة الجهرية (10 سنوات): بدأت بالصعود على الصفا وإنذار عشيرته. واجه المسلمون تعذيباً شديداً، فأمرهم بالهجرة للحبشة (السنة 5 للبعثة). وتلا ذلك حصار شعب بني هاشم لثلاث سنوات، ثم عام الحزن بوفاة أبي طالب وخديجة، ورحلة الطائف المؤلمة، ثم معجزة الإسراء والمعراج لتثبيت فؤاده.
• بيعة العقبة الأولى والثانية: بايع وفود الأوس والخزرج النبي بمكة على الإسلام وحمايته، مما مهد للهجرة.

ثالثاً: مرحلة المدينة المنورة والدولة (10 سنوات)
هاجر النبي ﷺ مع الصديق أبي بكر متخفياً في غار ثور حتى وصلا المدينة (1 هـ / 622م). وبدأ بتأسيس الدولة عبر ثلاث ركائز:
1. بناء المسجد النبوي الشريف كمركز للعبادة والشورى والتعليم.
2. المؤاخاة بين المهاجرين والأنصار لتذويب الفوارق القبلية والتكافل.
3. كتابة وثيقة المدينة المنورة كدستور ينظم العلاقة بين المسلمين واليهود وباقي الطوائف.""",
  ),
  _Section(
    icon: Icons.auto_stories_rounded,
    title: "الجدول الزمني للسيرة النبوية",
    subtitle: "أهم الأحداث التاريخية مرتبة بالسنوات هجرياً",
    accent: Color(0xFF4A90E2),
    content: """الجدول التاريخي لأبرز محطات السيرة النبوية الكبرى:

• عام الفيل (571م): الولادة النبوية الشريفة بمكة المكرمة.
• سن 6 سنوات: وفاة والدته آمنة بنت وهب في الأبواء.
• سن 8 سنوات: وفاة جده عبد المطلب وكفالة عمه أبي طالب.
• سن 12 سنة: رحلته الأولى للشام مع عمه وقصة الراهب بحيرا.
• سن 25 سنة: تجارته لخديجة بنت خويلد بالشام والزواج منها.
• سن 35 سنة: تجديد بناء الكعبة وحل نزاع الحجر الأسود بحكمته.
• سن 40 سنة (عام البعثة): نزول الوحي بغار حراء وبدء الرسالة.
• السنة 3 للبعثة: بدء الجهر بالدعوة والاضطهاد القرشي للمسلمين.
• السنة 5 للبعثة: الهجرة الأولى للمسلمين إلى الحبشة فراراً بدينهم.
• السنة 10 للبعثة: عام الحزن (وفاة أبي طالب وخديجة) ورحلة الطائف.
• السنة 11 للبعثة: الإسراء والمعراج وبيعة العقبة الأولى (12 رجلاً).
• السنة 12 للبعثة: بيعة العقبة الثانية (73 رجلاً وامرأتان).
• السنة 13 للبعثة (1 هـ): الهجرة النبوية إلى يثرب وبناء المسجد والمؤاخاة.
• السنة 2 هـ: فرض الصيام، تحويل القبلة إلى الكعبة، وغزوة بدر الكبرى.
• السنة 3 هـ: تحريم الخمر، وغزوة أحد (استشهاد حمزة ومصعب).
• السنة 4 هـ: غزوة بني النضير (إجلاء يهود بني النضير لمؤامرتهم).
• السنة 5 هـ: غزوة الخندق (الأحزاب) وحصار المدينة، وغزوة بني قريظة.
• السنة 6 هـ: صلح الحديبية وبيعة الرضوان تحت الشجرة.
• السنة 7 هـ: غزوة خيبر وعمرة القضاء ومكاتبة ملوك ورؤساء العالم.
• السنة 8 هـ: سرية مؤتة، فتح مكة الأعظم، وغزوة حنين، وغزوة الطائف.
• السنة 9 هـ: غزوة تبوك (العسرة) ضد الروم، وعام الوفود لدخول قبائل العرب في الإسلام.
• السنة 10 هـ: حجة الوداع وإلقاء خطبة البلاغ والوصايا الأخيرة.
• السنة 11 هـ: مرض النبي ﷺ ووفاته يوم الاثنين 12 ربيع الأول.""",
  ),
  _Section(
    icon: Icons.auto_awesome_rounded,
    title: "المعجزات النبوية الثابتة",
    subtitle: "أدلة النبوة الحسية والمعنوية المؤيدة بالوحي",
    accent: Color(0xFFD4A843),
    content: """أيد الله تبارك وتعالى نبيه ورسوله محمداً ﷺ بمعجزات باهرة خرق بها العادات، وأهمها:

1. القرآن الكريم: المعجزة العقلية الخالدة الباقية لكل العصور، التي تحدى الله بها الإنس والجن أن يأتوا بمثل سورة منها، فلم يستطيعوا رغم فصاحتهم وبلاغتهم.
2. الإسراء والمعراج: رحلته الجسدية في ليلة واحدة من المسجد الحرام للمسجد الأقصى، ثم العروج للسماوات العلا حتى سدرة المنتهى، وفرض الصلوات الخمس.
3. انشقاق القمر: سأله مشركو مكة آية، فأشار للقمر فانشق نصفين فرأوا جبل حراء بينهما، ونزل القرآن: ﴿اقْتَرَبَتِ السَّاعَةُ وَانشَقَّ الْقَمَرُ﴾.
4. نبع الماء من بين أصابعه: وقعت مراراً في أسفاره وغزواته عند نفاد الماء، فيضع يده الشريفة في الإناء فيثور الماء كأمثال العيون من بين أصابعه، فيشرب الجيش كله ويتوضأ (كما في الحديبية والتبوك).
5. تكثير الطعام القليل: مثل إشباع مئات الصحابة من صاع شعير وعناق شاة في بيت جابر بن عبد الله يوم الخندق، وفي قصة قرص الشعير ل أبي طلحة.
6. حنين جذع النخلة: كان يخطب على جذع نخلة بالمسجد، فلما صُنع له منبر وجلس عليه، حن الجذع وصاح كصياح الصبي شوقاً لرسول الله، حتى نزل وضمه فسكت الجذع.
7. سلام الحجر والشجر: قال ﷺ: "إني لأعرف حجراً بمكة كان يسلم علي قبل أن أبعث إني لأعرفه الآن"، وكان الشجر ينقاد له ويمشي بأمره.
8. إبراء المرضى وذوي العاهات: مثل رده لعين قتادة بن النعمان بعدما سالت على خده يوم أحد فعادت أحسن عينيه، وتفله في عيني علي بن أبي طالب يوم خيبر فبرئ من الرمد فوراً.
9. الإخبار بالمغيبات: إخباره بموت كسرى وقيصر، وفتح مصر والشام واليمن، وإخباره بفتنة عثمان ومقتل علي وحسين، وغيرها مما تحقق كما أخبر تماماً.""",
  ),
  _Section(
    icon: Icons.shield_rounded,
    title: "الغزوات والسرايا النبوية",
    subtitle: "الجهاد النبوي لحفظ كيان الدولة والدعوة",
    accent: Color(0xFFD0021B),
    content: """شرع الله الجهاد في سبيل الله لحماية الدين ودفع العدوان وتأمين نشر الرسالة، وقاد النبي ﷺ الجهاد بنفسه وبأصحابه:

أولاً: الغزوات النبوية
• الغزوة: هي المعركة العسكرية التي خرج فيها النبي ﷺ بنفسه قائداً للجيش، سواء حدث فيها قتال عسكري مباشر أو انتهت بدون قتال.
• عدد الغزوات: بلغت 27 غزوة خلال 10 سنوات (من 2 هـ إلى 9 هـ).
• الغزوات التي حدث فيها قتال فعلي (9 غزوات):
  1. غزوة بدر الكبرى (2 هـ) - انتصار حاسم للمسلمين.
  2. غزوة أحد (3 هـ) - درس بليغ في وجوب طاعة القائد النبوي.
  3. غزوة الخندق / الأحزاب (5 هـ) - حصار مشركي العرب للمدينة وفشله.
  4. غزوة بني قريظة (5 هـ) - معاقبة يهود بني قريظة لخيانتهم العظمى.
  5. غزوة بني المصطلق / المريسيع (5 هـ) - تشتيت كيد بني خزاعة.
  6. غزوة خيبر (7 هـ) - فتح معاقل وحصون اليهود بالشمال.
  7. فتح مكة الأعظم (8 هـ) - دخول مكة سلماً وهدم الأصنام.
  8. غزوة حنين (8 هـ) - مواجهة قبيلتي هوازن وثقيف وعبرة كثرة العدد.
  9. غزوة الطائف (8 هـ) - حصار ثقيف في حصونهم بالطائف.
• الغزوات الأخرى التي لم يحدث فيها قتال مباشر (18 غزوة): منها الأبواء (ودان وهي الأولى)، وبواط، وسفوان، وذات الرقاع، ودومة الجندل، وتبوك (وهي الأخيرة في 9 هـ).

ثانياً: السرايا النبوية
• السرية: هي البعثة العسكرية الاستطلاعية أو القتالية التي أرسلها النبي ﷺ ووجّهها، ولم يخرج فيها بنفسه بل أمّر عليها أحد أصحابه.
• عدد السرايا: تزيد على 60 سرية (وقيل تقارب 80 سرية).
• أهم السرايا: سرية سيف البحر (أول سرية بقيادة حمزة)، سرية نخلة (أول قتال وغنيمة بقيادة عبد الله بن جحش)، وسرية مؤتة (التي واجهت الروم بقيادة زيد وجعفر وابن رواحة وسماها البعض غزوة لعظمها).""",
  ),
  _Section(
    icon: Icons.menu_book_rounded,
    title: "جمع القرآن الكريم وتاريخه",
    subtitle: "تاريخ جمع المصحف الشريف عبر العصور الثلاثة",
    accent: Color(0xFF0D5C61),
    content: """حُفظ القرآن الكريم بعناية فائقة وضمان إلهي ﴿إِنَّا نَحْنُ نَزَّلْنَا الذِّكْرَ وَإِنَّا لَهُ لَحَافِظُونَ﴾، ومرّ جمعه بثلاث مراحل تاريخية:

المرحلة الأولى: الجمع في العهد النبوي ﷺ
• اعتمد الحفظ أساساً على الصدور لسرعة حفظ العرب وقوة ذاكرتهم، وكان جبريل يدارس النبي القرآن كل عام وفي العام الأخير دارسه مرتين.
• كان للنبي كتاب وحي يكتبون ما ينزل فوراً (أبرزهم: علي بن أبي طالب، أبي بن كعب، زيد بن ثابت، عثمان بن عفان).
• كُتب القرآن مفرقاً على الرقاع (الجلود)، واللخاف (الحجارة الرقيقة)، والأكتاف (عظام الحيوانات)، ولم يجمع في كتاب واحد لترقب نزول وحي ينسخ أو يضيف حتى وفاته ﷺ.

المرحلة الثانية: الجمع في عهد أبي بكر الصديق (12 هـ)
• السبب: استشهاد عدد كبير من قراء الصحابة والحفظة في حروب الردة (معركة اليمامة)، فأشار عمر بن الخطاب على أبي بكر بجمع القرآن خشية ضياعه.
• المهمة: كلف أبو بكر الصحابي الشاب زيد بن ثابت (كاتب الوحي الرئيسي) لجمعه، فقام بجمعه من الصدور والسطور بدقة بالغة؛ لم يقبل آية مكتوبة إلا بشاهدين عدلين يشهدان أنها كتبت بين يدي النبي.
• النتيجة: كُتب القرآن كاملاً في صحف موحدة مرتبة الآيات، وحفظت عند أبي بكر، ثم عند عمر بعد وفاته، ثم انتقلت لأم المؤمنين حفصة بنت عمر.

المرحلة الثالثة: الجمع العثماني وتوحيد المصاحف (25 هـ)
• السبب: اتساع الفتوحات واختلاف المسلمين الجدد في قراءات القرآن باختلاف لهجاتهم، حتى كادوا يكفرون بعضهم، فأسرع حذيفة بن اليمان لعثمان يطالبه بتدارك الأمة.
• المهمة: شكل عثمان لجنة برئاسة زيد بن ثابت وعضوية قرشيين (عبد الله بن الزبير، سعيد بن العاص، عبد الرحمن بن الحارث)، وأمرهم بنسخ صحف حفصة في مصحف واحد بلسان قريش.
• النتيجة: كُتب "المصحف الإمام"، وأُرسلت نسخ منه للأمصار (مكة، البصرة، الكوفة، الشام، اليمن، البحرين، وبقي واحد بالمدينة)، وأمر بحرق كل ما خالفه لتوحيد الأمة على رسم وقراءة واحدة.""",
  ),
  _Section(
    icon: Icons.emoji_events_rounded,
    title: "الإنجازات والتحول الحضاري",
    subtitle: "كيف غيّر الرسول وجه التاريخ في ٢٣ عاماً",
    accent: Color(0xFF2DB589),
    content: """خلال 23 عاماً فقط، أحدثت الدعوة النبوية تحولاً شاملاً لا نظير له في تاريخ البشرية:

─── الإنجاز العقائدي والروحي ───
• ترسيخ التوحيد: القضاء التام على الشرك وعبادة الأصنام وتطهير الكعبة.
• تحرير العقل: محاربة التنجيم والكهانة والخرافات الجاهلية والدعوة للتفكر والطلب المستمر للعلم.

─── الإنجاز الاجتماعي والإنساني ───
• المساواة المطلقة: إرساء مبدأ "لا فضل لعربي على أعجمي إلا بالتقوى".
• حقوق المرأة: منح المرأة ذمتها المالية المستقلة وحق الميراث والاختيار، ووصيته العظيمة: "استوصوا بالنساء خيراً".
• حقوق الضعفاء والعبيد: تشريع عتق الرقاب، ورفع شأن بلال وسلمان وصهيب، ورعاية الأيتام والفقراء.

─── الإنجاز السياسي والعسكري ───
• توحيد العرب: جمع القبائل المتناحرة لأول مرة تحت لواء واحد ودولة واحدة.
• بناء الدولة الدستورية: صياغة وثيقة المدينة وإرساء مبادئ الشورى والعدل بين المواطنين.
• تنظيم الجيش: تأسيس جيش منظم منضبط بأخلاق حربية صارمة تمنع قتل النساء والأطفال والشيوخ وهدم الصوامع وقطع الشجر.

─── الإنجاز التشريعي والقيمي ───
• مكارم الأخلاق: الصدق، الوفاء بالعهد، تحريم الظلم والربا والسرقة والزنا والخمور، ووضع قواعد المعاملات المالية العادلة.""",
  ),
  _Section(
    icon: Icons.brightness_3_rounded,
    title: "المرض والوفاة",
    subtitle: "١٢ ربيع الأول ١١ هـ - انقطاع الوحي ورحيله للرفيق الأعلى",
    accent: Color(0xFF8888CC),
    content: """رحيل النبي ﷺ كان أعظم فاجعة حلت بالمسلمين، وبها انقطع وحي السماء عن الأرض:

أولاً: بداية المرض والأيام الأخيرة
• بدأ المرض في أواخر شهر صفر 11 هـ بحمى وصداع شديدين عقب عودته من جنازة بالبقيع. واستمر مرضه 13 يوماً.
• لما اشتد عليه الوجع، استأذن زوجاته أن يُمرّض في بيت السيدة عائشة رضي الله عنها، فأذنّ له.
• لم يستطع الخروج للصلاة، فقال: "مروا أبا بكر فليصل بالناس"، إشارة مبطنة لخلافته وتفويضه لقيادة الأمة.
• في مرضه أوصى بإنفاذ جيش أسامة بن زيد، وكرر وصيته الذهبية: "الصلاة الصلاة، وما ملكت أيمانكم"، ووصيته بالأنصار وبالنساء خيراً.

ثانياً: لحظة الوفاة الشريفة
• في ضحى يوم الاثنين 12 ربيع الأول 11 هـ (الموافق 8 يونيو 632م)، وكان مسنداً رأسه الشريف إلى صدر السيدة عائشة، نظر إلى السواك فأشارت له أتريده؟ فأومأ برأسه فنظفته وطيبته فاستاك به أشد ما يكون.
• ثم رفع أصبعه الشريفة وشخص بصره نحو السقف، وهمس بكلماته الأخيرة: "بل الرفيق الأعلى من الجنة... اللهم الرفيق الأعلى"، ثم سقطت يده وفاضت روحه الطاهرة العطرة. وتوفي وعمره 63 سنة كاملة.

ثالثاً: موقف الصحابة الغامر وفاجعتهم
• صُدم الصحابة لدرجة أن عمر بن الخطاب شهر سيفه وقال: "من قال إن محمداً قد مات قطعت عنقه، إنما ذهب إلى ربه كما ذهب موسى".
• فجاء أبو بكر الصديق ودخل وقبّل جبهة النبي الشريفة وبكى وقال: "بأبي أنت وأمي يا رسول الله، طبت حياً وميتاً"، ثم خرج للناس وخطب خطبته الشهيرة الهادئة:
"أما بعد، فمن كان يعبد محمداً فإن محمداً قد مات، ومن كان يعبد الله فإن الله حي لا يموت"، وتلا قوله تعالى: ﴿وَمَا مُحَمَّدٌ إِلاَّ رَسُولٌ قَدْ خَلَتْ مِن قَبْلِهِ الرُّسُلُ أَفَإِن مَّاتَ أَوْ قُتِلَ انقَلَبْتُمْ عَلَى أَعْقَابِكُمْ﴾. فسقط الناس يبكون وعلموا بوفاته.

رابعاً: الغسل والتكفين والدفن
• غسله آل بيته (علي بن أبي طالب، العباس، الفضل وقثم ابنا العباس، أسامة بن زيد وشقران مولياه)، غسلوه في ثيابه تعظيماً له، وكفن في ثلاثة أثواب بيض سحولية ليس فيها قميص ولا عمامة.
• دُفن في موضع وفاته داخل حجرة عائشة بالمدينة المنورة، تنفيذاً لقول أبي بكر سمعت رسول الله يقول: "ما قبض الله نبياً إلا دُفن حيث يُقبض". وصلى عليه المسلمون فرادى ودون إمام، الرجال ثم النساء ثم الصبيان.""",
  ),
];

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class Rasolna extends StatefulWidget {
  const Rasolna({super.key});

  @override
  State<Rasolna> createState() => _RasolnaState();
}

class _RasolnaState extends State<Rasolna> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: _entryCtrl.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _entryCtrl.value) * -20),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _C.gold.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Top ornament row
            Row(
              children: [
                _GoldDivider(reversed: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "☽",
                    style: TextStyle(
                      color: _C.gold,
                      fontSize: 22,
                      shadows: [Shadow(color: _C.gold.withValues(alpha: 0.5), blurRadius: 16)],
                    ),
                  ),
                ),
                _GoldDivider(reversed: true),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "حياة الرسول ﷺ",
              style: TextStyle(
                color: _C.goldLight,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                shadows: [Shadow(color: Color(0x55D4A843), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "السيرة النبوية العطرة",
              style: TextStyle(
                color: _C.muted,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST ──────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _sections.length,
      itemBuilder: (context, i) => _SectionCard(
        section: _sections[i],
        index: i,
        entryController: _entryCtrl,
        onTap: () => _showDetailSheet(context, _sections[i]),
      ),
    );
  }

  // ── BOTTOM SHEET ──────────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context, _Section section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(section: section),
    );
  }
}

// ─── SECTION CARD ────────────────────────────────────────────────────────────

class _SectionCard extends StatefulWidget {
  final _Section section;
  final int index;
  final AnimationController entryController;
  final VoidCallback onTap;

  const _SectionCard({
    required this.section,
    required this.index,
    required this.entryController,
    required this.onTap,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  late final Animation<double> _entryFade;
  late final Animation<double> _entrySlide;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.035,
    );

    final start = (widget.index * 0.07).clamp(0.0, 0.85);
    final end   = (start + 0.28).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _entryFade  = curve;
    _entrySlide = Tween<double>(begin: 30, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return AnimatedBuilder(
      animation: Listenable.merge([widget.entryController, _pressCtrl]),
      builder: (_, __) => Opacity(
        opacity: _entryFade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _entrySlide.value),
          child: Transform.scale(
            scale: 1.0 - _pressCtrl.value,
            child: _buildCard(s),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(_Section s) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _C.surface,
          border: Border.all(color: s.accent.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: s.accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: 3,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [s.accent.withValues(alpha: 0.0), s.accent, s.accent.withValues(alpha: 0.0)],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.accent.withValues(alpha: 0.12),
                  border: Border.all(color: s.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Icon(s.icon, color: s.accent, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.subtitle,
                        style: TextStyle(
                          color: s.accent.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: s.accent.withValues(alpha: 0.6),
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DETAIL BOTTOM SHEET ─────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final _Section section;

  const _DetailSheet({required this.section});

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: _C.surfaceAlt,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: s.accent.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: s.accent.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _C.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.accent.withValues(alpha: 0.14),
                        border: Border.all(color: s.accent.withValues(alpha: 0.4), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: s.accent.withValues(alpha: 0.2),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(s.icon, color: s.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: TextStyle(
                              color: s.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.subtitle,
                            style: const TextStyle(
                              color: _C.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Divider(color: s.accent.withValues(alpha: 0.15), thickness: 1, indent: 24, endIndent: 24),
              const SizedBox(height: 8),
              // Body
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  children: [
                    Text(
                      s.content,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: _C.textBody,
                        fontSize: 15,
                        height: 1.95,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: s.accent.withValues(alpha: 0.12),
                      foregroundColor: s.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: s.accent.withValues(alpha: 0.3), width: 1),
                      ),
                    ),
                    child: const Text(
                      "إغلاق",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  final bool reversed;
  const _GoldDivider({required this.reversed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reversed
                ? [_C.gold.withValues(alpha: 0.4), Colors.transparent]
                : [Colors.transparent, _C.gold.withValues(alpha: 0.4)],
          ),
        ),
      ),
    );
  }
}

// ─── BACKGROUND ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BgPainter()),
    );
  }
}

class _BgPainter extends CustomPainter {
  static final _stars = List.generate(50, (i) {
    final r = math.Random(i * 41 + 9);
    return (x: r.nextDouble(), y: r.nextDouble(), rad: r.nextDouble() * 1.1 + 0.2, o: r.nextDouble() * 0.3 + 0.06);
  });

  @override
  void paint(Canvas canvas, Size sz) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF090B12), Color(0xFF07090F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    // Gold nebula
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.5, -0.8),
          radius: 0.55,
          colors: [const Color(0xFFD4A843).withValues(alpha: 0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withValues(alpha: s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}