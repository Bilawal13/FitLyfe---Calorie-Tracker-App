import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../services/theme_provider.dart';
import 'package:provider/provider.dart';

class FoodChartScreen extends StatefulWidget {
  final Function(Meal) onLog;
  final Function(Meal) onSaveMeal;

  const FoodChartScreen({
    super.key,
    required this.onLog,
    required this.onSaveMeal,
  });

  @override
  State<FoodChartScreen> createState() => _FoodChartScreenState();
}

class _FoodChartScreenState extends State<FoodChartScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Meal> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // <--- Add this line

  Future<void> _searchFoods(String query) async {
    final cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true; // <--- Set this to true when a search is initiated
    });

    try {
      const apiKey = String.fromEnvironment('USDA_API_KEY');
      final url = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': cleanedQuery,
          'pageSize': 20,
          // Optional: Restrict types to make results cleaner (e.g., 'Branded' and 'SR Legacy')
          'dataType': ['Branded', 'SR Legacy', 'Survey (FNDDS)']
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List foods = data['foods'] ?? [];

        final results = foods
            .map((f) {
              final List nutrients = f['foodNutrients'] ?? [];

              double getNutrient(int id) {
                final match = nutrients.firstWhere(
                  (n) => n['nutrientId'] == id,
                  orElse: () => {'value': 0.0},
                );
                return (match['value'] ?? 0.0).toDouble();
              }

              double cals = getNutrient(1008);
              double protein = getNutrient(1003);
              double carbs = getNutrient(1005);
              double fat = getNutrient(1004);
              double fiber = getNutrient(1079);
              double sodium = getNutrient(1093);

              // ── CLEAN UP THE FOOD NAME ──────────────────────────────────
              String rawName = f['description'] ?? 'Unknown Food';
              String brandName = f['brandOwner'] ?? '';

              // Capitalize nicely and strip out repetitive corporate clutter
              String displayName = _formatFoodName(rawName, brandName);

              return Meal(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    (f['fdcId']?.toString() ?? ''),
                name: displayName,
                group: f['foodCategory'] ?? 'General',
                calories: cals,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sodium: sodium,
              );
            })
            .where((meal) => meal.name.isNotEmpty && meal.calories > 0)
            .toList();

        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper function to clean up messy USDA uppercase and corporate strings
  String _formatFoodName(String description, String brand) {
    // Convert ALL CAPS descriptions to Title Case for readability
    String cleaned = description.toLowerCase();
    cleaned = cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    // If there's a brand owner, append it cleanly if not already included
    if (brand.isNotEmpty) {
      String formattedBrand = brand.toLowerCase();
      formattedBrand =
          formattedBrand[0].toUpperCase() + formattedBrand.substring(1);
      if (!cleaned.toLowerCase().contains(formattedBrand.toLowerCase())) {
        cleaned = '$cleaned ($formattedBrand)';
      }
    }

    // Remove messy trailing commas or extra punctuation
    if (cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned;
  }

  void _showDataSourceDialog(BuildContext context, AppColors c) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: c.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.eco_rounded, color: c.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Food Database Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fit Lyfe powers its food search using the official USDA FoodData Central database.',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This gives you access to hundreds of thousands of generic items, raw ingredients, and branded commercial products with standardized nutritional values.',
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSec,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final platformDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;
    final c = AppColors(isDark, themeProvider.accent);

    return Scaffold(
      backgroundColor: c.bg,
      // resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Food Library',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right:
                    8.0), // <--- Shifts it slightly left to match the search bar's 16px screen padding
            child: IconButton(
              icon: Icon(Icons.info_outline_rounded, color: c.textSec),
              onPressed: () => _showDataSourceDialog(context, c),
              tooltip: 'Data Source Info',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar Input ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: c.textPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) => _searchFoods(val),
              decoration: InputDecoration(
                hintText: 'Search any food or brand (e.g. Oats, Chicken)...',
                hintStyle: TextStyle(color: c.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: c.accent),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward_rounded, color: c.accent),
                  onPressed: () => _searchFoods(_searchController.text),
                ),
                filled: true,
                fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.accent, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Results View ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: c.accent))
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _hasSearched
                                ? 'Item not found. Try searching with a broader term or check your spelling.'
                                : 'Type a food item above and search the global database for instant nutritional values.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        food.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    // ── Corrected Calorie Badge ──────────
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: c.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${food.calories.toStringAsFixed(1)} kcal / 100g',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: c.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // ── Single Clean Macro Summary Row ───
                                Text(
                                  'P: ${food.protein.toStringAsFixed(1)}g · C: ${food.carbs.toStringAsFixed(1)}g · F: ${food.fat.toStringAsFixed(1)}g',
                                  style:
                                      TextStyle(fontSize: 11, color: c.textSec),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // ── Save Button ──────────────────────────
                                    OutlinedButton.icon(
                                      onPressed: () => _showPortionDialog(
                                          context, food, false, c),
                                      icon: Icon(Icons.bookmark_add_outlined,
                                          size: 16, color: c.accent),
                                      label: Text('Save',
                                          style: TextStyle(
                                              fontSize: 11, color: c.accent)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: c.accent),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // ── Log Button ───────────────────────────
                                    ElevatedButton.icon(
                                      onPressed: () => _showPortionDialog(
                                          context, food, true, c),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16),
                                      label: const Text('Log',
                                          style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Portion Sizing Dialog Helper ─────────────────────────────────────────
  void _showPortionDialog(
      BuildContext context, Meal baseMeal, bool isForLogging, AppColors c) {
    final TextEditingController gramController =
        TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adjust Serving Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter portion size for ${baseMeal.name}:',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: gramController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  suffixText: 'grams (g)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                double grams = double.tryParse(gramController.text) ?? 100.0;
                if (grams <= 0) grams = 100.0;

                double scale = grams / 100.0;

                Meal scaledMeal = Meal(
                  id: baseMeal.id,
                  name: '${baseMeal.name} (${grams.toStringAsFixed(0)}g)',
                  group: baseMeal.group,
                  calories: baseMeal.calories * scale,
                  protein: baseMeal.protein * scale,
                  carbs: baseMeal.carbs * scale,
                  fat: baseMeal.fat * scale,
                  fiber: baseMeal.fiber * scale,
                  sodium: baseMeal.sodium * scale,
                );

                Navigator.pop(context);

                if (isForLogging) {
                  widget.onLog(scaledMeal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged "${scaledMeal.name}"!'),
                      backgroundColor: c.accent3,
                    ),
                  );
                } else {
                  widget.onSaveMeal(scaledMeal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved "${scaledMeal.name}" to library!'),
                      backgroundColor: c.accent3,
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
