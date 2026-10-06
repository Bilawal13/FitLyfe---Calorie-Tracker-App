class Meal {
  final String id;
  final String name;
  final String group;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;

  Meal({
    required this.id,
    required this.name,
    this.group = 'General',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name']?.toString() ?? 'Unnamed Meal',
        group: json['group']?.toString().isNotEmpty == true
            ? json['group'].toString()
            : 'General',
        calories: json['calories'] != null
            ? double.tryParse(json['calories'].toString()) ?? 0.0
            : 0.0,
        protein: json['protein'] != null
            ? double.tryParse(json['protein'].toString()) ?? 0.0
            : 0.0,
        carbs: json['carbs'] != null
            ? double.tryParse(json['carbs'].toString()) ?? 0.0
            : 0.0,
        fat: json['fat'] != null
            ? double.tryParse(json['fat'].toString()) ?? 0.0
            : 0.0,
        fiber: json['fiber'] != null
            ? double.tryParse(json['fiber'].toString()) ?? 0.0
            : 0.0,
        sodium: json['sodium'] != null
            ? double.tryParse(json['sodium'].toString()) ?? 0.0
            : 0.0,
      );
}

class LoggedMeal {
  final Meal meal;
  final String groupName;
  final String emoji;
  final DateTime loggedAt;

  LoggedMeal({
    required this.meal,
    String? groupName,
    String? emoji,
    DateTime? loggedAt,
  })  : groupName = groupName ??
            meal.group, // <--- Automatically falls back to meal.group if omitted
        emoji = emoji ?? getEmojiForGroupName(groupName ?? meal.group),
        loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'meal': meal.toJson(),
        'groupName': groupName,
        'emoji': emoji,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory LoggedMeal.fromJson(Map<String, dynamic> json) {
    final mealObj = json['meal'] != null
        ? Meal.fromJson(json['meal'])
        : Meal(
            id: '0',
            name: 'Unknown',
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sodium: 0,
          );
    final group = json['groupName'] ?? mealObj.group;
    return LoggedMeal(
      meal: mealObj,
      groupName: group,
      emoji: json['emoji'] ?? getEmojiForGroupName(group),
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

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

  return '🍽️'; // Default food emoji fallback
}
