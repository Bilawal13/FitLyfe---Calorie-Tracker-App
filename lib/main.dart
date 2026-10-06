import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'screens/quick_tips_screen.dart';
import 'screens/food_chart.dart';
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
    ChangeNotifierProvider(
      create: (_) {
        final provider = ThemeProvider();
        provider.load();
        return provider;
      },
      child: const CalorieTrackerApp(),
    ),
  );
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;

    final colors = AppColors(isDark, themeProvider.accent);

    return MaterialApp(
      title: 'Fit Lyfe',
      debugShowCheckedModeBanner: false,
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
  List<LoggedMeal> _backupLogs = [];
  int _goal = 2000;
  bool _loading = true;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;

  bool _showGlobalUndoBanner = false;
  Timer? _globalUndoTimer;

  AppColors get c => widget.colors;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MobileAds.instance.initialize();
    });

    _loadAll();
    _initBannerAd();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _globalUndoTimer?.cancel();
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

  Future<void> _handleTabChange(int index) async {
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

    if (logCount >= 10) {
      logCount = 0;
      _showInterstitialAd();
    }
    await prefs.setInt('persistent_log_counter', logCount);
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      StorageService.getSavedMeals(),
      StorageService.getTodayLogs(),
      StorageService.getGoal(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    setState(() {
      _meals = results[0] as List<Meal>;
      _logs = results[1] as List<LoggedMeal>;
      _goal = results[2] as int;
      _loading = false;
    });
  }

  Future<void> _addMeal(Meal meal) async {
    setState(() => _meals.add(meal));
    await StorageService.saveMeals(_meals);
  }

  Future<void> _deleteMeal(int i) async {
    setState(() => _meals.removeAt(i));
    await StorageService.saveMeals(_meals);
  }

  Future<void> _logMeal(Meal meal) async {
    final log = LoggedMeal(meal: meal, loggedAt: DateTime.now());
    setState(() => _logs.add(log));
    await StorageService.saveLogs(_logs);

    await _handleMealLogged();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(_snack('"${meal.name}" logged!'));
    }
  }

  Future<void> _removeLog(int i) async {
    setState(() => _logs.removeAt(i));
    await StorageService.saveLogs(_logs);
  }

// Inside your main screen state class:

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
    final ctrl = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: c.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Set Daily Calorie Goal',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Calories (kcal)',
                suffixText: 'kcal',
                suffixStyle: TextStyle(color: c.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSec,
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final val = int.tryParse(ctrl.text);
                    if (val != null && val >= 500) {
                      setState(() => _goal = val);
                      await StorageService.saveGoal(val);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _openAddMealDialog({Map<String, dynamic>? prefill}) {
    showDialog(
      context: context,
      builder: (_) => AddMealDialog(
        prefill: prefill,
        onSave: _addMeal,
        c: c,
      ),
    );
  }

  SnackBar _snack(String msg) => SnackBar(
        content: Text(msg),
        backgroundColor: c.accent3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 48,
                  color: c.accent,
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
                'Track your nutrition seamlessly',
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
          onSetGoal: _showGoalDialog,
          onRemoveLog: _removeLog,
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
                ),
              ),
            );
          },
          onSettings: () {
            // Navigate to Settings screen programmatically
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          c: c),
      MealsScreen(
          meals: _meals,
          onAdd: _openAddMealDialog,
          onLog: _logMeal,
          onDelete: _deleteMeal,
          c: c),
      LogsScreen(
        logs: _logs,
        onRemoveLog: _removeLog,
        onResetDay: _resetDayWithUndo,
        onUndoReset:
            _undoResetData, // If you have your undo logic hooked up here
        c: c,
      ),
      FeedbackScreen(c: c),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      // Change this from screens[_tab] to IndexedStack so states are never destroyed!
      body: SafeArea(
        child: IndexedStack(
          index: _tab > 3 ? 0 : _tab,
          children: screens,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdLoaded && _bannerAd != null)
            Container(
              color: c.navBg,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          BottomNavigationBar(
            currentIndex: _tab > 3 ? 0 : _tab,
            onTap: _handleTabChange,
            type: BottomNavigationBarType.fixed,
            backgroundColor: c.navBg,
            selectedItemColor: c.accent,
            unselectedItemColor: c.textMuted,
            selectedLabelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded), label: 'Meals'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_rounded), label: 'Logs'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.feedback_rounded), label: 'Feedback'),
            ],
          ),
        ],
      ),
    );
  }
}
