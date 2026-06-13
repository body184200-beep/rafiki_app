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
    title: "الاسم والصفات",
    subtitle: "النسب الشريف والأخلاق الكريمة",
    accent: Color(0xFFD4A843),
    content: """أولاً: الاسم والنسب ﷺ
هو محمد بن عبد الله بن عبد المطلب بن هاشم، وينتهي نسبه إلى إسماعيل بن إبراهيم عليهما السلام.
وله أسماء عديدة وردت في الحديث، منها: محمد، أحمد، الماحي، الحاشر، والعاقب.

ثانياً: الصفات الخَلْقية
• الوجه: كالقمر ليلة البدر، أبيض مشربًا بحمرة.
• العينان: واسعتان، شديد سوادهما، وأهداب طويلة.
• الشعر: شديد السواد، يصل أحيانًا لشحمة الأذن.
• الجسم: متوسط الطول، عريض المنكبين، قوي البنية.
• الرائحة: كان أطيب الناس رائحة، وعرقه كالمسك.

ثالثاً: الصفات الخُلُقية
قالت عائشة رضي الله عنها: "كان خلقه القرآن"، ومن أبرز صفاته:
• الصدق والأمانة: عُرف قبل البعثة بالصادق الأمين.
• الرحمة: أرحم الناس بالأطفال والضعفاء والنساء.
• التواضع: يخدم أهله، ويجلس حيث ينتهي المجلس.
• الشجاعة: أشد الناس ثباتًا في القتال.
• الجود: كان أجود الناس، خاصة في رمضان.""",
  ),
  _Section(
    icon: Icons.child_care_rounded,
    title: "الولادة والنشأة",
    subtitle: "في مكة المكرمة عام الفيل",
    accent: Color(0xFF2DB589),
    content: """• ولد النبي محمد ﷺ في مكة المكرمة عام الفيل (571م تقريبًا)، يوم الاثنين من شهر ربيع الأول.

أولاً: النسب واليُتم المبكر
• والده: عبد الله بن عبد المطلب، توفي قبل ولادته.
• والدته: آمنة بنت وهب، توفيت وهو في سن 6 سنوات.
• جده: عبد المطلب، تكفّل به حتى وفاته وهو في سن 8 سنوات.
• عمه: أبو طالب، رعاه واحتضنه وحماه طوال حياته.

ثانياً: النشأة في البادية
• أُرسل إلى ديار بني سعد كما كان يفعل أشراف مكة.
• أرضعته حليمة السعدية وعاش في البادية حتى سن 4 سنوات.
• حدثت له حادثة شق الصدر، حيث طُهر قلبه بأمر من الله.

ثالثاً: العمل في الصغر والشباب
• رعى الغنم في صغره، وقال: "ما بعث الله نبياً إلا رعى الغنم".
• عمل في التجارة مع عمه أبي طالب في رحلات الشام.
• اشتهر بالصدق والأمانة حتى قبل البعثة.""",
  ),
  _Section(
    icon: Icons.favorite_border_rounded,
    title: "الزوجات",
    subtitle: "أمهات المؤمنين رضي الله عنهن",
    accent: Color(0xFFB85C5C),
    content: """• تزوج النبي ﷺ إحدى عشرة امرأة، وهن يُسمَّين "أمهات المؤمنين".

① خديجة بنت خويلد
أول زوجاته، وعاش معها 25 سنة. أول من آمن به وسانده بمالها ونفسها.

② سودة بنت زمعة
تزوجها بعد وفاة خديجة. عُرفت بخفة ظلها وحرصها على خدمة بيت النبي ﷺ.

③ عائشة بنت أبي بكر
أحب زوجاته إليه. من أعلم النساء بالحديث والفقه.

④ حفصة بنت عمر
ابنة عمر بن الخطاب. حُفظ عندها المصحف في عهد أبي بكر.

⑤ زينب بنت خزيمة
لُقبت بـ "أم المساكين". كانت كثيرة الصدقة والإحسان.

⑥ أم سلمة
عُرفت بالحكمة ورجاحة العقل. استشارها النبي ﷺ في صلح الحديبية.

⑦ زينب بنت جحش
نزل زواجها في القرآن لإبطال التبني.

⑧ جويرية بنت الحارث
كانت سبباً في عتق قومها بعد زواجها.

⑨ أم حبيبة
ابنة أبي سفيان. ثبتت على الإسلام في الحبشة رغم الغربة.

⑩ صفية بنت حيي
من نسل هارون عليه السلام. تزوجها النبي ﷺ بعد خيبر.

⑪ ميمونة بنت الحارث
آخر زوجاته ﷺ.

• مارية القبطية رضي الله عنها كانت ملك يمين، وأم ابنه إبراهيم.""",
  ),
  _Section(
    icon: Icons.people_outline_rounded,
    title: "الأولاد",
    subtitle: "ذريته الطاهرة ﷺ",
    accent: Color(0xFF6B7FD4),
    content: """• رُزق النبي ﷺ بسبعة أبناء: 3 ذكور و4 إناث.
• جميعهم من السيدة خديجة رضي الله عنها، إلا إبراهيم فمن مارية القبطية.

أولاً: الأبناء الذكور
• القاسم: أول أولاده، وبه كان يُكنى "أبو القاسم"، وتوفي صغيراً.
• عبد الله: لُقب بالطيب والطاهر، وتوفي صغيراً أيضاً.
• إبراهيم: وُلد في المدينة، وتوفي رضيعاً. قال النبي ﷺ:
"إن العين لتدمع والقلب ليحزن ولا نقول إلا ما يرضي ربنا".

ثانياً: البنات
• زينب: أكبر بناته، تزوجت أبو العاص بن الربيع.
• رقية: تزوجت عثمان بن عفان، وتوفيت في غزوة بدر.
• أم كلثوم: تزوجها عثمان بعد وفاة أختها، فلقب بـ "ذو النورين".
• فاطمة الزهراء: أحب بناته إليه، سيدة نساء أهل الجنة،
تزوجت علي بن أبي طالب، ومنها خرج نسل النبي ﷺ.""",
  ),
  _Section(
    icon: Icons.record_voice_over_rounded,
    title: "الدعوة الإسلامية",
    subtitle: "٢٣ عاماً من النور والهداية",
    accent: Color(0xFFD4A843),
    content: """مرت الدعوة الإسلامية بمرحلتين أساسيتين خلال 23 عاماً:

─── المرحلة المكية (13 سنة) ───
• الدعوة السرية (3 سنوات): بدأت بالأقربين.
• الدعوة الجهرية: بدأت بدعوة قريش على جبل الصفا.
• الهجرة إلى الحبشة: لحماية المسلمين من الظلم.
• الإسراء والمعراج: رحلة معجزة لتثبيت قلب النبي ﷺ.
• بيعة العقبة: بايع أهل المدينة النبي ﷺ على النصرة.

─── المرحلة المدنية (10 سنوات) ───
• بناء المسجد النبوي: أول مركز للعبادة والتعليم.
• المؤاخاة: بين المهاجرين والأنصار لتعزيز التكافل.
• وثيقة المدينة: أول دستور ينظم العلاقات بين سكان المدينة.
• الغزوات: بدر وأحد والخندق لحماية الدولة الإسلامية.
• فتح مكة: نقطة التحول الكبرى.

─── عالمية الدعوة ───
أرسل النبي ﷺ رسائل إلى ملوك العالم كهرقل وكسرى لدعوتهم إلى الإسلام.""",
  ),
  _Section(
    icon: Icons.emoji_events_rounded,
    title: "الإنجازات",
    subtitle: "تحول حضاري في ٢٣ عاماً",
    accent: Color(0xFF2DB589),
    content: """خلال 23 عاماً فقط، أحدثت الدعوة النبوية تغييرات كبرى:

─── الإنجاز العقائدي ───
• ترسيخ التوحيد: القضاء على عبادة الأصنام.
• تحرير العقل: محاربة الخرافات والدعوة إلى العلم.

─── الإنجاز الاجتماعي ───
• المساواة والعدالة: "لا فضل لعربي على أعجمي إلا بالتقوى".
• تحرير العبيد ورفع مكانة الإنسان (مثل بلال بن رباح).
• تكريم المرأة وإعطاؤها حقوقها الكاملة.

─── الإنجاز السياسي ───
• تأسيس الدولة الإسلامية في المدينة المنورة.
• توحيد الجزيرة العربية لأول مرة في التاريخ.

─── الإنجاز التشريعي ───
• تحويل المجتمع إلى قيم الصدق والأمانة والوفاء.
• تشريع الزكاة والصدقات لضمان العدالة الاجتماعية.

─── الإنجاز الثقافي ───
• حفظ اللغة العربية وتطوير علومها وبلاغتها بالقرآن الكريم.""",
  ),
  _Section(
    icon: Icons.brightness_3_rounded,
    title: "الوفاة",
    subtitle: "١٢ ربيع الأول ١١ هـ",
    accent: Color(0xFF8888CC),
    content: """توفي النبي محمد ﷺ يوم الاثنين 12 ربيع الأول 11 هـ (8 يونيو 632م)، عن عمر 63 عاماً.

─── بداية المرض ───
بدأ المرض بحمى وصداع شديد استمر نحو 13 يوماً. كان يحب أن يبقى في بيت السيدة عائشة فاستأذن زوجاته فوافقن.

─── أيامه الأخيرة ───
اشتد عليه المرض فأمر أن يؤم الناس أبو بكر الصديق. وأوصى الناس بالصلاة وبالنساء خيراً.

─── لحظة الوفاة ───
توفي ﷺ وهو مستند إلى صدر السيدة عائشة، وكان يقول:
"اللهم في الرفيق الأعلى" حتى فاضت روحه الطاهرة.

─── موقف الصحابة ───
قال أبو بكر الصديق:
"من كان يعبد محمداً فإن محمداً قد مات، ومن كان يعبد الله فإن الله حي لا يموت."
﴿وَمَا مُحَمَّدٌ إِلَّا رَسُولٌ قَدْ خَلَتْ مِن قَبْلِهِ الرُّسُلُ﴾

─── الغسل والدفن ───
غسله أهل بيته وعلي بن أبي طالب.
دُفن في موضع وفاته داخل حجرة السيدة عائشة، وهو الآن داخل المسجد النبوي الشريف.""",
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
            bottom: BorderSide(color: _C.gold.withOpacity(0.15), width: 1),
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
                      shadows: [Shadow(color: _C.gold.withOpacity(0.5), blurRadius: 16)],
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
          border: Border.all(color: s.accent.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: s.accent.withOpacity(0.10),
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
                    colors: [s.accent.withOpacity(0.0), s.accent, s.accent.withOpacity(0.0)],
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
                  color: s.accent.withOpacity(0.12),
                  border: Border.all(color: s.accent.withOpacity(0.35), width: 1),
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
                          color: s.accent.withOpacity(0.75),
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
                    color: s.accent.withOpacity(0.08),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: s.accent.withOpacity(0.6),
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
            border: Border.all(color: s.accent.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: s.accent.withOpacity(0.12),
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
                        color: s.accent.withOpacity(0.14),
                        border: Border.all(color: s.accent.withOpacity(0.4), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: s.accent.withOpacity(0.2),
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
              Divider(color: s.accent.withOpacity(0.15), thickness: 1, indent: 24, endIndent: 24),
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
                      backgroundColor: s.accent.withOpacity(0.12),
                      foregroundColor: s.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: s.accent.withOpacity(0.3), width: 1),
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
                ? [_C.gold.withOpacity(0.4), Colors.transparent]
                : [Colors.transparent, _C.gold.withOpacity(0.4)],
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
          colors: [const Color(0xFFD4A843).withOpacity(0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withOpacity(s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}