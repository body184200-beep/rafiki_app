import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// The title of the application
  ///
  /// In ar, this message translates to:
  /// **'رفيقي'**
  String get appTitle;

  /// No description provided for @nav_companions.
  ///
  /// In ar, this message translates to:
  /// **'الصحابة'**
  String get nav_companions;

  /// No description provided for @nav_battles.
  ///
  /// In ar, this message translates to:
  /// **'الغزوات'**
  String get nav_battles;

  /// No description provided for @nav_prophet.
  ///
  /// In ar, this message translates to:
  /// **'الرسول'**
  String get nav_prophet;

  /// No description provided for @nav_guide.
  ///
  /// In ar, this message translates to:
  /// **'دليلي'**
  String get nav_guide;

  /// No description provided for @nav_deeds.
  ///
  /// In ar, this message translates to:
  /// **'حسناتي'**
  String get nav_deeds;

  /// No description provided for @prayer_fajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayer_fajr;

  /// No description provided for @prayer_sunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayer_sunrise;

  /// No description provided for @prayer_dhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayer_dhuhr;

  /// No description provided for @prayer_asr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayer_asr;

  /// No description provided for @prayer_maghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayer_maghrib;

  /// No description provided for @prayer_isha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayer_isha;

  /// No description provided for @alert_fajr.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة الفجر\nفلا تتأخر في النهوض'**
  String get alert_fajr;

  /// No description provided for @alert_dhuhr.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة الظهر\nأقم الصلاة لله'**
  String get alert_dhuhr;

  /// No description provided for @alert_asr.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة العصر\nلا تفوِّتها'**
  String get alert_asr;

  /// No description provided for @alert_maghrib.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة المغرب\nبادر قبل أن يذهب الوقت'**
  String get alert_maghrib;

  /// No description provided for @alert_isha.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة العشاء\nأختم يومك بطاعة الله'**
  String get alert_isha;

  /// No description provided for @alert_now.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت {prayerName}'**
  String alert_now(String prayerName);

  /// No description provided for @next_prayer_title.
  ///
  /// In ar, this message translates to:
  /// **'🕌 الصلاة القادمة'**
  String get next_prayer_title;

  /// No description provided for @next_prayer_calculating.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحساب...'**
  String get next_prayer_calculating;

  /// No description provided for @next_prayer_tomorrow_fajr.
  ///
  /// In ar, this message translates to:
  /// **'فجر الغد · {time}'**
  String next_prayer_tomorrow_fajr(String time);

  /// No description provided for @tooltip_quran.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get tooltip_quran;

  /// No description provided for @tooltip_azkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get tooltip_azkar;

  /// No description provided for @tooltip_next_prayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get tooltip_next_prayer;

  /// No description provided for @tooltip_notifications.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get tooltip_notifications;

  /// No description provided for @tooltip_settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tooltip_settings;

  /// No description provided for @banner_isha_ended.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاة العشاء'**
  String get banner_isha_ended;

  /// No description provided for @banner_next_tomorrow_fajr.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة: فجر الغد الساعة {time}'**
  String banner_next_tomorrow_fajr(String time);

  /// No description provided for @settings_title.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings_title;

  /// No description provided for @settings_sections_label.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get settings_sections_label;

  /// No description provided for @settings_footer.
  ///
  /// In ar, this message translates to:
  /// **'صُنع بحب للمسلمين'**
  String get settings_footer;

  /// No description provided for @settings_no_username_hint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تعديل لإضافة اسمك'**
  String get settings_no_username_hint;

  /// No description provided for @settings_welcome_back.
  ///
  /// In ar, this message translates to:
  /// **'يسعدنا وجودك معنا ✨'**
  String get settings_welcome_back;

  /// No description provided for @settings_menu_rewards_title.
  ///
  /// In ar, this message translates to:
  /// **'المكافآت والصناديق'**
  String get settings_menu_rewards_title;

  /// No description provided for @settings_menu_rewards_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'نظام نقاطك والمكافآت'**
  String get settings_menu_rewards_subtitle;

  /// No description provided for @settings_menu_rewards_badge.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get settings_menu_rewards_badge;

  /// No description provided for @settings_menu_quran_radio_title.
  ///
  /// In ar, this message translates to:
  /// **'إذاعة القرآن'**
  String get settings_menu_quran_radio_title;

  /// No description provided for @settings_menu_quran_radio_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'استمع للقرآن الكريم'**
  String get settings_menu_quran_radio_subtitle;

  /// No description provided for @settings_menu_quran_radio_badge.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get settings_menu_quran_radio_badge;

  /// No description provided for @settings_menu_prayer_schedule_title.
  ///
  /// In ar, this message translates to:
  /// **'جدول الصلاة'**
  String get settings_menu_prayer_schedule_title;

  /// No description provided for @settings_menu_prayer_schedule_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة اليومية'**
  String get settings_menu_prayer_schedule_subtitle;

  /// No description provided for @settings_menu_challenge_title.
  ///
  /// In ar, this message translates to:
  /// **'تحدي الصحابة'**
  String get settings_menu_challenge_title;

  /// No description provided for @settings_menu_challenge_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختبر معلوماتك الإسلامية'**
  String get settings_menu_challenge_subtitle;

  /// No description provided for @settings_menu_challenge_badge.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get settings_menu_challenge_badge;

  /// No description provided for @settings_menu_prophets_title.
  ///
  /// In ar, this message translates to:
  /// **'قصص الأنبياء'**
  String get settings_menu_prophets_title;

  /// No description provided for @settings_menu_prophets_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'سير وقصص مباركة'**
  String get settings_menu_prophets_subtitle;

  /// No description provided for @profile_name_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك...'**
  String get profile_name_hint;

  /// No description provided for @profile_gender_label.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get profile_gender_label;

  /// No description provided for @profile_gender_male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get profile_gender_male;

  /// No description provided for @profile_gender_female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get profile_gender_female;

  /// No description provided for @profile_gender_male_label.
  ///
  /// In ar, this message translates to:
  /// **'أخ'**
  String get profile_gender_male_label;

  /// No description provided for @profile_gender_female_label.
  ///
  /// In ar, this message translates to:
  /// **'أخت'**
  String get profile_gender_female_label;

  /// No description provided for @profile_edit_button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get profile_edit_button;

  /// No description provided for @profile_close_button.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get profile_close_button;

  /// No description provided for @greeting_male.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً أخي'**
  String get greeting_male;

  /// No description provided for @greeting_female.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً أختي'**
  String get greeting_female;

  /// No description provided for @greeting_neutral.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بيك'**
  String get greeting_neutral;

  /// No description provided for @greeting_male_badge.
  ///
  /// In ar, this message translates to:
  /// **'أخ'**
  String get greeting_male_badge;

  /// No description provided for @greeting_female_badge.
  ///
  /// In ar, this message translates to:
  /// **'أخت'**
  String get greeting_female_badge;

  /// No description provided for @notif_title.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الأذكار'**
  String get notif_title;

  /// No description provided for @notif_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحكم في تنبيهاتك اليومية'**
  String get notif_subtitle;

  /// No description provided for @notif_permission_disabled.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات معطلة. يرجى تفعيل صلاحية الإشعارات لاستلام أذكارك المخصصة.'**
  String get notif_permission_disabled;

  /// No description provided for @notif_enable_button.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get notif_enable_button;

  /// No description provided for @notif_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات مجدولة بعد'**
  String get notif_empty;

  /// No description provided for @notif_add_title.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تذكير'**
  String get notif_add_title;

  /// No description provided for @notif_edit_title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التذكير'**
  String get notif_edit_title;

  /// No description provided for @notif_select_ready_zekr.
  ///
  /// In ar, this message translates to:
  /// **'اختر ذكراً جاهزاً'**
  String get notif_select_ready_zekr;

  /// No description provided for @notif_custom_zekr_label.
  ///
  /// In ar, this message translates to:
  /// **'أو اكتب ذكراً مخصصاً'**
  String get notif_custom_zekr_label;

  /// No description provided for @notif_zekr_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ذكرك هنا...'**
  String get notif_zekr_hint;

  /// No description provided for @notif_time_label.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get notif_time_label;

  /// No description provided for @notif_days_label.
  ///
  /// In ar, this message translates to:
  /// **'أيام التذكير'**
  String get notif_days_label;

  /// No description provided for @notif_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get notif_save;

  /// No description provided for @notif_error_no_zekr.
  ///
  /// In ar, this message translates to:
  /// **'يرجى كتابة أو اختيار ذكر أولاً'**
  String get notif_error_no_zekr;

  /// No description provided for @notif_error_no_days.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار يوم واحد على الأقل'**
  String get notif_error_no_days;

  /// No description provided for @notif_default_title.
  ///
  /// In ar, this message translates to:
  /// **'🤍 ذكر لطيف ليومك'**
  String get notif_default_title;

  /// No description provided for @day_sat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get day_sat;

  /// No description provided for @day_sat_short.
  ///
  /// In ar, this message translates to:
  /// **'سبت'**
  String get day_sat_short;

  /// No description provided for @day_sun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get day_sun;

  /// No description provided for @day_sun_short.
  ///
  /// In ar, this message translates to:
  /// **'أحد'**
  String get day_sun_short;

  /// No description provided for @day_mon.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get day_mon;

  /// No description provided for @day_mon_short.
  ///
  /// In ar, this message translates to:
  /// **'إثن'**
  String get day_mon_short;

  /// No description provided for @day_tue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get day_tue;

  /// No description provided for @day_tue_short.
  ///
  /// In ar, this message translates to:
  /// **'ثلا'**
  String get day_tue_short;

  /// No description provided for @day_wed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get day_wed;

  /// No description provided for @day_wed_short.
  ///
  /// In ar, this message translates to:
  /// **'أرب'**
  String get day_wed_short;

  /// No description provided for @day_thu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get day_thu;

  /// No description provided for @day_thu_short.
  ///
  /// In ar, this message translates to:
  /// **'خمس'**
  String get day_thu_short;

  /// No description provided for @day_fri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get day_fri;

  /// No description provided for @day_fri_short.
  ///
  /// In ar, this message translates to:
  /// **'جمع'**
  String get day_fri_short;

  /// No description provided for @tahdey_title.
  ///
  /// In ar, this message translates to:
  /// **'✦  تحدي الصحابة  ✦'**
  String get tahdey_title;

  /// No description provided for @tahdey_level_progress.
  ///
  /// In ar, this message translates to:
  /// **'المستوى {nextLevel} — {current}/{max} XP'**
  String tahdey_level_progress(String nextLevel, String current, String max);

  /// No description provided for @tahdey_done_count.
  ///
  /// In ar, this message translates to:
  /// **'{done}/{total} مهام'**
  String tahdey_done_count(String done, String total);

  /// No description provided for @tahdey_daily_tasks.
  ///
  /// In ar, this message translates to:
  /// **'مهام اليوم'**
  String get tahdey_daily_tasks;

  /// No description provided for @tahdey_completed_all.
  ///
  /// In ar, this message translates to:
  /// **'أتممت كل المهام! 🎉'**
  String get tahdey_completed_all;

  /// No description provided for @tahdey_reset_title.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط التقدم؟'**
  String get tahdey_reset_title;

  /// No description provided for @tahdey_reset_body.
  ///
  /// In ar, this message translates to:
  /// **'سيتم مسح كل XP والمستويات والشارات بشكل دائم.'**
  String get tahdey_reset_body;

  /// No description provided for @tahdey_reset_confirm.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط'**
  String get tahdey_reset_confirm;

  /// No description provided for @tahdey_reset_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get tahdey_reset_cancel;

  /// No description provided for @tahdey_badge_beginner.
  ///
  /// In ar, this message translates to:
  /// **'🥉 مبتدئ'**
  String get tahdey_badge_beginner;

  /// No description provided for @tahdey_badge_strong.
  ///
  /// In ar, this message translates to:
  /// **'🥈 قوي'**
  String get tahdey_badge_strong;

  /// No description provided for @tahdey_badge_legend.
  ///
  /// In ar, this message translates to:
  /// **'🏆 أسطورة'**
  String get tahdey_badge_legend;

  /// No description provided for @companion_the_prophet.
  ///
  /// In ar, this message translates to:
  /// **'النبي ﷺ'**
  String get companion_the_prophet;

  /// No description provided for @companion_abu_bakr.
  ///
  /// In ar, this message translates to:
  /// **'أبو بكر الصديق'**
  String get companion_abu_bakr;

  /// No description provided for @companion_umar.
  ///
  /// In ar, this message translates to:
  /// **'عمر بن الخطاب'**
  String get companion_umar;

  /// No description provided for @companion_uthman.
  ///
  /// In ar, this message translates to:
  /// **'عثمان بن عفان'**
  String get companion_uthman;

  /// No description provided for @companion_ali.
  ///
  /// In ar, this message translates to:
  /// **'علي بن أبي طالب'**
  String get companion_ali;

  /// No description provided for @companion_talha.
  ///
  /// In ar, this message translates to:
  /// **'طلحة بن عبيد الله'**
  String get companion_talha;

  /// No description provided for @companion_zubayr.
  ///
  /// In ar, this message translates to:
  /// **'الزبير بن العوام'**
  String get companion_zubayr;

  /// No description provided for @companion_abd_rahman.
  ///
  /// In ar, this message translates to:
  /// **'عبد الرحمن بن عوف'**
  String get companion_abd_rahman;

  /// No description provided for @companion_saad.
  ///
  /// In ar, this message translates to:
  /// **'سعد بن أبي وقاص'**
  String get companion_saad;

  /// No description provided for @companion_khalid.
  ///
  /// In ar, this message translates to:
  /// **'خالد بن الوليد'**
  String get companion_khalid;

  /// No description provided for @companion_bilal.
  ///
  /// In ar, this message translates to:
  /// **'بلال بن رباح'**
  String get companion_bilal;

  /// No description provided for @companion_salman.
  ///
  /// In ar, this message translates to:
  /// **'سلمان الفارسي'**
  String get companion_salman;

  /// No description provided for @companion_anas.
  ///
  /// In ar, this message translates to:
  /// **'أنس بن مالك'**
  String get companion_anas;

  /// No description provided for @task_night_prayer.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل'**
  String get task_night_prayer;

  /// No description provided for @task_fajr_congregation.
  ///
  /// In ar, this message translates to:
  /// **'صلاة الفجر جماعة'**
  String get task_fajr_congregation;

  /// No description provided for @task_morning_evening_azkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح والمساء'**
  String get task_morning_evening_azkar;

  /// No description provided for @task_dawah.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة إلى الله'**
  String get task_dawah;

  /// No description provided for @task_charity.
  ///
  /// In ar, this message translates to:
  /// **'الصدقة'**
  String get task_charity;

  /// No description provided for @task_maintain_ties.
  ///
  /// In ar, this message translates to:
  /// **'صلة الرحم'**
  String get task_maintain_ties;

  /// No description provided for @task_fajr.
  ///
  /// In ar, this message translates to:
  /// **'صلاة الفجر'**
  String get task_fajr;

  /// No description provided for @task_secret_charity.
  ///
  /// In ar, this message translates to:
  /// **'الصدقة السرية'**
  String get task_secret_charity;

  /// No description provided for @task_defend_islam.
  ///
  /// In ar, this message translates to:
  /// **'الدفاع عن الإسلام'**
  String get task_defend_islam;

  /// No description provided for @task_dhikr.
  ///
  /// In ar, this message translates to:
  /// **'ذكر الله'**
  String get task_dhikr;

  /// No description provided for @task_accompany_prophet.
  ///
  /// In ar, this message translates to:
  /// **'صحبة النبي ﷺ'**
  String get task_accompany_prophet;

  /// No description provided for @task_justice.
  ///
  /// In ar, this message translates to:
  /// **'العدل بين الناس'**
  String get task_justice;

  /// No description provided for @task_care_for_people.
  ///
  /// In ar, this message translates to:
  /// **'تفقد الرعية'**
  String get task_care_for_people;

  /// No description provided for @task_strength_of_truth.
  ///
  /// In ar, this message translates to:
  /// **'قوة الحق'**
  String get task_strength_of_truth;

  /// No description provided for @task_establish_state.
  ///
  /// In ar, this message translates to:
  /// **'إقامة الدولة'**
  String get task_establish_state;

  /// No description provided for @task_quran_reading.
  ///
  /// In ar, this message translates to:
  /// **'قراءة القرآن'**
  String get task_quran_reading;

  /// No description provided for @task_prepare_army.
  ///
  /// In ar, this message translates to:
  /// **'تجهيز جيش العسرة'**
  String get task_prepare_army;

  /// No description provided for @task_modesty.
  ///
  /// In ar, this message translates to:
  /// **'الحياء'**
  String get task_modesty;

  /// No description provided for @task_copy_quran.
  ///
  /// In ar, this message translates to:
  /// **'نسخ المصحف'**
  String get task_copy_quran;

  /// No description provided for @task_knowledge_judiciary.
  ///
  /// In ar, this message translates to:
  /// **'العلم والقضاء'**
  String get task_knowledge_judiciary;

  /// No description provided for @task_bravery.
  ///
  /// In ar, this message translates to:
  /// **'الشجاعة في المعارك'**
  String get task_bravery;

  /// No description provided for @task_zuhd.
  ///
  /// In ar, this message translates to:
  /// **'الزهد والتقوى'**
  String get task_zuhd;

  /// No description provided for @task_support_truth.
  ///
  /// In ar, this message translates to:
  /// **'نصرة الحق'**
  String get task_support_truth;

  /// No description provided for @task_protect_prophet.
  ///
  /// In ar, this message translates to:
  /// **'حماية النبي ﷺ'**
  String get task_protect_prophet;

  /// No description provided for @task_generosity.
  ///
  /// In ar, this message translates to:
  /// **'الكرم والجود'**
  String get task_generosity;

  /// No description provided for @task_support_muslims.
  ///
  /// In ar, this message translates to:
  /// **'نصرة المسلمين'**
  String get task_support_muslims;

  /// No description provided for @task_jihad.
  ///
  /// In ar, this message translates to:
  /// **'الجهاد'**
  String get task_jihad;

  /// No description provided for @task_halal_trade.
  ///
  /// In ar, this message translates to:
  /// **'التجارة الحلال'**
  String get task_halal_trade;

  /// No description provided for @task_big_charity.
  ///
  /// In ar, this message translates to:
  /// **'الصدقة الكبيرة'**
  String get task_big_charity;

  /// No description provided for @task_support_muslims2.
  ///
  /// In ar, this message translates to:
  /// **'دعم المسلمين'**
  String get task_support_muslims2;

  /// No description provided for @task_zuhd_in_wealth.
  ///
  /// In ar, this message translates to:
  /// **'الزهد في المال'**
  String get task_zuhd_in_wealth;

  /// No description provided for @task_dua.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء'**
  String get task_dua;

  /// No description provided for @task_lead_armies.
  ///
  /// In ar, this message translates to:
  /// **'قيادة الجيوش'**
  String get task_lead_armies;

  /// No description provided for @task_first_arrow.
  ///
  /// In ar, this message translates to:
  /// **'الرمية الأولى'**
  String get task_first_arrow;

  /// No description provided for @task_lead_battles.
  ///
  /// In ar, this message translates to:
  /// **'قيادة المعارك'**
  String get task_lead_battles;

  /// No description provided for @task_victories.
  ///
  /// In ar, this message translates to:
  /// **'الانتصارات'**
  String get task_victories;

  /// No description provided for @task_adhan.
  ///
  /// In ar, this message translates to:
  /// **'رفع الأذان'**
  String get task_adhan;

  /// No description provided for @task_patience_torture.
  ///
  /// In ar, this message translates to:
  /// **'الصبر على التعذيب'**
  String get task_patience_torture;

  /// No description provided for @task_steadfast_islam.
  ///
  /// In ar, this message translates to:
  /// **'الثبات على الإسلام'**
  String get task_steadfast_islam;

  /// No description provided for @task_seeking_knowledge.
  ///
  /// In ar, this message translates to:
  /// **'طلب العلم'**
  String get task_seeking_knowledge;

  /// No description provided for @task_wisdom.
  ///
  /// In ar, this message translates to:
  /// **'الحكمة'**
  String get task_wisdom;

  /// No description provided for @task_digging_trench.
  ///
  /// In ar, this message translates to:
  /// **'حفر الخندق'**
  String get task_digging_trench;

  /// No description provided for @task_serve_prophet.
  ///
  /// In ar, this message translates to:
  /// **'خدمة النبي ﷺ'**
  String get task_serve_prophet;

  /// No description provided for @task_preserve_hadith.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الحديث'**
  String get task_preserve_hadith;

  /// No description provided for @task_transmit_sunnah.
  ///
  /// In ar, this message translates to:
  /// **'نقل السنة'**
  String get task_transmit_sunnah;

  /// No description provided for @task_prayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get task_prayer;

  /// No description provided for @task_support_religion.
  ///
  /// In ar, this message translates to:
  /// **'نصرة الدين'**
  String get task_support_religion;

  /// No description provided for @task_courage.
  ///
  /// In ar, this message translates to:
  /// **'الشجاعة'**
  String get task_courage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
