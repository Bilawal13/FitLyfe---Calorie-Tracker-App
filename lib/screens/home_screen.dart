import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/meal.dart';
import '../services/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  final List<LoggedMeal> logs;
  final int goal;
  final VoidCallback onSetGoal;
  final Function(int) onRemoveLog;
  final VoidCallback onQuickTips;
  final VoidCallback onFoodChart;
  final VoidCallback onSettings;
  final AppColors c;

  const HomeScreen({
    super.key,
    required this.logs,
    required this.goal,
    required this.onSetGoal,
    required this.onRemoveLog,
    required this.onQuickTips,
    required this.onFoodChart,
    required this.onSettings,
    required this.c,
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
    final t = _totals;
    final cal = t['cal']!;
    final pct = (cal / goal).clamp(0.0, 1.0);
    final isOver = cal > goal;
    final ringColor = isOver ? c.danger : c.accent;

    // Calculate current user rank data based on streak rules
    final rankData = _calculateUserRank(logs, goal);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Summary",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary)),
                        Text(_formatDate(DateTime.now()),
                            style: TextStyle(fontSize: 12, color: c.textMuted)),
                      ]),
                  TextButton.icon(
                    onPressed: onSetGoal,
                    icon: Icon(Icons.tune, size: 16, color: c.accent),
                    label: Text('Goal: ${goal}kcal',
                        style: TextStyle(fontSize: 12, color: c.accent)),
                  ),
                ],
              ),
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
                        Text('kcal consumed',
                            style: TextStyle(fontSize: 12, color: c.textMuted)),
                        const SizedBox(height: 2),
                        Text('/ $goal goal',
                            style: TextStyle(fontSize: 11, color: c.textSec)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                        Text('Calorie progress',
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
                    Text('${(cal - goal).toInt()} kcal over goal',
                        style: TextStyle(fontSize: 11, color: c.danger)),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              // Macro row 1
              Row(children: [
                _MacroCard(
                    label: 'Protein',
                    value: '${t['protein']!.toInt()}g',
                    color: c.accent,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: 'Carbs',
                    value: '${t['carbs']!.toInt()}g',
                    color: c.warning,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: 'Fat',
                    value: '${t['fat']!.toInt()}g',
                    color: const Color(0xFF5CB8E8),
                    c: c),
              ]),
              const SizedBox(height: 10),

              // Macro row 2
              Row(children: [
                _MacroCard(
                    label: 'Fiber',
                    value: '${t['fiber']!.toInt()}g',
                    color: c.textSec,
                    c: c),
                const SizedBox(width: 10),
                _MacroCard(
                    label: 'Sodium',
                    value: '${t['sodium']!.toInt()}mg',
                    color: c.textSec,
                    c: c),
                const SizedBox(width: 10),
                Expanded(child: Container()),
              ]),
              const SizedBox(height: 24),

              // ── Aesthetic Action Buttons ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Quick Tips',
                      onTap: onQuickTips,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.grid_view_rounded,
                      label: 'Food Library',
                      onTap: onFoodChart,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: onSettings,
                      c: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // ── Side-Attached Aesthetic Rank Badge ──────────────────────────────
        _DraggableRankBadge(
          c: c,
          rankData: rankData,
          onTap: () => _showRankBottomSheet(context, c, rankData),
        ),
      ],
    );
  }

// ── Updated Rank Logic Helper (Up to 365 Days) ───────────────────────────
  Map<String, dynamic> _calculateUserRank(
      List<LoggedMeal> logs, int targetCalories) {
    if (logs.isEmpty) {
      return {'streak': 0, 'level': 0, 'title': 'Unranked', 'emoji': '💤'};
    }

    Map<String, double> dailyTotals = {};
    for (var item in logs) {
      final dateKey =
          "${item.loggedAt.year}-${item.loggedAt.month.toString().padLeft(2, '0')}-${item.loggedAt.day.toString().padLeft(2, '0')}";
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + item.meal.calories;
    }

    final sortedDates = dailyTotals.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    for (var dateStr in sortedDates) {
      final totalCals = dailyTotals[dateStr]!;
      if (targetCalories > 0 &&
          totalCals >= targetCalories &&
          totalCals <= (targetCalories + 200)) {
        currentStreak++;
      } else {
        break;
      }
    }

    String title;
    String emoji;
    int level;

    if (currentStreak >= 365) {
      level = 9;
      title = 'Fit Lyfe King';
      emoji = '👑';
    } else if (currentStreak >= 180) {
      level = 8;
      title = 'Half-Year Legend';
      emoji = '💫';
    } else if (currentStreak >= 90) {
      level = 7;
      title = 'Centurion Tracker';
      emoji = '🌟';
    } else if (currentStreak >= 60) {
      level = 6;
      title = 'Iron Will';
      emoji = '⚔️';
    } else if (currentStreak >= 30) {
      level = 5;
      title = 'Calorie Titan';
      emoji = '🛡️';
    } else if (currentStreak >= 14) {
      level = 4;
      title = 'Macro Alchemist';
      emoji = '🔥';
    } else if (currentStreak >= 7) {
      level = 3;
      title = 'Consistency Master';
      emoji = '⚡';
    } else if (currentStreak >= 4) {
      level = 2;
      title = 'Habit Builder';
      emoji = '🥉';
    } else if (currentStreak >= 1) {
      level = 1;
      title = 'Rookie';
      emoji = '🌱';
    } else {
      level = 0;
      title = 'Unranked';
      emoji = '💤';
    }

    return {
      'streak': currentStreak,
      'level': level,
      'title': title,
      'emoji': emoji,
    };
  }

  // ── Rank Popup Modal Sheet ───────────────────────────────────────────────
  void _showRankBottomSheet(
      BuildContext context, AppColors c, Map<String, dynamic> rankData) {
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
                    rankData['title'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Streak: ${rankData['streak']} Days',
                    style: TextStyle(fontSize: 13, color: c.textSec),
                  ),
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
                        Text(
                          '🎯 Rank Rules:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Log your daily calories between your target goal and up to +200 kcal over to maintain your streak. Missing your target window resets your rank progress!',
                          style: TextStyle(
                              fontSize: 12, color: c.textSec, height: 1.4),
                        ),
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
                      child: Text('Keep Going!',
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
                      child: Text('View All Ranks',
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
    final List<Map<String, dynamic>> allRanks = [
      {
        'level': 9,
        'title': 'Fit Lyfe King',
        'emoji': '👑',
        'req': '365+ Days Streak'
      },
      {
        'level': 8,
        'title': 'Half-Year Legend',
        'emoji': '💫',
        'req': '180 - 364 Days'
      },
      {
        'level': 7,
        'title': 'Centurion Tracker',
        'emoji': '🌟',
        'req': '90 - 179 Days'
      },
      {'level': 6, 'title': 'Iron Will', 'emoji': '⚔️', 'req': '60 - 89 Days'},
      {
        'level': 5,
        'title': 'Calorie Titan',
        'emoji': '🛡️',
        'req': '30 - 59 Days'
      },
      {
        'level': 4,
        'title': 'Macro Alchemist',
        'emoji': '🔥',
        'req': '14 - 29 Days'
      },
      {
        'level': 3,
        'title': 'Consistency Master',
        'emoji': '⚡',
        'req': '7 - 13 Days'
      },
      {
        'level': 2,
        'title': 'Habit Builder',
        'emoji': '🥉',
        'req': '4 - 6 Days'
      },
      {'level': 1, 'title': 'Rookie', 'emoji': '🌱', 'req': '1 - 3 Days'},
      {
        'level': 0,
        'title': 'Unranked',
        'emoji': '💤',
        'req': '0 Days (Inactive)'
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
            'Rank Progression Roadmap',
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
                                      'YOU',
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
                        'Lvl ${rank['level']}',
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
              child: Text('Close', style: TextStyle(color: c.accent)),
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
        onTap: onTap,
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

  const _DraggableRankBadge({
    super.key,
    required this.c,
    required this.rankData,
    required this.onTap,
  });

  @override
  State<_DraggableRankBadge> createState() => _DraggableRankBadgeState();
}

class _DraggableRankBadgeState extends State<_DraggableRankBadge> {
  double? _topPosition;

  @override
  Widget build(BuildContext context) {
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
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.c.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            border: Border.all(
              color: widget.c.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(-2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.rankData['emoji'],
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RANK ${widget.rankData['level']}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: widget.c.accent,
                    ),
                  ),
                  Text(
                    '${widget.rankData['streak']}d Streak',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.c.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
