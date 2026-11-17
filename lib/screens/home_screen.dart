import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/meal.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';
import '../services/language_provider.dart';

class HomeScreen extends StatelessWidget {
  final List<LoggedMeal> logs;
  final int goal;
  final VoidCallback onSetGoal;
  final Function(int) onRemoveLog;
  final VoidCallback onQuickTips;
  final VoidCallback onFoodChart;
  final VoidCallback onSettings;
  final VoidCallback onHistory;
  final VoidCallback? onQuickAdd;
  final List<DailySummary>? history;
  final bool showRolloverPrompt;
  final String? rolloverDate;
  final VoidCallback onDoneForDay;
  final VoidCallback onKeepDay;
  final AppColors c;
  final VoidCallback? onWatchRewardedAdForStreak;
  final Map<String, dynamic>? streakRecoveryInfo;
  final List<String> repairedDates;
  final int waterIntake;
  final int waterGoal;
  final Function(int)? onUpdateWater;
  final VoidCallback? onEditWaterGoal;
  final List<LoggedExercise> exercises;
  final VoidCallback? onLogWorkout;
  final Function(String)? onRemoveExercise;
  final ScrollController? scrollController;

  const HomeScreen({
    super.key,
    required this.logs,
    required this.goal,
    required this.onSetGoal,
    required this.onRemoveLog,
    required this.onQuickTips,
    required this.onFoodChart,
    required this.onSettings,
    required this.onHistory,
    this.onQuickAdd,
    this.history,
    this.showRolloverPrompt = false,
    this.rolloverDate,
    required this.onDoneForDay,
    required this.onKeepDay,
    required this.c,
    this.onWatchRewardedAdForStreak,
    this.streakRecoveryInfo,
    this.repairedDates = const [],
    this.waterIntake = 0,
    this.waterGoal = 2000,
    this.onUpdateWater,
    this.onEditWaterGoal,
    this.exercises = const [],
    this.onLogWorkout,
    this.onRemoveExercise,
    this.scrollController,
  });

  Map<String, double> get _totals => logs.fold(
        {'cal': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0, 'sodium': 0},
        (acc, l) {
          acc['cal'] = acc['cal']! + l.meal.calories;
          acc['protein'] = acc['protein']! + l.meal.protein;
          acc['carbs'] = acc['carbs']! + l.meal.carbs;
          acc['fat'] = acc['fat']! + l.meal.fat;
          acc['fiber'] = acc['fiber']! + l.meal.fiber;
          acc['sodium'] = acc['sodium']! + l.meal.sodium;
          return acc;
        },
      );

  String _formatDate(DateTime d, {String langCode = 'en'}) {
    return AppTranslations.formatDate(d, langCode);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = _totals;
    final cal = t['cal']!;
    final totalBurned = exercises.fold<double>(
        0.0, (acc, ex) => acc + ex.caloriesBurned);
    final netCalories = cal - totalBurned;
    final remainingCalories = (goal - netCalories).toInt();
    final pct = (cal / goal).clamp(0.0, 1.0);
    final isOver = cal > goal;
    final ringColor = isOver ? c.danger : c.accent;

    // Calculate current user rank data based on streak rules
    final rankData = _calculateUserRank(
      todayLogs: logs,
      targetCalories: goal,
      history: history,
      repairedDates: repairedDates,
      langCode: lang.currentLanguage,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.isUrdu
                              ? "آج کا خلاصہ"
                              : (lang.isArabic ? "ملخص اليوم" : "Today's Summary"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(DateTime.now(), langCode: lang.currentLanguage),
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      SoundService.playTap();
                      onHistory();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      child: Icon(Icons.history_rounded,
                          size: 18, color: c.accent),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      SoundService.playTap();
                      onSetGoal();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 14, color: c.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${goal}kcal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (showRolloverPrompt) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.accent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.bedtime_outlined,
                                color: c.accent, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Are you done for the day?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A new day has started. You still have ${cal.toInt()} kcal logged from ${rolloverDate ?? 'yesterday'}. Would you like to save this to your history and reset for today?',
                        style: TextStyle(
                            fontSize: 12, color: c.textSec, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                SoundService.playTap();
                                onKeepDay();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c.textSec,
                                side: BorderSide(color: c.border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Keep Logging',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                SoundService.playTap();
                                onDoneForDay();
                              },
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text(
                                'Yes, Done for Day',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.accent,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Calorie ring
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _RingPainter(
                        progress: pct, ringColor: ringColor, trackColor: c.bg3),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          cal.toInt().toString(),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                            color: isOver ? c.danger : c.textPrimary,
                          ),
                        ),
                        Text(
                            lang.isUrdu
                                ? 'کیلوری کھائی گئی'
                                : (lang.isArabic ? 'سعرة مستهلكة' : 'kcal consumed'),
                            style: TextStyle(fontSize: 12, color: c.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                            lang.isUrdu
                                ? '/ $goal ہدف'
                                : (lang.isArabic ? '/ $goal هدف' : '/ $goal goal'),
                            style: TextStyle(fontSize: 11, color: c.textSec)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Net Calorie Metric Strip ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CalorieSummaryItem(
                      label: lang.isUrdu
                          ? 'کھائی گئی'
                          : (lang.isArabic ? 'مستهلكة' : 'Consumed'),
                      value: '${cal.toInt()}',
                      unit: 'kcal',
                      icon: Icons.restaurant_rounded,
                      color: c.accent,
                      c: c,
                    ),
                    Container(width: 1, height: 26, color: c.border),
                    _CalorieSummaryItem(
                      label: lang.isUrdu
                          ? 'جلائی گئی'
                          : (lang.isArabic ? 'تم حرقها' : 'Burned'),
                      value: '-${totalBurned.toInt()}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      c: c,
                    ),
                    Container(width: 1, height: 26, color: c.border),
                    _CalorieSummaryItem(
                      label: lang.isUrdu
                          ? 'خالص'
                          : (lang.isArabic ? 'الصافي' : 'Net'),
                      value: '${netCalories.toInt()}',
                      unit: 'kcal',
                      icon: Icons.balance_rounded,
                      color: netCalories > goal ? c.danger : c.textPrimary,
                      c: c,
                    ),
                    Container(width: 1, height: 26, color: c.border),
                    _CalorieSummaryItem(
                      label: lang.isUrdu
                          ? 'باقی'
                          : (lang.isArabic ? 'المتبقي' : 'Remaining'),
                      value: '${math.max(0, remainingCalories)}',
                      unit: 'kcal',
                      icon: Icons.flag_rounded,
                      color: remainingCalories < 0 ? c.danger : c.accent,
                      c: c,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress bar card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.t('calorie_progress'),
                            style: TextStyle(fontSize: 12, color: c.textSec)),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 12,
                              color: isOver ? c.danger : c.accent),
                        ),
                      ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: c.bg3,
                      valueColor:
                          AlwaysStoppedAnimation(isOver ? c.danger : c.accent),
                    ),
                  ),
                  if (isOver) ...[
                    const SizedBox(height: 6),
                    Text('${(cal - goal).toInt()} ${lang.t('kcal_over_goal')}',
                        style: TextStyle(fontSize: 11, color: c.danger)),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              // Macro row 1
              Row(children: [
                _MacroCard(
                    label: lang.t('protein'),
                    value: '${t['protein']!.toInt()}g',
                    color: c.accent,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: lang.t('carbs'),
                    value: '${t['carbs']!.toInt()}g',
                    color: c.warning,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: lang.t('fat'),
                    value: '${t['fat']!.toInt()}g',
                    color: const Color(0xFF5CB8E8),
                    c: c),
              ]),
              const SizedBox(height: 10),

              // Macro row 2
              Row(children: [
                _MacroCard(
                    label: lang.t('fiber'),
                    value: '${t['fiber']!.toInt()}g',
                    color: c.textSec,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: lang.t('sodium'),
                    value: '${t['sodium']!.toInt()}mg',
                    color: c.textSec,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: lang.t('net_carbs'),
                    value: '${math.max(0, (t['carbs']! - t['fiber']!).toInt())}g',
                    color: const Color(0xFF10B981),
                    c: c),
              ]),
              const SizedBox(height: 20),

              // ── Activity & Workout Card ──
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🔥',
                                  style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    lang.isUrdu
                                        ? 'جلائی گئی کیلوریز'
                                        : (lang.isArabic
                                            ? 'السعرات المحروقة'
                                            : 'Burned Calories'),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary)),
                                Text(
                                    lang.isUrdu
                                        ? 'آج ${totalBurned.toInt()} کیلوری جلائی گئی'
                                        : (lang.isArabic
                                            ? 'تم حرق ${totalBurned.toInt()} سعرة اليوم'
                                            : '${totalBurned.toInt()} kcal burned today'),
                                    style: TextStyle(
                                        fontSize: 11, color: c.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        if (onLogWorkout != null)
                          ElevatedButton.icon(
                            onPressed: onLogWorkout,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                                lang.isUrdu
                                    ? 'ورزش درج کریں'
                                    : (lang.isArabic ? 'تسجيل تمرين' : 'Log Burn'),
                                style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                    if (exercises.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...exercises.map((ex) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              children: [
                                Text(ex.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.title,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: c.textPrimary)),
                                      if (ex.durationMinutes > 0)
                                        Text('${ex.durationMinutes} min',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${ex.caloriesBurned.toInt()} kcal',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                if (onRemoveExercise != null) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => onRemoveExercise!(ex.id),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(Icons.close_rounded,
                                          size: 16, color: c.textMuted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Water Tracker Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('💧',
                                  style: TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    lang.isUrdu
                                        ? 'روزانہ پانی کا استعمال'
                                        : (lang.isArabic
                                            ? 'استهلاك الماء اليومي'
                                            : 'Daily Water Intake'),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary)),
                                Text(
                                    lang.isUrdu
                                        ? '$waterIntake / $waterGoal ملی لیٹر • ${(waterIntake / 250).toInt()} از ${(waterGoal / 250).toInt()} گلاس'
                                        : (lang.isArabic
                                            ? '$waterIntake / $waterGoal ملل • ${(waterIntake / 250).toInt()} من ${(waterGoal / 250).toInt()} أكواب'
                                            : '$waterIntake / $waterGoal ml • ${(waterIntake / 250).toInt()} of ${(waterGoal / 250).toInt()} glasses'),
                                    style: TextStyle(
                                        fontSize: 11, color: c.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        if (onEditWaterGoal != null)
                          InkWell(
                            onTap: () {
                              SoundService.playTap();
                              onEditWaterGoal!();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tune_rounded,
                                      size: 12, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 4),
                                  Text('${waterGoal}ml',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0EA5E9))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (waterIntake / waterGoal).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: c.bg3,
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
                      ),
                    ),
                    if (waterIntake >= waterGoal) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                                lang.isUrdu
                                    ? 'روزانہ پانی کا ہدف مکمل ہو گیا! شاباش!'
                                    : (lang.isArabic
                                        ? 'تم الوصول للهدف اليومي من الماء! أحسنت!'
                                        : 'Daily hydration target reached! Great job!'),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Quick water buttons
                    Row(
                      children: [
                        Expanded(
                          child: _waterButton(
                            label: '+ 250ml',
                            icon: Icons.local_drink_rounded,
                            onTap: () => onUpdateWater?.call(250),
                            c: c,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _waterButton(
                            label: '+ 500ml',
                            icon: Icons.water_drop_rounded,
                            onTap: () => onUpdateWater?.call(500),
                            c: c,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _waterButton(
                          label: '- 250ml',
                          icon: Icons.remove_rounded,
                          onTap: () => onUpdateWater?.call(-250),
                          c: c,
                          isSecondary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Aesthetic Action Buttons ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.history_rounded,
                      label: lang.isUrdu
                          ? 'تاریخچہ'
                          : (lang.isArabic ? 'السجل' : 'History'),
                      onTap: onHistory,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.grid_view_rounded,
                      label: lang.isUrdu
                          ? 'فوڈ لائبریری'
                          : (lang.isArabic ? 'دليل الأطعمة' : 'Food Library'),
                      onTap: onFoodChart,
                      c: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: lang.isUrdu
                          ? 'فوری تجاویز'
                          : (lang.isArabic ? 'نصائح سريعة' : 'Quick Tips'),
                      onTap: onQuickTips,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.settings_outlined,
                      label: lang.isUrdu
                          ? 'ترتیبات'
                          : (lang.isArabic ? 'الإعدادات' : 'Settings'),
                      onTap: onSettings,
                      c: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (onQuickAdd != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SoundService.playTap();
                      onQuickAdd!();
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(lang.t('quick_log_meal'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    SoundService.playTap();
                    onDoneForDay();
                  },
                  icon: Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: c.accent),
                  label: Text(lang.isUrdu
                      ? 'آج کا دن مکمل کریں؟'
                      : (lang.isArabic
                          ? 'إنهاء اليوم؟ (إعادة ضبط)'
                          : 'Done for the Day? (Finish & Reset)')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // ── Side-Attached Aesthetic Rank Badge ──────────────────────────────
        _DraggableRankBadge(
          c: c,
          rankData: rankData,
          canRecover: streakRecoveryInfo?['canRecover'] == true,
          onTap: () {
            SoundService.playTap();
            _showRankBottomSheet(context, c, rankData);
          },
        ),
      ],
    );
  }

// ── Updated Rank Logic Helper (Up to 365 Days) ───────────────────────────
  Map<String, dynamic> _calculateUserRank({
    required List<LoggedMeal> todayLogs,
    required int targetCalories,
    List<DailySummary>? history,
    List<String> repairedDates = const [],
    String langCode = 'en',
  }) {
    final now = DateTime.now();

    String toDateKey(DateTime d) {
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    // 1. Build map of date -> calories and goal across history
    final Map<String, double> dayCaloriesMap = {};
    final Map<String, int> dayGoalMap = {};

    if (history != null) {
      for (final s in history) {
        if (s.date.isNotEmpty) {
          dayCaloriesMap[s.date] = s.calories;
          dayGoalMap[s.date] = s.goal > 0 ? s.goal : targetCalories;
        }
      }
    }

    // Current live logs for today override or supply today's calories
    final todayKey = toDateKey(now);
    double todayCalories = 0;
    for (final l in todayLogs) {
      todayCalories += l.meal.calories;
    }
    if (todayLogs.isNotEmpty || !dayCaloriesMap.containsKey(todayKey)) {
      dayCaloriesMap[todayKey] = todayCalories;
      dayGoalMap[todayKey] = targetCalories;
    }

    // 2. Goal range check: target goal ± 100 kcal or repaired via rewarded ad
    bool isDateMet(String dateKey, double cals, int g) {
      if (repairedDates.contains(dateKey)) return true;
      if (g <= 0) return false;
      final minCals = g - 100;
      final maxCals = g + 100;
      return cals >= minCals && cals <= maxCals;
    }

    final bool todayMet =
        isDateMet(todayKey, dayCaloriesMap[todayKey] ?? 0, targetCalories);

    // 3. Count streak backwards starting from today or yesterday
    int currentStreak = 0;

    if (todayMet) {
      currentStreak = 1;
      var checkDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      while (true) {
        final key = toDateKey(checkDate);
        if (dayCaloriesMap.containsKey(key) || repairedDates.contains(key)) {
          final cals = dayCaloriesMap[key] ?? targetCalories.toDouble();
          final g = dayGoalMap[key] ?? targetCalories;
          if (isDateMet(key, cals, g)) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    } else {
      var checkDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final yesterdayKey = toDateKey(checkDate);

      final yesterdayHasData = dayCaloriesMap.containsKey(yesterdayKey) ||
          repairedDates.contains(yesterdayKey);

      if (yesterdayHasData &&
          isDateMet(
              yesterdayKey,
              dayCaloriesMap[yesterdayKey] ?? targetCalories.toDouble(),
              dayGoalMap[yesterdayKey] ?? targetCalories)) {
        while (true) {
          final key = toDateKey(checkDate);
          if (dayCaloriesMap.containsKey(key) || repairedDates.contains(key)) {
            final cals = dayCaloriesMap[key] ?? targetCalories.toDouble();
            final g = dayGoalMap[key] ?? targetCalories;
            if (isDateMet(key, cals, g)) {
              currentStreak++;
              checkDate = checkDate.subtract(const Duration(days: 1));
              continue;
            }
          }
          break;
        }
      } else {
        currentStreak = 0;
      }
    }

    // 4. Determine rank level, title, emoji based on currentStreak
    String emoji;
    int level;

    if (currentStreak >= 365) {
      level = 9;
      emoji = '👑';
    } else if (currentStreak >= 180) {
      level = 8;
      emoji = '💫';
    } else if (currentStreak >= 90) {
      level = 7;
      emoji = '🌟';
    } else if (currentStreak >= 60) {
      level = 6;
      emoji = '⚔️';
    } else if (currentStreak >= 30) {
      level = 5;
      emoji = '🛡️';
    } else if (currentStreak >= 14) {
      level = 4;
      emoji = '🔥';
    } else if (currentStreak >= 7) {
      level = 3;
      emoji = '⚡';
    } else if (currentStreak >= 4) {
      level = 2;
      emoji = '🥉';
    } else if (currentStreak >= 1) {
      level = 1;
      emoji = '🌱';
    } else {
      level = 0;
      emoji = '💤';
    }

    final title = AppTranslations.getRankTitle(level, langCode);

    return {
      'streak': currentStreak,
      'level': level,
      'title': title,
      'emoji': emoji,
      'todayMet': todayMet,
      'todayCalories': todayCalories,
    };
  }

  // ── Rank Popup Modal Sheet ───────────────────────────────────────────────
  void _showRankBottomSheet(
      BuildContext context, AppColors c, Map<String, dynamic> rankData) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.bg,
      isScrollControlled:
          true, // <--- Allows the sheet to adjust dynamically if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              // <--- Makes the content scrollable to prevent overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(rankData['emoji'], style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    rankData['title'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.isUrdu
                        ? '${lang.t('current_streak_label')}: ${rankData['streak']} ${lang.t('days')}'
                        : 'Current Streak: ${rankData['streak']} Days',
                    style: TextStyle(fontSize: 13, color: c.textSec),
                  ),
                  if (streakRecoveryInfo != null &&
                      streakRecoveryInfo!['canRecover'] == true) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.18),
                            c.card,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.isUrdu
                                          ? 'اسٹریک ٹوٹ گیا! (${streakRecoveryInfo!['brokenStreak']} دن ضائع ہوئے)'
                                          : (lang.isArabic
                                              ? 'انقطعت السلسلة! (فقدت ${streakRecoveryInfo!['brokenStreak']} أيام)'
                                              : 'Streak Broke! (${streakRecoveryInfo!['brokenStreak']} Days Lost)'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      lang.isUrdu
                                          ? 'دوبارہ کوشش کے لیے ${streakRecoveryInfo!['hoursLeft']} گھنٹے ${streakRecoveryInfo!['minutesLeft']} منٹ باقی'
                                          : (lang.isArabic
                                              ? 'متبقي ${streakRecoveryInfo!['hoursLeft']} س و ${streakRecoveryInfo!['minutesLeft']} د للمحاولة'
                                              : '${streakRecoveryInfo!['hoursLeft']}h ${streakRecoveryInfo!['minutesLeft']}m left to retry'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lang.isUrdu
                                ? 'آپ کا اسٹریک ٹوٹ گیا کیونکہ کل کا ہدف مکمل نہیں ہوا۔ 24 گھنٹے ختم ہونے سے پہلے اپنا ${streakRecoveryInfo!['brokenStreak']} دن کا اسٹریک بحال کرنے کے لیے ایک مختصر ویڈیو اشتہار دیکھیں!'
                                : (lang.isArabic
                                    ? 'انقطعت سلسلتك لعدم تحقيق الهدف بالأمس. شاهد إعلاناً قصيراً لاستعادة سلسلتك المكونة من ${streakRecoveryInfo!['brokenStreak']} أيام قبل انتهاء مهلة الـ 24 ساعة!'
                                    : 'Your streak broke because yesterday\'s target was missed. Watch a short rewarded video ad to restore your ${streakRecoveryInfo!['brokenStreak']}-day streak right now before the 24-hour window expires!'),
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSec,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onWatchRewardedAdForStreak?.call();
                              },
                              icon: const Icon(Icons.play_circle_fill_rounded,
                                  size: 20),
                              label: Text(
                                lang.isUrdu
                                    ? 'اسٹریک واپس پانے کے لیے اشتہار دیکھیں (${streakRecoveryInfo!['brokenStreak']} دن)'
                                    : (lang.isArabic
                                        ? 'شاهد إعلاناً لاستعادة السلسلة (${streakRecoveryInfo!['brokenStreak']} أيام)'
                                        : 'Watch Ad to Get Streak Back (${streakRecoveryInfo!['brokenStreak']} Days)'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700] ?? c.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
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
                            Icon(Icons.track_changes_rounded,
                                size: 18, color: c.accent),
                            const SizedBox(width: 8),
                            Text(
                              lang.t('rank_rules_title'),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang.isUrdu
                              ? '• ہدف ونڈو: اسٹریک شروع کرنے اور برقرار رکھنے کے لیے روزانہ ہدف کے ±100 کیلوری کے اندر رہیں (مثلاً اگر ہدف $goal ہے تو ${goal - 100} سے ${goal + 100} کیلوری کے درمیان رہیں)۔'
                              : (lang.isArabic
                                  ? '• نطاق الهدف: حافظ على سعراتك ضمن ±100 سعرة من هدفك اليومي (مثلاً إذا كان هدفك $goal سعرة، حقق بين ${goal - 100} و ${goal + 100} سعرة) لبدء وتمديد سلسلتك.'
                                  : '• Goal Target Window: Count within ±100 kcal of your daily goal (e.g., if your goal is $goal kcal, reach between ${goal - 100} and ${goal + 100} kcal) to start and extend your streak.'),
                          style: TextStyle(
                              fontSize: 12, color: c.textSec, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.isUrdu
                              ? '• 24 گھنٹے اسٹریک پروٹیکشن: آپ کا اسٹریک اس وقت تک نہیں ٹوٹے گا جب تک پورا دن بغیر ہدف کے نہ گزر جائے۔ صبح جاگنے پر آپ کا پچھلا اسٹریک محفوظ رہتا ہے تاکہ آپ نئے دن کے کھانے درج کر سکیں!'
                              : (lang.isArabic
                                  ? '• حماية السلسلة لمدة 24 ساعة: لن تنقطع سلسلتك حتى يمر يوم كامل (24 ساعة) دون تسجيل وجبات ضمن نطاقك. عند استيقاظك، تُحفظ سلسلتك السابقة أثناء تسجيلك لليوم الجديد!'
                                  : '• 24-Hour Streak Protection: Your streak won\'t break until a full 24-hour day passes with no meals logged in your target window. When you wake up, your previous streak is preserved while you log meals for the new day!'),
                          style: TextStyle(
                              fontSize: 12, color: c.textSec, height: 1.4),
                        ),
                        if (goal > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.bg2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.t('your_target_window'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: c.textMuted),
                                ),
                                Text(
                                  lang.isUrdu
                                      ? '${goal - 100} – ${goal + 100} کیلوری'
                                      : (lang.isArabic
                                          ? '${goal - 100} – ${goal + 100} سعرة'
                                          : '${goal - 100} – ${goal + 100} kcal'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.accent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(lang.t('keep_going'),
                          style: TextStyle(
                              color: c.bg, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary Roadmap Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.accent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close current sheet
                        _showAllRanksDialog(
                            context, c, rankData['level']); // Open roadmap
                      },
                      child: Text(lang.t('view_all_ranks'),
                          style: TextStyle(
                              color: c.accent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// ── Updated View All Ranks Roadmap Dialog ────────────────────────────────
  void _showAllRanksDialog(
      BuildContext context, AppColors c, int currentLevel) {
    final lang = context.read<LanguageProvider>();
    final List<Map<String, dynamic>> allRanks = [
      {
        'level': 9,
        'title': lang.getRankTitle(9),
        'emoji': '👑',
        'req': lang.getRankReq(9),
      },
      {
        'level': 8,
        'title': lang.getRankTitle(8),
        'emoji': '💫',
        'req': lang.getRankReq(8),
      },
      {
        'level': 7,
        'title': lang.getRankTitle(7),
        'emoji': '🌟',
        'req': lang.getRankReq(7),
      },
      {
        'level': 6,
        'title': lang.getRankTitle(6),
        'emoji': '⚔️',
        'req': lang.getRankReq(6),
      },
      {
        'level': 5,
        'title': lang.getRankTitle(5),
        'emoji': '🛡️',
        'req': lang.getRankReq(5),
      },
      {
        'level': 4,
        'title': lang.getRankTitle(4),
        'emoji': '🔥',
        'req': lang.getRankReq(4),
      },
      {
        'level': 3,
        'title': lang.getRankTitle(3),
        'emoji': '⚡',
        'req': lang.getRankReq(3),
      },
      {
        'level': 2,
        'title': lang.getRankTitle(2),
        'emoji': '🥉',
        'req': lang.getRankReq(2),
      },
      {
        'level': 1,
        'title': lang.getRankTitle(1),
        'emoji': '🌱',
        'req': lang.getRankReq(1),
      },
      {
        'level': 0,
        'title': lang.getRankTitle(0),
        'emoji': '💤',
        'req': lang.getRankReq(0),
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: c.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang.t('rank_roadmap_title'),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textPrimary),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Fixed height so the long list is cleanly scrollable
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allRanks.length,
              itemBuilder: (context, index) {
                final rank = allRanks[index];
                final bool isCurrent = rank['level'] == currentLevel;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isCurrent ? c.accent.withValues(alpha: 0.15) : c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? c.accent : c.border,
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(rank['emoji'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // <--- Wrap title in Flexible so it wraps if too long
                                Flexible(
                                  child: Text(
                                    rank['title'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isCurrent ? c.accent : c.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      lang.t('you'),
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: c.bg),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rank['req'],
                              style: TextStyle(fontSize: 11, color: c.textSec),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Added safety spacing
                      Text(
                        '${lang.t('lvl')} ${rank['level']}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('close'), style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColors c;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          SoundService.playTap();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: c.accent),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor, trackColor;
  _RingPainter(
      {required this.progress,
      required this.ringColor,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const sw = 18.0;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

class _MacroCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppColors c;
  const _MacroCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.c});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500, color: color)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: c.textSec)),
          ]),
        ),
      );
}

class _DraggableRankBadge extends StatefulWidget {
  final AppColors c;
  final Map<String, dynamic> rankData;
  final VoidCallback onTap;
  final bool canRecover;

  const _DraggableRankBadge({
    required this.c,
    required this.rankData,
    required this.onTap,
    this.canRecover = false,
  });

  @override
  State<_DraggableRankBadge> createState() => _DraggableRankBadgeState();
}

class _DraggableRankBadgeState extends State<_DraggableRankBadge> {
  double? _topPosition;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    // Set default initial position if not dragged yet
    _topPosition ??= screenHeight * 0.22;

    return Positioned(
      right: 0,
      top: _topPosition,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            // Update Y position and clamp it so it doesn't get dragged off-screen
            _topPosition = (_topPosition! + details.delta.dy)
                .clamp(90.0, screenHeight - 180.0);
          });
        },
        onHorizontalDragEnd: (details) {
          // Swipe left to expand, swipe right to tuck away
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -100) {
              setState(() => _isExpanded = true);
            } else if (details.primaryVelocity! > 100) {
              setState(() => _isExpanded = false);
            }
          }
        },
        onTap: () {
          // If tucked, first tap expands; if already expanded, open details dialog
          if (!_isExpanded) {
            SoundService.playTap();
            setState(() => _isExpanded = true);
          } else {
            widget.onTap();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 10 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.c.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              bottomLeft: const Radius.circular(16),
              topRight: _isExpanded ? const Radius.circular(8) : Radius.zero,
              bottomRight: _isExpanded ? const Radius.circular(8) : Radius.zero,
            ),
            border: Border.all(
              color: widget.canRecover
                  ? Colors.orange
                  : widget.c.accent.withValues(alpha: 0.4),
              width: widget.canRecover ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.canRecover
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(-2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.canRecover ? '🔥' : widget.rankData['emoji'],
                style: const TextStyle(fontSize: 16),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.canRecover
                                ? lang.t('recover')
                                : '${lang.isUrdu ? 'درجہ' : (lang.isArabic ? 'المستوى' : 'RANK')} ${widget.rankData['level']}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: widget.canRecover
                                  ? Colors.orange
                                  : widget.c.accent,
                            ),
                          ),
                          Text(
                            widget.canRecover
                                ? lang.t('lost_streak')
                                : (lang.isUrdu || lang.isArabic
                                    ? '${widget.rankData['streak']} ${lang.t('day_streak')}'
                                    : '${widget.rankData['streak']}d Streak'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.canRecover
                                  ? Colors.orange
                                  : widget.c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: widget.c.textMuted,
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final AppColors c;

  const _CalorieSummaryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _waterButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
  required AppColors c,
  bool isSecondary = false,
}) {
  return InkWell(
    onTap: () {
      SoundService.playTap();
      onTap();
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isSecondary
            ? c.bg
            : const Color(0xFF0EA5E9).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSecondary
              ? c.border
              : const Color(0xFF0EA5E9).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSecondary ? c.textMuted : const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSecondary ? c.textSec : const Color(0xFF0EA5E9),
            ),
          ),
        ],
      ),
    ),
  );
}
