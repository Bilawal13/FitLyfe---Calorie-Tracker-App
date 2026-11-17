import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../data/common_foods.dart';
import '../models/meal.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';

enum FoodFilter { all, generic, branded }

class FoodSearchResult {
  final Meal meal;
  final bool isGeneric;
  final String brand;

  const FoodSearchResult({
    required this.meal,
    required this.isGeneric,
    this.brand = '',
  });
}

class FoodChartScreen extends StatefulWidget {
  final Function(Meal) onLog;
  final Function(Meal) onSaveMeal;
  final VoidCallback? onSearchPerformed;

  const FoodChartScreen({
    super.key,
    required this.onLog,
    required this.onSaveMeal,
    this.onSearchPerformed,
  });

  @override
  State<FoodChartScreen> createState() => _FoodChartScreenState();
}

class _FoodChartScreenState extends State<FoodChartScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodSearchResult> _allResults = [];
  FoodFilter _selectedFilter = FoodFilter.all;
  bool _isLoading = false;
  bool _hasSearched = false;
  List<String> _liveSuggestions = [];

  void _onSearchQueryChanged(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) {
      if (_liveSuggestions.isNotEmpty) {
        setState(() => _liveSuggestions = []);
      }
      return;
    }

    final matches = commonFoodsDatabase
        .where((f) =>
            f.name.toLowerCase().contains(clean) ||
            f.keywords.any((k) => k.toLowerCase().contains(clean)))
        .map((f) => f.name)
        .take(5)
        .toList();

    setState(() {
      _liveSuggestions = matches;
    });
  }

  final List<String> _popularSuggestions = [
    'Boiled Chickpeas',
    'Boiled Egg',
    'White Rice',
    'Chicken Breast',
    'Oatmeal',
    'Greek Yogurt',
    'Banana',
    'Lentils / Dal',
    'Sweet Potato',
    'Almonds',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodSearchResult> get _filteredResults {
    switch (_selectedFilter) {
      case FoodFilter.generic:
        return _allResults.where((r) => r.isGeneric).toList();
      case FoodFilter.branded:
        return _allResults.where((r) => !r.isGeneric).toList();
      case FoodFilter.all:
        return _allResults;
    }
  }

  int get _genericCount => _allResults.where((r) => r.isGeneric).length;
  int get _brandedCount => _allResults.where((r) => !r.isGeneric).length;

  Future<void> _searchFoods(String query) async {
    final cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    widget.onSearchPerformed?.call();

    final List<FoodSearchResult> combinedResults = [];

    // ── 1. Search Curated Local Database First (Instant & Offline) ────────
    final localMatches = searchCommonFoods(cleanedQuery);
    for (final meal in localMatches) {
      combinedResults.add(
        FoodSearchResult(
          meal: meal,
          isGeneric: true,
          brand: 'Standard Generic',
        ),
      );
    }

    // ── 2. Search USDA Online Database with Enhanced Parameters ──────────
    try {
      const envKey = String.fromEnvironment('USDA_API_KEY');
      final apiKey = envKey.isNotEmpty ? envKey : 'DEMO_KEY';
      final url = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': cleanedQuery,
              'pageSize': 25,
              'dataType': [
                'Foundation',
                'SR Legacy',
                'Survey (FNDDS)',
                'Branded',
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List foods = data['foods'] ?? [];

        final List<FoodSearchResult> genericFromApi = [];
        final List<FoodSearchResult> brandedFromApi = [];
        final Map<String, int> seenBrandRoots = {};

        for (final f in foods) {
          final List nutrients = f['foodNutrients'] ?? [];

          double getNutrient(int id) {
            final match = nutrients.firstWhere(
              (n) => n['nutrientId'] == id,
              orElse: () => {'value': 0.0},
            );
            return (match['value'] ?? 0.0).toDouble();
          }

          final double cals = getNutrient(1008);
          final double protein = getNutrient(1003);
          final double carbs = getNutrient(1005);
          final double fat = getNutrient(1004);
          final double fiber = getNutrient(1079);
          final double sodium = getNutrient(1093);

          if (cals <= 0) continue;

          final String rawName = f['description'] ?? 'Unknown Food';
          final String brandOwner = (f['brandOwner'] ?? '').toString().trim();
          final String dataType = (f['dataType'] ?? '').toString();

          final bool isGeneric = dataType.contains('Foundation') ||
              dataType.contains('SR') ||
              dataType.contains('Survey') ||
              brandOwner.isEmpty;

          final String displayName = _formatFoodName(rawName, brandOwner);

          // Skip if exact same food name already exists from local verified database
          final alreadyInLocal = combinedResults.any((r) =>
              r.meal.name.toLowerCase() == displayName.toLowerCase());
          if (alreadyInLocal) continue;

          final meal = Meal(
            id: 'usda_${f['fdcId'] ?? DateTime.now().millisecondsSinceEpoch}',
            name: displayName,
            group: f['foodCategory'] ?? (isGeneric ? 'Generic Food' : 'Branded Food'),
            calories: cals,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium,
          );

          if (isGeneric) {
            genericFromApi.add(
              FoodSearchResult(
                meal: meal,
                isGeneric: true,
                brand: 'USDA Standard',
              ),
            );
          } else {
            // ── Smart Deduplication for Store Brands ───────────────────────
            // Collapse identical store-brand products into at most 2 entries
            final rootKey = _normalizeBrandItemKey(rawName);
            final currentCount = seenBrandRoots[rootKey] ?? 0;
            if (currentCount >= 2) {
              continue; // Skip repetitive supermarket duplicates
            }
            seenBrandRoots[rootKey] = currentCount + 1;

            brandedFromApi.add(
              FoodSearchResult(
                meal: meal,
                isGeneric: false,
                brand: brandOwner.isNotEmpty ? brandOwner : 'Branded',
              ),
            );
          }
        }

        // Add USDA generic foods first, then deduplicated branded foods
        combinedResults.addAll(genericFromApi);
        combinedResults.addAll(brandedFromApi);
      }
    } catch (e) {
      // If USDA fails (network offline or rate limited), local results still work!
      debugPrint('USDA API search notice: $e');
    } finally {
      if (mounted) {
        setState(() {
          _allResults = combinedResults;
          _isLoading = false;
        });
      }
    }
  }

  /// Normalizes product names to detect duplicate white-label store brands
  String _normalizeBrandItemKey(String name) {
    return name
        .toLowerCase()
        .replaceAll(
          RegExp(
              r'\b(organic|canned|canned & drained|canned in water|all natural|natural|cooked|drained|low sodium|no salt added|fresh)\b'),
          '',
        )
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Format USDA uppercase and corporate strings into clean title case
  String _formatFoodName(String description, String brand) {
    String cleaned = description.toLowerCase();
    cleaned = cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    if (brand.isNotEmpty) {
      String formattedBrand = brand.toLowerCase();
      formattedBrand =
          formattedBrand[0].toUpperCase() + formattedBrand.substring(1);
      if (!cleaned.toLowerCase().contains(formattedBrand.toLowerCase())) {
        cleaned = '$cleaned ($formattedBrand)';
      }
    }

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
                'Food Library Data',
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
                'Fit Lyfe combines two intelligent sources:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Curated Whole Foods: Instant, verified home-cooked items (like boiled chickpeas, white rice, boiled eggs) that work completely offline.',
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSec,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. USDA FoodData Central: Access to hundreds of thousands of generic research items and commercial packaged products, with smart brand deduplication.',
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
              onPressed: () {
                SoundService.playTap();
                Navigator.pop(context);
              },
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
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(
          'Food Library',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.info_outline_rounded, color: c.textSec),
              onPressed: () {
                SoundService.playTap();
                _showDataSourceDialog(context, c);
              },
              tooltip: 'Data Source Info',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar Input ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: c.textPrimary),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchQueryChanged,
              onSubmitted: (val) {
                setState(() => _liveSuggestions.clear());
                _searchFoods(val);
              },
              decoration: InputDecoration(
                hintText: 'Search food (e.g. Boiled Chickpeas, Rice)...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: c.accent),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear_rounded, color: c.textMuted, size: 20),
                        onPressed: () {
                          SoundService.playTap();
                          _searchController.clear();
                          setState(() {
                            _liveSuggestions.clear();
                            _allResults.clear();
                            _hasSearched = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_rounded, color: c.accent),
                      onPressed: () {
                        SoundService.playTap();
                        setState(() => _liveSuggestions.clear());
                        _searchFoods(_searchController.text);
                      },
                    ),
                  ],
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

          // ── Live In-Search Recommendations ───────────────────────────────
          if (_liveSuggestions.isNotEmpty)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _liveSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final suggestion = _liveSuggestions[index];
                  return ActionChip(
                    avatar:
                        Icon(Icons.search_rounded, size: 14, color: c.accent),
                    label: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: c.card,
                    side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      SoundService.playTap();
                      _searchController.text = suggestion;
                      setState(() => _liveSuggestions.clear());
                      _searchFoods(suggestion);
                    },
                  );
                },
              ),
            ),

          // ── Category Filter Chips (Shown after search) ───────────────────
          if (_hasSearched && _allResults.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All (${_allResults.length})', FoodFilter.all, c),
                  const SizedBox(width: 8),
                  _buildFilterChip('🥗 Whole & Generic ($_genericCount)', FoodFilter.generic, c),
                  const SizedBox(width: 8),
                  _buildFilterChip('🏷️ Store Brands ($_brandedCount)', FoodFilter.branded, c),
                ],
              ),
            ),

          if (_hasSearched && _allResults.isNotEmpty) const SizedBox(height: 10),

          // ── Results or Quick Staples View ────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: c.accent),
                        const SizedBox(height: 16),
                        Text(
                          'Searching verified nutrition...',
                          style: TextStyle(color: c.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : !_hasSearched
                    ? _buildQuickStaplesView(c)
                    : _filteredResults.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 54, color: c.textMuted),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No matching foods found in this filter.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try switching to "All" or searching with broader keywords like "chickpeas", "egg", or "rice".',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: c.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _filteredResults.length,
                            itemBuilder: (context, index) {
                              final item = _filteredResults[index];
                              return _buildFoodCard(item, c);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FoodFilter filter, AppColors c) {
    final bool isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        SoundService.playTap();
        setState(() => _selectedFilter = filter);
      },
      selectedColor: c.accent.withValues(alpha: 0.18),
      backgroundColor: c.card,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? c.accent : c.textSec,
      ),
      side: BorderSide(
        color: isSelected ? c.accent : c.border,
        width: isSelected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildQuickStaplesView(AppColors c) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded, size: 18, color: c.warning),
            const SizedBox(width: 8),
            Text(
              'Popular Quick Searches',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSuggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              backgroundColor: c.card,
              labelStyle: TextStyle(fontSize: 12, color: c.textPrimary),
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                SoundService.playTap();
                _searchController.text = suggestion;
                _searchFoods(suggestion);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Text(
              'Common Whole Food Staples',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...commonFoodsDatabase.take(6).map((item) {
          final result = FoodSearchResult(
            meal: item.toMeal(),
            isGeneric: true,
            brand: 'Verified Staple',
          );
          return _buildFoodCard(result, c);
        }),
      ],
    );
  }

  Widget _buildFoodCard(FoodSearchResult item, AppColors c) {
    final food = item.meal;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badge: Generic vs Store Brand
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isGeneric
                            ? Colors.green.withValues(alpha: 0.12)
                            : c.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isGeneric
                            ? '🥗 Whole / Generic'
                            : (item.brand.isNotEmpty
                                ? '🏷️ ${item.brand}'
                                : '🏷️ Branded Item'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: item.isGeneric
                              ? Colors.green[700] ?? Colors.green
                              : c.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Calorie Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${food.calories.toStringAsFixed(0)} kcal / 100g',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Clean Macro Summary Row
          Text(
            'P: ${food.protein.toStringAsFixed(1)}g · C: ${food.carbs.toStringAsFixed(1)}g · F: ${food.fat.toStringAsFixed(1)}g · Fiber: ${food.fiber.toStringAsFixed(1)}g',
            style: TextStyle(fontSize: 11.5, color: c.textSec),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Save Button
              OutlinedButton.icon(
                onPressed: () {
                  SoundService.playTap();
                  _showPortionDialog(context, food, false, c);
                },
                icon: Icon(Icons.bookmark_add_outlined,
                    size: 16, color: c.accent),
                label: Text(
                  'Save',
                  style: TextStyle(fontSize: 12, color: c.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              // Log Button
              ElevatedButton.icon(
                onPressed: () {
                  SoundService.playTap();
                  _showPortionDialog(context, food, true, c);
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor:
                      c.accentType == AppAccentColor.black && c.dark
                          ? Colors.black
                          : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Portion Sizing Dialog with Quick Portion Buttons ─────────────────────
  void _showPortionDialog(
      BuildContext context, Meal baseMeal, bool isForLogging, AppColors c) {
    showDialog(
      context: context,
      builder: (_) => _PortionDialog(
        baseMeal: baseMeal,
        isForLogging: isForLogging,
        c: c,
        onConfirm: (scaledMeal) {
          if (isForLogging) {
            widget.onLog(scaledMeal);
          } else {
            widget.onSaveMeal(scaledMeal);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved "${scaledMeal.name}" to library!'),
                behavior: SnackBarBehavior.fixed,
                duration: const Duration(milliseconds: 1800),
              ),
            );
          }
        },
      ),
    );
  }
}

class _PortionDialog extends StatefulWidget {
  final Meal baseMeal;
  final bool isForLogging;
  final AppColors c;
  final Function(Meal) onConfirm;

  const _PortionDialog({
    required this.baseMeal,
    required this.isForLogging,
    required this.c,
    required this.onConfirm,
  });

  @override
  State<_PortionDialog> createState() => _PortionDialogState();
}

class _PortionDialogState extends State<_PortionDialog> {
  late final TextEditingController _gramController;

  @override
  void initState() {
    super.initState();
    _gramController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _gramController.dispose();
    super.dispose();
  }

  void _submit() {
    double grams = double.tryParse(_gramController.text) ?? 100.0;
    if (grams <= 0) grams = 100.0;
    final double scale = grams / 100.0;
    final baseMeal = widget.baseMeal;

    final Meal scaledMeal = Meal(
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

    widget.onConfirm(scaledMeal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final baseMeal = widget.baseMeal;
    double currentGrams = double.tryParse(_gramController.text) ?? 100.0;
    if (currentGrams <= 0) currentGrams = 100.0;
    final double scale = currentGrams / 100.0;

    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Adjust Serving Size',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: c.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baseMeal.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gramController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: c.textPrimary),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Portion Weight',
                suffixText: 'grams (g)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [50, 100, 150, 200, 250].map((g) {
                return InkWell(
                  onTap: () {
                    SoundService.playTap();
                    _gramController.text = g.toString();
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentGrams.toInt() == g
                          ? c.accent.withValues(alpha: 0.2)
                          : c.bg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentGrams.toInt() == g ? c.accent : c.border,
                      ),
                    ),
                    child: Text(
                      '${g}g',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: currentGrams.toInt() == g ? c.accent : c.textSec,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Calories',
                          style: TextStyle(fontSize: 12, color: c.textSec)),
                      Text(
                        '${(baseMeal.calories * scale).toStringAsFixed(1)} kcal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Protein: ${(baseMeal.protein * scale).toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: c.textPrimary),
                      ),
                      Text(
                        'Carbs: ${(baseMeal.carbs * scale).toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: c.textPrimary),
                      ),
                      Text(
                        'Fat: ${(baseMeal.fat * scale).toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: c.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            SoundService.playTap();
            Navigator.pop(context);
          },
          child: Text('Cancel', style: TextStyle(color: c.textSec)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: c.accentType == AppAccentColor.black && c.dark
                ? Colors.black
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            SoundService.playTap();
            _submit();
          },
          child: Text(widget.isForLogging ? 'Log to Today' : 'Save to Library'),
        ),
      ],
    );
  }
}
