import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import 'language_provider.dart';

class StreakService {
  static const _lastActiveStreakKey = 'streak_last_active';
  static const _brokenStreakCountKey = 'streak_broken_count';
  static const _streakBrokenAtKey = 'streak_broken_at_timestamp';
  static const _streakRepairUsedKey = 'streak_repair_used';
  static const _repairedDatesKey = 'streak_repaired_dates';

  static String toDateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Evaluates current streak and determines if a 24-hour streak recovery is available
  static Future<Map<String, dynamic>> evaluateStreakState({
    required int rawCalculatedStreak,
    required List<DailySummary>? history,
    required int targetCalories,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    int lastActiveStreak = prefs.getInt(_lastActiveStreakKey) ?? 0;
    int brokenStreak = prefs.getInt(_brokenStreakCountKey) ?? 0;
    int? brokenAtMs = prefs.getInt(_streakBrokenAtKey);
    bool repairUsed = prefs.getBool(_streakRepairUsedKey) ?? false;
    final List<String> repairedDates = prefs.getStringList(_repairedDatesKey) ?? [];

    if (rawCalculatedStreak > 0) {
      // User has an active streak right now!
      if (rawCalculatedStreak >= lastActiveStreak) {
        await prefs.setInt(_lastActiveStreakKey, rawCalculatedStreak);
        lastActiveStreak = rawCalculatedStreak;
      }
      // If user had previously used a repair and is now actively continuing, reset repairUsed
      if (repairUsed && rawCalculatedStreak > brokenStreak) {
        await prefs.setBool(_streakRepairUsedKey, false);
      }
    } else {
      // Streak is 0. Check if a previously active streak just broke.
      if (lastActiveStreak > 0 && brokenStreak == 0 && !repairUsed) {
        brokenStreak = lastActiveStreak;
        brokenAtMs = now.millisecondsSinceEpoch;
        await prefs.setInt(_brokenStreakCountKey, brokenStreak);
        await prefs.setInt(_streakBrokenAtKey, brokenAtMs);
        await prefs.setInt(_lastActiveStreakKey, 0);
        await prefs.setBool(_streakRepairUsedKey, false);
      } else if (brokenStreak == 0 && !repairUsed) {
        // Fallback: Check history to see if there was an active streak ending before yesterday
        final priorStreak = _calculatePriorStreakFromHistory(history, targetCalories);
        if (priorStreak > 0) {
          brokenStreak = priorStreak;
          brokenAtMs = now.millisecondsSinceEpoch;
          await prefs.setInt(_brokenStreakCountKey, brokenStreak);
          await prefs.setInt(_streakBrokenAtKey, brokenAtMs);
          await prefs.setInt(_lastActiveStreakKey, 0);
          await prefs.setBool(_streakRepairUsedKey, false);
        }
      }
    }

    // Check 24-hour expiration window
    bool canRecover = false;
    int hoursLeft = 0;
    int minutesLeft = 0;

    if (brokenStreak > 0 && !repairUsed && brokenAtMs != null) {
      final brokenTime = DateTime.fromMillisecondsSinceEpoch(brokenAtMs);
      final elapsed = now.difference(brokenTime);

      if (elapsed.inHours < 24) {
        canRecover = true;
        final remaining = const Duration(hours: 24) - elapsed;
        hoursLeft = remaining.inHours;
        minutesLeft = remaining.inMinutes % 60;
      } else {
        // More than 24 hours have passed! The retry window has expired.
        // The button disappears until the NEXT time a streak is built and breaks.
        canRecover = false;
      }
    }

    return {
      'canRecover': canRecover,
      'brokenStreak': brokenStreak,
      'hoursLeft': hoursLeft,
      'minutesLeft': minutesLeft,
      'repairedDates': repairedDates,
    };
  }

  /// Calculates a prior streak ending on day-before-yesterday if yesterday was missed
  static int _calculatePriorStreakFromHistory(List<DailySummary>? history, int targetCalories) {
    if (history == null || history.isEmpty) return 0;

    final Map<String, double> dayCaloriesMap = {};
    final Map<String, int> dayGoalMap = {};

    for (final s in history) {
      if (s.date.isNotEmpty) {
        dayCaloriesMap[s.date] = s.calories;
        dayGoalMap[s.date] = s.goal > 0 ? s.goal : targetCalories;
      }
    }

    final now = DateTime.now();
    // Yesterday was missed, start checking from 2 days ago
    var checkDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
    int priorStreak = 0;

    while (true) {
      final key = toDateKey(checkDate);
      if (dayCaloriesMap.containsKey(key)) {
        final cals = dayCaloriesMap[key]!;
        final g = dayGoalMap[key] ?? targetCalories;
        final minCals = g - 100;
        final maxCals = g + 100;
        if (cals >= minCals && cals <= maxCals) {
          priorStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
      }
      break;
    }

    return priorStreak;
  }

  /// Recovers the broken streak after watching the rewarded ad
  static Future<bool> recoverStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final int brokenStreak = prefs.getInt(_brokenStreakCountKey) ?? 0;
    if (brokenStreak <= 0) return false;

    // Yesterday's date was the missing link
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final yesterdayKey = toDateKey(yesterday);

    final List<String> repairedDates = prefs.getStringList(_repairedDatesKey) ?? [];
    if (!repairedDates.contains(yesterdayKey)) {
      repairedDates.add(yesterdayKey);
      await prefs.setStringList(_repairedDatesKey, repairedDates);
    }

    await prefs.setBool(_streakRepairUsedKey, true);
    await prefs.setInt(_lastActiveStreakKey, brokenStreak);
    await prefs.setInt(_brokenStreakCountKey, 0);
    await prefs.remove(_streakBrokenAtKey);

    return true;
  }

  /// Get list of repaired date keys
  static Future<List<String>> getRepairedDates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_repairedDatesKey) ?? [];
  }

  /// Calculates the current streak given logs, goal, history, and repaired dates
  static int calculateStreak({
    required List<LoggedMeal> todayLogs,
    required int targetCalories,
    List<DailySummary>? history,
    List<String> repairedDates = const [],
  }) {
    final now = DateTime.now();

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

    final todayKey = toDateKey(now);
    final sessionKey = todayLogs.isNotEmpty
        ? toDateKey(todayLogs.first.loggedAt)
        : todayKey;
    double logCalories = 0;
    for (final l in todayLogs) {
      logCalories += l.meal.calories;
    }
    if (todayLogs.isNotEmpty) {
      dayCaloriesMap[sessionKey] = logCalories;
      dayGoalMap[sessionKey] = targetCalories;
    }
    if (!dayCaloriesMap.containsKey(todayKey)) {
      dayCaloriesMap[todayKey] = (sessionKey == todayKey) ? logCalories : 0;
      dayGoalMap[todayKey] = targetCalories;
    }

    bool isDateMet(String dateKey, double cals, int g) {
      if (repairedDates.contains(dateKey)) return true;
      if (g <= 0) return false;
      final minCals = g - 100;
      final maxCals = g + 100;
      return cals >= minCals && cals <= maxCals;
    }

    final bool todayMet =
        isDateMet(todayKey, dayCaloriesMap[todayKey] ?? 0, targetCalories);

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

    return currentStreak;
  }

  /// Calculates the active user rank, level, streak, and status
  static Map<String, dynamic> calculateUserRank({
    required List<LoggedMeal> todayLogs,
    required int targetCalories,
    List<DailySummary>? history,
    List<String> repairedDates = const [],
    String langCode = 'en',
  }) {
    final now = DateTime.now();

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

    final todayKey = toDateKey(now);
    double todayCalories = 0;
    for (final l in todayLogs) {
      todayCalories += l.meal.calories;
    }
    if (todayLogs.isNotEmpty || !dayCaloriesMap.containsKey(todayKey)) {
      dayCaloriesMap[todayKey] = todayCalories;
      dayGoalMap[todayKey] = targetCalories;
    }

    bool isDateMet(String dateKey, double cals, int g) {
      if (repairedDates.contains(dateKey)) return true;
      if (g <= 0) return false;
      final minCals = g - 100;
      final maxCals = g + 100;
      return cals >= minCals && cals <= maxCals;
    }

    final bool todayMet =
        isDateMet(todayKey, dayCaloriesMap[todayKey] ?? 0, targetCalories);

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
}
