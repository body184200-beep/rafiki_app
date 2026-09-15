import 'package:flutter/material.dart';
import 'package:rafiki_app/features/companions/data/models/sahabi_model.dart';

const List<Sahabi> sahabaList = [
  // ─── الخلفاء الراشدون والعشرة المبشرون ───────────────────────────────────────
  Sahabi(name: "أبو بكر الصديق",      title: "الصدّيق",         initial: "أ", accent: Color(0xFFD4A843), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  Sahabi(name: "عمر بن الخطاب",       title: "الفاروق",         initial: "ع", accent: Color(0xFF8B2020), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  Sahabi(name: "عثمان بن عفان",       title: "ذو النورين",      initial: "ع", accent: Color(0xFF1A6B50), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  Sahabi(name: "علي بن أبي طالب",     title: "ابن عم رسول الله ﷺ وزوج فاطمة", initial: "ع", accent: Color(0xFF4A6BD4), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "آل البيت", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  Sahabi(name: "طلحة بن عبيد الله",    title: "الشهيد الحي",     initial: "ط", accent: Color(0xFFE2A732), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "الشهداء"]),
  Sahabi(name: "الزبير بن العوام",     title: "حواري الرسول ﷺ",  initial: "ز", accent: Color(0xFF9E2A2B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "القادة والفرسان"]),
  Sahabi(name: "سعد بن أبي وقاص",    title: "فارس الإسلام",     initial: "س", accent: Color(0xFF8B6020), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "القادة والفرسان"]),
  Sahabi(name: "سعيد بن زيد",         title: "مستجاب الدعوة",  initial: "س", accent: Color(0xFF5D4037), categories: ["العشرة المبشرون", "المهاجرون", "القادة والفرسان"]),
  Sahabi(name: "عبدالرحمن بن عوف",    title: "تاجر الرحمن الجواد", initial: "ع", accent: Color(0xFF2D8A6B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر"]),
  Sahabi(name: "أبو عبيدة بن الجراح",  title: "أمين هذه الأمة",  initial: "أ", accent: Color(0xFF355E3B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "القادة والفرسان"]),

  // ─── كبار الصحابة وأعلام الهدى ──────────────────────────────────────────────
  Sahabi(name: "حمزة بن عبد المطلب", title: "سيد الشهداء",      initial: "ح", accent: Color(0xFFD32F2F), categories: ["آل البيت", "المهاجرون", "أهل بدر", "الشهداء"]),
  Sahabi(name: "جعفر بن أبي طالب",   title: "ذو الجناحين",     initial: "ج", accent: Color(0xFF1976D2), categories: ["آل البيت", "المهاجرون", "الشهداء", "القادة والفرسان"]),
  Sahabi(name: "العباس بن عبد المطلب",title: "ساقي الحرمين",    initial: "ع", accent: Color(0xFF00796B), categories: ["آل البيت", "المهاجرون"]),
  Sahabi(name: "مصعب بن عمير",        title: "أول سفير في الإسلام", initial: "م", accent: Color(0xFF6B2D5E), categories: ["المهاجرون", "أهل بدر", "الشهداء"]),
  Sahabi(name: "بلال بن رباح",        title: "مؤذن الرسول ﷺ",  initial: "ب", accent: Color(0xFF8B4020), categories: ["المهاجرون", "أهل بدر"]),
  Sahabi(name: "سلمان الفارسي",      title: "الباحث عن الحقيقة", initial: "س", accent: Color(0xFF3F51B5), categories: ["المهاجرون", "رواة الحديث"]),
  Sahabi(name: "أبو ذر الغفاري",      title: "أصدق الناس لهجة", initial: "أ", accent: Color(0xFF00897B), categories: ["المهاجرون", "رواة الحديث"]),
  Sahabi(name: "عمار بن ياسر",        title: "الطيب المطيب",    initial: "ع", accent: Color(0xFFBF360C), categories: ["المهاجرون", "أهل بدر", "الشهداء"]),
  Sahabi(name: "معاذ بن جبل",         title: "إمام العلماء",     initial: "م", accent: Color(0xFF1A5C8B), categories: ["الأنصار", "أهل بدر", "رواة الحديث"]),
  Sahabi(name: "حذيفة بن اليمان",     title: "صاحب سر النبي ﷺ", initial: "ح", accent: Color(0xFF2D5C8B), categories: ["الأنصار", "رواة الحديث", "القادة والفرسان"]),
  Sahabi(name: "خالد بن الوليد",      title: "سيف الله المسلول", initial: "خ", accent: Color(0xFFB85C20), categories: ["المهاجرون", "القادة والفرسان"]),
  Sahabi(name: "عمرو بن العاص",       title: "داهية العرب وفاتح مصر", initial: "ع", accent: Color(0xFF6B3FA0), categories: ["المهاجرون", "القادة والفرسان"]),
  Sahabi(name: "أبو هريرة",          title: "حافظ الأمة وراوية الإسلام", initial: "أ", accent: Color(0xFF8D6E63), categories: ["المهاجرون", "رواة الحديث"]),
  Sahabi(name: "أنس بن مالك",         title: "خادم رسول الله ﷺ", initial: "أ", accent: Color(0xFF388E3C), categories: ["الأنصار", "أهل الرضوان", "رواة الحديث"]),
  Sahabi(name: "جابر بن عبد الله",    title: "مكثر الحديث النبوي", initial: "ج", accent: Color(0xFF0097A7), categories: ["الأنصار", "أهل الرضوان", "رواة الحديث"]),
  Sahabi(name: "عبد الله بن مسعود",   title: "فقيه الأمة وصاحب النعلين", initial: "ع", accent: Color(0xFF7E57C2), categories: ["المهاجرون", "أهل بدر", "رواة الحديث"]),
  Sahabi(name: "عبد الله بن عباس",   title: "ترجمان القرآن وحبر الأمة", initial: "ع", accent: Color(0xFFE64A19), categories: ["آل البيت", "المهاجرون", "رواة الحديث"]),
  Sahabi(name: "عبد الله بن عمر",     title: "المتبع للأثر والزاهد", initial: "ع", accent: Color(0xFFFBC02D), categories: ["المهاجرون", "أهل الرضوان", "رواة الحديث"]),
  Sahabi(name: "عبد الله بن الزبير",  title: "فارس المسجد وبطل الفتوح", initial: "ع", accent: Color(0xFF5C6BC0), categories: ["المهاجرون", "القادة والفرسان", "الشهداء"]),
  Sahabi(name: "زيد بن ثابت",         title: "جامع القرآن وفرض الأمة", initial: "ز", accent: Color(0xFF43A047), categories: ["الأنصار", "رواة الحديث"]),
  Sahabi(name: "أسامة بن زيد",        title: "حب رسول الله ﷺ وابن حبه", initial: "أ", accent: Color(0xFF3949AB), categories: ["المهاجرون", "القادة والفرسان"]),
  Sahabi(name: "أبو أيوب الأنصاري",  title: "مضيف النبي ﷺ في الهجرة", initial: "أ", accent: Color(0xFF512DA8), categories: ["الأنصار", "أهل بدر", "القادة والفرسان"]),

  // ─── أمهات المؤمنين والصحابيات الجليلات ──────────────────────────────────────
  Sahabi(name: "خديجة بنت خويلد",   title: "أم المؤمنين وسيدة نساء العالمين", initial: "خ", accent: Color(0xFFC2185B), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "عائشة بنت أبي بكر",   title: "الصديقة بنت الصديق وفقيهة الأمة", initial: "ع", accent: Color(0xFF7B1FA2), categories: ["آل البيت", "رواة الحديث", "الصحابيات"]),
  Sahabi(name: "حفصة بنت عمر",        title: "حارسة المصحف الشريف والصوامة", initial: "ح", accent: Color(0xFF303F9F), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "أم سلمة",             title: "المهاجرة الحكيمة ذات الرأي السديد", initial: "أ", accent: Color(0xFF00796B), categories: ["آل البيت", "رواة الحديث", "الصحابيات"]),
  Sahabi(name: "سودة بنت زمعة",       title: "أم المؤمنين الصالحة الجواد", initial: "س", accent: Color(0xFFEC407A), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "زينب بنت خزيمة",      title: "أم المساكين الرؤوف بالفقراء", initial: "ز", accent: Color(0xFFAB47BC), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "زينب بنت جحش",        title: "زوجة النبي بوحي السماء والأواهة", initial: "ز", accent: Color(0xFF7E57C2), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "جويرية بنت الحارث",   title: "العابدة المسبحة المحررة لقومها", initial: "ج", accent: Color(0xFF5C6BC0), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "أم حبيبة",            title: "المهاجرة الصابرة في بلاد الحبشة", initial: "أ", accent: Color(0xFF26A69A), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "صفية بنت حيي",        title: "سليلة الأنبياء والصادقة الحليمة", initial: "ص", accent: Color(0xFF9CCC65), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "ميمونة بنت الحارث",   title: "البرة التقية الواصلة للرحم", initial: "م", accent: Color(0xFFD4E157), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "فاطمة الزهراء",       title: "سيدة نساء أهل الجنة وبضعة المصطفى", initial: "ف", accent: Color(0xFFD81B60), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "أسماء بنت أبي بكر",   title: "ذات النطاقين وبطلة الهجرة", initial: "أ", accent: Color(0xFF0288D1), categories: ["المهاجرون", "الصحابيات"]),
  Sahabi(name: "نسيبة بنت كعب",       title: "أم عمارة فدائية يوم أحد", initial: "ن", accent: Color(0xFF689F38), categories: ["الأنصار", "أهل الرضوان", "الصحابيات"]),
  Sahabi(name: "سمية بنت خياط",       title: "أول شهيدة في الإسلام وصابرة مكة", initial: "س", accent: Color(0xFFE91E63), categories: ["الشهداء", "الصحابيات"]),

  // ─── أبناء وبنات النبي ﷺ ──────────────────────────────────────────────────
  Sahabi(name: "القاسم بن محمد",      title: "صاحب كنية النبي الشريفة", initial: "ق", accent: Color(0xFFFFA726), categories: ["آل البيت"]),
  Sahabi(name: "عبد الله بن محمد",     title: "الطيب الطاهر رضي الله عنه", initial: "ع", accent: Color(0xFFFF7043), categories: ["آل البيت"]),
  Sahabi(name: "إبراهيم بن محمد",      title: "ريحانة النبي في المدينة المنورة", initial: "إ", accent: Color(0xFF8D6E63), categories: ["آل البيت"]),
  Sahabi(name: "زينب بنت محمد",       title: "كبرى بنات النبي والصابرة", initial: "ز", accent: Color(0xFF26C6DA), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "رقية بنت محمد",       title: "ذات الهجرتين وزوجة ذي النورين", initial: "ر", accent: Color(0xFF29B6F6), categories: ["آل البيت", "الصحابيات"]),
  Sahabi(name: "أم كلثوم بنت محمد",   title: "زوجة عثمان بن عفان بعد أختها", initial: "أ", accent: Color(0xFF66BB6A), categories: ["آل البيت", "الصحابيات"]),
];

const List<Sahabi> tabiList = [
  Sahabi(name: "أويس القرني", title: "خير التابعين", initial: "أ", accent: Color(0xFF1E88E5), categories: ["الكل"]),
  Sahabi(name: "سعيد بن المسيب", title: "عالم أهل المدينة", initial: "س", accent: Color(0xFF43A047), categories: ["الكل"]),
  Sahabi(name: "الحسن البصري", title: "واعظ الأمة وزاهدها", initial: "ح", accent: Color(0xFF8E24AA), categories: ["الكل"]),
  Sahabi(name: "علي بن الحسين (زين العابدين)", title: "السجاد", initial: "ع", accent: Color(0xFFD81B60), categories: ["الكل", "آل البيت"]),
  Sahabi(name: "عمر بن عبد العزيز", title: "الخليفة الزاهد العادل", initial: "ع", accent: Color(0xFFF57C00), categories: ["الكل"]),
];
