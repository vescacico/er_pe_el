import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../services/exercise_database.dart';
import '../services/language_service.dart';
import '../services/sound_service.dart';
import '../services/quest_generation_service.dart';

class ExerciseQuestScreen extends StatefulWidget {
  final String uid;
  final Exercise exercise;
  final int sets;
  final int reps; // For static: duration in seconds, for reps: number of reps
  final int restSeconds;
  final int expReward;
  final String? questId;
  final VoidCallback onSuccess;
  final bool isStaticExercise; // true for plank, wall sit, etc.

  const ExerciseQuestScreen({
    super.key,
    required this.uid,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.expReward,
    this.questId,
    required this.onSuccess,
    this.isStaticExercise = false,
  });

  @override
  State<ExerciseQuestScreen> createState() => _ExerciseQuestScreenState();
}

class _ExerciseQuestScreenState extends State<ExerciseQuestScreen> {
  int _currentSet = 0;
  int _currentReps = 0;
  bool _isResting = false;
  bool _isCompleted = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  Timer? _timer;
  Timer? _repTimer;
  Timer? _countdownTimer;

  // Random Check System
  bool _isRandomCheckActive = false;
  int _randomCheckTimeLeft = 5;
  Timer? _randomCheckTimer;
  double _randomCheckX = 0;
  double _randomCheckY = 0;
  bool _randomCheckFailed = false;
  int _randomChecksDone = 0; // Track how many random checks have occurred
  static const int _maxRandomChecksPerSet = 2; // Max 2 random checks per set

  // Time-based tracking
  DateTime? _setStartTime;
  final Random _random = Random();

  // For static exercises (plank, etc.)
  bool get _isStatic => widget.isStaticExercise ||
      widget.exercise.category == 'core' &&
      (widget.exercise.nameId.toLowerCase().contains('plank') ||
       widget.exercise.nameId.toLowerCase().contains('wall sit'));

  // Time limit based on exercise difficulty and type (in seconds)
  int get _timeLimitForSet {
    if (_isStatic) {
      // For static exercises, time limit = hold duration + 30 seconds buffer
      return widget.reps + 30;
    }

    // For rep-based exercises
    final difficulty = widget.exercise.difficulty;
    // Base time: ~6 seconds per rep for easier exercises, 8 for harder
    final baseTimePerRep = difficulty == 'advanced' ? 8 : 6;
    final baseTime = widget.reps * baseTimePerRep;

    switch (difficulty) {
      case 'beginner':
        return baseTime + 90; // Extra time for beginners
      case 'intermediate':
        return baseTime + 60; // Extra time for intermediate
      case 'advanced':
        return baseTime + 30; // Less extra time for advanced
      default:
        return baseTime + 60;
    }
  }

  // Random check interval - longer for static exercises, 1-2 checks per set max
  int get _randomCheckIntervalSeconds {
    if (_isStatic) {
      // For plank/static: check at ~30s and ~45s marks (if holding that long)
      return widget.reps ~/ 3; // Roughly divide the hold into 3 parts
    }
    // For dynamic exercises: shorter intervals, but still max 2 per set
    if (widget.exercise.category == 'core') {
      return 20; // 20 seconds for other core exercises
    }
    return 15; // 15 seconds for other exercises
  }

  String get _langCode => LanguageService.getCurrentLanguage();
  final SoundService _sound = SoundService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _isCountingDown = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        _sound.playCountdownTick();
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _currentSet = 1;
          _isResting = false;
        });
      }
    });
  }

  void _startExercise() {
    _setStartTime = DateTime.now();
    _currentReps = 0;
    _randomChecksDone = 0;
    _repTimer?.cancel();
    _sound.resetTimerState();

    if (_isStatic) {
      _startStaticExercise();
    } else {
      _startRepBasedExercise();
    }
  }

  void _startStaticExercise() {
    // For plank/static: countdown the hold duration
    int timeLeft = widget.reps; // widget.reps is duration in seconds for static
    _repTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      timeLeft--;
      setState(() {
        _currentReps = widget.reps - timeLeft; // Show progress as reps completed
      });

      // Play timer sounds
      _sound.playStaticHoldTick(timeLeft);

      // Warning at specific times
      if (timeLeft == 10) {
        _sound.playWarning();
      }

      // Schedule random check (only 1-2 per set for static)
      if (_randomChecksDone < _maxRandomChecksPerSet && timeLeft <= widget.reps - 15) {
        _scheduleRandomCheck();
      }

      if (timeLeft <= 0) {
        timer.cancel();
        _completeStaticExercise();
      }
    });

    // Schedule first random check after initial hold period
    if (widget.reps > 20) {
      Future.delayed(Duration(seconds: widget.reps ~/ 2), () {
        if (mounted && !_isResting && !_isCompleted && _repTimer != null && _repTimer!.isActive) {
          _scheduleRandomCheck();
        }
      });
    }
  }

  void _startRepBasedExercise() {
    // For rep-based: countdown the time limit
    int timeLeft = _timeLimitForSet;
    _repTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      timeLeft--;

      // Play timer sounds
      _sound.playTimerTick(timeLeft);

      // Warning at 10 seconds
      if (timeLeft == 10) {
        _sound.playWarning();
      }

      setState(() {});

      // Schedule random check (1-2 per set)
      if (_randomChecksDone < _maxRandomChecksPerSet) {
        _scheduleRandomCheck();
      }

      if (timeLeft <= 0) {
        // Time's up! Count how many reps done manually
        timer.cancel();
        _showManualRepInput();
      }
    });

    // Trigger first random check after some time
    _scheduleRandomCheck();
  }

  void _completeStaticExercise() {
    _repTimer?.cancel();
    _sound.playSetComplete();
    if (_currentSet < widget.sets) {
      setState(() {
        _isResting = true;
      });
      _sound.playRestStart();
      _startRestTimer();
    } else {
      _completeExercise();
    }
  }

  void _scheduleRandomCheck() {
    if (_isCompleted || _isResting) return;
    if (_randomChecksDone >= _maxRandomChecksPerSet) return;

    int delay = _randomCheckIntervalSeconds + _random.nextInt(10) - 5;
    delay = delay.clamp(8, _randomCheckIntervalSeconds + 15);

    Future.delayed(Duration(seconds: delay), () {
      if (mounted && !_isResting && !_isCompleted &&
          _repTimer != null && _randomChecksDone < _maxRandomChecksPerSet) {
        _triggerRandomCheck();
      }
    });
  }

  void _triggerRandomCheck() {
    if (_isResting || _isCompleted) return;
    if (_randomChecksDone >= _maxRandomChecksPerSet) return;

    _randomChecksDone++;

    // Random position for the check button
    _randomCheckX = (_random.nextDouble() * 0.6) - 0.3;
    _randomCheckY = (_random.nextDouble() * 0.4) - 0.2;

    setState(() {
      _isRandomCheckActive = true;
      _randomCheckTimeLeft = 5;
    });

    _sound.playRandomCheckAlert();

    _randomCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _randomCheckTimeLeft--;
      });

      if (_randomCheckTimeLeft <= 0) {
        timer.cancel();
        _failRandomCheck();
      }
    });
  }

  void _successRandomCheck() {
    _randomCheckTimer?.cancel();
    _sound.playSuccess();
    setState(() {
      _isRandomCheckActive = false;
    });
    // Don't schedule more random checks for this set (already done 1-2)
  }

  void _failRandomCheck() {
    _randomCheckTimer?.cancel();
    _sound.playWarning();
    setState(() {
      _isRandomCheckActive = false;
      _randomCheckFailed = true;
    });

    // Show fail dialog
    _showRandomCheckFailDialog();
  }

  void _showRandomCheckFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              _langCode == 'id' ? 'GAGAL!' : 'FAILED!',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        content: Text(
          _langCode == 'id'
              ? 'Kamu tidak fokus! Quest gagal.'
              : 'You were not focused! Quest failed.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit quest
            },
            child: Text(
              _langCode == 'id' ? 'Keluar' : 'Exit',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Retry current set
              setState(() => _randomCheckFailed = false);
              _startExercise();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              _langCode == 'id' ? 'Coba Lagi' : 'Retry',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualRepInput() {
    _repTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.timer, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              _langCode == 'id' ? 'Waktu Habis!' : 'Time\'s Up!',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _langCode == 'id'
                  ? 'Berapa repetisi yang sudah kamu lakukan?'
                  : 'How many repetitions did you complete?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _RepInputSelector(
              maxReps: widget.reps,
              onSelected: (reps) {
                Navigator.pop(context);
                setState(() => _currentReps = reps);
                _onRepCountComplete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onRepCountComplete() {
    if (_currentReps >= widget.reps) {
      // Full completion
      _sound.playSuccess();
      _completeSet();
    } else if (_currentReps >= widget.reps * 0.5) {
      // Partial completion - count as set but with penalty note
      _sound.playBeep();
      _showPartialCompletion();
    } else {
      // Too few reps - fail
      _sound.playWarning();
      _showLowRepsDialog();
    }
  }

  void _showPartialCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              _langCode == 'id' ? 'Set Tidak Lengkap' : 'Incomplete Set',
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _langCode == 'id'
                  ? 'Kamu melakukan $_currentReps dari ${widget.reps} repetisi.'
                  : 'You completed $_currentReps of ${widget.reps} reps.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _langCode == 'id'
                  ? 'Set tetap dihitung, tapi fokus untuk menyelesaikan semuanya!'
                  : 'Set is still counted, but focus to complete all next time!',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSet();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text(
              _langCode == 'id' ? 'Lanjut' : 'Continue',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showLowRepsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.thumb_down, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              _langCode == 'id' ? 'Terlalu Sedikit!' : 'Too Few!',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _langCode == 'id'
                  ? 'Minimal harus完成 ${(widget.reps * 0.5).ceil()} repetisi!'
                  : 'You need to complete at least ${(widget.reps * 0.5).ceil()} reps!',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startExercise();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                _langCode == 'id' ? 'Coba Lagi' : 'Try Again',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              _langCode == 'id' ? 'Keluar' : 'Exit',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _completeSet() {
    _repTimer?.cancel();
    _sound.playSetComplete();
    if (_currentSet < widget.sets) {
      setState(() {
        _isResting = true;
        _currentReps = 0;
      });
      _sound.playRestStart();
      _startRestTimer();
    } else {
      _completeExercise();
    }
  }

  void _startRestTimer() {
    int restTime = widget.restSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restTime > 1) {
        setState(() => restTime--);
        // Warning beep at 5 seconds
        if (restTime == 5) {
          _sound.playWarning();
        } else {
          _sound.playTick();
        }
      } else {
        timer.cancel();
        setState(() {
          _isResting = false;
          _currentSet++;
        });
        _sound.playBeep();
      }
    });
  }

  void _completeExercise() {
    _sound.playCompletion();
    setState(() => _isCompleted = true);
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              t('quest_clear'),
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${widget.expReward} EXP',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('all_sets_completed'),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Save quest to history
              await QuestGenerationService.addQuestToHistory(
                uid: widget.uid,
                questId: widget.questId ?? widget.exercise.id,
                questName: widget.exercise.getName(_langCode),
                expReward: widget.expReward,
                exerciseType: widget.exercise.category,
              );

              // Also add to EXP history
              await QuestGenerationService.addExpToHistory(
                uid: widget.uid,
                amount: widget.expReward,
                source: widget.exercise.getName(_langCode),
              );

              Navigator.pop(context);
              widget.onSuccess();
              Navigator.pop(context);
            },
            child: Text(
              t('claim_exp'),
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _skipRest() {
    _timer?.cancel();
    _sound.playBeep();
    setState(() {
      _isResting = false;
      _currentSet++;
    });
  }

  void _quitQuest() {
    _timer?.cancel();
    _repTimer?.cancel();
    _randomCheckTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repTimer?.cancel();
    _countdownTimer?.cancel();
    _randomCheckTimer?.cancel();
    super.dispose();
  }

  int get _remainingTime {
    if (_repTimer == null || _setStartTime == null) return _timeLimitForSet;
    final elapsed = DateTime.now().difference(_setStartTime!).inSeconds;
    return (_timeLimitForSet - elapsed).clamp(0, _timeLimitForSet);
  }

  int get _staticTimeRemaining {
    // For static exercises, calculate remaining hold time
    if (_repTimer == null || _setStartTime == null) return widget.reps;
    final elapsed = DateTime.now().difference(_setStartTime!).inSeconds;
    return (widget.reps - elapsed).clamp(0, widget.reps);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCountingDown) {
      return _buildCountdownScreen();
    }

    if (_isResting) {
      return _buildRestScreen();
    }

    if (_isCompleted) {
      return _buildCompletedScreen();
    }

    return _buildExerciseScreen();
  }

  Widget _buildCountdownScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t('exercise_in_progress'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.exercise.getName(_langCode),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF10B981), width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  t('countdown'),
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestScreen() {
    int restTime = widget.restSeconds;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.exercise.getName(_langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _quitQuest,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'Set ${_currentSet}/${widget.sets} ${t('done')}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            StreamBuilder<int>(
              stream: Stream.periodic(const Duration(seconds: 1), (i) => restTime - i),
              builder: (context, snapshot) {
                final remaining = (snapshot.data ?? restTime).clamp(0, restTime);
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: remaining <= 5 ? Colors.red : Colors.amber,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${remaining}s',
                      style: TextStyle(
                        color: remaining <= 5 ? Colors.red : Colors.amber,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              t('rest_between_sets'),
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _skipRest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                'Skip Rest',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 100, color: Color(0xFF10B981)),
            const SizedBox(height: 20),
            Text(
              t('quest_clear'),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '+${widget.expReward} EXP',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseScreen() {
    final instructions = widget.exercise.getInstructions(_langCode);
    final tips = widget.exercise.getTips(_langCode);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.exercise.getName(_langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _quitQuest,
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isStatic
                  ? '${widget.sets} ${t('sets')} × ${widget.reps}s'
                  : '${widget.sets} ${t('sets')} × ${widget.reps} ${t('reps')}',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: const Color(0xFF111111),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t('sets')}: $_currentSet / ${widget.sets}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    // Time / Rep counter
                    if (_isStatic)
                      _buildStaticTimerDisplay()
                    else
                      _buildRepTimerDisplay(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise visualization with image from musclewiki
                      _buildExerciseImageSection(),
                      const SizedBox(height: 20),

                      // Target display card
                      _buildTargetCard(),
                      const SizedBox(height: 20),

                      // Start button (only show before starting)
                      if (_repTimer == null || !_repTimer!.isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _langCode == 'id' ? 'MULAI' : 'START',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Instructions
                      _buildSectionTitle(t('instructions')),
                      const SizedBox(height: 12),
                      ...instructions.asMap().entries.map((entry) {
                        return _buildInstructionItem(entry.key + 1, entry.value);
                      }),

                      const SizedBox(height: 24),

                      // Tips
                      _buildSectionTitle(t('tips')),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: tips.map((tip) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(tip, style: const TextStyle(color: Colors.amber, fontSize: 14)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Random Check Overlay
          if (_isRandomCheckActive)
            Positioned(
              left: MediaQuery.of(context).size.width * (0.2 + _randomCheckX),
              top: MediaQuery.of(context).size.height * (0.3 + _randomCheckY),
              child: GestureDetector(
                onTap: _successRandomCheck,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red, blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white, size: 40),
                      Text(
                        '$_randomCheckTimeLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _langCode == 'id' ? 'TAP!' : 'TAP!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStaticTimerDisplay() {
    final timeRemaining = _staticTimeRemaining;
    final progress = 1 - (timeRemaining / widget.reps);
    final isWarning = timeRemaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red : const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isWarning ? Colors.white : Colors.black,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${timeRemaining}s',
            style: TextStyle(
              color: isWarning ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepTimerDisplay() {
    final timeLeft = _remainingTime;
    final isWarning = timeLeft <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red : Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isWarning ? Colors.white : Colors.black,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${timeLeft}s',
            style: TextStyle(
              color: isWarning ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseImageSection() {
    final images = ExerciseDatabase.getExerciseImages(widget.exercise.id);

    if (images != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Starting position
          if (images['start'] != null) ...[
            Text(
              _langCode == 'id' ? 'Posisi Awal' : 'Starting Position',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.exercise.color.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images['start']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: widget.exercise.color,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _buildExerciseIconPlaceholder(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Ending position
          if (images['end'] != null) ...[
            Text(
              _langCode == 'id' ? 'Posisi Akhir' : 'Ending Position',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.exercise.color.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images['end']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: widget.exercise.color,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _buildExerciseIconPlaceholder(),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return _buildExerciseIconPlaceholder();
  }

  Widget _buildTargetCard() {
    if (_isStatic) {
      // For static exercises like plank
      final timeRemaining = _staticTimeRemaining;
      final progress = 1 - (timeRemaining / widget.reps);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: timeRemaining <= 10 ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              _langCode == 'id' ? 'HOLD' : 'HOLD',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.reps}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white10,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _langCode == 'id'
                  ? 'Tahan selama ${widget.reps} detik'
                  : 'Hold for ${widget.reps} seconds',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      // For rep-based exercises
      final timeLeft = _remainingTime;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: timeLeft <= 10 ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              'TARGET REPS',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.reps} reps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _langCode == 'id'
                  ? 'Waktu tersisa: ${timeLeft}s'
                  : 'Time remaining: ${timeLeft}s',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildExerciseIconPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: widget.exercise.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.exercise.color.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.exercise.icon,
            size: 80,
            color: widget.exercise.color,
          ),
          const SizedBox(height: 10),
          Text(
            widget.exercise.getName(_langCode),
            style: TextStyle(
              color: widget.exercise.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.exercise.icon,
          size: 80,
          color: widget.exercise.color,
        ),
        const SizedBox(height: 10),
        Text(
          widget.exercise.getName(_langCode),
          style: TextStyle(
            color: widget.exercise.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInstructionItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.exercise.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: widget.exercise.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk input manual jumlah repetisi
class _RepInputSelector extends StatelessWidget {
  final int maxReps;
  final Function(int) onSelected;

  const _RepInputSelector({required this.maxReps, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(maxReps + 1, (i) {
        final isTarget = i == maxReps;
        return ElevatedButton(
          onPressed: () => onSelected(i),
          style: ElevatedButton.styleFrom(
            backgroundColor: isTarget ? Colors.green : Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            '$i',
            style: TextStyle(
              color: isTarget ? Colors.white : Colors.grey[400],
              fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }
}
