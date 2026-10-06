import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure this is imported
import '../models/meal.dart';
import '../services/theme_provider.dart';

class LogsScreen extends StatefulWidget {
  final List<LoggedMeal> logs;
  final Function(int) onRemoveLog;
  final VoidCallback onResetDay;
  final VoidCallback? onUndoReset;
  final AppColors c;

  const LogsScreen({
    super.key,
    required this.logs,
    required this.onRemoveLog,
    required this.onResetDay,
    this.onUndoReset,
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

  String _formatDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = widget.c;
    final logs = widget.logs;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text('Activity & Meal Logs',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
        actions: [
          if (logs.isNotEmpty)
            TextButton.icon(
              onPressed: _triggerReset,
              icon: Icon(Icons.restart_alt_rounded, size: 16, color: c.danger),
              label: Text('Reset Day',
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
                Text(_formatDate(DateTime.now()),
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                const SizedBox(height: 16),
                Expanded(
                  child: logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt_rounded,
                                  size: 48, color: c.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No meals logged yet today.\nHead over to the Meals tab to log something!',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: c.textMuted, fontSize: 13),
                              ),
                            ],
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
                                    '${log.meal.calories.toStringAsFixed(1)} kcal',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: c.accent,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => widget.onRemoveLog(index),
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
                          "Day's logs reset.",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Expires in ${_getRemainingTimeString()}",
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _triggerUndo,
                      child: Text(
                        'UNDO',
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
