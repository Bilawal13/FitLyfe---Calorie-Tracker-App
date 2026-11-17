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

  return '🍽️'; // Default food emoji fallback
}


class LoggedExercise {
  final String id;
  final String title;
  final String icon;
  final double caloriesBurned;
  final int durationMinutes;
  final DateTime loggedAt;

  LoggedExercise({
    required this.id,
    required this.title,
    this.icon = '🔥',
    required this.caloriesBurned,
    this.durationMinutes = 0,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'caloriesBurned': caloriesBurned,
        'durationMinutes': durationMinutes,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory LoggedExercise.fromJson(Map<String, dynamic> json) => LoggedExercise(
        id: json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? 'Exercise',
        icon: json['icon']?.toString() ?? '🔥',
        caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        loggedAt: json['loggedAt'] != null
            ? DateTime.tryParse(json['loggedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class DailySummary {
  final String date; // YYYY-MM-DD
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final int mealCount;
  final int goal;
  final int waterIntake; // in ml
  final double burnedCalories; // in kcal

  DailySummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.mealCount,
    required this.goal,
    this.waterIntake = 0,
    this.burnedCalories = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'mealCount': mealCount,
        'goal': goal,
        'waterIntake': waterIntake,
        'burnedCalories': burnedCalories,
      };

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        date: json['date']?.toString() ?? '',
        calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
        sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
        mealCount: (json['mealCount'] as num?)?.toInt() ?? 0,
        goal: (json['goal'] as num?)?.toInt() ?? 2000,
        waterIntake: (json['waterIntake'] as num?)?.toInt() ?? 0,
        burnedCalories: (json['burnedCalories'] as num?)?.toDouble() ?? 0.0,
      );

  factory DailySummary.fromLogs({
    required String date,
    required List<LoggedMeal> logs,
    required int goal,
    int waterIntake = 0,
    double burnedCalories = 0.0,
  }) {
    double cal = 0, p = 0, c = 0, f = 0, fib = 0, sod = 0;
    for (final l in logs) {
      cal += l.meal.calories;
      p += l.meal.protein;
      c += l.meal.carbs;
      f += l.meal.fat;
      fib += l.meal.fiber;
      sod += l.meal.sodium;
    }
    return DailySummary(
      date: date,
      calories: cal,
      protein: p,
      carbs: c,
      fat: f,
      fiber: fib,
      sodium: sod,
      mealCount: logs.length,
      goal: goal,
      waterIntake: waterIntake,
      burnedCalories: burnedCalories,
    );
  }
}
