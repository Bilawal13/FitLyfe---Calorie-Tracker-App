import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SoundService handles calming audio feedback across the app with ambient
/// sonification settings, persistence, and fail-safe haptic/system fallbacks.
class SoundService {
  static const String _keySoundEnabled = 'sound_effects_enabled';
  static bool _soundEnabled = true;

  static bool get isSoundEnabled => _soundEnabled;

  static AudioPlayer? _tapPlayer;
  static AudioPlayer? _tabPlayer;
  static bool _initialized = false;

  /// Initialize sound settings and configure low-latency sonification context
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;

      // Configure audio context for ambient sonification on mobile devices
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));

      _tapPlayer = AudioPlayer();
      _tabPlayer = AudioPlayer();
      await _tapPlayer?.setReleaseMode(ReleaseMode.stop);
      await _tabPlayer?.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('SoundService.init note: $e');
    }
  }

  /// Toggle sound effects on/off and persist in SharedPreferences
  static Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, enabled);
    } catch (_) {}
  }

  /// Plays a soothing, rich organic chime on button presses
  static Future<void> playTap() async {
    if (!_soundEnabled) return;

    try {
      HapticFeedback.selectionClick();
      _tapPlayer ??= AudioPlayer();
      await _tapPlayer!.stop();
      await _tapPlayer!.play(
        AssetSource('audio/calm_tap.wav'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('SoundService.playTap fallback: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Plays a relaxing harmonic chord when changing tabs
  static Future<void> playTab() async {
    if (!_soundEnabled) return;

    try {
      HapticFeedback.lightImpact();
      _tabPlayer ??= AudioPlayer();
      await _tabPlayer!.stop();
      await _tabPlayer!.play(
        AssetSource('audio/calm_tab.wav'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('SoundService.playTab fallback: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }
}
