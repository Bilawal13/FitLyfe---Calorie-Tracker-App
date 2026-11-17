import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/language_provider.dart';
import '../services/sound_service.dart';

class RankRoadmapScreen extends StatelessWidget {
  final Map<String, dynamic> rankData;
  final int goal;
  final VoidCallback? onBack;

  const RankRoadmapScreen({
    super.key,
    required this.rankData,
    this.goal = 2000,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final platformDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;
    final c = AppColors(isDark, themeProvider.accent);
    final lang = context.watch<LanguageProvider>();

    final int currentLevel = (rankData['level'] as int?) ?? 0;
    final int streak = (rankData['streak'] as int?) ?? 0;
    final String emoji = (rankData['emoji'] as String?) ?? '🌱';
    final String title = (rankData['title'] as String?) ?? 'ROOKIE';

    final List<Map<String, dynamic>> allRanks = [
      {
        'level': 9,
        'title': lang.getRankTitle(9),
        'emoji': '👑',
        'req': lang.getRankReq(9),
      },
      {
        'level': 8,
        'title': lang.getRankTitle(8),
        'emoji': '💫',
        'req': lang.getRankReq(8),
      },
      {
        'level': 7,
        'title': lang.getRankTitle(7),
        'emoji': '🌟',
        'req': lang.getRankReq(7),
      },
      {
        'level': 6,
        'title': lang.getRankTitle(6),
        'emoji': '⚔️',
        'req': lang.getRankReq(6),
      },
      {
        'level': 5,
        'title': lang.getRankTitle(5),
        'emoji': '🛡️',
        'req': lang.getRankReq(5),
      },
      {
        'level': 4,
        'title': lang.getRankTitle(4),
        'emoji': '🔥',
        'req': lang.getRankReq(4),
      },
      {
        'level': 3,
        'title': lang.getRankTitle(3),
        'emoji': '⚡',
        'req': lang.getRankReq(3),
      },
      {
        'level': 2,
        'title': lang.getRankTitle(2),
        'emoji': '🥉',
        'req': lang.getRankReq(2),
      },
      {
        'level': 1,
        'title': lang.getRankTitle(1),
        'emoji': '🌱',
        'req': lang.getRankReq(1),
      },
      {
        'level': 0,
        'title': lang.getRankTitle(0),
        'emoji': '💤',
        'req': lang.getRankReq(0),
      },
    ];

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textPrimary),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  SoundService.playTap();
                  onBack!();
                },
              )
            : null,
        title: Text(
          lang.t('rank_roadmap_title'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Current Active Rank Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.accent.withValues(alpha: 0.18),
                  c.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.accent.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.accent.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${lang.isUrdu ? "درجہ" : (lang.isArabic ? "المستوى" : "LEVEL")} $currentLevel · $title',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: c.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.isUrdu
                            ? '$streak دن کا مسلسل اسٹریک'
                            : (lang.isArabic
                                ? '$streak أيام متتالية'
                                : '$streak Day Active Streak'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.isUrdu
                            ? 'روزانہ ہدف: ±100 کیلوری کے اندر'
                            : (lang.isArabic
                                ? 'الهدف اليومي: ضمن ±100 سعرة'
                                : 'Target: Within ±100 kcal of daily goal'),
                        style: TextStyle(fontSize: 11.5, color: c.textSec),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Rules Card ──
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
                    Icon(Icons.military_tech_rounded, size: 16, color: c.accent),
                    const SizedBox(width: 6),
                    Text(
                      lang.t('rank_rules_title'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lang.isUrdu
                      ? 'ہر روز اپنے ہدف ($goal کیلوری) کے ±100 اندر کھائیں تاکہ اسٹریک نہ ٹوٹے اور رینک بڑھے۔'
                      : (lang.isArabic
                          ? 'تناول سعرات ضمن ±100 من هدفك ($goal سعرة) كل يوم للحفاظ على السلسلة والارتقاء في الرتب.'
                          : 'Log within ±100 kcal of your goal ($goal kcal) daily to climb the leaderboard from Rookie to King!'),
                  style: TextStyle(fontSize: 11.5, color: c.textSec, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            lang.isUrdu ? 'تمام رینکس کے مراحل' : (lang.isArabic ? 'جميع الرتب' : 'All Rank Tiers'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // ── All Ranks List ──
          ...allRanks.map((rank) {
            final bool isCurrent = rank['level'] == currentLevel;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrent ? c.accent.withValues(alpha: 0.12) : c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent ? c.accent : c.border,
                  width: isCurrent ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(rank['emoji'], style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rank['title'],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? c.accent : c.textPrimary,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  lang.t('you'),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: c.bg,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rank['req'],
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isCurrent ? c.textPrimary : c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? c.accent.withValues(alpha: 0.25)
                          : c.bg2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lang.t('lvl')} ${rank['level']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? c.accent : c.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
