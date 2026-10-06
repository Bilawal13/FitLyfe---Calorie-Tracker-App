import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/theme_provider.dart';

// Helper function for dynamic group emojis
String getEmojiForGroupName(String groupName) {
  final name = groupName.toLowerCase();

  if (name.contains('break') ||
      name.contains('egg') ||
      name.contains('morning')) return '🍳';
  if (name.contains('lunch') || name.contains('noon')) return '🥪';
  if (name.contains('dinner') ||
      name.contains('night') ||
      name.contains('supper')) return '🍲';
  if (name.contains('snack') || name.contains('bite') || name.contains('treat'))
    return '🍿';
  if (name.contains('protein') ||
      name.contains('meat') ||
      name.contains('chicken') ||
      name.contains('beef') ||
      name.contains('gym')) return '🥩';
  if (name.contains('fruit') ||
      name.contains('apple') ||
      name.contains('berry')) return '🍎';
  if (name.contains('veg') || name.contains('salad') || name.contains('green'))
    return '🥗';
  if (name.contains('drink') ||
      name.contains('shake') ||
      name.contains('water') ||
      name.contains('juice') ||
      name.contains('coffee')) return '🥤';
  if (name.contains('sweet') ||
      name.contains('dessert') ||
      name.contains('sugar') ||
      name.contains('cake')) return '🍩';

  return '🍽️'; // Default fallback
}

class MealsScreen extends StatefulWidget {
  final List<Meal> meals;
  final VoidCallback onAdd;
  final Function(Meal) onLog;
  final Function(int) onDelete;
  final AppColors c;

  const MealsScreen({
    super.key,
    required this.meals,
    required this.onAdd,
    required this.onLog,
    required this.onDelete,
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Meals',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add New Meal', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Saved meals',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textSec,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Expanded(
            child: meals.isEmpty
                ? Center(
                    child: Text(
                      'No meals saved yet.\nTap "Add New Meal" to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textMuted, fontSize: 13),
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
                              '${groupItemList.length} items',
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
                                  Text('${meal.calories} kcal',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: c.accent,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => widget.onLog(meal),
                                    icon: Icon(Icons.add_circle_rounded,
                                        color: c.accent, size: 22),
                                    tooltip: 'Log Today',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () =>
                                        widget.onDelete(originalIndex),
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
  final AppColors c;
  const AddMealDialog(
      {super.key, required this.onSave, this.prefill, required this.c});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  late final TextEditingController _name,
      _group,
      _cal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sodium;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _name = TextEditingController(text: p?['name'] ?? '');
    _group = TextEditingController(text: p?['group'] ?? 'Breakfast');
    _cal = TextEditingController(text: p?['cal']?.toString() ?? '');
    _protein = TextEditingController(text: p?['protein']?.toString() ?? '');
    _carbs = TextEditingController(text: p?['carbs']?.toString() ?? '');
    _fat = TextEditingController(text: p?['fat']?.toString() ?? '');
    _fiber = TextEditingController(text: p?['fiber']?.toString() ?? '');
    _sodium = TextEditingController(text: p?['sodium']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final ctrl in [
      _name,
      _group,
      _cal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sodium
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final group = _group.text.trim();
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

  Widget _field(String hint, TextEditingController ctrl,
          {TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          keyboardType: type ?? TextInputType.text,
          style: TextStyle(color: widget.c.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: hint),
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
              _field('Meal name (e.g. Chicken Rice Bowl)', _name),
              _field('Meal Group (e.g. Breakfast, Lunch, Snacks)', _group),
              Row(children: [
                Expanded(
                    child: _field('Calories (kcal)', _cal,
                        type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Protein (g)', _protein,
                        type: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(
                    child: _field('Carbs (g)', _carbs,
                        type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Fat (g)', _fat, type: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(
                    child: _field('Fiber (g)', _fiber,
                        type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Sodium (mg)', _sodium,
                        type: TextInputType.number)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                        onPressed: _save, child: const Text('Save Meal'))),
              ]),
            ]),
      ),
    );
  }
}
