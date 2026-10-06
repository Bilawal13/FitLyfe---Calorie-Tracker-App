import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

class StorageService {
  static const _mealsKey = 'saved_meals';
  static const _logsKey = 'logged_meals';
  static const _goalKey = 'calorie_goal';
  static const _logDateKey = 'log_date';
  static const _backupLogsKey =
      'backup_logged_meals'; // <--- Added key for backup

  static Future<List<Meal>> getSavedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null) return [];
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
    if (prefs.getString(_logDateKey) != today) {
      await prefs.setString(_logDateKey, today);
      await prefs.remove(_logsKey);
      return [];
    }
    final raw = prefs.getString(_logsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => LoggedMeal.fromJson(e))
        .toList();
  }

  static Future<void> saveLogs(List<LoggedMeal> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _logsKey, jsonEncode(logs.map((l) => l.toJson()).toList()));
    await prefs.setString(_logDateKey, _todayStr());
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

  static Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 2000;
  }

  static Future<void> saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, goal);
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
