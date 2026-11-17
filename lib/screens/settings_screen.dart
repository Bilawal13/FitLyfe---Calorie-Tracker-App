import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import 'goal_calculator_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final AppColors? cParam;
  final VoidCallback? onStartTour;

  const SettingsScreen({super.key, this.cParam, this.onStartTour});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mealNotifEnabled = true;
  TimeOfDay _mealNotifTime = const TimeOfDay(hour: 20, minute: 0);

  bool _waterNotifEnabled = true;
  TimeOfDay _waterNotifTime = const TimeOfDay(hour: 14, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final notifService = NotificationService();
    final mealEnabled = await notifService.isMealReminderEnabled();
    final mealTime = await notifService.getMealReminderTime();
    final waterEnabled = await notifService.isWaterReminderEnabled();
    final waterTime = await notifService.getWaterReminderTime();

    if (mounted) {
      setState(() {
        _mealNotifEnabled = mealEnabled;
        _mealNotifTime = mealTime;
        _waterNotifEnabled = waterEnabled;
        _waterNotifTime = waterTime;
      });
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onSelected,
  }) async {
    SoundService.playTap();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

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

    Future<void> openGoalCalculator() async {
      final currentGoal = await StorageService.getGoal();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => GoalCalculatorDialog(
          currentGoal: currentGoal,
          onSave: (newGoal) async {
            await StorageService.saveGoal(newGoal);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Daily calorie target updated to $newGoal kcal!'),
                  backgroundColor: c.accent,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          c: c,
        ),
      );
    }

    Future<void> openWaterGoalDialog() async {
      final currentGoal = await StorageService.getWaterGoal();
      final ctrl = TextEditingController(text: currentGoal.toString());
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.bg2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Daily Water Target',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target (ml)',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixText: 'ml',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [1500, 2000, 2500, 3000]
                    .map((v) => ActionChip(
                          label: Text('${v}ml',
                              style: TextStyle(
                                  fontSize: 11, color: c.textPrimary)),
                          backgroundColor: c.bg3,
                          onPressed: () => ctrl.text = v.toString(),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: c.textSec)),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = int.tryParse(ctrl.text);
                if (val != null && val >= 500) {
                  await StorageService.saveWaterGoal(val);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(languageProvider.t('settings'),
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
            Text(languageProvider.t('appearance'),
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
                  label: languageProvider.t('system_default'),
                  subtitle: languageProvider.t('system_default_subtitle'),
                  selected: current == AppThemeMode.system,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.system),
                ),
                Divider(height: 1, color: c.border),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: languageProvider.t('light'),
                  subtitle: languageProvider.t('light_subtitle'),
                  selected: current == AppThemeMode.light,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.light),
                ),
                Divider(height: 1, color: c.border),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: languageProvider.t('dark'),
                  subtitle: languageProvider.t('dark_subtitle'),
                  selected: current == AppThemeMode.dark,
                  c: c,
                  onTap: () => themeProvider.setMode(AppThemeMode.dark),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Accent Color section ─────────────────────────────────────────
            Text(languageProvider.t('accent_color'),
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
            const SizedBox(height: 24),

            // ── Language section (Dropdown option) ───────────────────────────
            Text(languageProvider.t('language'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.language_rounded, color: c.accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.t('app_language'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          languageProvider.t('language_subtitle'),
                          style: TextStyle(fontSize: 12, color: c.textSec),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: languageProvider.currentLanguage,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: c.accent, size: 20),
                        dropdownColor: c.card,
                        borderRadius: BorderRadius.circular(12),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇺🇸 ', style: TextStyle(fontSize: 13)),
                                Text(
                                  languageProvider.t('lang_english'),
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: languageProvider.currentLanguage == 'en'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ur',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇵🇰 ', style: TextStyle(fontSize: 13)),
                                Text(
                                  languageProvider.t('lang_urdu'),
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: languageProvider.currentLanguage == 'ur'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇸🇦 ', style: TextStyle(fontSize: 13)),
                                Text(
                                  languageProvider.t('lang_arabic'),
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: languageProvider.currentLanguage == 'ar'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (newLang) async {
                          if (newLang != null &&
                              newLang != languageProvider.currentLanguage) {
                            SoundService.playTap();
                            await languageProvider.setLanguage(newLang);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              String snackMsg;
                              if (newLang == 'ur') {
                                snackMsg = languageProvider.t('language_changed_to_ur');
                              } else if (newLang == 'ar') {
                                snackMsg = languageProvider.t('language_changed_to_ar');
                              } else {
                                snackMsg = languageProvider.t('language_changed_to_en');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(snackMsg),
                                  backgroundColor: c.accent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Goals & Nutrition section ────────────────────────────────────
            Text(languageProvider.t('goals_nutrition'),
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
                _SettingsTile(
                  icon: Icons.track_changes_rounded,
                  title: languageProvider.t('calorie_goal_calc'),
                  subtitle: languageProvider.t('calorie_goal_desc'),
                  c: c,
                  onTap: openGoalCalculator,
                ),
                Divider(height: 1, color: c.border),
                _SettingsTile(
                  icon: Icons.water_drop_outlined,
                  title: languageProvider.t('daily_water_target'),
                  subtitle: languageProvider.t('daily_water_desc'),
                  c: c,
                  onTap: openWaterGoalDialog,
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Audio & Feedback section ────────────────────────────────────
            Text(languageProvider.t('audio_sound_effects'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: SoundService.isSoundEnabled,
                activeThumbColor: c.accent,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SoundService.isSoundEnabled
                        ? c.accent.withValues(alpha: 0.15)
                        : c.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    SoundService.isSoundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 20,
                    color: SoundService.isSoundEnabled ? c.accent : c.textMuted,
                  ),
                ),
                title: Text(
                  languageProvider.t('calming_sound_feedback'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                subtitle: Text(
                  languageProvider.t('calming_sound_desc'),
                  style: TextStyle(fontSize: 12, color: c.textSec, height: 1.3),
                ),
                onChanged: (val) async {
                  await SoundService.setSoundEnabled(val);
                  setState(() {});
                  if (val) {
                    SoundService.playTap();
                  }
                },
              ),
            ),
            const SizedBox(height: 28),

            // ── Daily Notifications & Reminders section ─────────────────────
            Text(languageProvider.t('notifications_title'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSec,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  // Meal Logging Reminder Switch & Time Picker
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _mealNotifEnabled,
                    activeThumbColor: c.accent,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _mealNotifEnabled
                            ? c.accent.withValues(alpha: 0.15)
                            : c.border.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 20,
                        color: _mealNotifEnabled ? c.accent : c.textMuted,
                      ),
                    ),
                    title: Text(
                      languageProvider.t('meal_reminder_label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      languageProvider.t('meal_reminder_desc'),
                      style: TextStyle(fontSize: 12, color: c.textSec, height: 1.3),
                    ),
                    onChanged: (val) async {
                      SoundService.playTap();
                      if (val) {
                        await NotificationService().requestPermissions();
                      }
                      setState(() => _mealNotifEnabled = val);
                      await NotificationService().setMealReminder(
                        enabled: val,
                        time: _mealNotifTime,
                      );
                    },
                  ),
                  if (_mealNotifEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: c.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            _mealNotifTime.format(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: c.accent,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _pickTime(
                                context: context,
                                initialTime: _mealNotifTime,
                                onSelected: (newTime) async {
                                  setState(() => _mealNotifTime = newTime);
                                  await NotificationService().setMealReminder(
                                    enabled: true,
                                    time: newTime,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(languageProvider
                                            .t('reminders_updated')),
                                        backgroundColor: c.accent,
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: Text(
                              languageProvider.t('change_time'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: c.accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Divider(height: 1, color: c.border),

                  // Water Reminder Switch & Time Picker
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _waterNotifEnabled,
                    activeThumbColor: const Color(0xFF0EA5E9),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _waterNotifEnabled
                            ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                            : c.border.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 20,
                        color: _waterNotifEnabled
                            ? const Color(0xFF0EA5E9)
                            : c.textMuted,
                      ),
                    ),
                    title: Text(
                      languageProvider.t('water_reminder_label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      languageProvider.t('water_reminder_desc'),
                      style: TextStyle(fontSize: 12, color: c.textSec, height: 1.3),
                    ),
                    onChanged: (val) async {
                      SoundService.playTap();
                      if (val) {
                        await NotificationService().requestPermissions();
                      }
                      setState(() => _waterNotifEnabled = val);
                      await NotificationService().setWaterReminder(
                        enabled: val,
                        time: _waterNotifTime,
                      );
                    },
                  ),
                  if (_waterNotifEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: c.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            _waterNotifTime.format(context),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _pickTime(
                                context: context,
                                initialTime: _waterNotifTime,
                                onSelected: (newTime) async {
                                  setState(() => _waterNotifTime = newTime);
                                  await NotificationService().setWaterReminder(
                                    enabled: true,
                                    time: newTime,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(languageProvider
                                            .t('reminders_updated')),
                                        backgroundColor: c.accent,
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: Text(
                              languageProvider.t('change_time'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── About & Help section ────────────────────────────────────────
            Text(languageProvider.t('help_about'),
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
                InkWell(
                  onTap: () {
                    SoundService.playTap();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    if (widget.onStartTour != null) {
                      widget.onStartTour!();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assistant_navigation,
                                size: 18, color: c.accent),
                            const SizedBox(width: 10),
                            Text(
                              languageProvider.t('take_app_tour'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: c.textMuted),
                      ],
                    ),
                  ),
                ),
                Divider(height: 22, color: c.border),
                _InfoRow(label: languageProvider.t('app_label'), value: 'Fit Lyfe', c: c),
                Divider(height: 20, color: c.border),
                _InfoRow(label: languageProvider.t('version_label'), value: '1.0.0', c: c),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors c;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: c.accent),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
