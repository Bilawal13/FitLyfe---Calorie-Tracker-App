import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class LanguageProvider extends ChangeNotifier {
  static const _langKey = 'app_language';

  // Default is 'en' (English)
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  Locale get locale => Locale(_currentLanguage);
  bool get isUrdu => _currentLanguage == 'ur';
  bool get isArabic => _currentLanguage == 'ar';
  bool get isRTL => _currentLanguage == 'ur' || _currentLanguage == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_langKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_currentLanguage == code) return;
    _currentLanguage = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
    notifyListeners();
    // Reschedule notifications in the newly selected language
    NotificationService().rescheduleAll(code);
  }

  String t(String key) {
    return AppTranslations.translate(key, _currentLanguage);
  }

  String getRankTitle(int level) {
    return AppTranslations.getRankTitle(level, _currentLanguage);
  }

  String getRankReq(int level) {
    return AppTranslations.getRankReq(level, _currentLanguage);
  }

  String formatDate(DateTime d) {
    return AppTranslations.formatDate(d, _currentLanguage);
  }
}

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // ── Common & Generic ──
    'app_title': {
      'en': 'Fit Lyfe',
      'ur': 'فٹ لائف',
      'ar': 'فت لايف',
    },
    // ── Notifications ──
    'notifications_title': {
      'en': 'Daily Reminders',
      'ur': 'روزانہ کی یاد دہانی',
      'ar': 'التذكيرات اليومية',
    },
    'notifications_subtitle': {
      'en': 'Set reminders to log your meals and drink water',
      'ur': 'کھانا درج کرنے اور پانی پینے کی یاد دہانی سیٹ کریں',
      'ar': 'اضبط تذكيرات لتسجيل وجباتك وشرب الماء',
    },
    'meal_reminder_label': {
      'en': 'Meal Reminder',
      'ur': 'کھانے کی یاد دہانی',
      'ar': 'تذكير الوجبات',
    },
    'meal_reminder_desc': {
      'en': 'Get reminded to finish logging your meals for the day',
      'ur': 'آج کا کھانا مکمل لاگ کرنے کی یاد دہانی حاصل کریں',
      'ar': 'تذكير لإنهاء تسجيل وجباتك اليومية',
    },
    'water_reminder_label': {
      'en': 'Water Reminder',
      'ur': 'پانی کی یاد دہانی',
      'ar': 'تذكير شرب الماء',
    },
    'water_reminder_desc': {
      'en': 'Stay hydrated with a mid-day drinking reminder',
      'ur': 'دوپہر کے وقت پانی پینے کی یاد دہانی کے ساتھ ہائیڈریٹ رہیں',
      'ar': 'حافظ على رطوبتك مع تذكير منتصف اليوم لشرب الماء',
    },
    'change_time': {
      'en': 'Change Time',
      'ur': 'وقت تبدیل کریں',
      'ar': 'تغيير الوقت',
    },
    'reminders_updated': {
      'en': 'Reminders updated successfully!',
      'ur': 'یاد دہانیاں کامیابی کے ساتھ اپ ڈیٹ ہو گئیں!',
      'ar': 'تم تحديث التذكيرات بنجاح!',
    },
    'meal_notif_title': {
      'en': '🔥 Keep Your Streak Alive!',
      'ur': '🔥 اپنا اسٹریک برقرار رکھیں!',
      'ar': '🔥 حافظ على استمرارية سلسلتك!',
    },
    'meal_notif_body': {
      'en': 'Don\'t forget to log your meals and finish today in Fit Lyfe!',
      'ur': 'فٹ لائف میں اپنے کھانے درج کرنا اور آج کا دن مکمل کرنا نہ بھولیں!',
      'ar': 'لا تنسَ تسجيل وجباتك وإنهاء يومك في فت لايف!',
    },
    'water_notif_title': {
      'en': '💧 Hydration Check!',
      'ur': '💧 پانی پینے کا وقت!',
      'ar': '💧 وقت شرب الماء!',
    },
    'water_notif_body': {
      'en': 'Drink a fresh glass of water to hit your daily hydration goal!',
      'ur': 'اپنا روزانہ کا ہدف پورا کرنے کے لیے ایک تازہ گلاس پانی پئیں!',
      'ar': 'اشرب كوباً من الماء العذب للوصول إلى هدفك اليومي من الترطيب!',
    },
    'app_tagline': {
      'en': 'Track your nutrition seamlessly',
      'ur': 'اپنی غذائیت اور کیلوریز کو آسانی سے ٹریک کریں',
      'ar': 'تتبع تغذيتك وسعراتك الحرارية بكل سهولة',
    },
    'save': {
      'en': 'Save',
      'ur': 'محفوظ کریں',
      'ar': 'حفظ',
    },
    'cancel': {
      'en': 'Cancel',
      'ur': 'منسوخ کریں',
      'ar': 'إلغاء',
    },
    'delete': {
      'en': 'Delete',
      'ur': 'حذف کریں',
      'ar': 'حذف',
    },
    'close': {
      'en': 'Close',
      'ur': 'بند کریں',
      'ar': 'إغلاق',
    },
    'edit': {
      'en': 'Edit',
      'ur': 'ترمیم کریں',
      'ar': 'تعديل',
    },
    'done': {
      'en': 'Done',
      'ur': 'مکمل',
      'ar': 'تم',
    },
    'calories': {
      'en': 'Calories',
      'ur': 'کیلوریز',
      'ar': 'سعرات',
    },
    'protein': {
      'en': 'Protein',
      'ur': 'پروٹین',
      'ar': 'بروتين',
    },
    'carbs': {
      'en': 'Carbs',
      'ur': 'کاربس',
      'ar': 'كربوهيدرات',
    },
    'fat': {
      'en': 'Fat',
      'ur': 'چکنائی',
      'ar': 'دهون',
    },
    'fiber': {
      'en': 'Fiber',
      'ur': 'فائبر',
      'ar': 'ألياف',
    },
    'sodium': {
      'en': 'Sodium',
      'ur': 'سوڈیم',
      'ar': 'صوديوم',
    },
    'net_carbs': {
      'en': 'Net Carbs',
      'ur': 'خالص کاربس',
      'ar': 'صافي الكارب',
    },
    'water': {
      'en': 'Water',
      'ur': 'پانی',
      'ar': 'ماء',
    },

    // ── Bottom Navigation Tabs ──
    'tab_home': {
      'en': 'Home',
      'ur': 'ہوم',
      'ar': 'الرئيسية',
    },
    'tab_meals': {
      'en': 'Meals',
      'ur': 'کھانے',
      'ar': 'الوجبات',
    },
    'tab_logs': {
      'en': 'Logs',
      'ur': 'لاگز',
      'ar': 'السجلات',
    },
    'tab_feedback': {
      'en': 'Feedback',
      'ur': 'فیڈبیک',
      'ar': 'التقييم',
    },

    // ── Settings Screen ──
    'settings': {
      'en': 'Settings',
      'ur': 'ترتیبات',
      'ar': 'الإعدادات',
    },
    'appearance': {
      'en': 'Appearance',
      'ur': 'ظاہری شکل',
      'ar': 'المظهر',
    },
    'system_default': {
      'en': 'System default',
      'ur': 'سسٹم کا طے شدہ',
      'ar': 'تلقائي النظام',
    },
    'system_default_subtitle': {
      'en': 'Follows your device\'s theme',
      'ur': 'آپ کے ڈیوائس کی تھیم کے مطابق',
      'ar': 'يتبع إعدادات جهازك',
    },
    'light': {
      'en': 'Light',
      'ur': 'لائٹ',
      'ar': 'فاتح',
    },
    'light_subtitle': {
      'en': 'Always use light theme',
      'ur': 'ہمیشہ لائٹ تھیم استعمال کریں',
      'ar': 'استخدام المظهر الفاتح دائماً',
    },
    'dark': {
      'en': 'Dark',
      'ur': 'ڈارک',
      'ar': 'داكن',
    },
    'dark_subtitle': {
      'en': 'Always use dark theme',
      'ur': 'ہمیشہ ڈارک تھیم استعمال کریں',
      'ar': 'استخدام المظهر الداكن دائماً',
    },
    'accent_color': {
      'en': 'Accent Color',
      'ur': 'لہجے کا رنگ',
      'ar': 'اللون الأساسي',
    },
    'calorie_goal': {
      'en': 'Calorie Goal',
      'ur': 'کیلوری کا ہدف',
      'ar': 'هدف السعرات',
    },
    'set_daily_target': {
      'en': 'Set your daily target',
      'ur': 'اپنا روزانہ کا ہدف مقرر کریں',
      'ar': 'حدد هدفك اليومي',
    },
    'sound_effects': {
      'en': 'Sound Effects',
      'ur': 'آواز کے اثرات',
      'ar': 'المؤثرات الصوتية',
    },
    'play_sounds_desc': {
      'en': 'Play subtle sounds on buttons, adds, and deletes',
      'ur': 'بٹن، کھانا شامل اور حذف کرنے پر دھیمی آواز چلائیں',
      'ar': 'تشغيل أصوات هادئة عند الضغط والإضافة والحذف',
    },
    'smart_goal_calculator': {
      'en': 'Smart Goal Calculator',
      'ur': 'اسمارٹ گول کیلکولیٹر',
      'ar': 'حاسبة الأهداف الذكية',
    },
    'smart_goal_desc': {
      'en': 'Calculate maintenance calories, BMR & surplus/deficit',
      'ur': 'اپنے جسم کے مطابق روزانہ کی ضروری کیلوریز کا حساب لگائیں',
      'ar': 'احسب سعرات الثبات ومعدل الأيض والعجز/الفائض',
    },
    'reset_today_data': {
      'en': 'Reset Today\'s Data',
      'ur': 'آج کا ڈیٹا ری سیٹ کریں',
      'ar': 'إعادة ضبط بيانات اليوم',
    },
    'reset_today_desc': {
      'en': 'Clear all logged meals and water for today',
      'ur': 'آج کے تمام درج شدہ کھانے اور پانی صاف کریں',
      'ar': 'مسح جميع الوجبات والماء المسجلة لهذا اليوم',
    },
    'clear_all_data': {
      'en': 'Clear All App Data',
      'ur': 'تمام ایپ ڈیٹا صاف کریں',
      'ar': 'مسح كافة بيانات التطبيق',
    },
    'clear_all_desc': {
      'en': 'Delete all saved meals and today\'s progress',
      'ur': 'تمام محفوظ کردہ کھانے اور آج کی پیش رفت حذف کریں',
      'ar': 'حذف الوجبات المحفوظة وسجل اليوم بالكامل',
    },
    'language': {
      'en': 'Language',
      'ur': 'زبان',
      'ar': 'اللغة',
    },
    'select_language': {
      'en': 'Select your preferred language',
      'ur': 'اپنی پسندیدہ زبان منتخب کریں',
      'ar': 'اختر لغتك المفضلة',
    },
    'english': {
      'en': 'English',
      'ur': 'English (انگریزی)',
      'ar': 'English (الإنجليزية)',
    },
    'urdu': {
      'en': 'Urdu',
      'ur': 'اردو (Urdu)',
      'ar': 'الأردية (Urdu)',
    },
    'arabic': {
      'en': 'Arabic',
      'ur': 'عربی (Arabic)',
      'ar': 'العربية (Arabic)',
    },
    'lang_english': {
      'en': 'English',
      'ur': 'انگریزی (English)',
      'ar': 'الإنجليزية (English)',
    },
    'lang_urdu': {
      'en': 'Urdu',
      'ur': 'اردو (Urdu)',
      'ar': 'الأردية (Urdu)',
    },
    'lang_arabic': {
      'en': 'Arabic',
      'ur': 'عربی (Arabic)',
      'ar': 'العربية (Arabic)',
    },
    'language_changed_to_en': {
      'en': 'Language switched to English',
      'ur': 'زبان انگریزی میں تبدیل کر دی گئی ہے',
      'ar': 'تم تغيير اللغة إلى الإنجليزية',
    },
    'language_changed_to_ur': {
      'en': 'Language switched to Urdu',
      'ur': 'زبان اردو میں تبدیل کر دی گئی ہے',
      'ar': 'تم تغيير اللغة إلى الأردية',
    },
    'language_changed_to_ar': {
      'en': 'Language switched to Arabic',
      'ur': 'زبان عربی میں تبدیل کر دی گئی ہے',
      'ar': 'تم تغيير اللغة إلى العربية',
    },
    'app_language': {
      'en': 'App Language',
      'ur': 'ایپ کی زبان',
      'ar': 'لغة التطبيق',
    },
    'language_subtitle': {
      'en': 'Select between English, Urdu, or Arabic',
      'ur': 'انگریزی، اردو یا عربی کا انتخاب کریں',
      'ar': 'اختر بين الإنجليزية أو الأردية أو العربية',
    },
    'goals_nutrition': {
      'en': 'Goals & Nutrition',
      'ur': 'اہداف اور غذائیت',
      'ar': 'الأهداف والتغذية',
    },
    'calorie_goal_calc': {
      'en': 'Smart Goal & Calorie Calculator',
      'ur': 'اسمارٹ گول اور کیلوری کیلکولیٹر',
      'ar': 'حاسبة الأهداف والسعرات الذكية',
    },
    'calorie_goal_desc': {
      'en': 'Set or calculate your daily calorie target with BMR & TDEE guidance',
      'ur': 'BMR اور TDEE رہنمائی کے ساتھ روزانہ کیلوری کا ہدف مقرر کریں',
      'ar': 'احسب أو حدد هدف السعرات اليومي وفق معدلات الأيض والحرق',
    },
    'daily_water_target': {
      'en': 'Daily Water Target',
      'ur': 'روزانہ پانی کا ہدف',
      'ar': 'هدف شرب الماء اليومي',
    },
    'daily_water_desc': {
      'en': 'Customize your daily hydration goal',
      'ur': 'اپنے روزانہ پانی پینے کا ہدف حسب ضرورت بنائیں',
      'ar': 'خصص هدفك اليومي من شرب الماء',
    },
    'audio_sound_effects': {
      'en': 'Audio & Sound Effects',
      'ur': 'آڈیو اور آواز کے اثرات',
      'ar': 'الصوت والمؤثرات الصوتية',
    },
    'calming_sound_feedback': {
      'en': 'Calming Sound Feedback',
      'ur': 'پرسکون صوتی تاثرات',
      'ar': 'تأثيرات صوتية هادئة',
    },
    'calming_sound_desc': {
      'en': 'Plays subtle interactive audio on button clicks, meal logs & deletes',
      'ur': 'بٹن کلک، کھانا شامل کرنے اور حذف کرنے پر نرم آواز سنائی دے گی',
      'ar': 'أصوات تفاعلية هادئة عند الضغط على الأزرار وتسجيل الوجبات وحذفها',
    },
    'help_about': {
      'en': 'Help & About',
      'ur': 'مدد اور معلومات',
      'ar': 'المساعدة ومعلومات التطبيق',
    },
    'take_app_tour': {
      'en': 'Take App Tour Again',
      'ur': 'ایپ کا تعارفی ٹور دوبارہ دیکھیں',
      'ar': 'إعادة الجولة التعريفية بالتطبيق',
    },
    'app_label': {
      'en': 'Application',
      'ur': 'ایپلی کیشن',
      'ar': 'التطبيق',
    },
    'version_label': {
      'en': 'Version',
      'ur': 'ورژن',
      'ar': 'الإصدار',
    },

    // ── Home Screen & Progress ──
    'calorie_progress': {
      'en': 'Calorie progress',
      'ur': 'کیلوری پیش رفت',
      'ar': 'تقدم السعرات',
    },
    'kcal_over_goal': {
      'en': 'kcal over goal',
      'ur': 'کیلوری ہدف سے زیادہ',
      'ar': 'سعرة فوق الهدف',
    },
    'current_streak_label': {
      'en': 'Current Streak',
      'ur': 'موجودہ اسٹریک',
      'ar': 'السلسلة الحالية',
    },
    'days': {
      'en': 'Days',
      'ur': 'دن',
      'ar': 'أيام',
    },
    'day_streak': {
      'en': 'd Streak',
      'ur': 'دن کا اسٹریک',
      'ar': 'أيام متتالية',
    },
    'recover': {
      'en': 'RECOVER',
      'ur': 'بحالی',
      'ar': 'استعادة',
    },
    'lost_streak': {
      'en': 'Lost Streak',
      'ur': 'گمشدہ اسٹریک',
      'ar': 'سلسلة مفقودة',
    },
    'keep_going': {
      'en': 'Keep Going!',
      'ur': 'جاری رکھیں!',
      'ar': 'استمر!',
    },
    'view_all_ranks': {
      'en': 'View All Ranks',
      'ur': 'تمام رینکس دیکھیں',
      'ar': 'عرض جميع الرتب',
    },
    'rank_roadmap_title': {
      'en': 'Rank Progression Roadmap',
      'ur': 'رینک کے مراحل اور روڈ میپ',
      'ar': 'مسار ومراحل الرتب',
    },
    'rank_rules_title': {
      'en': '🎯 Rank & Streak Rules:',
      'ur': '🎯 رینک اور اسٹریک کے اصول:',
      'ar': '🎯 قواعد الرتب والسلسلة:',
    },
    'your_target_window': {
      'en': 'Your Target Window:',
      'ur': 'آپ کی ٹارگٹ رینج:',
      'ar': 'نطاقك المستهدف:',
    },
    'you': {
      'en': 'YOU',
      'ur': 'آپ',
      'ar': 'أنت',
    },
    'lvl': {
      'en': 'Lvl',
      'ur': 'لیول',
      'ar': 'المستوى',
    },

    // ── Quick Log & Entry Modals ──
    'quick_log_meal': {
      'en': 'Quick Log Meal',
      'ur': 'فوری کھانا درج کریں',
      'ar': 'تسجيل وجبة سريع',
    },
    'quick_calorie_entry': {
      'en': 'Quick Calorie Entry',
      'ur': 'فوری کیلوری کا اندراج',
      'ar': 'إدخال سريع للسعرات',
    },
    'enter_calories_desc': {
      'en': 'Enter calories directly without details',
      'ur': 'تفصیلات کے بغیر براہ راست کیلوریز درج کریں',
      'ar': 'أدخل السعرات مباشرة بدون تفاصيل',
    },
    'quick_calorie_desc': {
      'en': 'Enter calories directly without details',
      'ur': 'تفصیلات کے بغیر براہ راست کیلوریز درج کریں',
      'ar': 'أدخل السعرات مباشرة بدون تفاصيل',
    },
    'search_food_library': {
      'en': 'Search Food Library',
      'ur': 'فوڈ لائبریری تلاش کریں',
      'ar': 'البحث في دليل الأطعمة',
    },
    'search_food_desc': {
      'en': 'Browse healthy foods with calories and macros',
      'ur': 'کیلوریز اور میکروز کے ساتھ صحت مند کھانے تلاش کریں',
      'ar': 'تصفح أطعمة صحية مع السعرات والعناصر الغذائية',
    },
    'select_saved_meals': {
      'en': 'Select from Saved Meals',
      'ur': 'محفوظ کھانوں سے منتخب کریں',
      'ar': 'اختر من الوجبات المحفوظة',
    },
    'select_saved_desc': {
      'en': 'Quickly pick items from your personal meal catalog',
      'ur': 'اپنی ذاتی فہرست سے فوری طور پر کھانے منتخب کریں',
      'ar': 'اختر سريعاً من قائمة وجباتك المفضلة',
    },
    'enter_meal_name': {
      'en': 'e.g. Afternoon Snack',
      'ur': 'مثلاً: شام کا اسنیک',
      'ar': 'مثال: وجبة خفيفة',
    },
    'meal_name': {
      'en': 'Meal Name',
      'ur': 'کھانے کا نام',
      'ar': 'اسم الوجبة',
    },
    'add_to_today': {
      'en': 'Add to Today',
      'ur': 'آج میں شامل کریں',
      'ar': 'إضافة إلى اليوم',
    },
    'browse_saved_meals': {
      'en': 'Browse Saved Meals',
      'ur': 'محفوظ کھانے دیکھیں',
      'ar': 'تصفح الوجبات المحفوظة',
    },

    // ── Logs Screen ──
    'no_meals_today': {
      'en': 'No meals logged today',
      'ur': 'آج کوئی کھانا درج نہیں کیا گیا',
      'ar': 'لم يتم تسجيل وجبات اليوم',
    },
    'log_meals_empty_desc': {
      'en': 'Tap + to log your breakfast, lunch, or snacks and monitor your daily calorie intake.',
      'ur': 'ناشتہ، دوپہر یا رات کا کھانا درج کرنے کے لیے + پر ٹیپ کریں اور اپنی کیلوریز کا ریکارڈ رکھیں۔',
      'ar': 'اضغط على + لتسجيل إفطارك أو غدائك أو وجباتك الخفيفة ومتابعة سعراتك اليومية.',
    },
    'reset_today': {
      'en': 'Reset Today',
      'ur': 'آج کا دن ری سیٹ کریں',
      'ar': 'إعادة ضبط اليوم',
    },

    // ── Quick Tips Screen ──
    'quick_tips_title': {
      'en': 'Smart Tracking Tips',
      'ur': 'اسمارٹ ٹریکنگ تجاویز',
      'ar': 'نصائح التتبع الذكية',
    },
    'quick_tips_subtitle': {
      'en': 'Use these pro tips to measure calories accurately and make tracking effortless.',
      'ur': 'کیلوریز کی درست پیمائش اور آسانی سے ٹریک کرنے کے لیے یہ ماہرانہ تجاویز استعمال کریں۔',
      'ar': 'استخدم هذه النصائح الاحترافية لحساب السعرات بدقة وتسهيل عملية التتبع.',
    },
    'tip1_title': {
      'en': 'Check Labels & Serving Sizes',
      'ur': 'لیبلز اور سرونگ سائز چیک کریں',
      'ar': 'تحقق من الملصقات وحجم الحصة',
    },
    'tip1_desc': {
      'en': 'Always read the nutritional breakdown on packaging carefully. Double-check the serving size so you never accidentally log a fraction of what you actually eat.',
      'ur': 'پیکجنگ پر غذائی معلومات ہمیشہ غور سے پڑھیں۔ سرونگ سائز ضرور چیک کریں تاکہ آپ کی خوراک کا صحیح حساب رہے۔',
      'ar': 'اقرأ دائماً البيانات الغذائية على العبوة بعناية. تأكد من حجم الحصة لتجنب تسجيل كمية أقل مما تناولته فعلياً.',
    },
    'tip2_title': {
      'en': 'Weigh & Consult AI',
      'ur': 'وزن کریں اور AI سے رہنمائی لیں',
      'ar': 'زن طعامك واستشر الذكاء الاصطناعي',
    },
    'tip2_desc': {
      'en': 'Place fresh or unlabelled foods on a kitchen scale in grams. Ask any AI model or database for precise macro values, then save them to your app for quick logging.',
      'ur': 'کھانے کی اشیاء کو کچن اسکیل پر گرام میں تولیں۔ درست غذائی اقدار معلوم کریں اور فوری لاگنگ کے لیے ایپ میں محفوظ کریں۔',
      'ar': 'ضع الأطعمة الطازجة على ميزان المطبخ بالجرام. اسأل الذكاء الاصطناعي عن القيم الغذائية الدقيقة واحفظها لتسجيلها بسرعة.',
    },
    'tip3_title': {
      'en': 'Account for Hidden Oils & Sauces',
      'ur': 'پوشیدہ تیل اور ساسز کا خیال رکھیں',
      'ar': 'احسب الزيوت والصلصات الخفية',
    },
    'tip3_desc': {
      'en': 'Cooking oils, butter, and dressings add up fast. Measure your cooking fats with a spoon rather than eyeballing them to keep your tracking accurate.',
      'ur': 'کھانا پکانے کا تیل، مکھن اور ڈریسنگز تیزی سے کیلوریز بڑھاتے ہیں۔ اندازے کے بجائے چمچ سے ناپیں تاکہ ٹریکنگ درست رہے۔',
      'ar': 'زيوت الطهي والزبدة والصلصات تزيد السعرات بسرعة. قم بقياس الدهون بالملعقة بدلاً من التقدير بالعين لضمان الدقة.',
    },
    'tip4_title': {
      'en': 'Weigh Consistently (Raw vs. Cooked)',
      'ur': 'مستقل مزاجی سے وزن کریں (کچا بمقابلہ پکا ہوا)',
      'ar': 'زن طعامك بطريقة ثابتة (نيء أم مطبوخ)',
    },
    'tip4_desc': {
      'en': 'Meats and grains change weight when cooked due to water loss or absorption. Stick to weighing items either entirely raw or entirely cooked for reliable daily data.',
      'ur': 'گوشت اور اناج پکنے کے بعد پانی کم یا زیادہ ہونے سے وزن بدل لیتے ہیں۔ قابل اعتماد نتائج کے لیے یا تو ہمیشہ کچا تولیں یا پکا ہوا۔',
      'ar': 'يتغير وزن اللحوم والحبوب عند الطهي لفقدان الماء أو امتصاصه. التزم بوزن الأطعمة إما نيئة دائماً أو مطبوخة دائماً.',
    },

    // ── Feedback Screen ──
    'feedback_title': {
      'en': 'Send Feedback',
      'ur': 'رائے بھیجیں',
      'ar': 'إرسال ملاحظات',
    },
    'feedback_subtitle': {
      'en': 'Help us make Fit Lyfe better for you!',
      'ur': 'فٹ لائف کو آپ کے لیے مزید بہتر بنانے میں مدد کریں!',
      'ar': 'ساعدنا في جعل فت لايف أفضل من أجلك!',
    },
    'feedback_hint': {
      'en': 'Tell us what you love or what we can improve...',
      'ur': 'ہمیں بتائیں کہ آپ کو کیا پسند آیا یا ہم کیا بہتر بنا سکتے ہیں...',
      'ar': 'أخبرنا بما يعجبك أو ما يمكننا تحسينه...',
    },
    'submit_feedback': {
      'en': 'Submit Feedback',
      'ur': 'رائے ارسال کریں',
      'ar': 'إرسال الملاحظات',
    },

    // ── History Screen ──
    'daily_history': {
      'en': 'Daily History',
      'ur': 'روزانہ کی تاریخ',
      'ar': 'السجل اليومي',
    },
    'no_history_recorded': {
      'en': 'No History Recorded Yet',
      'ur': 'ابھی تک کوئی ہسٹری موجود نہیں',
      'ar': 'لا توجد سجلات محفوظة بعد',
    },
    'no_history_desc': {
      'en': 'When you finish your day on the Home screen, your daily nutrition and calorie logs are archived here for you to review anytime.',
      'ur': 'جب آپ ہوم اسکرین پر اپنا دن مکمل کریں گے، تو آپ کی روزانہ کی غذائیت اور کیلوریز یہاں محفوظ ہو جائیں گی تاکہ آپ کسی بھی وقت جائزہ لے سکیں۔',
      'ar': 'عند إنهاء يومك في الشاشة الرئيسية، ستتم أرشفة سجلات التغذية والسعرات الحرارية هنا لمراجعتها في أي وقت.',
    },
    'back_to_home': {
      'en': 'Back to Home',
      'ur': 'ہوم پر واپس جائیں',
      'ar': 'العودة إلى الرئيسية',
    },
    'clear_history': {
      'en': 'Clear History',
      'ur': 'ہسٹری صاف کریں',
      'ar': 'مسح السجل',
    },
    'clear_all_history': {
      'en': 'Clear All History',
      'ur': 'تمام ہسٹری صاف کریں',
      'ar': 'مسح كل السجل',
    },
    'delete_day_record': {
      'en': 'Delete Day Record',
      'ur': 'دن کا ریکارڈ حذف کریں',
      'ar': 'حذف سجل اليوم',
    },
    'past_daily_records': {
      'en': 'Past Daily Records',
      'ur': 'گزشتہ دنوں کے ریکارڈز',
      'ar': 'سجلات الأيام السابقة',
    },
    'nutrition_overview': {
      'en': 'Nutrition Overview',
      'ur': 'غذائیت کا خلاصہ',
      'ar': 'نظرة عامة على التغذية',
    },
    'aggregated_all_days': {
      'en': 'Aggregated across all logged days',
      'ur': 'تمام درج شدہ دنوں کا مجموعی جائزہ',
      'ar': 'مجموع كافة الأيام المسجلة',
    },
    'days_logged': {
      'en': 'Days Logged',
      'ur': 'درج شدہ دن',
      'ar': 'الأيام المسجلة',
    },
    'avg_calories': {
      'en': 'Avg Calories',
      'ur': 'اوسط کیلوریز',
      'ar': 'متوسط السعرات',
    },
    'avg_protein': {
      'en': 'Avg Protein',
      'ur': 'اوسط پروٹین',
      'ar': 'متوسط البروتين',
    },

    // ── Meals Screen ──
    'my_meals': {
      'en': 'My Meals',
      'ur': 'میرے کھانے',
      'ar': 'وجباتي',
    },
    'add_meal': {
      'en': 'Add Meal',
      'ur': 'کھانا شامل کریں',
      'ar': 'إضافة وجبة',
    },
    'no_saved_meals': {
      'en': 'No saved meals yet',
      'ur': 'ابھی تک کوئی کھانا محفوظ نہیں',
      'ar': 'لا توجد وجبات محفوظة حتى الآن',
    },
    'load_starter_meals': {
      'en': 'Load Starter Meals',
      'ur': 'ابتدائی کھانے لوڈ کریں',
      'ar': 'تحميل الوجبات الجاهزة',
    },

    // ── Logs Screen & Common ──
    'no_logs_today': {
      'en': 'No meals logged today',
      'ur': 'آج کوئی کھانا لاگ نہیں ہوا',
      'ar': 'لم تسجل أي وجبة اليوم',
    },
    'days_logs_reset': {
      'en': 'Today\'s logs have been reset',
      'ur': 'آج کے لاگز ری سیٹ ہو گئے ہیں',
      'ar': 'تمت إعادة ضبط سجلات اليوم',
    },
    'reset_day': {
      'en': 'Reset Day',
      'ur': 'دن ری سیٹ کریں',
      'ar': 'إعادة ضبط اليوم',
    },
    'undo': {
      'en': 'Undo',
      'ur': 'واپس لیں',
      'ar': 'تراجع',
    },
    'quick_tips': {
      'en': 'Quick Nutrition Tips',
      'ur': 'فوری غذائی ٹپس',
      'ar': 'نصائح غذائية سريعة',
    },
  };

  static String translate(String key, String langCode) {
    final map = _translations[key];
    if (map == null) return key;
    return map[langCode] ?? map['en'] ?? key;
  }

  static String getRankTitle(int level, String langCode) {
    if (langCode == 'ur') {
      switch (level) {
        case 9:
          return 'فٹ لائف کنگ';
        case 8:
          return 'چھ ماہ کا لیجنڈ';
        case 7:
          return 'سینچورین ٹریکر';
        case 6:
          return 'آہنی عزم';
        case 5:
          return 'کیلوری ٹائٹن';
        case 4:
          return 'میکرو کیمیا گر';
        case 3:
          return 'مستقل مزاجی ماسٹر';
        case 2:
          return 'عادت ساز';
        case 1:
          return 'نوآموز';
        default:
          return 'غیر درجہ بند';
      }
    } else if (langCode == 'ar') {
      switch (level) {
        case 9:
          return 'ملك فت لايف';
        case 8:
          return 'أسطورة نصف العام';
        case 7:
          return 'متتبع المئة';
        case 6:
          return 'إرادة حديدية';
        case 5:
          return 'عملاق السعرات';
        case 4:
          return 'خبير العناصر';
        case 3:
          return 'أستاذ الالتزام';
        case 2:
          return 'بانٍ للعادات';
        case 1:
          return 'مبتدئ';
        default:
          return 'غير مصنف';
      }
    }
    switch (level) {
      case 9:
        return 'Fit Lyfe King';
      case 8:
        return 'Half-Year Legend';
      case 7:
        return 'Centurion Tracker';
      case 6:
        return 'Iron Will';
      case 5:
        return 'Calorie Titan';
      case 4:
        return 'Macro Alchemist';
      case 3:
        return 'Consistency Master';
      case 2:
        return 'Habit Builder';
      case 1:
        return 'Rookie';
      default:
        return 'Unranked';
    }
  }

  static String getRankReq(int level, String langCode) {
    if (langCode == 'ur') {
      switch (level) {
        case 9:
          return '365+ دن کا اسٹریک';
        case 8:
          return '180 - 364 دن';
        case 7:
          return '90 - 179 دن';
        case 6:
          return '60 - 89 دن';
        case 5:
          return '30 - 59 دن';
        case 4:
          return '14 - 29 دن';
        case 3:
          return '7 - 13 دن';
        case 2:
          return '4 - 6 دن';
        case 1:
          return '1 - 3 دن';
        default:
          return '0 دن (غیر فعال)';
      }
    } else if (langCode == 'ar') {
      switch (level) {
        case 9:
          return '365+ يوم متتالي';
        case 8:
          return '180 - 364 يوم';
        case 7:
          return '90 - 179 يوم';
        case 6:
          return '60 - 89 يوم';
        case 5:
          return '30 - 59 يوم';
        case 4:
          return '14 - 29 يوم';
        case 3:
          return '7 - 13 يوم';
        case 2:
          return '4 - 6 أيام';
        case 1:
          return '1 - 3 أيام';
        default:
          return '0 يوم (غير نشط)';
      }
    }
    switch (level) {
      case 9:
        return '365+ Days Streak';
      case 8:
        return '180 - 364 Days';
      case 7:
        return '90 - 179 Days';
      case 6:
        return '60 - 89 Days';
      case 5:
        return '30 - 59 Days';
      case 4:
        return '14 - 29 Days';
      case 3:
        return '7 - 13 Days';
      case 2:
        return '4 - 6 Days';
      case 1:
        return '1 - 3 Days';
      default:
        return '0 Days (Inactive)';
    }
  }

  static String formatDate(DateTime d, String langCode) {
    const daysEn = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const daysUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    const daysAr = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];

    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const monthsUr = [
      'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
      'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
    ];
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    if (langCode == 'ur') {
      return '${daysUr[d.weekday - 1]}، ${d.day} ${monthsUr[d.month - 1]}، ${d.year}';
    } else if (langCode == 'ar') {
      return '${daysAr[d.weekday - 1]}، ${d.day} ${monthsAr[d.month - 1]}، ${d.year}';
    }
    return '${daysEn[d.weekday - 1]}, ${monthsEn[d.month - 1]} ${d.day}, ${d.year}';
  }
}
