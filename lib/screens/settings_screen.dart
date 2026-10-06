import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatelessWidget {
  // We can make 'c' optional or remove it from constructor since we compute it live now
  final AppColors? cParam;
  const SettingsScreen({super.key, this.cParam});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Compute colors live inside build so changes apply instantly!
    final platformDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDark = themeProvider.mode == AppThemeMode.system
        ? platformDark
        : themeProvider.mode == AppThemeMode.dark;
    final c = AppColors(isDark, themeProvider.accent);

    final current = themeProvider.mode;
    final currentAccent = themeProvider.accent;

    Future<void> launchSocialUrl(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance section ───────────────────────────────────────────
            Text('Appearance',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(children: [
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: 'System default',
                  subtitle: 'Follows your device\'s theme',
                  selected: current == AppThemeMode.system,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.system),
                ),
                Divider(height: 1, color: c.border),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  subtitle: 'Always use light theme',
                  selected: current == AppThemeMode.light,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.light),
                ),
                Divider(height: 1, color: c.border),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  subtitle: 'Always use dark theme',
                  selected: current == AppThemeMode.dark,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.dark),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Accent Color section ─────────────────────────────────────────
            Text('Accent Color',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _colorCircle(context, AppAccentColor.purple,
                      const Color(0xFF8B5CF6), currentAccent, c),
                  _colorCircle(context, AppAccentColor.blue,
                      const Color(0xFF3B82F6), currentAccent, c),
                  _colorCircle(context, AppAccentColor.green,
                      const Color(0xFF10B981), currentAccent, c),
                  _colorCircle(context, AppAccentColor.red,
                      const Color(0xFFEF4444), currentAccent, c),
                  _colorCircle(context, AppAccentColor.yellow,
                      const Color(0xFFF59E0B), currentAccent, c),
                  _colorCircle(context, AppAccentColor.skyBlue,
                      const Color(0xFF0EA5E9), currentAccent, c),
                  _colorCircle(context, AppAccentColor.black,
                      c.dark ? Colors.white : Colors.black, currentAccent, c),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── About section ────────────────────────────────────────────────
            Text('About',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(children: [
                _InfoRow(label: 'App', value: 'Fit Lyfe', c: c),
                Divider(height: 20, color: c.border),
                _InfoRow(label: 'Version', value: '1.0.0', c: c),
              ]),
            ),
            // ── PsyCodes Studio Social Footer with Twitter (X) ─────────────────
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'Powered by PsyCodes Studio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSec,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect with us',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // YouTube
                        IconButton(
                          icon:
                              const FaIcon(FontAwesomeIcons.youtube, size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.youtube.com/@PsyCodes-Studio'),
                          tooltip: 'YouTube',
                        ),
                        // Twitter / X
                        IconButton(
                          icon:
                              const FaIcon(FontAwesomeIcons.xTwitter, size: 20),
                          color: c.accent,
                          onPressed: () =>
                              launchSocialUrl('https://x.com/PsyCodesAI'),
                          tooltip: 'Twitter (X)',
                        ),
                        // LinkedIn
                        IconButton(
                          icon:
                              const FaIcon(FontAwesomeIcons.linkedin, size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.linkedin.com/company/psycodestudios'),
                          tooltip: 'LinkedIn',
                        ),
                        // Instagram
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.instagram,
                              size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.instagram.com/psycodestudios'),
                          tooltip: 'Instagram',
                        ),
                        // Facebook
                        IconButton(
                          icon:
                              const FaIcon(FontAwesomeIcons.facebook, size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.facebook.com/profile.php?id=61591393350288'),
                          tooltip: 'Facebook',
                        ),
                        // TikTok
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.tiktok, size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.tiktok.com/@psycodes_studio'),
                          tooltip: 'TikTok',
                        ),
                        // Reddit
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.reddit, size: 20),
                          color: c.accent,
                          onPressed: () => launchSocialUrl(
                              'https://www.reddit.com/user/PsyCodes-Studio/'),
                          tooltip: 'Reddit',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorCircle(BuildContext context, AppAccentColor colorEnum,
      Color displayColor, AppAccentColor currentAccent, AppColors c) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = currentAccent == colorEnum;

    return GestureDetector(
      onTap: () => themeProvider.setAccent(colorEnum),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? c.textPrimary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                  color: displayColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1)
          ],
        ),
        child: isSelected
            ? Center(
                child: Icon(Icons.check,
                    size: 18,
                    color: colorEnum == AppAccentColor.black && !c.dark
                        ? Colors.white
                        : (colorEnum == AppAccentColor.black && c.dark
                            ? Colors.black
                            : Colors.white)))
            : null,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool selected;
  final AppColors c;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? c.accent.withValues(alpha: 0.15) : c.bg3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? c.accent : c.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? c.accent : c.textPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: c.textMuted)),
                  ]),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: c.accent, size: 20),
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final AppColors c;
  const _InfoRow({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: c.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      );
}
