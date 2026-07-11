import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service untuk mengelola sound effects dalam aplikasi
/// Menggunakan system sounds dan haptic feedback untuk real-time timer
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;

  // Timer state untuk real-time countdown sounds
  int _lastTickSecond = -1;

  /// Inisialisasi sound service
  static Future<void> initialize() async {
    // Set audio mode for low latency
    await _instance._audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  /// Set mute/unmute
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  bool get isMuted => _isMuted;

  /// Reset timer state - call when starting new timer
  void resetTimerState() {
    _lastTickSecond = -1;
  }

  /// Play timer tick - call every second during countdown
  /// Only plays sound at specific intervals to avoid audio overload
  Future<void> playTimerTick(int currentSecond) async {
    if (_isMuted) return;

    try {
      // Reset if timer restarted
      if (currentSecond > _lastTickSecond && _lastTickSecond > 0) {
        _lastTickSecond = currentSecond;
        return;
      }
      _lastTickSecond = currentSecond;

      // Play tick based on time remaining
      if (currentSecond <= 5) {
        // Last 5 seconds - short beep each second
        await SystemSound.play(SystemSoundType.click);
      } else if (currentSecond <= 10) {
        // 6-10 seconds - tick every 2 seconds
        if (currentSecond % 2 == 0) {
          await SystemSound.play(SystemSoundType.click);
        }
      } else if (currentSecond % 10 == 0) {
        // Every 10 seconds otherwise
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      HapticFeedback.lightImpact();
    }
  }

  /// Mainkan countdown tick - for countdown before exercise starts
  Future<void> playCountdownTick() async {
    if (_isMuted) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Mainkan tick sound untuk timer (legacy support)
  Future<void> playTick() async {
    if (_isMuted) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      HapticFeedback.lightImpact();
    }
  }

  /// Mainkan warning beep (3x beep cepat) - untuk waktu hampir habis
  Future<void> playWarning() async {
    if (_isMuted) return;
    try {
      for (int i = 0; i < 3; i++) {
        await SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Mainkan success sound
  Future<void> playSuccess() async {
    if (_isMuted) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 100));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Mainkan alarm untuk random check - distinctive vibration pattern
  Future<void> playRandomCheckAlert() async {
    if (_isMuted) return;
    try {
      // Vibration pattern untuk alert
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignore
    }
  }

  /// Mainkan countdown sound (legacy support)
  Future<void> playCountdown() async {
    if (_isMuted) return;
    HapticFeedback.mediumImpact();
  }

  /// Mainkan completion fanfare
  Future<void> playCompletion() async {
    if (_isMuted) return;
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignore
    }
  }

  /// Mainkan rest start sound
  Future<void> playRestStart() async {
    if (_isMuted) return;
    HapticFeedback.lightImpact();
  }

  /// Mainkan quest ready alert
  Future<void> playQuestReady() async {
    if (_isMuted) return;
    HapticFeedback.vibrate();
  }

  /// Play static exercise hold sound - for plank/static holds
  /// This is called every few seconds during static exercises
  Future<void> playStaticHoldTick(int secondsRemaining) async {
    if (_isMuted) return;

    try {
      if (secondsRemaining <= 10) {
        // Last 10 seconds - beep every second
        await SystemSound.play(SystemSoundType.click);
      } else if (secondsRemaining <= 30) {
        // Last 30 seconds - beep every 5 seconds
        if (secondsRemaining % 5 == 0) {
          await SystemSound.play(SystemSoundType.click);
        }
      } else if (secondsRemaining % 15 == 0) {
        // Beyond 30 seconds - beep every 15 seconds
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      // Silent fallback
    }
  }

  /// Play time up alert - for when time limit is reached
  Future<void> playTimeUpAlert() async {
    if (_isMuted) return;
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignore
    }
  }

  /// Play rep completion sound - when a rep is counted
  Future<void> playRepComplete() async {
    if (_isMuted) return;
    HapticFeedback.lightImpact();
  }

  /// Play set complete sound
  Future<void> playSetComplete() async {
    if (_isMuted) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 80));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Play beep (legacy support)
  Future<void> playBeep() async {
    if (_isMuted) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
