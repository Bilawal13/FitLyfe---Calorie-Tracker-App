import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class QuickTipsScreen extends StatelessWidget {
  const QuickTipsScreen({super.key});

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
        title: Text('Quick Tips',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Master Your Nutrition Tracking',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use these pro tips to measure calories accurately and make tracking effortless.',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          const SizedBox(height: 20),
          _TipCard(
            icon: Icons.label_outline_rounded,
            title: 'Check Labels & Serving Sizes',
            description:
                'Always read the nutritional breakdown on packaging carefully. Double-check the serving size so you never accidentally log a fraction of what you actually eat.',
            c: c,
          ),
          const SizedBox(height: 14),
          _TipCard(
            icon: Icons.scale_rounded,
            title: 'Weigh & Consult AI',
            description:
                'Place fresh or unlabelled foods on a kitchen scale in grams. Ask any AI model or database for precise macro values, then save them to your app for quick logging.',
            c: c,
          ),
          const SizedBox(height: 14),
          _TipCard(
            icon: Icons.opacity_rounded,
            title: 'Account for Hidden Oils & Sauces',
            description:
                'Cooking oils, butter, and dressings add up fast. Measure your cooking fats with a spoon rather than eyeballing them to keep your tracking accurate.',
            c: c,
          ),
          const SizedBox(height: 14),
          _TipCard(
            icon: Icons.restaurant_rounded,
            title: 'Weigh Consistently (Raw vs. Cooked)',
            description:
                'Meats and grains change weight when cooked due to water loss or absorption. Stick to weighing items either entirely raw or entirely cooked for reliable daily data.',
            c: c,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final AppColors c;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSec,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
