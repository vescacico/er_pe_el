import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import '../services/sound_service.dart';

/// Focus Check Screen - Anti-cheat mechanism for plank/static exercises
///
/// This screen appears randomly during plank exercises to verify user attention.
/// User must tap the button within 7 seconds at a random position on screen.
///
/// Features:
/// - Full screen blocking overlay
/// - Random button position (avoiding screen edges and notch areas)
/// - 7 second countdown timer
/// - Sound effects for urgency
/// - Automatic fail if not tapped in time
class FocusCheckScreen extends StatefulWidget {
  /// Total time user has to tap (in seconds)
  final int timeLimit;

  /// Callback when user successfully taps the button
  final VoidCallback onSuccess;

  /// Callback when user fails to tap in time
  final VoidCallback onFail;

  /// Minimum distance from screen edges (as percentage of screen dimension)
  final double edgePadding;

  /// Visual theme color
  final Color accentColor;

  const FocusCheckScreen({
    super.key,
    this.timeLimit = 7,
    required this.onSuccess,
    required this.onFail,
    this.edgePadding = 0.15,
    this.accentColor = const Color(0xFFEF4444),
  });

  /// Show the focus check as a full screen dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => FocusCheckScreen(
        onSuccess: () => Navigator.pop(context, true),
        onFail: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  State<FocusCheckScreen> createState() => _FocusCheckScreenState();
}

class _FocusCheckScreenState extends State<FocusCheckScreen>
    with TickerProviderStateMixin {
  late int _timeLeft;
  Timer? _timer;

  // Button position (as percentage of screen)
  late double _buttonX;
  late double _buttonY;
  bool _positionGenerated = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Sound
  final SoundService _sound = SoundService();

  // Random generator
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Lock orientation to current orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _timeLeft = widget.timeLimit;

    // Setup animations
    _setupAnimations();

    // Start countdown
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // MediaQuery is only safe to read here, not in initState().
    // Guard with a flag so this only runs once per widget lifetime.
    if (!_positionGenerated) {
      _generateRandomPosition();
      _positionGenerated = true;
    }
  }

  void _setupAnimations() {
    // Pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shake animation for warning
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _generateRandomPosition() {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Calculate safe zone (avoiding notches, status bar, etc.)
    final minX = safeArea.left + (screenSize.width * widget.edgePadding);
    final maxX = screenSize.width - safeArea.right - (screenSize.width * widget.edgePadding) - 100;
    final minY = safeArea.top + (screenSize.height * widget.edgePadding);
    final maxY = screenSize.height - safeArea.bottom - (screenSize.height * widget.edgePadding) - 100;

    // Generate random position within safe zone
    _buttonX = minX + _random.nextDouble() * (maxX - minX);
    _buttonY = minY + _random.nextDouble() * (maxY - minY);

    // Clamp to ensure button stays within bounds
    _buttonX = _buttonX.clamp(0, screenSize.width - 100);
    _buttonY = _buttonY.clamp(0, screenSize.height - 100);
  }

  void _startCountdown() {
    _sound.playRandomCheckAlert();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeLeft--;
      });

      // Warning sounds based on time remaining
      if (_timeLeft == 5) {
        _sound.playWarning();
        _pulseController.stop();
      } else if (_timeLeft == 3) {
        _sound.playWarning();
        _shakeController.repeat(reverse: true);
      } else if (_timeLeft <= 1) {
        _sound.playWarning();
      }

      if (_timeLeft <= 0) {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTap() {
    if (!mounted) return;

    _timer?.cancel();
    _sound.playSuccess();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.onSuccess();
  }

  void _onTimeUp() {
    if (!mounted) return;

    _sound.playWarning();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Show fail animation before calling onFail
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FailDialog(
        onRetry: () {
          Navigator.pop(context);
          widget.onFail();
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _timeLeft <= 3;
    final isCritical = _timeLeft <= 1;

    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.95),
        body: Stack(
          children: [
            // Warning text at top
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Icon(
                    isCritical ? Icons.warning : Icons.touch_app,
                    color: isCritical ? Colors.red : widget.accentColor,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isCritical ? Colors.red : widget.accentColor,
                      fontSize: isCritical ? 32 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    child: Text(
                      LanguageService.getCurrentLanguage() == 'id'
                          ? 'FOCUS CHECK!'
                          : 'FOCUS CHECK!',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService.getCurrentLanguage() == 'id'
                        ? 'Tap tombol merah secepat mungkin!'
                        : 'Tap the red button as fast as possible!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Timer at center top
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? Colors.red.withOpacity(0.2)
                        : widget.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isCritical ? Colors.red : widget.accentColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCritical ? Colors.red : widget.accentColor)
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: isCritical ? Colors.red : widget.accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isCritical ? Colors.red : widget.accentColor,
                          fontSize: isCritical ? 32 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text('$_timeLeft'),
                      ),
                      Text(
                        LanguageService.getCurrentLanguage() == 'id' ? 's' : 's',
                        style: TextStyle(
                          color: isCritical
                              ? Colors.red.withOpacity(0.7)
                              : widget.accentColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instructions at bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService.getCurrentLanguage() == 'id'
                          ? 'Jaga fokus dan jangan sentuh layar!'
                          : 'Stay focused and do not touch the screen!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // The focus check button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _buttonX,
              top: _buttonY,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      isWarning ? _shakeAnimation.value : 0,
                      0,
                    ),
                    child: Transform.scale(
                      scale: isWarning ? 1.0 : _pulseAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _onTap,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.8),
                        ],
                        center: Alignment.topLeft,
                        radius: 1.2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.8),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LanguageService.getCurrentLanguage() == 'id'
                              ? 'TAP!'
                              : 'TAP!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pulsing ring effect around button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _buttonX - 20,
              top: _buttonY - 20,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.5,
                    child: Opacity(
                      opacity: 1.0 - (_pulseAnimation.value - 1.0) * 2,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog shown when user fails the focus check
class _FailDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _FailDialog({
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Text(
            LanguageService.getCurrentLanguage() == 'id'
                ? 'QUEST GAGAL!'
                : 'QUEST FAILED!',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sentiment_very_dissatisfied,
            color: Colors.red.withOpacity(0.7),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            LanguageService.getCurrentLanguage() == 'id'
                ? 'Kamu tidak fokus!\nQuest plank gagal.'
                : 'You were not focused!\nPlank quest failed.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            LanguageService.getCurrentLanguage() == 'id'
                ? 'Pastikan untuk tetap fokus next time!'
                : 'Make sure to stay focused next time!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onExit,
          child: Text(
            LanguageService.getCurrentLanguage() == 'id' ? 'Keluar' : 'Exit',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: Text(
            LanguageService.getCurrentLanguage() == 'id' ? 'Coba Lagi' : 'Retry',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Compact Focus Check Widget for embedding in other screens
///
/// This widget shows a mini focus check overlay that can be placed
/// on top of exercise screens
class FocusCheckOverlay extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  final int timeLimit;
  final bool isActive;
  final double buttonX;
  final double buttonY;
  final int timeLeft;

  const FocusCheckOverlay({
    super.key,
    required this.onSuccess,
    required this.onFail,
    this.timeLimit = 7,
    required this.isActive,
    required this.buttonX,
    required this.buttonY,
    required this.timeLeft,
  });

  @override
  State<FocusCheckOverlay> createState() => FocusCheckOverlayState();
}

class FocusCheckOverlayState extends State<FocusCheckOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final isWarning = widget.timeLeft <= 3;
    final isCritical = widget.timeLeft <= 1;

    return Positioned(
      left: widget.buttonX,
      top: widget.buttonY,
      child: GestureDetector(
        onTap: widget.onSuccess,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isWarning ? 1.0 : _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.red,
                      Colors.red.withOpacity(0.8),
                    ],
                    center: Alignment.topLeft,
                    radius: 1.2,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 28,
                    ),
                    Text(
                      '${widget.timeLeft}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Helper to check if focus check should trigger
/// Based on random chance and elapsed time
bool shouldTriggerFocusCheck({
  required int elapsedSeconds,
  required int totalDuration,
  required int maxChecks,
  required int checksDone,
}) {
  if (checksDone >= maxChecks) return false;

  // Calculate check points (e.g., at 25%, 50%, 75% of duration)
  final checkPoints = <double>[0.25, 0.5, 0.75];

  final progress = elapsedSeconds / totalDuration;

  for (final point in checkPoints) {
    if ((progress - point).abs() < 0.05 && checksDone < maxChecks) {
      return true;
    }
  }

  return false;
}