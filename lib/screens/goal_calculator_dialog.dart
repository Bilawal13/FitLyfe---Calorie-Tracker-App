import 'package:flutter/material.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';

class GoalCalculatorDialog extends StatefulWidget {
  final int currentGoal;
  final Function(int newGoal) onSave;
  final AppColors c;

  const GoalCalculatorDialog({
    super.key,
    required this.currentGoal,
    required this.onSave,
    required this.c,
  });

  @override
  State<GoalCalculatorDialog> createState() => _GoalCalculatorDialogState();
}

class _GoalCalculatorDialogState extends State<GoalCalculatorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _manualCtrl;

  // Wizard state
  bool _isMale = true;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  bool _weightInKg = true;
  bool _heightInCm = true;

  // Activity multipliers
  // 1.2: Sedentary, 1.375: Light, 1.55: Moderate, 1.725: Very Active
  double _activityMultiplier = 1.375;

  // Pathway: -500 (Deficit), -300 (Mild), -750 (Aggressive), 0 (Maintain), +250 (Lean Bulk), +500 (Bulk)
  int _pathwayDelta = -500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _manualCtrl = TextEditingController(text: widget.currentGoal.toString());
    _ageCtrl = TextEditingController(text: '26');
    _weightCtrl = TextEditingController(text: '70');
    _heightCtrl = TextEditingController(text: '175');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  double get _computedBmr {
    final age = double.tryParse(_ageCtrl.text) ?? 25;
    double weight = double.tryParse(_weightCtrl.text) ?? 70;
    if (!_weightInKg) weight *= 0.453592; // lbs to kg

    double height = double.tryParse(_heightCtrl.text) ?? 175;
    if (!_heightInCm) height *= 2.54; // inches to cm

    // Mifflin-St Jeor Formula
    if (_isMale) {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  double get _computedTdee => _computedBmr * _activityMultiplier;

  int get _computedTargetCalories {
    final target = _computedTdee + _pathwayDelta;
    return target.round().clamp(1000, 5000);
  }

  String get _pathwayLabel {
    if (_pathwayDelta == -500) return 'Moderate Deficit (-500 kcal)';
    if (_pathwayDelta == -300) return 'Mild Deficit (-300 kcal)';
    if (_pathwayDelta == -750) return 'Rapid Deficit (-750 kcal)';
    if (_pathwayDelta == 0) return 'Maintenance (TDEE)';
    if (_pathwayDelta == 250) return 'Lean Bulk (+250 kcal)';
    if (_pathwayDelta == 500) return 'Standard Bulk (+500 kcal)';
    return 'Custom Pathway';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;

    return Dialog(
      backgroundColor: c.bg2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: (availableHeight * 0.90).clamp(320.0, 750.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header (Overflow-safe) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.track_changes_rounded,
                        color: c.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calorie Goal & Pathways',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          'Personalized nutrition & deficit calculator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: c.textMuted, size: 20),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () {
                      SoundService.playTap();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Distinct Spaced Segmented Tabs (No White Underline) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _topTabPill(
                      label: 'Guided Pathway',
                      icon: Icons.auto_awesome_rounded,
                      isSelected: _tabController.index == 0,
                      c: c,
                      onTap: () {
                        setState(() => _tabController.animateTo(0));
                      },
                    ),
                  ),
                  const SizedBox(width: 10), // Clean spacing between tabs
                  Expanded(
                    child: _topTabPill(
                      label: 'Quick Manual',
                      icon: Icons.tune_rounded,
                      isSelected: _tabController.index == 1,
                      c: c,
                      onTap: () {
                        setState(() => _tabController.animateTo(1));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPathwayWizard(c),
                  _buildManualTab(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topTabPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required AppColors c,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        SoundService.playTap();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.accent : c.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? c.accent : c.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : c.textSec,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : c.textSec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathwayWizard(AppColors c) {
    final bmr = _computedBmr.round();
    final tdee = _computedTdee.round();
    final target = _computedTargetCalories;

    // Macro estimation: 30% Protein (4 kcal/g), 45% Carbs (4 kcal/g), 25% Fat (9 kcal/g)
    final proteinGrams = (target * 0.30 / 4).round();
    final carbsGrams = (target * 0.45 / 4).round();
    final fatGrams = (target * 0.25 / 9).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Biological Sex ──
          Text('1. Biological Sex',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _genderButton(
                  label: 'Male',
                  emoji: '👨',
                  selected: _isMale,
                  onTap: () => setState(() => _isMale = true),
                  c: c,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _genderButton(
                  label: 'Female',
                  emoji: '👩',
                  selected: !_isMale,
                  onTap: () => setState(() => _isMale = false),
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 2. Body Metrics (Age, Weight, Height) ──
          Text('2. Body Metrics',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _metricField(
                  title: 'Age',
                  unit: 'yrs',
                  controller: _ageCtrl,
                  c: c,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _metricField(
                  title: 'Weight',
                  unit: _weightInKg ? 'kg' : 'lbs',
                  controller: _weightCtrl,
                  onToggleUnit: () =>
                      setState(() => _weightInKg = !_weightInKg),
                  c: c,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _metricField(
                  title: 'Height',
                  unit: _heightInCm ? 'cm' : 'in',
                  controller: _heightCtrl,
                  onToggleUnit: () =>
                      setState(() => _heightInCm = !_heightInCm),
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 3. Daily Activity Level ──
          Text('3. Daily Activity Multiplier',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 6),
          _activityCard(
            title: 'Sedentary',
            desc: 'Desk job, little to no exercise',
            emoji: '🪑',
            factor: '1.20x',
            multiplier: 1.2,
            c: c,
          ),
          _activityCard(
            title: 'Lightly Active',
            desc: 'Light workout / walking 1–3 days/wk',
            emoji: '🚶',
            factor: '1.38x',
            multiplier: 1.375,
            c: c,
          ),
          _activityCard(
            title: 'Moderately Active',
            desc: 'Moderate exercise / gym 3–5 days/wk',
            emoji: '🏃',
            factor: '1.55x',
            multiplier: 1.55,
            c: c,
          ),
          _activityCard(
            title: 'Very Active',
            desc: 'Intense training / sport 6–7 days/wk',
            emoji: '⚡',
            factor: '1.73x',
            multiplier: 1.725,
            c: c,
          ),
          const SizedBox(height: 14),

          // ── 4. Goal Pathway ──
          Row(
            children: [
              Text(
                '4. Choose Pathway',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textSec),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _pathwayLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pathwayChip(
                label: '📉 Moderate Deficit (-500)',
                badge: 'Recommended',
                delta: -500,
                c: c,
              ),
              _pathwayChip(
                label: '🌿 Mild Deficit (-300)',
                delta: -300,
                c: c,
              ),
              _pathwayChip(
                label: '🔥 Rapid Deficit (-750)',
                delta: -750,
                c: c,
              ),
              _pathwayChip(
                label: '⚖️ Maintenance (0)',
                delta: 0,
                c: c,
              ),
              _pathwayChip(
                label: '💪 Lean Bulk (+250)',
                delta: 250,
                c: c,
              ),
              _pathwayChip(
                label: '⚡ Standard Bulk (+500)',
                delta: 500,
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 5. Target Output Blueprint Card ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _infoPill('BMR: $bmr kcal', c),
                    _infoPill('TDEE: $tdee kcal', c),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _pathwayDelta < 0
                            ? 'Deficit'
                            : _pathwayDelta > 0
                                ? 'Surplus'
                                : 'Maintain',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: c.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$target',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kcal / day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Target calories for your selected nutrition pathway.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: c.border),
                const SizedBox(height: 10),
                Text(
                  'Recommended Macro Breakdown',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textSec),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _macroCard(
                        title: 'Protein',
                        grams: '${proteinGrams}g',
                        percent: '30%',
                        color: c.accent,
                        c: c,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _macroCard(
                        title: 'Carbs',
                        grams: '${carbsGrams}g',
                        percent: '45%',
                        color: c.warning,
                        c: c,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _macroCard(
                        title: 'Fat',
                        grams: '${fatGrams}g',
                        percent: '25%',
                        color: const Color(0xFF5CB8E8),
                        c: c,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Apply Goal Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SoundService.playTap();
                widget.onSave(target);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                'Apply Goal ($target kcal)',
                style:
                    const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: c.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Direct Calorie Target',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Set a custom daily calorie ceiling without the metabolic wizard.',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _manualCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Daily Goal',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'e.g. 2000',
                    suffixText: 'kcal',
                    suffixStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: c.accent),
                    filled: true,
                    fillColor: c.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Popular Benchmark Presets',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [1500, 1800, 2000, 2200, 2500, 2800].map((val) {
              final isSel = _manualCtrl.text == val.toString();
              return ActionChip(
                label: Text('$val kcal',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : c.textPrimary)),
                backgroundColor: isSel ? c.accent : c.bg3,
                side: BorderSide(color: isSel ? c.accent : c.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  SoundService.playTap();
                  setState(() => _manualCtrl.text = val.toString());
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SoundService.playTap();
                final val = int.tryParse(_manualCtrl.text);
                if (val != null && val >= 500) {
                  widget.onSave(val);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Save Custom Goal',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderButton({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return InkWell(
      onTap: () {
        SoundService.playTap();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.15) : c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: c.accent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricField({
    required String title,
    required String unit,
    required TextEditingController controller,
    VoidCallback? onToggleUnit,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (onToggleUnit != null)
                InkWell(
                  onTap: () {
                    SoundService.playTap();
                    onToggleUnit();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      unit,
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: c.accent),
                    ),
                  ),
                )
              else
                Text(
                  unit,
                  style: TextStyle(fontSize: 9.5, color: c.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: c.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              filled: true,
              fillColor: c.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard({
    required String title,
    required String desc,
    required String emoji,
    required String factor,
    required double multiplier,
    required AppColors c,
  }) {
    final selected = (_activityMultiplier - multiplier).abs() < 0.01;
    return InkWell(
      onTap: () {
        SoundService.playTap();
        setState(() => _activityMultiplier = multiplier);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.12) : c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? c.accent : c.textPrimary),
                  ),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5, color: c.textMuted, height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? c.accent.withValues(alpha: 0.2)
                    : c.bg3,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                factor,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? c.accent : c.textSec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathwayChip({
    required String label,
    String? badge,
    required int delta,
    required AppColors c,
  }) {
    final selected = _pathwayDelta == delta;
    return InkWell(
      onTap: () {
        SoundService.playTap();
        setState(() => _pathwayDelta = delta);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : c.textPrimary,
              ),
            ),
            if (badge != null && !selected) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: c.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoPill(String text, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w600, color: c.textSec),
      ),
    );
  }

  Widget _macroCard({
    required String title,
    required String grams,
    required String percent,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              grams,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary),
            ),
          ),
          Text(
            percent,
            style: TextStyle(fontSize: 9.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
