// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رفيقي';

  @override
  String get nav_companions => 'الصحابة';

  @override
  String get nav_battles => 'الغزوات';

  @override
  String get nav_prophet => 'الرسول';

  @override
  String get nav_guide => 'دليلي';

  @override
  String get nav_deeds => 'حسناتي';

  @override
  String get prayer_fajr => 'الفجر';

  @override
  String get prayer_sunrise => 'الشروق';

  @override
  String get prayer_dhuhr => 'الظهر';

  @override
  String get prayer_asr => 'العصر';

  @override
  String get prayer_maghrib => 'المغرب';

  @override
  String get prayer_isha => 'العشاء';

  @override
  String get alert_fajr => 'حان وقت صلاة الفجر\nفلا تتأخر في النهوض';

  @override
  String get alert_dhuhr => 'حان وقت صلاة الظهر\nأقم الصلاة لله';

  @override
  String get alert_asr => 'حان وقت صلاة العصر\nلا تفوِّتها';

  @override
  String get alert_maghrib => 'حان وقت صلاة المغرب\nبادر قبل أن يذهب الوقت';

  @override
  String get alert_isha => 'حان وقت صلاة العشاء\nأختم يومك بطاعة الله';

  @override
  String alert_now(String prayerName) {
    return 'حان وقت $prayerName';
  }

  @override
  String get next_prayer_title => '🕌 الصلاة القادمة';

  @override
  String get next_prayer_calculating => 'جاري الحساب...';

  @override
  String next_prayer_tomorrow_fajr(String time) {
    return 'فجر الغد · $time';
  }

  @override
  String get tooltip_quran => 'المصحف';

  @override
  String get tooltip_azkar => 'الأذكار';

  @override
  String get tooltip_next_prayer => 'الصلاة القادمة';

  @override
  String get tooltip_notifications => 'التنبيهات';

  @override
  String get tooltip_settings => 'الإعدادات';

  @override
  String get banner_isha_ended => 'انتهت صلاة العشاء';

  @override
  String banner_next_tomorrow_fajr(String time) {
    return 'الصلاة القادمة: فجر الغد الساعة $time';
  }

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_sections_label => 'الأقسام';

  @override
  String get settings_footer => 'صُنع بحب للمسلمين';

  @override
  String get settings_no_username_hint => 'اضغط تعديل لإضافة اسمك';

  @override
  String get settings_welcome_back => 'يسعدنا وجودك معنا ✨';

  @override
  String get settings_menu_rewards_title => 'المكافآت والصناديق';

  @override
  String get settings_menu_rewards_subtitle => 'نظام نقاطك والمكافآت';

  @override
  String get settings_menu_rewards_badge => 'جديد';

  @override
  String get settings_menu_quran_radio_title => 'إذاعة القرآن';

  @override
  String get settings_menu_quran_radio_subtitle => 'استمع للقرآن الكريم';

  @override
  String get settings_menu_quran_radio_badge => 'مباشر';

  @override
  String get settings_menu_prayer_schedule_title => 'جدول الصلاة';

  @override
  String get settings_menu_prayer_schedule_subtitle => 'مواقيت الصلاة اليومية';

  @override
  String get settings_menu_challenge_title => 'تحدي الصحابة';

  @override
  String get settings_menu_challenge_subtitle => 'اختبر معلوماتك الإسلامية';

  @override
  String get settings_menu_challenge_badge => 'جديد';

  @override
  String get settings_menu_prophets_title => 'قصص الأنبياء';

  @override
  String get settings_menu_prophets_subtitle => 'سير وقصص مباركة';

  @override
  String get profile_name_hint => 'اكتب اسمك...';

  @override
  String get profile_gender_label => 'النوع';

  @override
  String get profile_gender_male => 'ذكر';

  @override
  String get profile_gender_female => 'أنثى';

  @override
  String get profile_gender_male_label => 'أخ';

  @override
  String get profile_gender_female_label => 'أخت';

  @override
  String get profile_edit_button => 'تعديل';

  @override
  String get profile_close_button => 'إغلاق';

  @override
  String get greeting_male => 'أهلاً أخي';

  @override
  String get greeting_female => 'أهلاً أختي';

  @override
  String get greeting_neutral => 'أهلاً بيك';

  @override
  String get greeting_male_badge => 'أخ';

  @override
  String get greeting_female_badge => 'أخت';

  @override
  String get notif_title => 'إشعارات الأذكار';

  @override
  String get notif_subtitle => 'تحكم في تنبيهاتك اليومية';

  @override
  String get notif_permission_disabled =>
      'الإشعارات معطلة. يرجى تفعيل صلاحية الإشعارات لاستلام أذكارك المخصصة.';

  @override
  String get notif_enable_button => 'تفعيل';

  @override
  String get notif_empty => 'لا توجد إشعارات مجدولة بعد';

  @override
  String get notif_add_title => 'إضافة تذكير';

  @override
  String get notif_edit_title => 'تعديل التذكير';

  @override
  String get notif_select_ready_zekr => 'اختر ذكراً جاهزاً';

  @override
  String get notif_custom_zekr_label => 'أو اكتب ذكراً مخصصاً';

  @override
  String get notif_zekr_hint => 'اكتب ذكرك هنا...';

  @override
  String get notif_time_label => 'وقت التذكير';

  @override
  String get notif_days_label => 'أيام التذكير';

  @override
  String get notif_save => 'حفظ';

  @override
  String get notif_error_no_zekr => 'يرجى كتابة أو اختيار ذكر أولاً';

  @override
  String get notif_error_no_days => 'يرجى اختيار يوم واحد على الأقل';

  @override
  String get notif_default_title => '🤍 ذكر لطيف ليومك';

  @override
  String get day_sat => 'السبت';

  @override
  String get day_sat_short => 'سبت';

  @override
  String get day_sun => 'الأحد';

  @override
  String get day_sun_short => 'أحد';

  @override
  String get day_mon => 'الاثنين';

  @override
  String get day_mon_short => 'إثن';

  @override
  String get day_tue => 'الثلاثاء';

  @override
  String get day_tue_short => 'ثلا';

  @override
  String get day_wed => 'الأربعاء';

  @override
  String get day_wed_short => 'أرب';

  @override
  String get day_thu => 'الخميس';

  @override
  String get day_thu_short => 'خمس';

  @override
  String get day_fri => 'الجمعة';

  @override
  String get day_fri_short => 'جمع';

  @override
  String get tahdey_title => '✦  تحدي الصحابة  ✦';

  @override
  String tahdey_level_progress(String nextLevel, String current, String max) {
    return 'المستوى $nextLevel — $current/$max XP';
  }

  @override
  String tahdey_done_count(String done, String total) {
    return '$done/$total مهام';
  }

  @override
  String get tahdey_daily_tasks => 'مهام اليوم';

  @override
  String get tahdey_completed_all => 'أتممت كل المهام! 🎉';

  @override
  String get tahdey_reset_title => 'إعادة ضبط التقدم؟';

  @override
  String get tahdey_reset_body =>
      'سيتم مسح كل XP والمستويات والشارات بشكل دائم.';

  @override
  String get tahdey_reset_confirm => 'إعادة ضبط';

  @override
  String get tahdey_reset_cancel => 'إلغاء';

  @override
  String get tahdey_badge_beginner => '🥉 مبتدئ';

  @override
  String get tahdey_badge_strong => '🥈 قوي';

  @override
  String get tahdey_badge_legend => '🏆 أسطورة';

  @override
  String get companion_the_prophet => 'النبي ﷺ';

  @override
  String get companion_abu_bakr => 'أبو بكر الصديق';

  @override
  String get companion_umar => 'عمر بن الخطاب';

  @override
  String get companion_uthman => 'عثمان بن عفان';

  @override
  String get companion_ali => 'علي بن أبي طالب';

  @override
  String get companion_talha => 'طلحة بن عبيد الله';

  @override
  String get companion_zubayr => 'الزبير بن العوام';

  @override
  String get companion_abd_rahman => 'عبد الرحمن بن عوف';

  @override
  String get companion_saad => 'سعد بن أبي وقاص';

  @override
  String get companion_khalid => 'خالد بن الوليد';

  @override
  String get companion_bilal => 'بلال بن رباح';

  @override
  String get companion_salman => 'سلمان الفارسي';

  @override
  String get companion_anas => 'أنس بن مالك';

  @override
  String get task_night_prayer => 'قيام الليل';

  @override
  String get task_fajr_congregation => 'صلاة الفجر جماعة';

  @override
  String get task_morning_evening_azkar => 'أذكار الصباح والمساء';

  @override
  String get task_dawah => 'الدعوة إلى الله';

  @override
  String get task_charity => 'الصدقة';

  @override
  String get task_maintain_ties => 'صلة الرحم';

  @override
  String get task_fajr => 'صلاة الفجر';

  @override
  String get task_secret_charity => 'الصدقة السرية';

  @override
  String get task_defend_islam => 'الدفاع عن الإسلام';

  @override
  String get task_dhikr => 'ذكر الله';

  @override
  String get task_accompany_prophet => 'صحبة النبي ﷺ';

  @override
  String get task_justice => 'العدل بين الناس';

  @override
  String get task_care_for_people => 'تفقد الرعية';

  @override
  String get task_strength_of_truth => 'قوة الحق';

  @override
  String get task_establish_state => 'إقامة الدولة';

  @override
  String get task_quran_reading => 'قراءة القرآن';

  @override
  String get task_prepare_army => 'تجهيز جيش العسرة';

  @override
  String get task_modesty => 'الحياء';

  @override
  String get task_copy_quran => 'نسخ المصحف';

  @override
  String get task_knowledge_judiciary => 'العلم والقضاء';

  @override
  String get task_bravery => 'الشجاعة في المعارك';

  @override
  String get task_zuhd => 'الزهد والتقوى';

  @override
  String get task_support_truth => 'نصرة الحق';

  @override
  String get task_protect_prophet => 'حماية النبي ﷺ';

  @override
  String get task_generosity => 'الكرم والجود';

  @override
  String get task_support_muslims => 'نصرة المسلمين';

  @override
  String get task_jihad => 'الجهاد';

  @override
  String get task_halal_trade => 'التجارة الحلال';

  @override
  String get task_big_charity => 'الصدقة الكبيرة';

  @override
  String get task_support_muslims2 => 'دعم المسلمين';

  @override
  String get task_zuhd_in_wealth => 'الزهد في المال';

  @override
  String get task_dua => 'الدعاء';

  @override
  String get task_lead_armies => 'قيادة الجيوش';

  @override
  String get task_first_arrow => 'الرمية الأولى';

  @override
  String get task_lead_battles => 'قيادة المعارك';

  @override
  String get task_victories => 'الانتصارات';

  @override
  String get task_adhan => 'رفع الأذان';

  @override
  String get task_patience_torture => 'الصبر على التعذيب';

  @override
  String get task_steadfast_islam => 'الثبات على الإسلام';

  @override
  String get task_seeking_knowledge => 'طلب العلم';

  @override
  String get task_wisdom => 'الحكمة';

  @override
  String get task_digging_trench => 'حفر الخندق';

  @override
  String get task_serve_prophet => 'خدمة النبي ﷺ';

  @override
  String get task_preserve_hadith => 'حفظ الحديث';

  @override
  String get task_transmit_sunnah => 'نقل السنة';

  @override
  String get task_prayer => 'الصلاة';

  @override
  String get task_support_religion => 'نصرة الدين';

  @override
  String get task_courage => 'الشجاعة';
}
