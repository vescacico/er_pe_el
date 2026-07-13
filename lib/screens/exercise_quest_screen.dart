import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../services/exercise_database.dart';
import '../services/language_service.dart';
import '../services/sound_service.dart';
import '../services/quest_generation_service.dart';
import 'focus_check_screen.dart';

class ExerciseQuestScreen extends StatefulWidget {
  final String uid;
  final Exercise exercise;
  final int sets;
  final int reps;
  final int restSeconds;
  final int expReward;
  final String? questId;
  final VoidCallback onSuccess;
  final bool isStaticExercise;

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
  State<ExerciseQuestScreen> createState() => ExerciseQuestScreenState();
}

class ExerciseQuestScreenState extends State<ExerciseQuestScreen> {
  static const int _sessionTimeLimit = 180;

  int _currentSet = 0;
  int _currentReps = 0;
  bool _isResting = false;
  bool _isCompleted = false;
  bool _isCountingDown = false;
  bool _exerciseStarted = false;
  int _countdown = 3;
  int _sessionTimeLeft = _sessionTimeLimit;
  int _holdTimeLeft = 0;
  int _restTimeLeft = 0;
  bool _finishedEarly = false;
  bool _randomCheckActive = false;

  Timer? _timer;
  Timer? _randomCheckTimer;
  Timer? _sessionTimer;
  final SoundService _sound = SoundService();

  @override
  void initState() {
    super.initState();
    _holdTimeLeft = widget.reps;
    _sessionTimeLeft = _sessionTimeLimit;
    _isCountingDown = true;
    _startCountdown();
    _scheduleRandomCheck();
  }

  // Start session timer that counts down
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionTimeLeft > 0 && !_isResting && !_isCompleted) {
        setState(() => _sessionTimeLeft--);
      }
      if (_sessionTimeLeft <= 0) {
        timer.cancel();
      }
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _sound.playCountdown();
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _exerciseStarted = true;
          if (widget.isStaticExercise) {
            _startHoldTimer();
          }
        });
        _startSessionTimer(); // Start session countdown
      }
    });
  }

  void _scheduleRandomCheck() {
    final delay = 15 + (DateTime.now().millisecond % 31);
    _randomCheckTimer = Timer(Duration(seconds: delay), _triggerRandomCheck);
  }

  void _startHoldTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_holdTimeLeft > 1) {
        setState(() => _holdTimeLeft--);
      } else {
        timer.cancel();
        _completeSet();
      }
    });
  }

  void _startRestTimer() {
    // Calculate rest time based on exercise difficulty: 5-45 seconds
    // Use exercise difficulty or fall back to quest difficulty
    int restDuration;
    final exerciseDifficulty = widget.exercise.difficulty.toLowerCase();

    if (exerciseDifficulty.contains('beginner') || exerciseDifficulty == 'easy') {
      restDuration = 8; // 8 seconds for easy/beginner
    } else if (exerciseDifficulty.contains('intermediate') || exerciseDifficulty == 'medium') {
      restDuration = 15; // 15 seconds for medium
    } else if (exerciseDifficulty == 'hard' || exerciseDifficulty.contains('advanced')) {
      restDuration = 25; // 25 seconds for hard
    } else if (exerciseDifficulty.contains('expert')) {
      restDuration = 40; // 40 seconds for expert
    } else {
      // Fall back to widget.restSeconds but clamp between 5-45
      restDuration = widget.restSeconds.clamp(5, 45);
    }

    _restTimeLeft = restDuration;
    setState(() => _isResting = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeLeft > 1) {
        _sound.playTick();
        setState(() => _restTimeLeft--);
      } else {
        timer.cancel();
        _sound.playRestStart();
        _startNextSet();
      }
    });
  }

  // Skip rest and continue immediately
  void _skipRest() {
    _timer?.cancel();
    setState(() => _restTimeLeft = 0);
    _sound.playSuccess();
    _startNextSet();
  }

  void _triggerRandomCheck() {
    if (_isResting || _isCompleted) return;
    _showFocusCheck();
  }

  Future<void> _showFocusCheck() async {
    final result = await FocusCheckScreen.show(context);
    if (result == null || !result) {
      _failRandomCheck();
    }
  }

  void _failRandomCheck() {
    _sound.playWarning();
    setState(() => _randomCheckActive = false);
    _showFailDialog();
  }

  void _showFailDialog() {
    final lang = LanguageService.getCurrentLanguage();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red),
        ),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(lang == 'id' ? 'Gagal!' : 'Failed!', style: const TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          lang == 'id' ? 'Kamu tidak fokus saat exercise!' : 'You were not focused during exercise!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(lang == 'id' ? 'Keluar' : 'Exit', style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetExercise();
            },
            child: Text(lang == 'id' ? 'Coba Lagi' : 'Retry', style: const TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _resetExercise() {
    setState(() {
      _currentSet = 0;
      _currentReps = 0;
      _holdTimeLeft = widget.reps;
      _sessionTimeLeft = _sessionTimeLimit;
      _isResting = false;
      _randomCheckActive = false;
      _finishedEarly = false;
      _isCountingDown = true;
      _exerciseStarted = false;
      _countdown = 3;
    });
    _startCountdown();
    _scheduleRandomCheck();
  }

  void _incrementReps() {
    if (_currentReps < widget.reps) {
      _sound.playRepComplete();
      setState(() {
        _currentReps++;
        if (_currentReps >= widget.reps) {
          _finishedEarly = true;
        }
      });
      if (_currentReps >= widget.reps) {
        _completeSet();
      }
    }
  }

  void _completeSet() {
    _timer?.cancel();
    _sound.playSetComplete();
    if (_currentSet + 1 >= widget.sets) {
      _completeExercise();
    } else {
      setState(() {
        _currentSet++;
        _currentReps = 0;
        _holdTimeLeft = widget.reps;
      });
      _startRestTimer();
    }
  }

  void _startNextSet() {
    setState(() {
      _isResting = false;
      _currentReps = 0;
      _holdTimeLeft = widget.reps;
    });
    if (widget.isStaticExercise) {
      _startHoldTimer();
    }
  }

  void _completeExercise() {
    setState(() => _isCompleted = true);
    _timer?.cancel();
    _randomCheckTimer?.cancel();
    _sound.playCompletion();

    final lang = LanguageService.getCurrentLanguage();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(lang == 'id' ? 'Selesai!' : 'Completed!', style: const TextStyle(color: Color(0xFF10B981))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${widget.expReward} EXP',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (_finishedEarly) ...[
              const SizedBox(height: 8),
              Text(
                lang == 'id' ? 'Selesai lebih awal!' : 'Finished early!',
                style: const TextStyle(color: Colors.amber),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await QuestGenerationService.addQuestToHistory(
                uid: widget.uid,
                questId: widget.questId ?? widget.exercise.id,
                questName: widget.exercise.getName(lang),
                expReward: widget.expReward,
                exerciseType: widget.exercise.category,
              );
              await QuestGenerationService.addExpToHistory(
                uid: widget.uid,
                amount: widget.expReward,
                source: widget.exercise.getName(lang),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              widget.onSuccess();
              Navigator.pop(context);
            },
            child: Text(lang == 'id' ? 'Klaim EXP' : 'Claim EXP', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _quitQuest() {
    _timer?.cancel();
    _randomCheckTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _randomCheckTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCountingDown) return _buildCountdownScreen();
    if (_isResting) return _buildRestScreen();
    if (_isCompleted) return _buildCompletedScreen();
    return _buildExerciseScreen();
  }

  Widget _buildCountdownScreen() {
    final lang = LanguageService.getCurrentLanguage();
    final name = widget.exercise.getName(lang);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lang == 'id' ? 'Latihan dalam progres' : 'Exercise in progress',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 4),
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 72, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isStaticExercise
                  ? (lang == 'id' ? 'Bersiaplah menahan!' : 'Get Ready to Hold!')
                  : (lang == 'id' ? 'Bersiaplah!' : 'Get Ready!'),
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestScreen() {
    // Calculate actual rest duration for progress display
    int restDuration;
    final exerciseDifficulty = widget.exercise.difficulty.toLowerCase();

    if (exerciseDifficulty.contains('beginner') || exerciseDifficulty == 'easy') {
      restDuration = 8;
    } else if (exerciseDifficulty.contains('intermediate') || exerciseDifficulty == 'medium') {
      restDuration = 15;
    } else if (exerciseDifficulty == 'hard' || exerciseDifficulty.contains('advanced')) {
      restDuration = 25;
    } else if (exerciseDifficulty.contains('expert')) {
      restDuration = 40;
    } else {
      restDuration = widget.restSeconds.clamp(5, 45);
    }

    final progress = restDuration > 0 ? (_restTimeLeft / restDuration) : 0.0;
    final isCritical = _restTimeLeft <= 3;
    final lang = LanguageService.getCurrentLanguage();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('REST', style: TextStyle(color: Colors.white54, fontSize: 24, letterSpacing: 4)),
            const SizedBox(height: 30),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isCritical ? Colors.red : Colors.amber, width: 4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: isCritical ? Colors.red : Colors.amber,
                    ),
                  ),
                  Text(
                    '$_restTimeLeft',
                    style: TextStyle(
                      color: isCritical ? Colors.red : Colors.amber,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              lang == 'id' ? 'Set selanjutnya' : 'Next set',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            Text(
              '${_currentSet + 1}/${widget.sets}',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Skip rest button
            TextButton(
              onPressed: _skipRest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  lang == 'id' ? 'LEWATI REST >' : 'SKIP REST >',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 100),
            const SizedBox(height: 20),
            Text(
              LanguageService.getCurrentLanguage() == 'id' ? 'Selesai!' : 'Completed!',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '+${widget.expReward} EXP',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseScreen() {
    final lang = LanguageService.getCurrentLanguage();
    final progress = _sessionTimeLimit > 0 ? (_sessionTimeLeft / _sessionTimeLimit) : 0.0;
    final isWarning = _sessionTimeLeft <= 30;
    final isCritical = _sessionTimeLeft <= 10;
    final instructions = widget.exercise.getInstructions(lang);
    final tips = widget.exercise.getTips(lang);
    final name = widget.exercise.getName(lang);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _quitQuest),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF111111),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: isCritical ? Colors.red : (isWarning ? Colors.orange : Colors.amber),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang == 'id' ? 'Sisa Waktu' : 'Time Left',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          _formatTime(_sessionTimeLeft),
                          style: TextStyle(
                            color: isCritical ? Colors.red : (isWarning ? Colors.orange : Colors.amber),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        color: isCritical ? Colors.red : (isWarning ? Colors.orange : Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Set: $_currentSet / ${widget.sets}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        if (_exerciseStarted && !widget.isStaticExercise)
                          Text(
                            lang == 'id' ? 'Tap untuk repetisi' : 'Tap to count reps',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExerciseImageSection(),
                      const SizedBox(height: 20),
                      _buildTargetCard(),
                      const SizedBox(height: 16),

                      // Quick Guide Panel - User friendly guide
                      _buildQuickGuidePanel(),

                      const SizedBox(height: 16),

                      if (!_exerciseStarted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              lang == 'id' ? 'MULAI' : 'START',
                              style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                          ),
                        ),
                      if (_exerciseStarted && !widget.isStaticExercise && !_isResting) _buildTapArea(),
                      const SizedBox(height: 24),
                      Text(
                        lang == 'id' ? 'Instruksi' : 'Instructions',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < instructions.length; i++)
                        _buildInstructionItem(i + 1, instructions[i]),
                      const SizedBox(height: 24),
                      Text(
                        lang == 'id' ? 'Tips' : 'Tips',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTipsSection(tips),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_randomCheckActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _randomCheckTimer?.cancel();
                  setState(() => _randomCheckActive = false);
                  _sound.playSuccess();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.red, blurRadius: 30, spreadRadius: 10)],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 50),
                          SizedBox(height: 8),
                          Text('TAP!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startExercise() {
    setState(() {
      _exerciseStarted = true;
      if (widget.isStaticExercise) {
        _startHoldTimer();
      }
    });
  }

  Widget _buildTapArea() {
    final lang = LanguageService.getCurrentLanguage();
    return GestureDetector(
      onTap: _incrementReps,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.touch_app, color: Color(0xFF10B981), size: 48),
            const SizedBox(height: 8),
            Text(
              lang == 'id' ? 'TAP untuk repetisi' : 'TAP for reps',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$_currentReps / ${widget.reps}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (_finishedEarly) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      lang == 'id' ? 'Cepat!' : 'Fast!',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard() {
    final lang = LanguageService.getCurrentLanguage();
    if (widget.isStaticExercise) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _holdTimeLeft <= 10 ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              'HOLD',
              style: const TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            Text(
              _exerciseStarted ? '${_holdTimeLeft}s' : '${widget.reps}s',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${lang == 'id' ? 'Tahan selama ' : 'Hold for '}${widget.reps}${lang == 'id' ? ' detik' : ' seconds'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(
            _exerciseStarted ? '$_currentReps / ${widget.reps}' : '${widget.reps}',
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.sets} ${lang == 'id' ? 'Set' : 'Sets'} x ${widget.reps} ${lang == 'id' ? 'Rep' : 'Reps'}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            lang == 'id' ? 'Tap untuk menghitung repetisi' : 'Tap to count repetitions',
            style: const TextStyle(color: Colors.amber, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseImageSection() {
    final images = ExerciseDatabase.getExerciseImages(widget.exercise.id);
    if (images == null) return _buildIconPlaceholder();

    final lang = LanguageService.getCurrentLanguage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images['start'] != null) ...[
          Text(
            lang == 'id' ? 'Posisi Awal' : 'Starting Position',
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
              child: CachedNetworkImage(
                imageUrl: images['start']!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildIconPlaceholder(),
                errorWidget: (context, url, error) => _buildIconPlaceholder(),
              ),
            ),
          ),
        ],
        if (images['end'] != null) ...[
          const SizedBox(height: 16),
          Text(
            lang == 'id' ? 'Posisi Akhir' : 'Ending Position',
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
              child: CachedNetworkImage(
                imageUrl: images['end']!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildIconPlaceholder(),
                errorWidget: (context, url, error) => _buildIconPlaceholder(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: widget.exercise.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.exercise.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.exercise.icon, size: 80, color: widget.exercise.color),
          const SizedBox(height: 10),
          Text(
            widget.exercise.getName(LanguageService.getCurrentLanguage()),
            style: TextStyle(color: widget.exercise.color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
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
                style: TextStyle(color: widget.exercise.color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildTipsSection(List<String> tips) {
    if (tips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Text(
          LanguageService.getCurrentLanguage() == 'id' ? 'Tidak ada tips tersedia' : 'No tips available',
          style: const TextStyle(color: Colors.amber, fontSize: 14),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(tip, style: const TextStyle(color: Colors.amber, fontSize: 14))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // Quick Guide Panel - User friendly guide for exercise
  Widget _buildQuickGuidePanel() {
    final lang = LanguageService.getCurrentLanguage();
    final isId = lang == 'id';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            const Color(0xFF111111),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                isId ? 'Panduan Singkat' : 'Quick Guide',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step-by-step guide
          if (!_exerciseStarted) ...[
            _buildGuideStep(
              icon: Icons.touch_app,
              color: Colors.blue,
              title: isId ? '1. Tekan MULAI' : '1. Press START',
              description: isId ? 'Untuk mulai exercise' : 'To start exercise',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              icon: Icons.repeat,
              color: Colors.orange,
              title: isId ? '2. Tap Layar' : '2. Tap Screen',
              description: isId
                  ? 'Tap layar untuk menghitung repetisi'
                  : 'Tap screen to count repetitions',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              icon: Icons.timer,
              color: Colors.amber,
              title: isId ? '3. Istirahat' : '3. Rest',
              description: isId
                  ? 'Istirahat sebentar antar set'
                  : 'Rest briefly between sets',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              icon: Icons.flag,
              color: Colors.green,
              title: isId ? '4. Selesaikan!' : '4. Complete!',
              description: isId
                  ? 'Kumpulkan semua set untuk klaim EXP'
                  : 'Complete all sets to claim EXP',
            ),
          ] else ...[
            _buildGuideStep(
              icon: Icons.touch_app,
              color: const Color(0xFF10B981),
              title: isId ? '✓ Tap Layar!' : '✓ Tap Screen!',
              description: isId
                  ? 'Tap untuk menghitung repetisi $_currentReps/${widget.reps}'
                  : 'Tap to count reps $_currentReps/${widget.reps}',
              isActive: true,
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              icon: Icons.repeat,
              color: Colors.grey,
              title: isId
                  ? 'Set ${_currentSet + 1}/${widget.sets}'
                  : 'Set ${_currentSet + 1}/${widget.sets}',
              description: isId
                  ? 'Selesaikan ${widget.reps} repetisi per set'
                  : 'Complete ${widget.reps} reps per set',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isActive ? Colors.white : color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? color : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: isActive ? color.withOpacity(0.8) : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
