import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
import 'models/meal.dart';
import 'screens/home_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/logs_screen.dart'; // NEW: Logs Screen import
import 'screens/feedback_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';
import 'services/theme_provider.dart';
import 'services/language_provider.dart';
import 'screens/quick_tips_screen.dart';
import 'screens/food_chart.dart';
import 'screens/history_screen.dart';
import 'screens/rank_screen.dart';
import 'screens/app_tour_overlay.dart';
import 'services/sound_service.dart';
import 'screens/goal_calculator_dialog.dart';
import 'screens/workout_dialog.dart';
import 'services/streak_service.dart';
import 'services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: 'https://mhhckkarxvpbgmlvlmsg.supabase.co',
    publishableKey: 'sb_publishable_Qr-hkvXuGKAiy0u7mb-0Ig_-914rbds',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            provider.load();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = LanguageProvider();
            provider.load();
            return provider;
          },
        ),
      ],
      child: const CalorieTrackerApp(),
    ),
  );
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;

    final colors = AppColors(isDark, themeProvider.accent);

    return MaterialApp(
      title: 'Fit Lyfe',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ur', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(AppColors(false, themeProvider.accent)),
      darkTheme: buildTheme(AppColors(true, themeProvider.accent)),
      themeMode: themeProvider.mode == AppThemeMode.system
          ? ThemeMode.system
          : themeProvider.mode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
      home: MainShell(colors: colors),
    );
  }
}

class MainShell extends StatefulWidget {
  final AppColors colors;
  const MainShell({super.key, required this.colors});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  List<Meal> _meals = [];
  List<LoggedMeal> _logs = [];
  List<DailySummary> _dailyHistory = [];
  bool _showRolloverPrompt = false;
  String _rolloverDate = '';
  int _goal = 2000;
  int _waterIntake = 0;
  int _waterGoal = 2000;
  List<LoggedExercise> _exercises = [];
  bool _loading = true;
  bool _showAppTour = false;
  final ScrollController _homeScrollController = ScrollController();

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  Map<String, dynamic> _streakRecoveryInfo = {};
  List<String> _repairedDates = [];

  AppColors get c => widget.colors;

  @override
  void initState() {
    super.initState();

    SoundService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MobileAds.instance.initialize();
      NotificationService().init().then((_) {
        NotificationService().requestPermissions();
      });
    });

    _loadAll();
    _initBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5263115271954461/4103986790',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-5263115271954461/2599333434',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialLoaded = false;
      _interstitialAd = null;
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId:
          'ca-app-pub-3940256099942544/5224354917', // Google AdMob Rewarded Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void _showRewardedAdForStreak() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          await StreakService.recoverStreak();
          await _loadAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🔥 Streak Recovered! Your streak is restored!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: c.accent3,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Reward video is loading, please try again in a moment...'),
          backgroundColor: c.accent,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _handleTabChange(int index) async {
    SoundService.playTab();
    setState(() => _tab = index);

    final prefs = await SharedPreferences.getInstance();
    int tabCount = prefs.getInt('persistent_tab_counter') ?? 0;
    tabCount++;

    if (tabCount >= 15) {
      tabCount = 0;
      _showInterstitialAd();
    }
    await prefs.setInt('persistent_tab_counter', tabCount);
  }

  Future<void> _handleMealLogged() async {
    final prefs = await SharedPreferences.getInstance();
    int logCount = prefs.getInt('persistent_log_counter') ?? 0;
    logCount++;

    if (logCount >= 15) {
      logCount = 0;
      _showInterstitialAd();
    }
    await prefs.setInt('persistent_log_counter', logCount);
  }

  Future<void> _handleSearchPerformed() async {
    final prefs = await SharedPreferences.getInstance();
    int searchCount = prefs.getInt('persistent_search_counter') ?? 0;
    searchCount++;

    if (searchCount >= 15) {
      searchCount = 0;
      _showInterstitialAd();
    }
    await prefs.setInt('persistent_search_counter', searchCount);
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      StorageService.getSavedMeals(),
      StorageService.getTodayLogs(),
      StorageService.getGoal(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    final history = await StorageService.getDailyHistory();
    final isRollover = await StorageService.isDayRolloverPending();
    final savedDate = await StorageService.getLoggedDate();
    final water = await StorageService.getWaterIntake();
    final waterGoal = await StorageService.getWaterGoal();
    final exercises = await StorageService.getLoggedExercises();

    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_app_tour') ?? false;

    final repaired = await StreakService.getRepairedDates();
    final rawStreak = StreakService.calculateStreak(
      todayLogs: results[1] as List<LoggedMeal>,
      targetCalories: results[2] as int,
      history: history,
      repairedDates: repaired,
    );
    final recoveryInfo = await StreakService.evaluateStreakState(
      rawCalculatedStreak: rawStreak,
      history: history,
      targetCalories: results[2] as int,
    );

    if (mounted) {
      setState(() {
        _meals = results[0] as List<Meal>;
        _logs = results[1] as List<LoggedMeal>;
        _goal = results[2] as int;
        _waterIntake = water;
        _waterGoal = waterGoal;
        _exercises = exercises;
        _dailyHistory = history;
        _repairedDates = repaired;
        _streakRecoveryInfo = recoveryInfo;
        _showRolloverPrompt =
            isRollover && (savedDate != null && savedDate.isNotEmpty);
        _rolloverDate = savedDate ?? '';
        _showAppTour = !hasSeenTour;
        _loading = false;
      });
    }

    if (_logs.isNotEmpty) {
      final sessionDate = StorageService.getSessionDate(_logs, savedDate);
      double burned = 0;
      for (final ex in exercises) {
        burned += ex.caloriesBurned;
      }
      final summary = DailySummary.fromLogs(
        date: sessionDate,
        logs: _logs,
        goal: _goal,
        waterIntake: water,
        burnedCalories: burned,
      );
      await StorageService.upsertDailySummary(summary);
      final today = StorageService.todayStr();
      if (sessionDate != today) {
        await StorageService.removeDuplicateSummary(
          keepDate: sessionDate,
          suspectDate: today,
          summary: summary,
        );
      }
      final updatedHistory = await StorageService.getDailyHistory();
      final updatedRawStreak = StreakService.calculateStreak(
        todayLogs: _logs,
        targetCalories: _goal,
        history: updatedHistory,
        repairedDates: _repairedDates,
      );
      final updatedRecoveryInfo = await StreakService.evaluateStreakState(
        rawCalculatedStreak: updatedRawStreak,
        history: updatedHistory,
        targetCalories: _goal,
      );
      if (mounted) {
        setState(() {
          _dailyHistory = updatedHistory;
          _streakRecoveryInfo = updatedRecoveryInfo;
        });
      }
    }
  }

  Future<void> _addMeal(Meal meal) async {
    setState(() => _meals.add(meal));
    await StorageService.saveMeals(_meals);
    if (meal.group.isNotEmpty) {
      await StorageService.saveCustomGroup(meal.group);
    }
  }

  Future<void> _deleteMeal(int i) async {
    setState(() => _meals.removeAt(i));
    await StorageService.saveMeals(_meals);
  }

  Future<void> _logMeal(Meal meal) async {
    final log = LoggedMeal(meal: meal, loggedAt: DateTime.now());
    setState(() => _logs.add(log));
    await StorageService.saveLogs(_logs);
    final history = await StorageService.getDailyHistory();
    if (mounted) {
      setState(() => _dailyHistory = history);
    }

    await _handleMealLogged();

    if (mounted) {
      final calStr = meal.calories % 1 == 0
          ? meal.calories.toInt().toString()
          : meal.calories.toStringAsFixed(1);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Logged "${meal.name}" ($calStr kcal)'),
      );
    }
  }

  Future<void> _removeLog(int i) async {
    setState(() => _logs.removeAt(i));
    await StorageService.saveLogs(_logs);
    final history = await StorageService.getDailyHistory();
    if (mounted) {
      setState(() => _dailyHistory = history);
    }
  }

// Inside your main screen state class:

  Future<void> _handleDoneForDay() async {
    if (!_showRolloverPrompt) {
      if (_logs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('No meals logged yet to finish the day.'),
        );
        return;
      }
      double totalCal = 0;
      for (final l in _logs) {
        totalCal += l.meal.calories;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.bg2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_outline_rounded,
                    color: c.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Done for the Day?',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'This will save your current totals (${totalCal.toInt()} kcal) to history and reset your counters for a fresh day.',
            style: TextStyle(color: c.textSec, fontSize: 13.5, height: 1.4),
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
                      foregroundColor: c.textSec,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Keep Logging',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    onPressed: () {
                      SoundService.playTap();
                      Navigator.pop(ctx, true);
                    },
                    label: const Text('Yes, Done',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await StorageService.finalizeDayAndReset();
    setState(() {
      _logs.clear();
      _waterIntake = 0;
      _exercises.clear();
      _showRolloverPrompt = false;
    });
    final updatedHistory = await StorageService.getDailyHistory();
    if (mounted) {
      setState(() => _dailyHistory = updatedHistory);
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Day finalized! Totals saved to your history.'),
      );
    }
  }

  Future<void> _handleKeepLogging() async {
    setState(() {
      _showRolloverPrompt = false;
    });
    await StorageService.continueLoggingCurrentDay();
  }

  Future<void> _resetDayWithUndo() async {
    final backup = List<LoggedMeal>.from(_logs);
    await StorageService.saveBackupLogs(backup); // <--- Save persistently

    setState(() {
      _logs.clear();
    });
    await StorageService.saveLogs(_logs);
  }

// When tapping UNDO:
  Future<void> _undoResetData() async {
    List<LoggedMeal> logsToRestore =
        await StorageService.getBackupLogs(); // <--- Load persistently

    setState(() {
      _logs = List<LoggedMeal>.from(logsToRestore);
    });
    await StorageService.saveLogs(_logs);
    await StorageService.clearBackupLogs(); // <--- Clean up after restoring
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (_) => GoalCalculatorDialog(
        currentGoal: _goal,
        onSave: (val) async {
          setState(() => _goal = val);
          await StorageService.saveGoal(val);
          if (_logs.isNotEmpty) {
            await StorageService.saveLogs(_logs);
          }
          final history = await StorageService.getDailyHistory();
          if (mounted) {
            setState(() => _dailyHistory = history);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              _snack('Daily goal set to $val kcal!'),
            );
          }
        },
        c: c,
      ),
    );
  }

  Future<void> _updateWaterIntake(int delta) async {
    final next = (_waterIntake + delta).clamp(0, 10000);
    setState(() => _waterIntake = next);
    await StorageService.saveWaterIntake(next);
  }

  void _editWaterGoal() {
    final ctrl = TextEditingController(text: _waterGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Daily Water Goal',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'Target (ml)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixText: 'ml',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [1500, 2000, 2500, 3000]
                  .map((v) => ActionChip(
                        label: Text('${v}ml',
                            style:
                                TextStyle(fontSize: 11, color: c.textPrimary)),
                        backgroundColor: c.bg3,
                        onPressed: () {
                          SoundService.playTap();
                          ctrl.text = v.toString();
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundService.playTap();
              Navigator.pop(ctx);
            },
            child: Text('Cancel', style: TextStyle(color: c.textSec)),
          ),
          ElevatedButton(
            onPressed: () async {
              SoundService.playTap();
              final val = int.tryParse(ctrl.text);
              if (val != null && val >= 500) {
                setState(() => _waterGoal = val);
                await StorageService.saveWaterGoal(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openWorkoutDialog() {
    showDialog(
      context: context,
      builder: (_) => WorkoutDialog(
        onLog: (exercise) async {
          final updated = List<LoggedExercise>.from(_exercises)
            ..insert(0, exercise);
          setState(() => _exercises = updated);
          await StorageService.saveLoggedExercises(updated);
          if (_logs.isNotEmpty) {
            await StorageService.saveLogs(_logs);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              _snack(
                  'Burned ${exercise.caloriesBurned.toInt()} kcal (${exercise.title})!'),
            );
          }
        },
        c: c,
      ),
    );
  }

  Future<void> _removeExercise(String id) async {
    final updated = List<LoggedExercise>.from(_exercises)
      ..removeWhere((e) => e.id == id);
    setState(() => _exercises = updated);
    await StorageService.saveLoggedExercises(updated);
    if (_logs.isNotEmpty) {
      await StorageService.saveLogs(_logs);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Workout entry removed'),
      );
    }
  }

  void _openAddMealDialog({Map<String, dynamic>? prefill}) {
    showDialog(
      context: context,
      builder: (_) => AddMealDialog(
        prefill: prefill,
        existingGroups: _meals
            .map((m) => m.group)
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList(),
        onSave: _addMeal,
        c: c,
      ),
    );
  }

  SnackBar _snack(String msg) => SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: c.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: c.bg2,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(milliseconds: 1800),
      );

  void _openQuickAddModal(AppColors c) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('quick_log_meal'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.border),
                ),
                tileColor: c.card,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_rounded, color: c.accent, size: 22),
                ),
                title: Text(lang.t('search_food_library'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontSize: 14)),
                subtitle: Text(lang.t('search_food_desc'),
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: c.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodChartScreen(
                        onLog: _logMeal,
                        onSaveMeal: _addMeal,
                        onSearchPerformed: _handleSearchPerformed,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.border),
                ),
                tileColor: c.card,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.amber, size: 22),
                ),
                title: Text(lang.t('quick_calorie_entry'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontSize: 14)),
                subtitle: Text(lang.t('quick_calorie_desc'),
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: c.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _showQuickCalorieDialog(c);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.border),
                ),
                tileColor: c.card,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded,
                      color: Colors.green, size: 22),
                ),
                title: Text('${lang.t('select_saved_meals')} (${_meals.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontSize: 14)),
                subtitle: Text(lang.t('select_saved_desc'),
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: c.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleTabChange(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickCalorieDialog(AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => _QuickCalorieDialog(
        c: c,
        onLog: _logMeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final platformDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;

    final c = AppColors(isDark, themeProvider.accent);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/app_icon3.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Fit Lyfe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageProvider.t('app_tagline'),
                style: TextStyle(
                  fontSize: 14,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }


    // 5-Tab Layout Setup
    final screens = [
      HomeScreen(
          logs: _logs,
          goal: _goal,
          history: _dailyHistory,
          showRolloverPrompt: _showRolloverPrompt,
          rolloverDate: _rolloverDate,
          onDoneForDay: _handleDoneForDay,
          onKeepDay: _handleKeepLogging,
          onSetGoal: _showGoalDialog,
          onRemoveLog: _removeLog,
          onWatchRewardedAdForStreak: _showRewardedAdForStreak,
          streakRecoveryInfo: _streakRecoveryInfo,
          repairedDates: _repairedDates,
          waterIntake: _waterIntake,
          waterGoal: _waterGoal,
          onUpdateWater: _updateWaterIntake,
          onEditWaterGoal: _editWaterGoal,
          exercises: _exercises,
          onLogWorkout: _openWorkoutDialog,
          onRemoveExercise: _removeExercise,
          onQuickTips: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuickTipsScreen()),
            );
          },
          onFoodChart: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodChartScreen(
                  onLog: _logMeal,
                  onSaveMeal: _addMeal,
                  onSearchPerformed: _handleSearchPerformed,
                ),
              ),
            );
          },
          onHistory: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(
                  c: c,
                  todayLogs: _logs,
                  currentGoal: _goal,
                ),
              ),
            );
          },
          onQuickAdd: () => _openQuickAddModal(c),
          onSettings: () {
            // Navigate to Settings screen programmatically
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  onStartTour: () {
                    setState(() => _showAppTour = true);
                  },
                ),
              ),
            );
          },
          scrollController: _homeScrollController,
          c: c),
      MealsScreen(
          meals: _meals,
          onAdd: _openAddMealDialog,
          onLog: _logMeal,
          onDelete: _deleteMeal,
          onLoadStarterMeals: () async {
            final starters = StorageService.defaultStarterMeals;
            setState(() => _meals.addAll(starters));
            await StorageService.saveMeals(_meals);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              _snack('Loaded ${starters.length} starter meals!'),
            );
          },
          c: c),
      LogsScreen(
        logs: _logs,
        onRemoveLog: _removeLog,
        onResetDay: _resetDayWithUndo,
        onUndoReset:
            _undoResetData, // If you have your undo logic hooked up here
        onNavigateToMeals: () => _handleTabChange(1),
        onQuickAdd: () => _openQuickAddModal(c),
        c: c,
      ),
      FeedbackScreen(c: c),
      FoodChartScreen(
        onLog: _logMeal,
        onSaveMeal: _addMeal,
        onSearchPerformed: _handleSearchPerformed,
      ),
      RankRoadmapScreen(
        rankData: StreakService.calculateUserRank(
          todayLogs: _logs,
          targetCalories: _goal,
          history: _dailyHistory,
          repairedDates: _repairedDates,
          langCode: languageProvider.currentLanguage,
        ),
        goal: _goal,
        onBack: () => setState(() => _tab = 0),
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: c.bg,
          floatingActionButton: _tab == 0
              ? FloatingActionButton(
                  onPressed: () {
                    SoundService.playTap();
                    _openQuickAddModal(c);
                  },
                  backgroundColor: c.accent,
                  foregroundColor:
                      c.accentType == AppAccentColor.black && c.dark
                          ? Colors.black
                          : Colors.white,
                  elevation: 4,
                  tooltip: languageProvider.t('quick_log_meal'),
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
          // Change this from screens[_tab] to IndexedStack so states are never destroyed!
          body: SafeArea(
            child: IndexedStack(
              index: _tab > 5 ? 0 : _tab,
              children: screens,
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAdLoaded && _bannerAd != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      color: c.navBg,
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                BottomNavigationBar(
                  currentIndex: _tab > 3 ? 0 : _tab,
                  onTap: _handleTabChange,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: c.navBg,
                  selectedItemColor: c.accent,
                  unselectedItemColor: c.textMuted,
                  selectedLabelStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: [
                    BottomNavigationBarItem(
                        icon: const Icon(Icons.home_rounded),
                        label: languageProvider.t('tab_home')),
                    BottomNavigationBarItem(
                        icon: const Icon(Icons.restaurant_menu_rounded),
                        label: languageProvider.t('tab_meals')),
                    BottomNavigationBarItem(
                        icon: const Icon(Icons.list_alt_rounded),
                        label: languageProvider.t('tab_logs')),
                    BottomNavigationBarItem(
                        icon: const Icon(Icons.feedback_rounded),
                        label: languageProvider.t('tab_feedback')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showAppTour)
          AppTourOverlay(
            c: c,
            onTabChangeRequested: (tabIndex) {
              setState(() => _tab = tabIndex);
            },
            onScrollRequested: (offset) {
              if (_homeScrollController.hasClients) {
                _homeScrollController.animateTo(
                  offset.clamp(
                      0.0, _homeScrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                );
              }
            },
            onFinish: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_seen_app_tour', true);
              if (mounted) {
                setState(() {
                  _showAppTour = false;
                  _tab = 0;
                });
                if (_homeScrollController.hasClients) {
                  _homeScrollController.jumpTo(0.0);
                }
              }
            },
          ),
      ],
    );
  }
}

class _QuickCalorieDialog extends StatefulWidget {
  final AppColors c;
  final Function(Meal) onLog;

  const _QuickCalorieDialog({required this.c, required this.onLog});

  @override
  State<_QuickCalorieDialog> createState() => _QuickCalorieDialogState();
}

class _QuickCalorieDialogState extends State<_QuickCalorieDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _calCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Quick Snack');
    _calCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final cal = double.tryParse(_calCtrl.text.trim()) ?? 0;
    if (cal > 0) {
      final name = _nameCtrl.text.trim().isEmpty
          ? 'Quick Snack'
          : _nameCtrl.text.trim();
      final quickMeal = Meal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        group: 'Snacks',
        calories: cal,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sodium: 0,
      );
      widget.onLog(quickMeal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final lang = context.watch<LanguageProvider>();
    return Dialog(
      backgroundColor: c.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('quick_calorie_entry'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: lang.t('meal_name'),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: lang.t('enter_meal_name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: '${lang.t('calories')} (kcal)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'e.g. 250',
                suffixText: 'kcal',
                suffixStyle: TextStyle(color: c.textMuted),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      SoundService.playTap();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSec,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(lang.t('cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      SoundService.playTap();
                      _submit();
                    },
                    child: Text(lang.t('save')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
