import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sound_service.dart';
import '../services/theme_provider.dart';
import '../services/language_provider.dart';

typedef RectBuilder = Rect Function(Size screenSize, EdgeInsets safePadding);

class TourStep {
  final int tabIndex;
  final double? scrollOffset;
  final String Function(LanguageProvider lang) badge;
  final String Function(LanguageProvider lang) title;
  final String Function(LanguageProvider lang) description;
  final RectBuilder targetRectBuilder;
  final double borderRadius;
  final bool cardAbove;

  const TourStep({
    required this.tabIndex,
    this.scrollOffset,
    required this.badge,
    required this.title,
    required this.description,
    required this.targetRectBuilder,
    this.borderRadius = 16.0,
    this.cardAbove = false,
  });
}

class AppTourOverlay extends StatefulWidget {
  final AppColors c;
  final Function(int) onTabChangeRequested;
  final Function(double)? onScrollRequested;
  final VoidCallback onFinish;

  const AppTourOverlay({
    super.key,
    required this.c,
    required this.onTabChangeRequested,
    this.onScrollRequested,
    required this.onFinish,
  });

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _morphController;
  Animation<Rect?>? _morphAnimation;

  final List<TourStep> _steps = [
    // 1. Calorie & Macro Ring (Home Top)
    TourStep(
      tabIndex: 0,
      scrollOffset: 0.0,
      borderRadius: 22.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 1 از 9 · ہوم'
          : (lang.isArabic ? 'الخطوة 1 من 9 · الرئيسية' : 'STEP 1 OF 9 · HOME'),
      title: (lang) => lang.isUrdu
          ? 'روزانہ کا ہدف اور میکرو رنگ'
          : (lang.isArabic
              ? 'الهدف اليومي وحلقة السعرات'
              : 'Daily Target & Macro Ring'),
      description: (lang) => lang.isUrdu
          ? 'آپ کا لائیو غذائی مرکز! یہاں آپ کی باقی بچ جانے والی روزانہ کیلوریز اور پروٹین، کاربس، چکنائی، فائبر اور سوڈیم کی فوری تفصیلات نظر آتی ہیں۔'
          : (lang.isArabic
              ? 'مركز تغذيتك المباشر! يعرض سعراتك المتبقية والتوزيع المباشر للبروتين والكربوهيدرات والدهون والألياف والصوديوم.'
              : 'Your live nutrition hub! Displays your remaining daily calories and real-time breakdowns for Protein, Carbs, Fat, Fiber, and Sodium.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        safe.top + 64.0,
        size.width - 24.0,
        325.0,
      ),
    ),

    // 2. Goal Pathways & Target Calorie (Home Top Right Header)
    TourStep(
      tabIndex: 0,
      scrollOffset: 0.0,
      borderRadius: 14.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 2 از 9 · ہوم'
          : (lang.isArabic ? 'الخطوة 2 من 9 · الرئيسية' : 'STEP 2 OF 9 · HOME'),
      title: (lang) => lang.isUrdu
          ? 'اسمارٹ گول کیلکولیٹر اور ہدف'
          : (lang.isArabic
              ? 'حاسبة الأهداف والسعرات الذكية'
              : 'Goal Pathways & Target Calorie'),
      description: (lang) => lang.isUrdu
          ? 'روزانہ کیلوری کے ہدف کے لیے اس بٹن پر ٹیپ کریں! اپنے قد، وزن اور سرگرمی کے مطابق BMR/TDEE کے ساتھ ہدف مقرر کریں۔'
          : (lang.isArabic
              ? 'اضغط هنا لفتح حاسبة الأهداف الذكية! اختر المسار الإرشادي لحساب معدل الأيض والعجز/الفائض أو حدد هدفاً يدوياً سريعاً.'
              : 'Tap this button anytime to open the Smart Goal Calculator! Choose Guided Pathway to calculate BMR/TDEE deficit or surplus, or set a Quick Manual target.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        size.width - 113.0,
        safe.top + 15.0,
        100.0,
        52.0,
      ),
    ),

    // 3. Consistency Rank Roadmap Screen
    TourStep(
      tabIndex: 5,
      scrollOffset: 0.0,
      borderRadius: 20.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 3 از 9 · رینکس'
          : (lang.isArabic ? 'الخطوة 3 من 9 · الرتب' : 'STEP 3 OF 9 · RANKS'),
      title: (lang) => lang.isUrdu
          ? 'مستقل مزاجی اسٹریک اور رینک روڈ میپ'
          : (lang.isArabic
              ? 'خريطة رتب وسلسلة الالتزام'
              : 'Consistency Ranks & Streaks'),
      description: (lang) => lang.isUrdu
          ? 'روزانہ ہدف کے ±100 کیلوری کے اندر رہیں تاکہ اسٹریک بنے اور آپ نوآموز سے فٹ لائف کنگ تک 10 رینکس حاصل کر سکیں۔ یہاں آپ اپنا موجودہ رینک اور روڈ میپ دیکھ سکتے ہیں۔'
          : (lang.isArabic
              ? 'حقق ضمن ±100 سعرة من هدفك اليومي لبناء سلسلة التزام والارتقاء عبر 10 رتب من مبتدئ إلى ملك فت لايف! تابع رتبتك الحالية وخريطة الإنجازات هنا.'
              : 'Hit within ±100 kcal of your daily goal to build consistency streaks and climb 10 ranks from Rookie to Fit Lyfe King! Track your active tier and milestone roadmap right here.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        16.0,
        safe.top + 64.0,
        size.width - 32.0,
        106.0,
      ),
    ),

    // 4. Water Intake Tracker (Home Middle - Auto Scrolled past Burned Calories)
    TourStep(
      tabIndex: 0,
      scrollOffset: 640.0,
      borderRadius: 18.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 4 از 9 · ہوم'
          : (lang.isArabic ? 'الخطوة 4 من 9 · الرئيسية' : 'STEP 4 OF 9 · HOME'),
      title: (lang) => lang.isUrdu
          ? 'پانی کا استعمال اور ہائیڈریشن'
          : (lang.isArabic
              ? 'متابعة شرب الماء والترطيب'
              : 'Water Tracker & Hydration'),
      description: (lang) => lang.isUrdu
          ? 'پانی پینا نہ بھولیں! فوری کپس (+250 ملی لیٹر، +500 ملی لیٹر) کے ساتھ پانی درج کریں اور اپنا روزانہ کا ہدف مقرر کریں۔'
          : (lang.isArabic
              ? 'حافظ على رطوبة جسمك! سجل شرب الماء بضغطة سريعة (+250 ملل، +500 ملل) وخصص هدفك اليومي من شرب الماء.'
              : 'Stay hydrated! Log water with single-tap quick cups (+250ml, +500ml) and tap the tune icon to customize your daily hydration target.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        safe.top + 150.0,
        size.width - 24.0,
        160.0,
      ),
    ),

    // 5. Done for the Day (Home Bottom - Auto Scrolled to End)
    TourStep(
      tabIndex: 0,
      scrollOffset: 3000.0,
      borderRadius: 16.0,
      cardAbove: true,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 5 از 9 · ہوم'
          : (lang.isArabic ? 'الخطوة 5 من 9 · الرئيسية' : 'STEP 5 OF 9 · HOME'),
      title: (lang) => lang.isUrdu
          ? 'آج کا دن مکمل کریں؟ (محفوظ و ری سیٹ)'
          : (lang.isArabic
              ? 'إنهاء اليوم؟ (حفظ وإعادة ضبط)'
              : 'Done for the Day (Finish & Reset)'),
      description: (lang) => lang.isUrdu
          ? 'آج کا کھانا مکمل ہو گیا؟ یہاں ٹیپ کریں تاکہ آج کی غذائیت تاریخ میں محفوظ ہو جائے اور کل کے لیے نیا آغاز ہو۔'
          : (lang.isArabic
              ? 'أنهيت وجباتك اليوم؟ اضغط هنا لأرشفة بيانات اليوم بأمان في السجل وإعادة تصفير العدادات ليوم جديد.'
              : 'Finished eating for the day? Tap here to securely archive today’s nutrition into Daily History and reset counters for a fresh tomorrow.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        size.height - safe.bottom - 210.0,
        size.width - 24.0,
        56.0,
      ),
    ),

    // 6. Quick Add Action Button (Home Bottom Right)
    TourStep(
      tabIndex: 0,
      scrollOffset: 0.0,
      borderRadius: 37.0,
      cardAbove: true,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 6 از 9 · ہوم'
          : (lang.isArabic ? 'الخطوة 6 من 9 · الرئيسية' : 'STEP 6 OF 9 · HOME'),
      title: (lang) => lang.isUrdu
          ? 'فوری اندراج کا بٹن'
          : (lang.isArabic ? 'زر الإضافة السريع' : 'Quick Add Action Button'),
      description: (lang) => lang.isUrdu
          ? 'چلتے پھرتے فوری اندراج! جب چاہیں بغیر تفصیلات کے کیلوریز اور اسنیکس چند سیکنڈ میں درج کریں۔'
          : (lang.isArabic
              ? 'تسجيل سريع في ثوانٍ! اضغط على هذا الزر العائم في أي وقت لإضافة سعرات ووجبات خفيفة مباشرة وبكل سهولة.'
              : 'Fast entry on the fly! Tap this floating button anytime to quick-add custom calories and snacks in seconds.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        size.width - 81.0,
        size.height - safe.bottom - 137.0,
        74.0,
        74.0,
      ),
    ),

    // 7. Food Library & Verified Search (Food Library Screen)
    TourStep(
      tabIndex: 4,
      scrollOffset: 0.0,
      borderRadius: 18.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 7 از 9 · فوڈ لائبریری'
          : (lang.isArabic
              ? 'الخطوة 7 من 9 · دليل الأطعمة'
              : 'STEP 7 OF 9 · FOOD LIBRARY'),
      title: (lang) => lang.isUrdu
          ? 'فوڈ لائبریری اور تصدیق شدہ کھانے'
          : (lang.isArabic
              ? 'دليل الأطعمة والبحث الموثق'
              : 'Food Library & USDA Search'),
      description: (lang) => lang.isUrdu
          ? 'صحت بخش کھانے تلاش کریں، ترکیبیں بنائیں اور لائیو میکرو پریویو کے ساتھ سرونگ سائز تبدیل کریں۔'
          : (lang.isArabic
              ? 'تصفح أطعمة صحية منتقاة، وابحث في قاعدة بيانات موثقة، وأنشئ وجباتك الخاصة مع معاينة فورية للعناصر.'
              : 'Browse curated whole foods, search verified items, explore food categories, and inspect live macro previews.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        safe.top + 54.0,
        size.width - 24.0,
        230.0,
      ),
    ),

    // 8. Meal Timeline & Diary (Logs Tab)
    TourStep(
      tabIndex: 2,
      scrollOffset: 0.0,
      borderRadius: 20.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 8 از 9 · لاگز'
          : (lang.isArabic ? 'الخطوة 8 من 9 · السجلات' : 'STEP 8 OF 9 · LOGS'),
      title: (lang) => lang.isUrdu
          ? 'روزانہ کے کھانے اور ڈائری'
          : (lang.isArabic
              ? 'سجل وجبات اليوم والجدول الزمني'
              : 'Meal Timeline & Diary'),
      description: (lang) => lang.isUrdu
          ? 'آج کے تمام کھانوں کی ترتیب اور میکروز کا جائزہ لیں۔ کسی بھی کھانے پر ٹیپ کر کے مقدار تبدیل کریں یا حذف کریں۔'
          : (lang.isArabic
              ? 'راجع وجباتك اليومية بالترتيب الزمني وتوزيع العناصر الغذائية. اضغط على أي وجبة لتعديل الحصة أو حذفها.'
              : 'Review today’s chronological meal logs, nutrient timing, and macro percentages. Tap any logged food to edit portions or remove entries anytime.'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        safe.top + 54.0,
        size.width - 24.0,
        350.0,
      ),
    ),

    // 9. Feedback & Community (Feedback Tab)
    TourStep(
      tabIndex: 3,
      scrollOffset: 0.0,
      borderRadius: 20.0,
      cardAbove: false,
      badge: (lang) => lang.isUrdu
          ? 'مرحلہ 9 از 9 · فیڈبیک'
          : (lang.isArabic
              ? 'الخطوة 9 من 9 · التقييم'
              : 'STEP 9 OF 9 · FEEDBACK'),
      title: (lang) => lang.isUrdu
          ? 'رائے اور تجاویز'
          : (lang.isArabic ? 'التقييم والملاحظات' : 'Feedback & Community'),
      description: (lang) => lang.isUrdu
          ? 'کوئی تجویز ہے یا مدد چاہیے؟ اپنی رائے براہ راست ہماری ٹیم کو بھیجیں تاکہ ایپ مزید بہتر ہو سکے!'
          : (lang.isArabic
              ? 'هل لديك اقتراح أو تحتاج مساعدة؟ أرسل ملاحظاتك مباشرة إلى فريق التطوير للمساهمة في التحديثات القادمة!'
              : 'Have a suggestion, need help, or want to report an issue? Send your thoughts directly to our development team to shape future updates!'),
      targetRectBuilder: (size, safe) => Rect.fromLTWH(
        12.0,
        safe.top + 54.0,
        size.width - 24.0,
        330.0,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyStepEnvironment(_steps[0]);
    });
  }

  void _applyStepEnvironment(TourStep step) {
    widget.onTabChangeRequested(step.tabIndex);
    if (step.scrollOffset != null) {
      widget.onScrollRequested?.call(step.scrollOffset!);
    } else {
      widget.onScrollRequested?.call(0.0);
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _nextStep(Size screenSize, EdgeInsets safePadding) {
    SoundService.playTap();
    if (_currentStepIndex < _steps.length - 1) {
      final oldRect =
          _steps[_currentStepIndex].targetRectBuilder(screenSize, safePadding);
      setState(() {
        _currentStepIndex++;
      });
      _applyStepEnvironment(_steps[_currentStepIndex]);

      final nextRect =
          _steps[_currentStepIndex].targetRectBuilder(screenSize, safePadding);
      _morphAnimation = RectTween(begin: oldRect, end: nextRect).animate(
        CurvedAnimation(parent: _morphController, curve: Curves.easeOutCubic),
      );
      _morphController.forward(from: 0.0);
    } else {
      widget.onScrollRequested?.call(0.0);
      widget.onFinish();
    }
  }

  void _skipTour() {
    SoundService.playTap();
    widget.onScrollRequested?.call(0.0);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final step = _steps[_currentStepIndex];
    final isLastStep = _currentStepIndex == _steps.length - 1;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safePadding = mediaQuery.padding;

    final targetRect = step.targetRectBuilder(screenSize, safePadding);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _morphController,
        builder: (context, _) {
          final currentRect =
              (_morphAnimation != null && _morphController.isAnimating)
                  ? _morphAnimation!.value ?? targetRect
                  : targetRect;

          // Compute card position safely preventing any clamp inversion
          double cardTop;
          if (step.cardAbove) {
            final minTop = safePadding.top + 12.0;
            final maxTop = math.max(minTop, currentRect.top - 180.0);
            cardTop = (currentRect.top - 248.0).clamp(minTop, maxTop);
          } else {
            final minTop = safePadding.top + 16.0;
            final maxTop = math.max(minTop, screenSize.height - safePadding.bottom - 220.0);
            cardTop = (currentRect.bottom + 24.0).clamp(minTop, maxTop);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dark Backdrop with transparent spotlight cutout
              CustomPaint(
                size: screenSize,
                painter: _SpotlightHolePainter(
                  targetRect: currentRect,
                  borderRadius: step.borderRadius,
                  overlayColor: Colors.black.withValues(alpha: 0.78),
                ),
              ),

              // 2. Intercept taps on the dimmed backdrop
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {},
                child: const SizedBox.expand(),
              ),

              // 3. Tour Guide Explanation Card
              Positioned(
                left: 20,
                right: 20,
                top: cardTop,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.c.bg2,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.c.accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: widget.c.accent.withValues(alpha: 0.18),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header (Step indicator + Skip button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: widget.c.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.c.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 13, color: widget.c.accent),
                                  const SizedBox(width: 5),
                                  Text(
                                    step.badge(lang),
                                    style: TextStyle(
                                      color: widget.c.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _skipTour,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                lang.isUrdu
                                    ? 'ٹور چھوڑیں'
                                    : (lang.isArabic
                                        ? 'تخطي الجولة'
                                        : 'Skip Tour'),
                                style: TextStyle(
                                  color: widget.c.textMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          step.title(lang),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: widget.c.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 7),

                        // Description
                        Text(
                          step.description(lang),
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.c.textSec,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Step progress dots + Next button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(_steps.length, (idx) {
                                final isActive = idx == _currentStepIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(right: 5),
                                  width: isActive ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? widget.c.accent
                                        : widget.c.border,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _nextStep(screenSize, safePadding),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.c.accent,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                              ),
                              icon: Icon(
                                isLastStep
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isLastStep
                                    ? (lang.isUrdu
                                        ? 'شروع کریں'
                                        : (lang.isArabic
                                            ? 'ابدأ الآن'
                                            : 'Get Started'))
                                    : (lang.isUrdu
                                        ? 'اگلا'
                                        : (lang.isArabic ? 'التالي' : 'Next')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints the dimmed backdrop with a smooth cutout hole for the target feature
class _SpotlightHolePainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final Color overlayColor;

  _SpotlightHolePainter({
    required this.targetRect,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(borderRadius),
      ));

    // Combine paths with difference operation so the hole stays transparent
    final combined = Path.combine(PathOperation.difference, bgPath, holePath);
    final paint = Paint()..color = overlayColor;
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(_SpotlightHolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.overlayColor != overlayColor;
  }
}
