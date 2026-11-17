import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../services/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/language_provider.dart';

// Helper function for dynamic group emojis
String getEmojiForGroupName(String groupName) {
  final name = groupName.toLowerCase();

  if (name.contains('break') ||
      name.contains('egg') ||
      name.contains('morning')) {
    return '🍳';
  }
  if (name.contains('lunch') || name.contains('noon')) return '🥪';
  if (name.contains('dinner') ||
      name.contains('night') ||
      name.contains('supper')) {
    return '🍲';
  }
  if (name.contains('snack') ||
      name.contains('bite') ||
      name.contains('treat')) {
    return '🍿';
  }
  if (name.contains('protein') ||
      name.contains('meat') ||
      name.contains('chicken') ||
      name.contains('beef') ||
      name.contains('gym')) {
    return '🥩';
  }
  if (name.contains('fruit') ||
      name.contains('apple') ||
      name.contains('berry')) {
    return '🍎';
  }
  if (name.contains('veg') ||
      name.contains('salad') ||
      name.contains('green')) {
    return '🥗';
  }
  if (name.contains('drink') ||
      name.contains('shake') ||
      name.contains('water') ||
      name.contains('juice') ||
      name.contains('coffee')) {
    return '🥤';
  }
  if (name.contains('sweet') ||
      name.contains('dessert') ||
      name.contains('sugar') ||
      name.contains('cake')) {
    return '🍩';
  }

  return '🍽️'; // Default fallback
}

class MealsScreen extends StatefulWidget {
  final List<Meal> meals;
  final VoidCallback onAdd;
  final Function(Meal) onLog;
  final Function(int) onDelete;
  final VoidCallback? onLoadStarterMeals;
  final AppColors c;

  const MealsScreen({
    super.key,
    required this.meals,
    required this.onAdd,
    required this.onLog,
    required this.onDelete,
    this.onLoadStarterMeals,
    required this.c,
  });

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with AutomaticKeepAliveClientMixin {
  final Map<String, bool> _groupExpansionStates = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = widget.c;
    final meals = widget.meals;

    final Map<String, List<Meal>> groupedMeals = {};
    for (var meal in meals) {
      final groupName = meal.group.isNotEmpty ? meal.group : 'General';
      groupedMeals.putIfAbsent(groupName, () => []).add(meal);
    }

    final lang = context.watch<LanguageProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.t('my_meals'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SoundService.playTap();
                widget.onAdd();
              },
              icon: const Icon(Icons.add),
              label: Text(lang.t('add_meal'), style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
              lang.isUrdu
                  ? 'محفوظ شدہ کھانے'
                  : (lang.isArabic ? 'الوجبات المحفوظة' : 'Saved meals'),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textSec,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Expanded(
            child: meals.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded,
                              size: 48, color: c.textMuted),
                          const SizedBox(height: 14),
                          Text(
                            lang.t('no_saved_meals'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang.isUrdu
                                ? 'اپنی ترکیبیں بنائیں یا پہلے سے تیار شدہ کھانے لوڈ کریں۔'
                                : (lang.isArabic
                                    ? 'أنشئ وصفاتك الخاصة أو حمّل وجبات جاهزة للبدء سريعاً.'
                                    : 'Create your own recipes or quickly load starter meals.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                          if (widget.onLoadStarterMeals != null) ...[
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () {
                                SoundService.playTap();
                                widget.onLoadStarterMeals?.call();
                              },
                              icon: const Icon(Icons.auto_awesome_rounded,
                                  size: 16),
                              label: Text(lang.t('load_starter_meals')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c.accent,
                                side: BorderSide(
                                    color: c.accent.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView(
                    children: groupedMeals.entries.map((entry) {
                      final groupTitle = entry.key;
                      final groupItemList = entry.value;
                      final groupEmoji = getEmojiForGroupName(
                          groupTitle); // Get matching emoji

                      final bool isExpanded =
                          _groupExpansionStates[groupTitle] ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _groupExpansionStates[groupTitle] = expanded;
                            });
                          },
                          title: Row(
                            children: [
                              Text(groupEmoji,
                                  style: const TextStyle(
                                      fontSize:
                                          16)), // Display emoji in group header
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  groupTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 24.0),
                            child: Text(
                              '${groupItemList.length} ${groupItemList.length == 1 ? 'item' : 'items'}',
                              style:
                                  TextStyle(fontSize: 11, color: c.textMuted),
                            ),
                          ),
                          iconColor: c.accent,
                          collapsedIconColor: c.textMuted,
                          children: groupItemList.map((meal) {
                            final originalIndex = meals.indexOf(meal);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border:
                                    Border(top: BorderSide(color: c.border)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(meal.name,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: c.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'P:${meal.protein.toInt()}g · C:${meal.carbs.toInt()}g · F:${meal.fat.toInt()}g',
                                          style: TextStyle(
                                              fontSize: 11, color: c.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                      '${meal.calories % 1 == 0 ? meal.calories.toInt() : meal.calories.toStringAsFixed(1)} kcal',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: c.accent,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      SoundService.playTap();
                                      widget.onLog(meal);
                                    },
                                    icon: Icon(Icons.add_circle_rounded,
                                        color: c.accent, size: 22),
                                    tooltip: 'Log Today',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      SoundService.playTap();
                                      widget.onDelete(originalIndex);
                                    },
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: c.danger, size: 20),
                                    tooltip: 'Delete Meal',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class AddMealDialog extends StatefulWidget {
  final Function(Meal) onSave;
  final Map<String, dynamic>? prefill;
  final List<String>? existingGroups;
  final AppColors c;

  const AddMealDialog({
    super.key,
    required this.onSave,
    this.prefill,
    this.existingGroups,
    required this.c,
  });

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  static const List<String> defaultGroups = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Protein',
    'Fruits',
    'Vegetables',
    'Drinks',
    'Sweets',
    'General',
  ];

  late final TextEditingController _name,
      _cal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sodium;

  final TextEditingController _customGroupCtrl = TextEditingController();
  final FocusNode _customGroupFocus = FocusNode();

  List<String> _groupOptions = [];
  String? _selectedGroup;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _name = TextEditingController(text: p?['name'] ?? '');
    _cal = TextEditingController(text: p?['cal']?.toString() ?? '');
    _protein = TextEditingController(text: p?['protein']?.toString() ?? '');
    _carbs = TextEditingController(text: p?['carbs']?.toString() ?? '');
    _fat = TextEditingController(text: p?['fat']?.toString() ?? '');
    _fiber = TextEditingController(text: p?['fiber']?.toString() ?? '');
    _sodium = TextEditingController(text: p?['sodium']?.toString() ?? '');

    _groupOptions = List.from(defaultGroups);

    // Include groups already present in user's saved meals
    if (widget.existingGroups != null) {
      for (final g in widget.existingGroups!) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty && !_groupOptions.contains(trimmed)) {
          _groupOptions.add(trimmed);
        }
      }
    }

    final initialGroup = p?['group']?.toString().trim();
    if (initialGroup != null && initialGroup.isNotEmpty) {
      if (!_groupOptions.contains(initialGroup)) {
        _groupOptions.add(initialGroup);
      }
      _selectedGroup = initialGroup;
    } else {
      _selectedGroup = 'Breakfast';
    }

    _loadCustomGroups();
  }

  Future<void> _loadCustomGroups() async {
    final customGroups = await StorageService.getCustomGroups();
    if (!mounted) return;
    setState(() {
      for (final g in customGroups) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty && !_groupOptions.contains(trimmed)) {
          _groupOptions.add(trimmed);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final ctrl in [
      _name,
      _cal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sodium,
      _customGroupCtrl,
    ]) {
      ctrl.dispose();
    }
    _customGroupFocus.dispose();
    super.dispose();
  }

  void _applyCustomGroup() {
    final newGroup = _customGroupCtrl.text.trim();
    if (newGroup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }
    if (!_groupOptions.contains(newGroup)) {
      _groupOptions.add(newGroup);
    }
    StorageService.saveCustomGroup(newGroup);
    setState(() {
      _selectedGroup = newGroup;
      _isCustomMode = false;
      _customGroupCtrl.clear();
    });
  }

  void _save() {
    final name = _name.text.trim();
    String group = _selectedGroup ?? 'Breakfast';

    if (_isCustomMode && _customGroupCtrl.text.trim().isNotEmpty) {
      final customGroup = _customGroupCtrl.text.trim();
      if (!_groupOptions.contains(customGroup)) {
        _groupOptions.add(customGroup);
      }
      StorageService.saveCustomGroup(customGroup);
      group = customGroup;
    }

    final cal = int.tryParse(_cal.text) ?? 0;
    if (name.isEmpty || cal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a meal name and calories.')));
      return;
    }
    widget.onSave(Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      group: group.isEmpty ? 'General' : group,
      calories: cal.toDouble(),
      protein: double.tryParse(_protein.text) ?? 0,
      carbs: double.tryParse(_carbs.text) ?? 0,
      fat: double.tryParse(_fat.text) ?? 0,
      fiber: double.tryParse(_fiber.text) ?? 0,
      sodium: double.tryParse(_sodium.text) ?? 0,
    ));
    Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController ctrl,
          {TextInputType? type, String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: type ?? TextInputType.text,
          style: TextStyle(color: widget.c.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hint,
            labelStyle: TextStyle(
              color: widget.c.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: widget.c.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: TextStyle(
              color: widget.c.textMuted.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Dialog(
      backgroundColor: c.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Meal',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              const SizedBox(height: 16),
              _field('Meal Name', _name, hint: 'e.g. Chicken Rice Bowl'),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _isCustomMode ? null : _selectedGroup,
                      dropdownColor: c.bg2,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: c.textSec),
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      isExpanded: true,
                      hint: Text(
                        _isCustomMode
                            ? 'Custom category selected...'
                            : 'Select Meal Group',
                        style: TextStyle(
                            color: _isCustomMode ? c.accent : c.textMuted,
                            fontSize: 14,
                            fontWeight: _isCustomMode
                                ? FontWeight.w500
                                : FontWeight.normal),
                      ),
                      items: [
                        ..._groupOptions.map((group) {
                          final emoji = getEmojiForGroupName(group);
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Row(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    group,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        DropdownMenuItem<String>(
                          value: '__ADD_CUSTOM__',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: c.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_rounded,
                                    color: c.accent, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '+ Add Custom Category...',
                                style: TextStyle(
                                  color: c.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == '__ADD_CUSTOM__') {
                          setState(() {
                            _isCustomMode = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _customGroupFocus.requestFocus();
                          });
                        } else if (val != null) {
                          setState(() {
                            _selectedGroup = val;
                            _isCustomMode = false;
                            _customGroupCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (_isCustomMode) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customGroupCtrl,
                          focusNode: _customGroupFocus,
                          style: TextStyle(color: c.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'New category (e.g. Smoothies, Late Night)',
                            prefixIcon: Icon(Icons.label_outline,
                                color: c.accent, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: c.textMuted, size: 18),
                              onPressed: () {
                                setState(() {
                                  _isCustomMode = false;
                                  _customGroupCtrl.clear();
                                });
                              },
                              tooltip: 'Cancel',
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _applyCustomGroup(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          SoundService.playTap();
                          _applyCustomGroup();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ],
              Row(children: [
                Expanded(
                    child: _field('Calories (kcal)', _cal,
                        type: TextInputType.number, hint: '0')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Protein (g)', _protein,
                        type: TextInputType.number, hint: '0')),
              ]),
              Row(children: [
                Expanded(
                    child: _field('Carbs (g)', _carbs,
                        type: TextInputType.number, hint: '0')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Fat (g)', _fat,
                        type: TextInputType.number, hint: '0')),
              ]),
              Row(children: [
                Expanded(
                    child: _field('Fiber (g)', _fiber,
                        type: TextInputType.number, hint: '0')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Sodium (mg)', _sodium,
                        type: TextInputType.number, hint: '0')),
              ]),
              const SizedBox(height: 4),
              Row(children: [
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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          SoundService.playTap();
                          _save();
                        },
                        child: const Text('Save Meal'))),
              ]),
            ]),
      ),
    );
  }
}
