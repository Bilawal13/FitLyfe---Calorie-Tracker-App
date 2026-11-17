import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../services/storage_service.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';
import '../services/language_provider.dart';

class HistoryScreen extends StatefulWidget {
  final AppColors c;
  final List<LoggedMeal>? todayLogs;
  final int? currentGoal;

  const HistoryScreen({
    super.key,
    required this.c,
    this.todayLogs,
    this.currentGoal,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailySummary> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final list = await StorageService.getDailyHistory();

    // If there are live logs, merge or update the session summary in memory
    final todayLogs = widget.todayLogs;
    if (todayLogs != null && todayLogs.isNotEmpty) {
      final sessionDate = StorageService.getSessionDate(todayLogs);
      final goal = widget.currentGoal ?? await StorageService.getGoal();
      final water = await StorageService.getWaterIntake();
      final exercises = await StorageService.getLoggedExercises();
      double burned = 0;
      for (final ex in exercises) {
        burned += ex.caloriesBurned;
      }
      final sessionSummary = DailySummary.fromLogs(
        date: sessionDate,
        logs: todayLogs,
        goal: goal,
        waterIntake: water,
        burnedCalories: burned,
      );
      final idx = list.indexWhere((h) => h.date == sessionDate);
      if (idx >= 0) {
        list[idx] = sessionSummary;
      } else {
        list.insert(0, sessionSummary);
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      // Also persist it so it stays updated
      await StorageService.upsertDailySummary(sessionSummary);
    }

    if (!mounted) return;
    setState(() {
      _history = list;
      _loading = false;
    });
  }

  Future<void> _deleteRecord(DailySummary summary, LanguageProvider lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.c.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.c.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: widget.c.danger, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              lang.t('delete_day_record'),
              style: TextStyle(
                color: widget.c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          lang.isUrdu
              ? 'کیا آپ واقعی ${_formatDateTitle(summary.date, lang)} کا ریکارڈ حذف کرنا چاہتے ہیں؟'
              : (lang.isArabic
                  ? 'هل أنت متأكد من حذف سجل ${_formatDateTitle(summary.date, lang)}؟'
                  : 'Are you sure you want to delete the record for ${_formatDateTitle(summary.date, lang)}?'),
          style: TextStyle(color: widget.c.textSec, fontSize: 13.5, height: 1.35),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.playTap();
                    Navigator.pop(ctx, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.c.textSec,
                    side: BorderSide(color: widget.c.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(lang.t('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.c.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  onPressed: () {
                    SoundService.playTap();
                    Navigator.pop(ctx, true);
                  },
                  label: Text(lang.t('delete'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteDailySummary(summary.date);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.isUrdu
                ? '${_formatDateTitle(summary.date, lang)} کا ریکارڈ حذف کر دیا گیا'
                : (lang.isArabic
                    ? 'تم حذف سجل ${_formatDateTitle(summary.date, lang)}'
                    : 'Removed record for ${_formatDateTitle(summary.date, lang)}')),
            backgroundColor: widget.c.accent3,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllHistory(LanguageProvider lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.c.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.c.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded,
                  color: widget.c.danger, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              lang.t('clear_all_history'),
              style: TextStyle(
                color: widget.c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          lang.isUrdu
              ? 'اس سے تمام محفوظ شدہ روزانہ غذائی ریکارڈ ہمیشہ کے لیے صاف ہو جائیں گے۔ اس عمل کو واپس نہیں لایا جا سکتا۔'
              : (lang.isArabic
                  ? 'سيؤدي هذا إلى مسح جميع السجلات الغذائية اليومية نهائياً. لا يمكن التراجع عن هذا الإجراء.'
                  : 'This will permanently erase all saved daily nutrition records. This action cannot be undone.'),
          style: TextStyle(color: widget.c.textSec, fontSize: 13.5, height: 1.35),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.playTap();
                    Navigator.pop(ctx, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.c.textSec,
                    side: BorderSide(color: widget.c.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(lang.t('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.c.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  onPressed: () {
                    SoundService.playTap();
                    Navigator.pop(ctx, true);
                  },
                  label: Text(lang.isUrdu
                      ? 'تمام صاف کریں'
                      : (lang.isArabic ? 'مسح الكل' : 'Clear All'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearDailyHistory();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.isUrdu
                ? 'تمام تاریخچہ صاف کر دیا گیا ہے۔'
                : (lang.isArabic
                    ? 'تم مسح كافة السجلات بنجاح.'
                    : 'All history has been cleared.')),
            backgroundColor: widget.c.accent3,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDateTitle(String dateStr, LanguageProvider lang) {
    if (dateStr.isEmpty) {
      return lang.isUrdu
          ? 'نامعلوم تاریخ'
          : (lang.isArabic ? 'تاريخ غير معروف' : 'Unknown Date');
    }
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final d = DateTime(year, month, day);

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final diff = todayDate.difference(DateTime(d.year, d.month, d.day)).inDays;

      final enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final urDays = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
      final arDays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

      final enMonths = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final urMonths = [
        'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
        'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
      ];
      final arMonths = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];

      final dayName = lang.isUrdu
          ? urDays[d.weekday - 1]
          : (lang.isArabic ? arDays[d.weekday - 1] : enDays[d.weekday - 1]);
      final monthName = lang.isUrdu
          ? urMonths[d.month - 1]
          : (lang.isArabic ? arMonths[d.month - 1] : enMonths[d.month - 1]);

      if (diff == 0) {
        return lang.isUrdu
            ? 'آج · $dayName، $day $monthName'
            : (lang.isArabic
                ? 'اليوم · $dayName، $day $monthName'
                : 'Today · $dayName, $monthName $day');
      } else if (diff == 1) {
        return lang.isUrdu
            ? 'گزشتہ کل · $dayName، $day $monthName'
            : (lang.isArabic
                ? 'أمس · $dayName، $day $monthName'
                : 'Yesterday · $dayName, $monthName $day');
      } else {
        return lang.isUrdu
            ? '$dayName، $day $monthName $year'
            : (lang.isArabic
                ? '$dayName، $day $monthName $year'
                : '$dayName, $monthName $day, $year');
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final lang = context.watch<LanguageProvider>();

    // Calculate aggregated stats
    double totalCalories = 0;
    double totalProtein = 0;
    for (final s in _history) {
      totalCalories += s.calories;
      totalProtein += s.protein;
    }
    final avgCal = _history.isNotEmpty ? (totalCalories / _history.length).round() : 0;
    final avgProtein = _history.isNotEmpty ? (totalProtein / _history.length).round() : 0;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(
          lang.t('daily_history'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: c.textSec),
              color: c.bg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                SoundService.playTap();
                if (val == 'clear') _clearAllHistory(lang);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: c.danger, size: 20),
                      const SizedBox(width: 10),
                      Text(lang.t('clear_history'),
                          style: TextStyle(color: c.danger, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : _history.isEmpty
              ? _buildEmptyState(c, lang)
              : RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.bg2,
                  onRefresh: _loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Overview metrics card
                      _buildOverviewCard(c, avgCal, avgProtein, lang),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lang.t('past_daily_records'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.textSec,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang.isUrdu
                                ? '${_history.length} دن درج ہوئے'
                                : (lang.isArabic
                                    ? 'تم تسجيل ${_history.length} أيام'
                                    : '${_history.length} ${_history.length == 1 ? 'day' : 'days'} logged'),
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._history.map((summary) => _buildDayCard(summary, c, lang)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCard(AppColors c, int avgCal, int avgProtein, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics_outlined, color: c.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('nutrition_overview'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      lang.t('aggregated_all_days'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  lang.t('days_logged'),
                  '${_history.length}',
                  Icons.calendar_month_rounded,
                  c.accent,
                  c,
                ),
              ),
              Container(width: 1, height: 40, color: c.border),
              Expanded(
                child: _buildMetricItem(
                  lang.t('avg_calories'),
                  '$avgCal kcal',
                  Icons.local_fire_department_rounded,
                  c.warning,
                  c,
                ),
              ),
              Container(width: 1, height: 40, color: c.border),
              Expanded(
                child: _buildMetricItem(
                  lang.t('avg_protein'),
                  '${avgProtein}g',
                  Icons.fitness_center_rounded,
                  const Color(0xFF5CB8E8),
                  c,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color, AppColors c) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: c.textMuted),
        ),
      ],
    );
  }

  Widget _buildDayCard(DailySummary summary, AppColors c, LanguageProvider lang) {
    final cal = summary.calories;
    final goal = summary.goal > 0 ? summary.goal : 2000;
    final pct = (cal / goal).clamp(0.0, 1.0);
    final isOver = cal > goal;
    final progressColor = isOver ? c.danger : c.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Delete action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 15, color: c.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateTitle(summary.date, lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (summary.mealCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.bg3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lang.isUrdu
                            ? '${summary.mealCount} کھانے'
                            : (lang.isArabic
                                ? '${summary.mealCount} وجبات'
                                : '${summary.mealCount} ${summary.mealCount == 1 ? 'meal' : 'meals'}'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: c.textSec,
                        ),
                      ),
                    ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: () {
                      SoundService.playTap();
                      _deleteRecord(summary, lang);
                    },
                    icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                    tooltip: lang.isUrdu
                        ? 'دن کا ریکارڈ حذف کریں'
                        : (lang.isArabic ? 'حذف سجل اليوم' : 'Delete day record'),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calorie progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '${cal.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isOver ? c.danger : c.accent,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        lang.isUrdu
                            ? ' / $goal ہدف'
                            : (lang.isArabic ? ' / $goal هدف' : ' / $goal goal'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOver
                    ? (lang.isUrdu
                        ? '+${(cal - goal).toInt()} زیادہ'
                        : (lang.isArabic
                            ? '+${(cal - goal).toInt()} سعرة فائضة'
                            : '+${(cal - goal).toInt()} kcal over'))
                    : '${((cal / goal) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: c.bg3,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 14),

          // Macro Breakdown Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMacroPill(
                  lang.isUrdu
                      ? '🥩 پروٹین'
                      : (lang.isArabic ? '🥩 بروتين' : '🥩 Protein'),
                  '${summary.protein.toInt()}g',
                  c.accent,
                  c),
              _buildMacroPill(
                  lang.isUrdu
                      ? '🌾 کاربس'
                      : (lang.isArabic ? '🌾 كربوهيدرات' : '🌾 Carbs'),
                  '${summary.carbs.toInt()}g',
                  c.warning,
                  c),
              _buildMacroPill(
                  lang.isUrdu
                      ? '🥑 چکنائی'
                      : (lang.isArabic ? '🥑 دهون' : '🥑 Fat'),
                  '${summary.fat.toInt()}g',
                  const Color(0xFF5CB8E8),
                  c),
              _buildMacroPill(
                  lang.isUrdu
                      ? '🥗 فائبر'
                      : (lang.isArabic ? '🥗 ألياف' : '🥗 Fiber'),
                  '${summary.fiber.toInt()}g',
                  c.textSec,
                  c),
              _buildMacroPill(
                  lang.isUrdu
                      ? '🧂 سوڈیم'
                      : (lang.isArabic ? '🧂 صوديوم' : '🧂 Sodium'),
                  '${summary.sodium.toInt()}mg',
                  c.textSec,
                  c),
              if (summary.waterIntake > 0)
                _buildMacroPill(
                    lang.isUrdu
                        ? '💧 پانی'
                        : (lang.isArabic ? '💧 ماء' : '💧 Water'),
                    '${summary.waterIntake}ml',
                    const Color(0xFF0EA5E9),
                    c),
              if (summary.burnedCalories > 0)
                _buildMacroPill(
                    lang.isUrdu
                        ? '🔥 جلائی گئی'
                        : (lang.isArabic ? '🔥 تم حرقها' : '🔥 Burned'),
                    '-${summary.burnedCalories.toInt()} kcal',
                    Colors.orange,
                    c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textSec),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors c, LanguageProvider lang) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.accent.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 50,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                lang.t('no_history_recorded'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  lang.t('no_history_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textMuted,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    label: Text(
                      lang.t('back_to_home'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor:
                          c.accentType == AppAccentColor.black && c.dark
                              ? Colors.black
                              : Colors.white,
                      elevation: 2,
                      shadowColor: c.accent.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
