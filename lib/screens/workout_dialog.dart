import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';

class WorkoutDialog extends StatefulWidget {
  final Function(LoggedExercise exercise) onLog;
  final AppColors c;

  const WorkoutDialog({
    super.key,
    required this.onLog,
    required this.c,
  });

  @override
  State<WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<WorkoutDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _caloriesCtrl;
  String _selectedEmoji = '🏃';

  final List<Map<String, dynamic>> _presets = [
    {
      'title': 'Outdoor Running',
      'icon': '🏃',
      'duration': 30,
      'calories': 300.0,
    },
    {
      'title': 'Brisk Walking',
      'icon': '🚶',
      'duration': 30,
      'calories': 130.0,
    },
    {
      'title': 'Cycling',
      'icon': '🚴',
      'duration': 30,
      'calories': 250.0,
    },
    {
      'title': 'Gym / Weightlifting',
      'icon': '🏋️',
      'duration': 45,
      'calories': 220.0,
    },
    {
      'title': 'Swimming',
      'icon': '🏊',
      'duration': 30,
      'calories': 280.0,
    },
    {
      'title': 'HIIT / Cardio Circuit',
      'icon': '🥊',
      'duration': 25,
      'calories': 260.0,
    },
    {
      'title': 'Yoga & Stretching',
      'icon': '🧘',
      'duration': 35,
      'calories': 110.0,
    },
    {
      'title': 'Jump Rope',
      'icon': '⚡',
      'duration': 15,
      'calories': 180.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Outdoor Running');
    _durationCtrl = TextEditingController(text: '30');
    _caloriesCtrl = TextEditingController(text: '300');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(Map<String, dynamic> preset) {
    setState(() {
      _selectedEmoji = preset['icon'];
      _nameCtrl.text = preset['title'];
      _durationCtrl.text = preset['duration'].toString();
      _caloriesCtrl.text = (preset['calories'] as double).toInt().toString();
    });
  }

  void _submit() {
    final title = _nameCtrl.text.trim();
    final calories = double.tryParse(_caloriesCtrl.text.trim()) ?? 0.0;
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;

    if (title.isEmpty || calories <= 0) return;

    final exercise = LoggedExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      icon: _selectedEmoji,
      caloriesBurned: calories,
      durationMinutes: duration,
      loggedAt: DateTime.now(),
    );

    widget.onLog(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return Dialog(
      backgroundColor: c.bg2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🔥', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Log Workout & Burn',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () {
                      SoundService.playTap();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Presets
              Text('Quick Workout Presets',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSec)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((p) {
                  final isSel = _nameCtrl.text == p['title'];
                  return InkWell(
                    onTap: () {
                      SoundService.playTap();
                      _selectPreset(p);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.orange.withValues(alpha: 0.18)
                            : c.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSel ? Colors.orange : c.border,
                            width: isSel ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p['icon'], style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            p['title'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.orange : c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Inputs
              Text('Activity Details',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSec)),
              const SizedBox(height: 8),

              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Exercise / Workout Name',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'e.g. 5k Morning Jog',
                  filled: true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '30',
                        suffixText: 'min',
                        suffixStyle: TextStyle(color: c.textMuted),
                        filled: true,
                        fillColor: c.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Calories Burned',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '300',
                        suffixText: 'kcal',
                        suffixStyle: TextStyle(color: c.textMuted),
                        filled: true,
                        fillColor: c.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SoundService.playTap();
                    _submit();
                  },
                  icon: const Icon(Icons.local_fire_department_rounded,
                      size: 20, color: Colors.white),
                  label: const Text(
                    'Log Workout Burn',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
