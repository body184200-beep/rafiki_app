import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SahabiDetails extends StatefulWidget {
  final String name;
  final String biography;
  final List<String> battles;
  final List<String> attributes;
  final String additionalInfo;
  final String description;
  final String day;

  const SahabiDetails({
    super.key,
    required this.name,
    required this.biography,
    required this.battles,
    required this.attributes,
    required this.additionalInfo,
    required this.description,
    required this.day,
  });

  static SahabiDetails fromName(String name) {
    Map<String, dynamic>? data = sahabaData[name];

    if (data == null) {
      final trimmed = name.trim();
      final match = sahabaData.entries.where(
            (e) => e.key.trim() == trimmed,
      );
      if (match.isNotEmpty) data = match.first.value;
    }

    if (data == null || data.isEmpty) {
      return SahabiDetails(
        name: name,
        description: "لا توجد بيانات",
        biography: "",
        battles: [],
        attributes: [],
        additionalInfo: "",
        day: "",
      );
    }

    return SahabiDetails(
      name: name,
      description: data["description"] ?? "",
      biography: data["biography"] ?? "",
      battles: List<String>.from(data["battles"] ?? []),
      attributes: List<String>.from(data["attributes"] ?? []),
      additionalInfo: data["additionalInfo"] ?? "",
      day: data["day"] ?? "",
    );
  }

  static final Map<String, Map<String, dynamic>> sahabaData = {
    "أبو بكر الصديق": {
      "description": "خليفة الرسول ﷺ وأحد العشرة المبشرين بالجنة.",
      "biography":
      "أبو بكر الصديق رضي الله عنه، رفيق الرسول ﷺ وأول الخلفاء الراشدين...",
      "battles": ["غزوة بدر", "غزوة أحد", "فتح مكة"],
      "attributes": ["الصديق", "الأمين", "الشجاع"],
      "additionalInfo": "أول من أسلم بعد خديجة رضي الله عنها.",
      "day": """
قبل أن ينبلج ضياء الفجر في المدينة المنورة، كان الصمت يلف أزقتها إلا من همسات خاشعة تنبعث من بيتٍ متواضع بجوار المسجد.  
هناك، يقف أبو بكر الصديق، الرجل الرقيق القلب، يتلو القرآن بصوتٍ متهدج يغلبه البكاء.

────────────────────

🟦 فجر الإيمان (صلاة الفجر)

مع الأذان الأول، يخرج أبو بكر إلى المسجد، فيؤمّ الناس في صلاة الفجر بقلبٍ خاشع وحضورٍ كامل.

ثم يجلس يذكر الله حتى تشرق الشمس، كأن قلبه لا يفارق السماء.

────────────────────

🟦 نهار العدل (تفقد الرعية)

في ضحى اليوم، يخرج الخليفة من بين الناس لا ليُرى، بل ليرى أحوالهم.

قد تراه عند باب أرملة، أو يساعد محتاجاً دون أن يعرفه أحد، يعيش بين الناس كواحدٍ منهم، لا كحاكم فوقهم.

────────────────────

🟦 مجلس الشورى (قيادة الأمة)

حين ينتصف النهار، يعود إلى المسجد حيث يجلس مع الصحابة، يتشاور معهم في أمور الأمة، ويقود بحكمة وهدوء بعيداً عن التكبر.

────────────────────

🟦 الزهد (حياة بلا تكلف)

كان طعامه كسرة خبز ولبن، وثوبه بسيط، لكن هيبته عظيمة لأن مصدرها الإيمان لا المظاهر.

────────────────────

🟦 الليل (العبادة الخفية)

وفي الليل، لا ينام أبو بكر حتى يطمئن على الناس، ثم يقوم بين يدي ربه يناجيه حتى يغلبه التعب.

────────────────────

✨ النهاية

هكذا عاش أبو بكر الصديق،  
خليفةً زاهداً، وقائداً رحيماً،  
جمع بين قوة الحكم ورقة القلب،  
فصار مثالاً للحاكم الذي يقود الأمة وهو يخدمها.
"""
    },
    "عمر بن الخطاب": {
      "description": "ثاني الخلفاء الراشدين، معروف بالعدل والفاروقية.",
      "biography":
      "عمر بن الخطاب رضي الله عنه، ثاني الخلفاء الراشدين، قوي الشخصية وعادل...",
      "battles": ["غزوة بدر", "غزوة أحد", "فتح مكة"],
      "attributes": ["الفاروق", "القوي", "العادل"],
      "additionalInfo": "اشتهر بالعدل وحكمه الراشد.",
      "day": """
في قلب الصحراء الواسعة، حيث تلتقي قسوة الرمال بصلابة الرجال، تبرز قصة رجل لم يكن مجرد حاكم، بل كان روحاً تمشي بالعدل بين الناس.  
إنه عمر بن الخطاب، الفاروق الذي فرق الله به بين الحق والباطل.

────────────────────

🟦 مشهد القدس (تواضع القائد)

تبدأ الرواية حين دخل عمر بن الخطاب إلى القدس لا كملكٍ متكبر، بل كعبدٍ خاضع لله، يقود ناقته بنفسه وخادمه يركب خلفه بالتناوب.

دخل بثوبٍ مرقّع، فأدهش بطاركة الروم الذين رأوا هيبة بلا زينة.

وقال كلمته الخالدة:  
"نحن قوم أعزنا الله بالإسلام، فمهما ابتغينا العزة في غيره أذلنا الله".

────────────────────

🟦 مشهد العدل (الخوف من الحساب)

في المدينة، كان عمر يجلس على التراب لا على العروش، ويقسم المال بنفسه وهو يرتجف خوفاً من المسؤولية.

كان يقول:  
"لو عثرت بغلة في العراق لسُئل عنها عمر: لمَ لم تُمهد لها الطريق؟"

────────────────────

🟦 مشهد العمل (راعي الأمة)

في يومٍ حار، خرج عمر بن الخطاب بنفسه يطارد بعيراً ضائعاً من إبل الصدقة.

فلما رآه الصحابة متعباً قالوا له: لقد أتعبت من يأتي بعدك.  
فقال: "والله لو ضاع عقالٌ لسُئل عنه عمر".

────────────────────

🟦 مشهد الليل (الحارس المجهول)

في الليل، كان يخرج متخفياً يتفقد بيوت الناس، لا يحرس القصور بل يبحث عن الجائع والمحتاج.

────────────────────

🟦 مشهد الدعاء (قلب الخوف)

وفي ليلة من الليالي، دخل بيته بعد أن أطعم الأرملة وأبناءها، ثم قام يصلي ويبكي، ويقول:

"اللهم كبرت سني، وضعفت قوتي، وانتشرت رعيتي، فاقبضني إليك غير مفرط ولا مفتون".

────────────────────

✨ النهاية

رحل عمر بن الخطاب،  
لكن بقيت سيرته ميزاناً للعدل،  
وبقي اسمه رمزاً للحاكم الذي يخاف الله أكثر مما يخافه الناس.
"""
    },
    "عثمان بن عفان": {
      "description": "ثالث الخلفاء الراشدين، جمع القرآن الكريم.",
      "biography":
      "عثمان بن عفان رضي الله عنه، من السابقين للإسلام، وكان معروفًا بكرمه...",
      "battles": ["غزوة بدر", "غزوة أحد", "فتح مكة"],
      "attributes": ["الجواد", "الصبور", "الحكيم"],
      "additionalInfo": "جمع القرآن في مصحف واحد.",
      "day": """
في بيتٍ أضاءته أنوار النبوة منذ الصغر، نشأ عثمان بن عفان، الفتى الذي لم يسجد لصنمٍ قط، فكرم الله وجهه، وجمع فيه شجاعة الأبطال وحكمة العلماء.

────────────────────

🟦 مشهد الكرم (تجهيز جيش العسرة)

في غزوة تبوك، حين نادى النبي ﷺ الناس للإنفاق في سبيل الله، تقدم عثمان وجهز ثلث الجيش:
- 950 بعيرًا  
- 50 فرسًا  
- 1000 دينار ذهب  

فقال النبي ﷺ: "ما ضر عثمان ما عمل بعد اليوم".

────────────────────

🟦 مشهد الجمع (مصحف الأمة)

لاحظ عثمان اختلاف الناس في قراءة القرآن، فجمع الصحابة وأصدر أمراً تاريخياً بجمع القرآن في مصحف واحد.

فوحّد الأمة على كتاب واحد إلى يوم القيامة.

────────────────────

🟦 مشهد الزهد والصبر

رغم ثروته الطائلة، كان عثمان يعيش ببساطة، ويصوم النهار ويقوم الليل، حتى قيل عنه: "ختم القرآن في ركعة".

────────────────────

✨ النهاية

رحل عثمان بن عفان،  
لكن بقيت سيرته مدرسة في الكرم والعلم والزهد،  
وبقي القرآن الذي جمعه معجزة خالدة.
"""
    },
    "علي بن أبي طالب": {
      "description": "ابن عم الرسول ﷺ، رابع الخلفاء الراشدين.",
      "biography":
      "علي بن أبي طالب رضي الله عنه، شجاع وصالح، أول من أسلم من الصبيان...",
      "battles": ["غزوة بدر", "غزوة أحد", "الخندق"],
      "attributes": ["الشجاع", "العادل", "الحكيم"],
      "additionalInfo": "زوج فاطمة الزهراء رضي الله عنها.",
      "day": """
في أزقة مكة الضيقة، وقبل أن تشرق شمس الإسلام، كان هناك غلامٌ صغير لا يفارق النبي ﷺ لحظة.  
إنه علي بن أبي طالب، ابن عم النبي ﷺ وأول من آمن من الصبيان.

────────────────────

🟦 مشهد الفداء (ليلة الهجرة)

حين اجتمعت قريش لقتل النبي ﷺ، طلب منه أن ينام في فراشه تلك الليلة.

فنام علي في فراش النبي ﷺ مطمئناً، رغم أن السيوف كانت تحاصر البيت من كل اتجاه.

────────────────────

🟦 مشهد خيبر (باب الحصن)

في غزوة خيبر، قال النبي ﷺ:  
"لأعطين الراية غداً رجلاً يحب الله ورسوله ويحبه الله ورسوله".

وفي الصباح، أعطى الراية لعلي، فاندفع نحو حصن خيبر وقاتل بشدة حتى فُتح.

────────────────────

🟦 مشهد النهاية (فزت ورب الكعبة)

في الكوفة، وبينما كان يوقظ الناس لصلاة الفجر، ضربته يد الغدر.

فسقط في المحراب، ولم يصرخ، بل قال كلمته الأخيرة:  
"فزت ورب الكعبة".

────────────────────

✨ النهاية

رحل علي بن أبي طالب،  
لكن بقي سيفه رمزاً،  
وبقيت سيرته مدرسة في الشجاعة والزهد والعلم والعدل.
"""
    },
    "خالد بن الوليد": {
      "description": "سيف الله المسلول وقائد عسكري بارع.",
      "biography":
      "خالد بن الوليد رضي الله عنه، من أبرز قادة المسلمين العسكريين...",
      "battles": ["غزوة مؤتة", "فتح مكة", "اليمامة"],
      "attributes": ["الشجاع", "الفارس البارع", "القائد المحنك"],
      "additionalInfo": "لقب بسيف الله المسلول.",
      "day": """
تخيل رجلاً لم يعرف طعم الهزيمة قط، لا في جاهلية ولا في إسلام؛ رجلٌ كان يرى في قعقعة السيوف وصهيل الخيول أجمل ألحان الحياة.  
إنه خالد بن الوليد، "سيف الله المسلول" الذي خاض أكثر من مائة معركة ولم يُكسر له لواء.

────────────────────

🟦 مشهد العبقرية (يوم مؤتة)

في أرض الأردن، وجد المسلمون أنفسهم أمام جيش ضخم من الروم.  
استُشهد القادة الثلاثة، فتقدم خالد وانتزع الراية.

غيّر تشكيل الجيش، وأثار الغبار بالخيل ليوهم العدو بقدوم مدد، فانسحب بالجيش بأمان.

وعندها قال النبي ﷺ: "ثم أخذ الراية سيفٌ من سيوف الله".

────────────────────

🟦 مشهد الإخلاص (قمة العزل)

حين عُزل عن القيادة، لم يعترض ولم يغضب، وقال:  
"أنا لا أقاتل من أجل عمر، بل أقاتل من أجل رب عمر".

وبقي يقاتل كجندي عادي بنفس الإخلاص.

────────────────────

🟦 مشهد الوداع (فراش الشجاعة)

في حمص على فراش الموت، كشف جسده المغطى بآثار المعارك وقال:  
"لقد شهدتُ كذا وكذا معركة، وما في جسدي موضع شبر إلا وفيه ضربة سيف، وها أنا أموت على فراشي، فلا نامت أعين الجبناء".

────────────────────

✨ النهاية

رحل خالد بن الوليد،  
لكن بقيت سيرته مدرسة في العسكرية والشجاعة والإخلاص.
"""
    },
    "عمرو بن العاص": {
      "description": "فاتح مصر وقائد عسكري ذكي.",
      "biography":
      "عمرو بن العاص رضي الله عنه، قاد فتح مصر وحقق العديد من الانتصارات...",
      "battles": ["فتح مصر", "معارك الفتح الإسلامي", "غزوات في الشام"],
      "attributes": ["الاستراتيجي", "الشجاع", "الحكيم"],
      "additionalInfo": "كان حكيماً في السياسة والحرب.",
      "day": """
تخيل رجلاً يجمع بين دهاء السياسة وقوة القائد.  
إنه عمرو بن العاص، داهية العرب وقائد فتح مصر.

────────────────────

🟦 مشهد فتح مصر

توجه عمرو بجيش صغير إلى مصر، ولم يعتمد على القوة وحدها بل على التخطيط والسياسة.

حاصر حصن بابليون، ثم دخل في تفاوض ذكي مع أهل مصر، فاستقبلوه كفاتح لا كغازٍ.

وبنى مدينة "الفسطاط" وأسس أول مسجد في إفريقيا.

────────────────────

🟦 مشهد النهاية (صدق اللحظة الأخيرة)

في آخر حياته بكى وقال لابنه عبد الله:
"لقد مررتُ بثلاث مراحل: عدو للإسلام، ثم مسلم مجاهد، ثم أمير اختلط عليه أمر الدنيا".

────────────────────

✨ النهاية

رحل عمرو بن العاص،  
لكن بقي أثره في مصر التي أصبحت داراً للإسلام.
"""
    },
    "عبدالرحمن بن عوف": {
      "description": "أحد العشرة المبشرين بالجنة، تاجر وفاعل خير.",
      "biography": "عبدالرحمن بن عوف رضي الله عنه، معروف بغناه وكرمه...",
      "battles": ["غزوة بدر", "غزوة أحد"],
      "attributes": ["الكرم", "الصديق", "الراعي للمحتاجين"],
      "additionalInfo": "ساهم في دعم المسلمين مالياً.",
      "day": """
تخيل رجلاً بدأت حكايته وهو لا يملك درهماً واحداً، وانتهت وهو أغنى رجل في الأمة، ومع ذلك لم تغلبه الدنيا يوماً.  
إنه عبد الرحمن بن عوف، التاجر الصدوق وأحد العشرة المبشرة بالجنة.

────────────────────

🟦 مشهد العزة (دلّوني على السوق)

حين هاجر من مكة فقيراً، عرض عليه سعد بن الربيع ماله وزوجته.

فقال عبد الرحمن بعزة:
"بارك الله لك في أهلك ومالك، ولكن دلّوني على السوق".

ذهب إلى السوق بالقليل، فبنى ثروته بيده.

────────────────────

🟦 مشهد القافلة التي هزت المدينة

جاءت قافلته من الشام بمئات الإبل، فنادى:
"أشهدكم أن هذه القافلة بما فيها صدقة في سبيل الله".

────────────────────

🟦 مشهد الدموع

في آخر حياته، وُضع أمامه طعام وهو صائم فبكى وقال:
"قُتل مصعب بن عمير وهو خير مني، وأخشى أن نكون قد عُجّل لنا طيباتنا في الدنيا".

────────────────────

✨ النهاية

رحل عبد الرحمن بن عوف،  
فكان بحق: "التاجر الذي اشترى الجنة بالدنيا".
"""
    },
    "سعد بن أبي وقاص": {
      "description": "قائد فتح فارس ومشارك في عدة غزوات.",
      "biography": "سعد بن أبي وقاص رضي الله عنه، شارك في غزوة بدر وأحد...",
      "battles": ["غزوة بدر", "فتح فارس", "أحد"],
      "attributes": ["الشجاع", "القائد العسكري", "الصادق"],
      "additionalInfo": "أول من رفع راية الفتح في العراق.",
      "day": """
تخيل شاباً في مقتبل العمر، يمتلك دقة لا تخطئ هدفاً، وقلباً لا يعرف الخوف.  
إنه سعد بن أبي وقاص، خال النبي ﷺ، وأول من رمى بسهم في سبيل الله.

────────────────────

🟦 مشهد الثبات (صراع الحب والعقيدة)

حين أسلم سعد، امتنعت أمه عن الطعام والشراب لإرغامه على ترك الإسلام.

فوقف ثابتاً وقال:
"يا أُماه، والله لو كانت لكِ مائة نفس فخرجت نفساً نفساً ما تركت ديني هذا".

────────────────────

🟦 مشهد الفداء (ارمِ فداك أبي وأمي)

في يوم أُحد، ثبت سعد بجانب النبي ﷺ، فكان النبي يناوله السهام ويقول:
"ارمِ يا سعد.. فداك أبي وأمي".

────────────────────

🟦 مشهد القادسية

حين اشتد المرض منعه من ركوب الفرس، قاد الجيش بالرسائل من وراء الألم، حتى سقطت المدائن عاصمة كسرى.

────────────────────

✨ النهاية

رحل سعد بن أبي وقاص،  
فكان بحق: "فارس القادسية الذي لا تنكسر إرادته".
"""
    },
    "معاذ بن جبل": {
      "description": "عالم وفقيه من صحابة الرسول ﷺ.",
      "biography":
      "معاذ بن جبل رضي الله عنه، خبير في العلم والفقه وكان مستشاراً للرسول ﷺ...",
      "battles": ["غزوة بدر", "أحد"],
      "attributes": ["العالم", "الحكيم", "المستشار"],
      "additionalInfo": "أرسل إلى اليمن ليعلم الناس دين الله.",
      "day": """
تخيل شاباً من الأنصار، طويلاً، وسيمًا، يلمع في المدينة كأنه كوكب دريّ في ليلها.  
إنه معاذ بن جبل، الذي قال عنه النبي ﷺ: "أعلمُ أمتي بالحلال والحرام".

────────────────────

🟦 مشهد الحب النبوي

أخذ النبي ﷺ بيد معاذ وقال:
"يا معاذ، والله إني لأحبك".

فأوصاه: "لا تدعنَّ في دبر كل صلاة أن تقول: اللهم أعني على ذكرك وشكرك وحسن عبادتك".

────────────────────

🟦 مشهد السفير والمعلم (إلى اليمن)

سأله النبي ﷺ: "بمَ تقضي؟"  
قال معاذ: "بكتاب الله، فإن لم أجد فبسنة رسول الله، فإن لم أجد اجتهدت رأيي".

فضرب النبي ﷺ صدره فرحاً: "الحمد لله الذي وفق رسول رسول الله".

────────────────────

🟦 مشهد النهاية (شهيد الشام)

حين جاء طاعون عمواس، نظر إلى يده وقال:
"خنقك خنقك... فوعزتك إنك لتعلم أني أحبك".

────────────────────

✨ النهاية

رحل معاذ بن جبل شاباً،  
فكان بحق: "إمام العلماء وفقه القلوب".
"""
    },
    "مصعب بن عمير": {
      "description": "أول سفير للإسلام بالمدينة المنورة.",
      "biography":
      "مصعب بن عمير رضي الله عنه، أول من علم أهل المدينة دين الإسلام...",
      "battles": ["غزوة بدر"],
      "attributes": ["المعلم", "الصادق", "الشجاع"],
      "additionalInfo": "ساهم في نشر الإسلام قبل الهجرة.",
      "day": """
تخيل فتىً نشأ في رفاهية مكة وأناقتها، تعطر بأفخر العطور، ولبس أجمل الثياب.

ثم اختار الله على كل ذلك.

إنه مصعب بن عمير، أول سفير في تاريخ الإسلام.

────────────────────

🟦 مشهد التحول

حين أسلم، غضبت أسرته وحبسته، لكن قلبه كان حراً لا تستطيع قضبان الدنيا أن تأسره.

────────────────────

🟦 مشهد السفارة (المدينة تنتظر)

أرسله النبي ﷺ إلى المدينة وحده، فعلّم الناس القرآن وأسلم على يديه أسعد بن زرارة وسعد بن معاذ وأهل دور كثيرة.

────────────────────

🟦 مشهد الاستشهاد (غزوة أحد)

استُشهد في أحد وهو يحمل الراية، فلم يجدوا له كفناً إلا بردة.

إن غُطي رأسه بدت رجلاه، فأمر النبي ﷺ أن يُغطى رأسه ويُجعل على رجليه الحشيش.

ودّعه النبي ﷺ بدمعة وقال:
"لقد رأيتك بمكة وما بها أرق منك حُلةً، وأحسن منك شعرًا، ثم أصبحت شعثًا بملابس بالية في سبيل الله".

────────────────────

✨ النهاية

رحل مصعب بن عمير،  
لكن بقيت المدينة شاهدة على بذرة زرعها.
"""
    },
    "بلال بن رباح": {
      "description": "مؤذن الرسول ﷺ وأحد الصابرين في الإسلام.",
      "biography":
      "بلال بن رباح رضي الله عنه، أول مؤذن للرسول ﷺ وصابر على التعذيب...",
      "battles": ["غزوة بدر", "أحد"],
      "attributes": ["الصبر", "الشجاعة", "الإخلاص"],
      "additionalInfo": "عرف بصوته الجميل في الأذان.",
      "day": """
تخيل رجلاً كان يُباع ويُشترى في أسواق مكة، جسده يحمل آثار السياط، لكن روحه كانت أعلى من القيود.

إنه بلال بن رباح رضي الله عنه، أول مؤذن في الإسلام.

────────────────────

🟦 مشهد الصمود (أحدٌ أحد)

في رمضاء مكة الملتهبة، كان أمية بن خلف يعذبه ليجبره على ترك الإسلام.

لكن بلالاً كان يردد:
"أحدٌ.. أحد"

حتى جاء أبو بكر الصديق فاشتراه وأعتقه لوجه الله.

────────────────────

🟦 مشهد العزة (فوق ظهر الكعبة)

في يوم فتح مكة، وقف بلال فوق الكعبة ورفع صوته بالأذان لأول مرة:
"الله أكبر... الله أكبر"

فأعلن أن الإسلام لا يفرق بين عربي وأعجمي، إلا بالتقوى.

────────────────────

🟦 مشهد الوفاء (الأذان الذي أبكى المدينة)

بعد وفاة النبي ﷺ، طلب منه الصحابة أن يؤذن مرة واحدة.

حين قال: "أشهد أن محمداً رسول الله"  
بكت المدينة كلها.

────────────────────

🟦 مشهد الرحيل

في لحظات احتضاره، قال بابتسامة:
"وا طرباه.. غداً نلقى الأحبة.. محمداً وحزبه"

────────────────────

✨ النهاية

رحل بلال بن رباح،  
وكان كما قال النبي ﷺ:
"يا بلال، إني سمعت دفّ نعليك في الجنة"
"""
    },
    "حذيفة بن اليمان": {
      "description": "خبير في أحوال المنافقين وصاحب العلم الغيبي.",
      "biography":
      "حذيفة بن اليمان رضي الله عنه، أعطاه الرسول ﷺ أمانة معرفة المنافقين...",
      "battles": ["غزوة بدر", "أحد", "الخندق"],
      "attributes": ["الحكيم", "الشجاع", "الذكي"],
      "additionalInfo": "سمي بذي اليمان لأنه صاحب ثقة الرسول ﷺ.",
      "day": """
تخيل رجلاً يمشي بين الناس بصمتٍ مهيب، يحمل في صدره أسراراً لو باح بها لزلزلت الأرض.

إنه حذيفة بن اليمان، "أمين سر رسول الله ﷺ".

────────────────────

🟦 مشهد الذكاء المختلف

كان الصحابة يسألون النبي ﷺ عن الخير، أما حذيفة فكان يسأله عن الشر.

كان يقول:
"كنت أسأله عن الشر مخافة أن يدركني".

────────────────────

🟦 مشهد ليلة الأحزاب

في ليلة شديدة البرد والمدينة محاصرة، تسلل حذيفة وسط الظلام حتى جلس قرب أبي سفيان دون أن يُكشف أمره.

عاد بالأخبار التي طمأنت المسلمين.

────────────────────

🟦 مشهد جامع المصحف

لاحظ اختلاف الناس في قراءة القرآن، فأسرع إلى عثمان بن عفان وقال:
"أدرك هذه الأمة قبل أن يختلفوا في كتابهم كما اختلفت الأمم السابقة".

────────────────────

🟦 مشهد الرحيل

في لحظات الموت قال:
"حبيبٌ جاء على فاقة... لا أفلح من ندم".

────────────────────

✨ النهاية

رحل حذيفة بن اليمان،  
فكان بحق: "بوصلة الأمان في عصر الاضطراب".
"""
    },
  };

  @override
  State<SahabiDetails> createState() => _SahabiDetailsState();
}

// ══════════════════════════════════════════════════════════
//  STATE
// ══════════════════════════════════════════════════════════
class _SahabiDetailsState extends State<SahabiDetails>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _orbRotate;
  late Animation<double>   _shimmer;

  final ScrollController _scroll = ScrollController();
  double _scrollOffset = 0;

  // ── PALETTE ───────────────────────────────────────────
  static const Color _bg        = Color(0xFF080D1A);
  static const Color _surface   = Color(0xFF0E1628);
  static const Color _gold      = Color(0xFFD4A853);
  static const Color _goldLight = Color(0xFFF0C97A);
  static const Color _teal      = Color(0xFF1ABC9C);
  static const Color _tealDark  = Color(0xFF148F77);
  static const Color _text      = Color(0xFFF0EAD6);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _purple    = Color(0xFF6C3483);
  static const Color _blue      = Color(0xFF1A3A5C);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _orbCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _orbRotate  = CurvedAnimation(parent: _orbCtrl,  curve: Curves.linear);
    _shimmer    = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);

    _entryCtrl.forward();
    _scroll.addListener(() => setState(() => _scrollOffset = _scroll.offset));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _shimmerCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          _buildBackground(),
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _entryFade,
                  child: SlideTransition(
                    position: _entrySlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 60),
                      child: Column(children: [
                        const SizedBox(height: 24),
                        _buildDescriptionBanner(),
                        const SizedBox(height: 20),
                        if (widget.biography.isNotEmpty) _buildBiographyCard(),
                        if (widget.battles.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildBattlesCard(),
                        ],
                        if (widget.attributes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildAttributesCard(),
                        ],
                        if (widget.additionalInfo.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                        ],
                        if (widget.day.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDayCard(),
                        ],
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildTopGradient(),
        ]),
      ),
    );
  }

  // ── BACKGROUND ────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _orbRotate,
      builder: (_, __) {
        final t = _orbRotate.value * 2 * math.pi;
        return Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, -0.4),
                radius: 1.4,
                colors: [Color(0xFF0A1628), _bg],
              ),
            ),
          ),
          CustomPaint(painter: _MeshPainter(), size: Size.infinite),
          _orb(-0.1 + 0.05 * math.sin(t),       -0.5, 280, _teal,   0.06),
          _orb(0.5  + 0.04 * math.cos(t * 0.7),  0.2, 200, _blue,   0.10),
          _orb(-0.3 + 0.03 * math.sin(t * 1.3),  0.7, 150, _gold,   0.05),
          _orb(0.2  + 0.04 * math.cos(t * 1.1), -0.2, 180, _purple, 0.04),
        ]);
      },
    );
  }

  Widget _orb(double x, double y, double size, Color color, double opacity) {
    return Positioned(
      left: MediaQuery.of(context).size.width  * (x + 0.5) - size / 2,
      top:  MediaQuery.of(context).size.height * (y + 0.5) - size / 2,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 100,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_bg, _bg.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────
  Widget _buildSliverAppBar() {
    final collapsed = _scrollOffset > 220;
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: collapsed ? _surface : Colors.transparent,
      elevation: collapsed ? 4 : 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _goldLight, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
        title: collapsed
            ? Text(widget.name,
            style: const TextStyle(
                color: _goldLight, fontSize: 17, fontWeight: FontWeight.bold))
            : null,
        centerTitle: true,
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF080D1A)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          // ── Avatar ──────────────────────────────────
          AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) {
              return Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.25 + 0.1 * _shimmer.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2A40), Color(0xFF0E1628)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.5 + 0.3 * _shimmer.value),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 24),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.name.isNotEmpty ? widget.name[0] : "؟",
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: _goldLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _text, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(widget.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _textMuted, fontSize: 13, height: 1.5)),
          ),
          const SizedBox(height: 16),
          // ── Quick Stats Row ──────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _statPill(Icons.military_tech_rounded,
                "${widget.battles.length} غزوة", _teal),
            const SizedBox(width: 10),
            _statPill(Icons.star_rounded,
                "${widget.attributes.length} صفة", _gold),
          ]),
        ]),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── DESCRIPTION BANNER ────────────────────────────────
  Widget _buildDescriptionBanner() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              _teal.withValues(alpha: 0.15 + 0.05 * _shimmer.value),
              _teal.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerRight, end: Alignment.centerLeft,
          ),
          border: Border.all(color: _teal.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: _teal.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -2),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Text(widget.description,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: _text, fontSize: 15, height: 1.6,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.15),
              border: Border.all(color: _teal.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.person_rounded, color: _teal, size: 22),
          ),
        ]),
      ),
    );
  }

  // ── BIOGRAPHY CARD ────────────────────────────────────
  Widget _buildBiographyCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("السيرة", Icons.menu_book_rounded, _gold),
        const SizedBox(height: 14),
        Text(widget.biography,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Color(0xFFCBC8BE), fontSize: 14.5, height: 1.8)),
      ]),
    );
  }

  // ── BATTLES CARD ──────────────────────────────────────
  Widget _buildBattlesCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("الغزوات والمعارك", Icons.shield_rounded, _teal),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.battles.map((b) => _chip(b, _teal)).toList(),
        ),
      ]),
    );
  }

  // ── ATTRIBUTES CARD ───────────────────────────────────
  Widget _buildAttributesCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("الصفات", Icons.auto_awesome_rounded, _gold),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.attributes.map((a) => _chip(a, _gold)).toList(),
        ),
      ]),
    );
  }

  // ── INFO CARD ─────────────────────────────────────────
  Widget _buildInfoCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("معلومة إضافية", Icons.lightbulb_rounded, _goldLight),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _gold.withValues(alpha: 0.07),
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
          ),
          child: Text(widget.additionalInfo,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: _goldLight, fontSize: 14.5, height: 1.7)),
        ),
      ]),
    );
  }

  // ── DAY CARD ──────────────────────────────────────────
  Widget _buildDayCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1020), Color(0xFF0D1A2E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(color: _gold.withValues(alpha: 0.07), blurRadius: 30, spreadRadius: 2),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              colors: [_gold.withValues(alpha: 0.18), _gold.withValues(alpha: 0.04)],
            ),
          ),
          child: Row(children: [
            const Icon(Icons.auto_stories_rounded, color: _goldLight, size: 24),
            const SizedBox(width: 12),
            const Text("يوم من حياته",
                style: TextStyle(
                    color: _goldLight, fontSize: 18,
                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _gold.withValues(alpha: 0.15),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: const Text("رواية",
                  style: TextStyle(color: _goldLight, fontSize: 11)),
            ),
          ]),
        ),
        Container(height: 1, color: _gold.withValues(alpha: 0.1)),
        // ── Content ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(22),
          child: Text(widget.day,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: _text, fontSize: 15, height: 2.0)),
        ),
      ]),
    );
  }

  // ── HELPERS ───────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.4)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  GLASS CARD
// ══════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0E1628),
        border: Border.all(color: const Color(0xFF1C2840), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MESH PAINTER
// ══════════════════════════════════════════════════════════
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFF1ABC9C).withValues(alpha: 0.025)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const s = 65.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p1);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p1);
    }
    final p2 = Paint()
      ..color = const Color(0xFFD4A853).withValues(alpha: 0.015)
      ..strokeWidth = 0.4;
    for (double i = -size.height; i < size.width + size.height; i += 90) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p2);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}