import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

class StorageService {
  static const _mealsKey = 'saved_meals';
  static const _logsKey = 'logged_meals';
  static const _goalKey = 'calorie_goal';
  static const _logDateKey = 'log_date';
  static const _customGroupsKey = 'custom_meal_groups';
  static const _backupLogsKey =
      'backup_logged_meals'; // <--- Added key for backup
  static const _historyKey = 'daily_summaries_history';
  static const _dismissedRolloverDateKey = 'dismissed_rollover_date';

  /// Helper to determine the true creation date of a logging session (YYYY-MM-DD)
  static String getSessionDate(List<LoggedMeal> logs, [String? fallbackDate]) {
    if (logs.isNotEmpty) {
      final d = logs.first.loggedAt;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (fallbackDate != null && fallbackDate.isNotEmpty) {
      return fallbackDate;
    }
    return todayStr();
  }

  static List<Meal> get defaultStarterMeals => [
        Meal(
          id: 'starter_1',
          name: '2 Scrambled Eggs & Whole Wheat Toast',
          group: 'Breakfast',
          calories: 320,
          protein: 16,
          carbs: 26,
          fat: 16,
          fiber: 4,
          sodium: 380,
        ),
        Meal(
          id: 'starter_2',
          name: 'Oatmeal with Milk & Banana',
          group: 'Breakfast',
          calories: 350,
          protein: 12,
          carbs: 62,
          fat: 6,
          fiber: 7,
          sodium: 120,
        ),
        Meal(
          id: 'starter_3',
          name: 'Grilled Chicken Breast & White Rice',
          group: 'Lunch',
          calories: 450,
          protein: 42,
          carbs: 45,
          fat: 9,
          fiber: 2,
          sodium: 390,
        ),
        Meal(
          id: 'starter_4',
          name: 'Chicken Rice Bowl with Veggies',
          group: 'Dinner',
          calories: 520,
          protein: 44,
          carbs: 58,
          fat: 12,
          fiber: 6,
          sodium: 480,
        ),
        Meal(
          id: 'starter_5',
          name: 'Greek Yogurt with Berries & Honey',
          group: 'Snacks',
          calories: 210,
          protein: 18,
          carbs: 28,
          fat: 3,
          fiber: 4,
          sodium: 70,
        ),
        Meal(
          id: 'starter_6',
          name: 'Whey Protein Shake (with Water)',
          group: 'Snacks',
          calories: 130,
          protein: 25,
          carbs: 3,
          fat: 2,
          fiber: 1,
          sodium: 140,
        ),
      ];

  static Future<List<Meal>> getSavedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null) {
      final starters = defaultStarterMeals;
      await saveMeals(starters);
      return starters;
    }
    return (jsonDecode(raw) as List).map((e) => Meal.fromJson(e)).toList();
  }

  static Future<void> saveMeals(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _mealsKey, jsonEncode(meals.map((m) => m.toJson()).toList()));
  }

  static Future<List<LoggedMeal>> getTodayLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_logDateKey);

    if (savedDate == null) {
      await prefs.setString(_logDateKey, today);
    }

    // Do NOT automatically wipe logs on date change!
    // The user will be asked if they are done for the day instead.
    final raw = prefs.getString(_logsKey);
    if (raw == null) return [];
    final logs = (jsonDecode(raw) as List)
        .map((e) => LoggedMeal.fromJson(e))
        .toList();
    if (logs.isNotEmpty) {
      final creationDate = getSessionDate(logs, savedDate);
      if (savedDate != creationDate) {
        await prefs.setString(_logDateKey, creationDate);
      }
    }
    return logs;
  }

  static Future<String?> getLoggedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_logDateKey);
  }

  static Future<bool> isDayRolloverPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logsKey);
    if (raw == null || raw.isEmpty || raw == '[]') {
      return false;
    }
    final today = _todayStr();
    final dismissed = prefs.getString(_dismissedRolloverDateKey);
    if (dismissed == today) {
      return false;
    }
    final savedDate = prefs.getString(_logDateKey);
    if (savedDate != null && savedDate != today) {
      return true;
    }
    return false;
  }

  static Future<void> continueLoggingCurrentDay() async {
    final prefs = await SharedPreferences.getInstance();
    // Do NOT overwrite _logDateKey with today! Overwriting it destroys the original creation date.
    // Instead, remember that rollover was dismissed for today so we don't prompt again today.
    await prefs.setString(_dismissedRolloverDateKey, _todayStr());
  }

  static const _waterIntakeKey = 'daily_water_intake';
  static const _waterGoalKey = 'daily_water_goal';
  static const _exercisesKey = 'daily_logged_exercises';

  static Future<int> getWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterIntakeKey) ?? 0;
  }

  static Future<void> saveWaterIntake(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterIntakeKey, ml);
  }

  static Future<int> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterGoalKey) ?? 2000;
  }

  static Future<void> saveWaterGoal(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, ml);
  }

  static Future<List<LoggedExercise>> getLoggedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exercisesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LoggedExercise.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLoggedExercises(List<LoggedExercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _exercisesKey, jsonEncode(exercises.map((e) => e.toJson()).toList()));
  }

  static Future<void> finalizeDayAndReset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final raw = prefs.getString(_logsKey);
    if (raw != null) {
      try {
        final oldLogs = (jsonDecode(raw) as List)
            .map((e) => LoggedMeal.fromJson(e))
            .toList();
        if (oldLogs.isNotEmpty) {
          final creationDate = getSessionDate(
            oldLogs,
            prefs.getString(_logDateKey) ?? today,
          );
          final goal = prefs.getInt(_goalKey) ?? 2000;
          final water = await getWaterIntake();
          final exercises = await getLoggedExercises();
          double burned = 0;
          for (final ex in exercises) {
            burned += ex.caloriesBurned;
          }

          final summary = DailySummary.fromLogs(
            date: creationDate,
            logs: oldLogs,
            goal: goal,
            waterIntake: water,
            burnedCalories: burned,
          );
          await upsertDailySummary(summary);

          // If tracking finished on a day later than creation date,
          // make sure no phantom duplicate exists on the finish date or later
          if (creationDate != today) {
            await removeDuplicateSummary(
              keepDate: creationDate,
              suspectDate: today,
              summary: summary,
            );
          }
        }
      } catch (_) {}
    }
    await prefs.setString(_logDateKey, today);
    await prefs.remove(_logsKey);
    await prefs.remove(_dismissedRolloverDateKey);
    await prefs.remove(_waterIntakeKey);
    await prefs.remove(_exercisesKey);
  }

  static Future<void> saveLogs(List<LoggedMeal> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _logsKey, jsonEncode(logs.map((l) => l.toJson()).toList()));
    final today = _todayStr();
    final creationDate = getSessionDate(
      logs,
      prefs.getString(_logDateKey) ?? today,
    );
    await prefs.setString(_logDateKey, creationDate);

    // Save summary strictly under the day the tracking session was created
    if (logs.isNotEmpty) {
      final goal = prefs.getInt(_goalKey) ?? 2000;
      final water = await getWaterIntake();
      final exercises = await getLoggedExercises();
      double burned = 0;
      for (final ex in exercises) {
        burned += ex.caloriesBurned;
      }
      final summary = DailySummary.fromLogs(
        date: creationDate,
        logs: logs,
        goal: goal,
        waterIntake: water,
        burnedCalories: burned,
      );
      await upsertDailySummary(summary);

      if (creationDate != today) {
        await removeDuplicateSummary(
          keepDate: creationDate,
          suspectDate: today,
          summary: summary,
        );
      }
    }
  }

  // --- DAILY HISTORY METHODS ---

  /// Removes any duplicate summaries that share the exact same nutritional facts
  /// but have different dates, keeping only the earliest date (the creation date).
  static List<DailySummary> deduplicateDailySummaries(List<DailySummary> list) {
    if (list.length <= 1) return list;
    // Sort chronological: earliest first so creation dates take priority
    final sorted = List<DailySummary>.from(list)
      ..sort((a, b) => a.date.compareTo(b.date));
    final List<DailySummary> result = [];

    for (final item in sorted) {
      final isDuplicate = result.any((existing) =>
          existing.date != item.date &&
          existing.mealCount > 0 &&
          existing.mealCount == item.mealCount &&
          (existing.calories - item.calories).abs() < 0.1 &&
          (existing.protein - item.protein).abs() < 0.1 &&
          (existing.carbs - item.carbs).abs() < 0.1 &&
          (existing.fat - item.fat).abs() < 0.1 &&
          (existing.fiber - item.fiber).abs() < 0.1 &&
          (existing.sodium - item.sodium).abs() < 0.1);

      if (!isDuplicate) {
        result.add(item);
      }
    }

    // Sort descending by date (newest first)
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  static Future<void> removeDuplicateSummary({
    required String keepDate,
    required String suspectDate,
    required DailySummary summary,
  }) async {
    if (keepDate == suspectDate) return;
    final history = await getDailyHistory();
    final initialLen = history.length;
    history.removeWhere((h) =>
        h.date == suspectDate &&
        h.mealCount == summary.mealCount &&
        (h.calories - summary.calories).abs() < 0.1 &&
        (h.protein - summary.protein).abs() < 0.1 &&
        (h.carbs - summary.carbs).abs() < 0.1 &&
        (h.fat - summary.fat).abs() < 0.1);
    if (history.length != initialLen) {
      await saveDailyHistory(history);
    }
  }

  static Future<List<DailySummary>> getDailyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => DailySummary.fromJson(e))
          .toList();
      final deduped = deduplicateDailySummaries(list);
      if (deduped.length != list.length) {
        await saveDailyHistory(deduped);
      }
      return deduped;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDailyHistory(List<DailySummary> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((h) => h.toJson()).toList()),
    );
  }

  static Future<void> upsertDailySummary(DailySummary summary) async {
    if (summary.date.isEmpty) return;
    final history = await getDailyHistory();
    final index = history.indexWhere((h) => h.date == summary.date);
    if (index >= 0) {
      history[index] = summary;
    } else {
      history.add(summary);
    }
    final deduped = deduplicateDailySummaries(history);
    await saveDailyHistory(deduped);
  }

  static Future<void> deleteDailySummary(String date) async {
    final history = await getDailyHistory();
    history.removeWhere((h) => h.date == date);
    await saveDailyHistory(history);
  }

  static Future<void> clearDailyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // --- NEW METHODS FOR PERSISTENT UNDO BACKUPS ---

  static Future<void> saveBackupLogs(List<LoggedMeal> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _backupLogsKey, jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  static Future<List<LoggedMeal>> getBackupLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_backupLogsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => LoggedMeal.fromJson(e))
        .toList();
  }

  static Future<void> clearBackupLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupLogsKey);
  }

  // ----------------------------------------------

  static Future<List<String>> getCustomGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customGroupsKey) ?? [];
  }

  static Future<void> saveCustomGroup(String group) async {
    final trimmed = group.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_customGroupsKey) ?? [];
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      await prefs.setStringList(_customGroupsKey, list);
    }
  }

  static Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 2000;
  }

  static Future<void> saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, goal);
  }

  static String todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _todayStr() => todayStr();
}
