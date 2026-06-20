import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  Entry
// ─────────────────────────────────────────────────────────────
void main() => runApp(const PrayerGuideApp());

class PrayerGuideApp extends StatelessWidget {
  const PrayerGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _P.bg,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const PrayerPodcastPage(),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────
class _P {
  static const bg       = Color(0xFF0A0C10);
  static const surface  = Color(0xFF111520);
  static const card     = Color(0xFF161B2A);
  static const cardHigh = Color(0xFF1C2337);

  static const amber    = Color(0xFFE8A030);
  static const amberDim = Color(0xFF6E4A12);
  static const amberSoft= Color(0xFFF5C878);

  static const teal     = Color(0xFF28B8A4);
  static const tealDim  = Color(0xFF10534A);

  static const text1    = Color(0xFFF0ECD8);
  static const text2    = Color(0xFFB8B09A);
  static const text3    = Color(0xFF6E6858);

  static const red      = Color(0xFFE05050);

  // Per-category accent
  static const List<List<Color>> palettes = [
    [Color(0xFF1A3350), Color(0xFF28B8A4)],   // teal
    [Color(0xFF2A1A10), Color(0xFFE8A030)],   // amber
    [Color(0xFF1A2A1A), Color(0xFF58C878)],   // green
    [Color(0xFF28102A), Color(0xFFB868D8)],   // purple
    [Color(0xFF10202A), Color(0xFF40A8D8)],   // sky
    [Color(0xFF2A1A1A), Color(0xFFE87050)],   // coral
  ];
}

// ─────────────────────────────────────────────────────────────
//  Data
// ─────────────────────────────────────────────────────────────
class Episode {
  final int number;
  final String title;
  final String body;
  final String category;
  final String duration;

  const Episode({
    required this.number,
    required this.title,
    required this.body,
    required this.category,
    required this.duration,
  });

  List<Color> get palette => _P.palettes[number % _P.palettes.length];
}

final List<Episode> kEpisodes = [
  Episode(number: 1, title: "كيف تحافظ على الصلاة؟", duration: "١٢ دقيقة", category: "الصلاة", body:
  "الصلاة هي الركن الثاني من أركان الإسلام، وأول ما يُحاسب عليه العبد يوم القيامة.\n\n"
      "📌 لماذا هي أهم عبادة؟\n"
      "- هي الصلة المباشرة بين العبد وربه\n"
      "- تنهى عن الفحشاء والمنكر\n"
      "- تحفظ القلب من القسوة\n"
      "- سبب للرزق والبركة وتيسير الحياة\n\n"
      "📌 حلول عملية قوية:\n"
      "- الصلاة فور الأذان بدون تأخير\n"
      "- ربط الصلاة بعادة يومية ثابتة\n"
      "- الصلاة في المسجد ولو مرة يوميًا\n\n"
      "🕌 قال ﷺ: «العهد الذي بيننا وبينهم الصلاة»\n\n"
      "💡 البداية ليست الكمال… البداية ألا تتركها أبدًا."),

  Episode(number: 2, title: "الوضوء نور للمؤمن", duration: "٨ دقائق", category: "الطهارة", body:
  "الوضوء ليس مجرد غسل أعضاء، بل عبادة عظيمة تمحو الذنوب.\n\n"
      "💧 ماذا يحدث في الوضوء؟\n"
      "- تخرج الذنوب مع الماء من الأعضاء\n"
      "- يتجدد نور القلب والوجه\n"
      "- يستعد المسلم للوقوف بين يدي الله\n\n"
      "📌 سنن مهمة:\n"
      "- السواك\n"
      "- التثليث\n"
      "- الدعاء بعد الوضوء\n\n"
      "🕌 قال ﷺ: «إذا توضأ العبد خرجت خطاياه»\n\n"
      "💡 كل وضوء = بداية صفحة جديدة في حياتك."),

  Episode(number: 3, title: "الخشوع في الصلاة", duration: "١٥ دقيقة", category: "الصلاة", body:
  "الخشوع هو روح الصلاة، وبدونه تصبح حركات بلا روح.\n\n"
      "🤲 معنى الخشوع:\n"
      "- حضور القلب مع الله\n"
      "- فهم الآيات\n"
      "- سكون الجوارح\n\n"
      "📌 كيف تصل للخشوع؟\n"
      "1- تخيل أنك في آخر صلاة في حياتك\n"
      "2- قراءة ببطء وتركيز\n"
      "3- تقليل الملهيات قبل الصلاة\n"
      "4- إطالة السجود والدعاء\n\n"
      "🕌 كان النبي ﷺ يقول: «أرحنا بها يا بلال»\n\n"
      "💡 الخشوع تدريب… وليس شعورًا عابرًا."),

  Episode(number: 4, title: "أثر الصلاة في الحياة", duration: "١٠ دقائق", category: "الصلاة", body:
  "الصلاة ليست عبادة فقط… بل نظام حياة كامل.\n\n"
      "✨ آثارها:\n"
      "- راحة نفسية عميقة\n"
      "- قوة في اتخاذ القرار\n"
      "- تنظيم الوقت\n"
      "- ترك المعاصي تدريجيًا\n\n"
      "🕌 قال ﷺ: «قرة عيني في الصلاة»\n\n"
      "💡 من أقام الصلاة… أقام الله له حياته."),

  Episode(number: 5, title: "قيام الليل سر القوة", duration: "١٨ دقيقة", category: "قيام الليل", body:
  "قيام الليل مدرسة الإيمان العميق.\n\n"
      "📌 فضله:\n"
      "- قرب شديد من الله\n"
      "- استجابة الدعاء\n"
      "- نور في الوجه والقلب\n\n"
      "📌 كيف تبدأ؟\n"
      "- ركعتين فقط يوميًا\n"
      "- قبل النوم أو قبيل الفجر\n\n"
      "🕌 قال تعالى: «إن ناشئة الليل هي أشد وطأ»\n\n"
      "💡 القليل الدائم يصنع الإيمان العظيم."),

  Episode(number: 6, title: "علاج الفتور الإيماني", duration: "١٣ دقيقة", category: "الإيمان", body:
  "الفتور طبيعي لكن الخطر هو الاستسلام له.\n\n"
      "📌 أسبابه:\n"
      "- الذنوب المتكررة\n"
      "- الغفلة\n"
      "- البيئة السيئة\n\n"
      "📌 العلاج:\n"
      "- قرآن يومي ولو صفحة\n"
      "- ذكر مستمر\n"
      "- صحبة صالحة\n\n"
      "🕌 قال ﷺ: «إن الإيمان ليخلق كما يخلق الثوب»\n\n"
      "💡 لا تترك نفسك تنطفئ."),

  Episode(number: 7, title: "أثر الذنوب على القلب", duration: "١١ دقيقة", category: "التوبة", body:
  "الذنب لا يمر… بل يترك أثرًا في القلب.\n\n"
      "📌 علاماته:\n"
      "- قسوة القلب\n"
      "- فقدان الطمأنينة\n"
      "- ضعف العبادة\n\n"
      "📌 العلاج:\n"
      "- التوبة الفورية\n"
      "- الاستغفار\n"
      "- ترك أسباب الذنب\n\n"
      "🕌 «كلا بل ران على قلوبهم»\n\n"
      "💡 القلب يُشفى بالتوبة فقط."),

  Episode(number: 8, title: "قوة الذكر", duration: "٩ دقائق", category: "الذكر", body:
  "الذكر هو غذاء القلب الحقيقي.\n\n"
      "📌 أهم الأذكار:\n"
      "- سبحان الله\n"
      "- الحمد لله\n"
      "- لا إله إلا الله\n"
      "- الله أكبر\n\n"
      "📌 أثره:\n"
      "- طمأنينة\n"
      "- قوة داخلية\n\n"
      "🕌 «ألا بذكر الله تطمئن القلوب»\n\n"
      "💡 اجعل لسانك لا يتوقف عن الذكر."),

  Episode(number: 9, title: "الصبر في الابتلاء", duration: "١٤ دقيقة", category: "الإيمان", body:
  "الابتلاء ليس عقوبة… بل رفع درجات.\n\n"
      "📌 أنواعه:\n"
      "- مرض\n"
      "- فقد\n"
      "- ضيق\n\n"
      "📌 ثماره:\n"
      "- تكفير الذنوب\n"
      "- رفع المكانة\n\n"
      "🕌 «إن الله مع الصابرين»\n\n"
      "💡 الصبر = قوة خفية."),

  Episode(number: 10, title: "التوبة النصوح", duration: "١٦ دقيقة", category: "التوبة", body:
  "التوبة بداية حياة جديدة بالكامل.\n\n"
      "📌 شروطها:\n"
      "- الإقلاع عن الذنب\n"
      "- الندم الحقيقي\n"
      "- عدم العودة\n\n"
      "🕌 «إن الله يحب التوابين»\n\n"
      "💡 لا تؤجل الرجوع لله."),

  Episode(number: 11, title: "فضل القرآن", duration: "١٢ دقيقة", category: "القرآن", body:
  "القرآن هو حياة القلوب.\n\n"
      "📌 فضله:\n"
      "- شفاء\n"
      "- هداية\n"
      "- نور\n\n"
      "🕌 «إن هذا القرآن يهدي للتي هي أقوم»\n\n"
      "💡 لا تهجر القرآن مهما قلّ وقتك."),

  Episode(number: 12, title: "حسن الخلق", duration: "١١ دقيقة", category: "الأخلاق", body:
  "الأخلاق هي الدين الحقيقي في التعامل.\n\n"
      "📌 أمثلة:\n"
      "- الصدق\n"
      "- الرحمة\n"
      "- العفو\n\n"
      "🕌 «إنما بعثت لأتمم مكارم الأخلاق»\n\n"
      "💡 أخلاقك هي صورتك الحقيقية."),

  Episode(number: 13, title: "مراقبة الله", duration: "١٠ دقائق", category: "الإيمان", body:
  "أن تعبد الله كأنك تراه.\n\n"
      "📌 أثرها:\n"
      "- ترك الذنوب\n"
      "- قوة الإيمان\n\n"
      "🕌 «ألم يعلم بأن الله يرى»\n\n"
      "💡 راقب الله في السر."),

  Episode(number: 14, title: "بر الوالدين", duration: "١٧ دقيقة", category: "الأخلاق", body:
  "بر الوالدين من أعظم أبواب الجنة.\n\n"
      "📌 مظاهره:\n"
      "- الاحترام\n"
      "- الدعاء\n"
      "- الطاعة\n\n"
      "🕌 «وبالوالدين إحسانًا»\n\n"
      "💡 رضا الله في رضاهم."),

  Episode(number: 15, title: "الصحبة الصالحة", duration: "١٣ دقيقة", category: "الأخلاق", body:
  "الصديق يصنع دينك.\n\n"
      "📌 صفاته:\n"
      "- يذكرك بالله\n"
      "- يعينك على الطاعة\n\n"
      "🕌 «المرء على دين خليله»\n\n"
      "💡 اختر من يرفعك."),

  Episode(number: 16, title: "فضل الصدقة", duration: "٩ دقائق", category: "الأخلاق", body:
  "الصدقة تطفئ الذنب.\n\n"
      "📌 آثارها:\n"
      "- بركة المال\n"
      "- دفع البلاء\n\n"
      "🕌 «الصدقة تطفئ الخطيئة»\n\n"
      "💡 حتى بالقليل."),

  Episode(number: 17, title: "الاستغفار", duration: "٨ دقائق", category: "الذكر", body:
  "الاستغفار مفتاح كل خير.\n\n"
      "📌 فوائده:\n"
      "- مغفرة الذنوب\n"
      "- فتح الأرزاق\n\n"
      "🕌 «استغفروا ربكم إنه كان غفارًا»\n\n"
      "💡 اجعل لسانك دائمًا يستغفر."),

  Episode(number: 18, title: "حب النبي ﷺ", duration: "١٤ دقيقة", category: "الإيمان", body:
  "حب النبي أصل الإيمان.\n\n"
      "📌 علاماته:\n"
      "- اتباع سنته\n"
      "- كثرة الصلاة عليه\n\n"
      "🕌 «لا يؤمن أحدكم حتى أكون أحب إليه»\n\n"
      "💡 الحب = اتباع."),

  Episode(number: 19, title: "تنظيم اليوم مع الصلاة", duration: "١١ دقيقة", category: "الصلاة", body:
  "الصلاة تنظم حياتك.\n\n"
      "📌 أثرها:\n"
      "- ترتيب الوقت\n"
      "- تقليل التشتت\n\n"
      "💡 اجعل يومك حول الصلاة."),

  Episode(number: 20, title: "آداب النوم", duration: "٧ دقائق", category: "السنن", body:
  "النوم عبادة إذا نويت.\n\n"
      "📌 سننه:\n"
      "- الوضوء\n"
      "- الذكر\n"
      "- النوم على اليمين\n\n"
      "💡 نومك يمكن أن يصبح عبادة."),

  Episode(number: 21, title: "غض البصر", duration: "١٠ دقائق", category: "الأخلاق", body:
  "غض البصر يحفظ القلب.\n\n"
      "📌 أثره:\n"
      "- طهارة القلب\n"
      "- قوة الإيمان\n\n"
      "🕌 «قل للمؤمنين يغضوا من أبصارهم»\n\n"
      "💡 البداية من نظرة."),

  Episode(number: 22, title: "ترك المعاصي", duration: "١٢ دقيقة", category: "التوبة", body:
  "المعصية بداية الانهيار.\n\n"
      "📌 علاجها:\n"
      "- التوبة فورًا\n"
      "- تغيير البيئة\n\n"
      "💡 لا تؤجل التغيير."),

  Episode(number: 23, title: "الدعاء المستجاب", duration: "١٥ دقيقة", category: "الذكر", body:
  "الدعاء قوة المؤمن.\n\n"
      "📌 أوقات الإجابة:\n"
      "- السجود\n"
      "- الثلث الأخير\n\n"
      "🕌 «ادعوني أستجب لكم»\n\n"
      "💡 ادع بقلب حاضر."),

  Episode(number: 24, title: "الرزق الحلال", duration: "١٣ دقيقة", category: "الأخلاق", body:
  "الحلال بركة.\n\n"
      "📌 أثره:\n"
      "- راحة القلب\n"
      "- بركة المال\n\n"
      "💡 الحلال أساس النجاح."),

  Episode(number: 25, title: "راحة القلب", duration: "١٠ دقائق", category: "الإيمان", body:
  "راحة القلب في الله فقط.\n\n"
      "📌 مصادرها:\n"
      "- الصلاة\n"
      "- القرآن\n"
      "- الذكر\n\n"
      "💡 لا راحة إلا مع الله."),

  Episode(number: 26, title: "حب الخير للناس", duration: "٨ دقائق", category: "الأخلاق", body:
  "الإيمان = حب الخير للآخرين.\n\n"
      "📌 أثره:\n"
      "- صفاء القلب\n"
      "- سلام داخلي\n\n"
      "💡 احب للناس الخير."),

  Episode(number: 27, title: "الرضا بالابتلاء", duration: "١٢ دقيقة", category: "الإيمان", body:
  "الرضا أعلى من الصبر.\n\n"
      "📌 ثماره:\n"
      "- راحة نفسية\n"
      "- قرب من الله\n\n"
      "💡 ارضَ تعش مرتاحًا."),

  Episode(number: 28, title: "القرآن حياة", duration: "١١ دقيقة", category: "القرآن", body:
  "القرآن يحيي القلوب.\n\n"
      "📌 أثره:\n"
      "- هداية\n"
      "- نور\n\n"
      "💡 لا تهجر القرآن."),

  Episode(number: 29, title: "الاستقامة", duration: "١٤ دقيقة", category: "الإيمان", body:
  "الاستقامة = الثبات.\n\n"
      "📌 معناها:\n"
      "- طاعة مستمرة\n"
      "- ترك المعاصي\n\n"
      "💡 القليل الدائم أفضل."),

  Episode(number: 30, title: "حسن الخاتمة", duration: "٢٠ دقيقة", category: "الإيمان", body:
  "حسن الخاتمة أعظم نعمة.\n\n"
      "📌 أسبابها:\n"
      "- الاستقامة\n"
      "- الذكر\n"
      "- الإخلاص\n\n"
      "🕌 اللهم ارزقنا حسن الخاتمة\n\n"
      "💡 كيف تعيش = كيف تموت."),
];

const List<String> kCategories = [
  "الكل", "الصلاة", "الإيمان", "التوبة", "الذكر",
  "القرآن", "الأخلاق", "الطهارة", "قيام الليل", "السنن"
];

// ─────────────────────────────────────────────────────────────
//  Main Page
// ─────────────────────────────────────────────────────────────
class PrayerPodcastPage extends StatefulWidget {
  const PrayerPodcastPage({super.key});

  @override
  State<PrayerPodcastPage> createState() => _PrayerPodcastPageState();
}

class _PrayerPodcastPageState extends State<PrayerPodcastPage>
    with TickerProviderStateMixin {
  String _selectedCategory = "الكل";
  int? _playingIndex;
  final Set<int> _listened = {};

  late AnimationController _bgCtrl;

  List<Episode> get _filtered => _selectedCategory == "الكل"
      ? kEpisodes
      : kEpisodes.where((e) => e.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _BgPainter(_bgCtrl.value),
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildStats(),
                _buildCategoryRow(),
                const SizedBox(height: 8),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        color: _P.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text(
                      "بودكاستي الإيماني",
                      style: TextStyle(
                        color: _P.text2,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "🎧 رحلتك الروحية",
                  style: TextStyle(
                    color: _P.text1,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          _AvatarButton(
            listened: _listened.length,
            total: kEpisodes.length,
          ),
        ],
      ),
    );
  }

  // ── Stats row ───────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _StatChip(
              icon: Icons.headphones_rounded,
              label: "${_listened.length} مسموعة",
              color: _P.teal),
          const SizedBox(width: 10),
          _StatChip(
              icon: Icons.library_music_rounded,
              label: "${kEpisodes.length} حلقة",
              color: _P.amber),
          const SizedBox(width: 10),
          _StatChip(
              icon: Icons.trending_up_rounded,
              label: "${((_listened.length / kEpisodes.length) * 100).toInt()}%",
              color: _P.amberSoft),
        ],
      ),
    );
  }

  // ── Category chips ──────────────────────────────────
  Widget _buildCategoryRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: kCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = kCategories[i];
            final sel = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel ? _P.amber : _P.card,
                  border: Border.all(
                    color: sel
                        ? _P.amber
                        : _P.text3.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: sel ? _P.bg : _P.text2,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Episode list ────────────────────────────────────
  Widget _buildList() {
    final items = _filtered;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final ep = items[i];
        final isPlaying = _playingIndex == ep.number;
        return _EpisodeCard(
          episode: ep,
          isPlaying: isPlaying,
          isListened: _listened.contains(ep.number),
          onPlay: () {
            setState(() {
              if (_playingIndex == ep.number) {
                _listened.add(ep.number);
                _playingIndex = null;
              } else {
                _playingIndex = ep.number;
              }
            });
          },
          onListened: () => setState(() => _listened.add(ep.number)),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Episode Card
// ─────────────────────────────────────────────────────────────
class _EpisodeCard extends StatefulWidget {
  final Episode episode;
  final bool isPlaying;
  final bool isListened;
  final VoidCallback onPlay;
  final VoidCallback onListened;

  const _EpisodeCard({
    required this.episode,
    required this.isPlaying,
    required this.isListened,
    required this.onPlay,
    required this.onListened,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final accent = ep.palette[1];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.isPlaying ? ep.palette[0] : _P.card,
            border: Border.all(
              color: widget.isPlaying
                  ? accent.withValues(alpha: 0.5)
                  : _P.text3.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: widget.isPlaying
                ? [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Accent stripe on right
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent.withValues(alpha: 0.8), accent.withValues(alpha: 0.2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    // ── Top Row ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 20, 14),
                      child: Row(
                        children: [
                          // Play button
                          _PlayButton(
                            isPlaying: widget.isPlaying,
                            accent: accent,
                            onTap: widget.onPlay,
                          ),
                          const SizedBox(width: 14),
                          // Title + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: accent.withValues(alpha: 0.25),
                                            width: 0.8),
                                      ),
                                      child: Text(
                                        ep.category,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (widget.isListened) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.check_circle_rounded,
                                          color: _P.teal, size: 14),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "الحلقة ${ep.number}: ${ep.title}",
                                  style: TextStyle(
                                    color: widget.isPlaying
                                        ? _P.text1
                                        : _P.text1.withValues(alpha: 0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 12, color: _P.text3),
                                    const SizedBox(width: 4),
                                    Text(
                                      ep.duration,
                                      style: const TextStyle(
                                          color: _P.text3, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Expand arrow
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _P.text3,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Player bar (when playing) ──
                    if (widget.isPlaying) _buildPlayerBar(accent),
                    // ── Expanded body ──
                    SizeTransition(
                      sizeFactor: _expandAnim,
                      child: _buildExpandedBody(accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBar(Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _P.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        children: [
          // Waveform bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(28, (i) {
              final h = 4.0 + sin(i * 0.7) * 10 + (i % 3 == 0 ? 6 : 0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: h.clamp(4, 20).toDouble(),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.4 + (i % 4) * 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.38,
              backgroundColor: _P.bg,
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("04:32",
                  style: TextStyle(color: accent, fontSize: 11)),
              Row(
                children: [
                  _ControlBtn(Icons.replay_10_rounded, accent, () {}),
                  const SizedBox(width: 12),
                  _ControlBtn(Icons.forward_10_rounded, accent, () {}),
                  const SizedBox(width: 12),
                  _ControlBtn(Icons.done_all_rounded, _P.teal, widget.onListened),
                ],
              ),
              const Text("11:58",
                  style: TextStyle(color: _P.text3, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.bg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: accent.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Text(
        widget.episode.body,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: _P.text2,
          fontSize: 14,
          height: 1.85,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Play Button
// ─────────────────────────────────────────────────────────────
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final Color accent;
  final VoidCallback onTap;

  const _PlayButton(
      {required this.isPlaying, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isPlaying
                ? [accent, accent.withValues(alpha: 0.6)]
                : [_P.cardHigh, _P.surface],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isPlaying ? 0.6 : 0.3),
            width: 1.5,
          ),
          boxShadow: isPlaying
              ? [
            BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]
              : [],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isPlaying ? _P.bg : accent,
          size: 24,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Small Control Button
// ─────────────────────────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ControlBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stat Chip
// ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Avatar / Progress Donut
// ─────────────────────────────────────────────────────────────
class _AvatarButton extends StatelessWidget {
  final int listened;
  final int total;

  const _AvatarButton({required this.listened, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _DonutPainter(listened / total),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _P.card,
            ),
            child: const Icon(Icons.person_rounded, color: _P.amber, size: 22),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = _P.text3.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = _P.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, track);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  Background Painter
// ─────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep gradient base
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0C10),
          const Color(0xFF0D1020),
          const Color(0xFF0A0C14),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ambient glow top-right (amber)
    final glowPaint = Paint()
      ..color = const Color(0xFFE8A030).withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1 + sin(t * 2 * pi) * 20),
      180,
      glowPaint,
    );

    // Ambient glow bottom-left (teal)
    final glow2 = Paint()
      ..color = const Color(0xFF28B8A4).withValues(alpha: 0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8 + cos(t * 2 * pi) * 15),
      160,
      glow2,
    );

    // Subtle dot grid
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.025);
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}