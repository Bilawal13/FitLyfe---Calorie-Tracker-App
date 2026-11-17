import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure this is imported
import '../models/meal.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';
import '../services/language_provider.dart';

class LogsScreen extends StatefulWidget {
  final List<LoggedMeal> logs;
  final Function(int) onRemoveLog;
  final VoidCallback onResetDay;
  final VoidCallback? onUndoReset;
  final VoidCallback? onNavigateToMeals;
  final VoidCallback? onQuickAdd;
  final AppColors c;

  const LogsScreen({
    super.key,
    required this.logs,
    required this.onRemoveLog,
    required this.onResetDay,
    this.onUndoReset,
    this.onNavigateToMeals,
    this.onQuickAdd,
    required this.c,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _showUndoBanner = false;
  DateTime? _expirationTime;
  Timer? _countdownTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkSavedUndoState(); // Check if there's an active undo window when app opens
  }

  Future<void> _checkSavedUndoState() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString('reset_undo_expiry');

    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (expiry.isAfter(DateTime.now())) {
        // The 2-hour window is still active!
        setState(() {
          _expirationTime = expiry;
          _showUndoBanner = true;
        });
        _startCountdownTicker();
      } else {
        // Expired while app was closed, clean up storage
        prefs.remove('reset_undo_expiry');
      }
    }
  }

  void _triggerReset() async {
    widget.onResetDay();

    final expiry = DateTime.now().add(const Duration(hours: 2));
    _expirationTime = expiry;

    // Save expiration time persistently
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reset_undo_expiry', expiry.toIso8601String());

    setState(() {
      _showUndoBanner = true;
    });

    _startCountdownTicker();
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _expirationTime == null) {
        timer.cancel();
        return;
      }

      final remaining = _expirationTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        _clearSavedUndoState();
        if (mounted) {
          setState(() {
            _showUndoBanner = false;
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _clearSavedUndoState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reset_undo_expiry');
  }

  void _triggerUndo() async {
    _countdownTimer?.cancel();
    await _clearSavedUndoState();

    setState(() {
      _showUndoBanner = false;
    });

    if (widget.onUndoReset != null) {
      widget.onUndoReset!();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getRemainingTimeString() {
    if (_expirationTime == null) return '02:00:00';
    final remaining = _expirationTime!.difference(DateTime.now());
    if (remaining.isNegative) return '00:00:00';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ... (keep your existing _formatDate and build method unchanged)

  String _formatDate(DateTime d, [String langCode = 'en']) {
    return AppTranslations.formatDate(d, langCode);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = widget.c;
    final logs = widget.logs;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(
            lang.isUrdu
                ? 'سرگرمی اور کھانے کے لاگز'
                : (lang.isArabic ? 'سجلات النشاط والوجبات' : 'Activity & Meal Logs'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
        actions: [
          if (logs.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                SoundService.playTap();
                _triggerReset();
              },
              icon: Icon(Icons.restart_alt_rounded, size: 16, color: c.danger),
              label: Text(lang.t('reset_day'),
                  style: TextStyle(fontSize: 12, color: c.danger)),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(DateTime.now(), lang.currentLanguage),
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                const SizedBox(height: 16),
                Expanded(
                  child: logs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt_rounded,
                                    size: 48, color: c.textMuted),
                                const SizedBox(height: 14),
                                Text(
                                  lang.t('no_logs_today'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lang.isUrdu
                                      ? 'آج کی کیلوریز، پروٹین اور غذائیت ٹریک کرنے کے لیے کھانا لاگ کریں۔'
                                      : (lang.isArabic
                                          ? 'سجل وجباتك اليوم لتتبع السعرات والبروتين والعناصر الغذائية.'
                                          : 'Log meals to track your calories, protein, and macros for today.'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: c.textMuted, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                if (widget.onQuickAdd != null)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      SoundService.playTap();
                                      widget.onQuickAdd!();
                                    },
                                    icon: const Icon(Icons.add_rounded,
                                        size: 18),
                                    label: Text(lang.t('quick_log_meal')),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                if (widget.onNavigateToMeals != null) ...[
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      SoundService.playTap();
                                      widget.onNavigateToMeals!();
                                    },
                                    icon: const Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 16),
                                    label: Text(lang.t('browse_saved_meals')),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(children: [
                                Text(
                                  log.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(log.meal.name,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: c.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'P:${log.meal.protein.toInt()}g · C:${log.meal.carbs.toInt()}g · F:${log.meal.fat.toInt()}g',
                                        style: TextStyle(
                                            fontSize: 11, color: c.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                    '${log.meal.calories % 1 == 0 ? log.meal.calories.toInt() : log.meal.calories.toStringAsFixed(1)} kcal',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: c.accent,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    SoundService.playTap();
                                    widget.onRemoveLog(index);
                                  },
                                  child: Icon(Icons.close,
                                      size: 18, color: c.danger),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Local Tab-Specific Undo Banner with Live Countdown Timer
          if (_showUndoBanner)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.accent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.t('days_logs_reset'),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.isUrdu
                              ? "میعاد ختم: ${_getRemainingTimeString()}"
                              : (lang.isArabic
                                  ? "ينتهي خلال: ${_getRemainingTimeString()}"
                                  : "Expires in ${_getRemainingTimeString()}"),
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        SoundService.playTap();
                        _triggerUndo();
                      },
                      child: Text(
                        lang.t('undo'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: c.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
