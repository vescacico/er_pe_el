import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/user_profile_service.dart';
import '../services/quest_generation_service.dart';
import '../services/language_service.dart';
import '../services/exercise_database.dart';
import '../quest_walk.dart';
import 'exercise_quest_screen.dart';
import 'exercise_detail_screen.dart';
import 'hydration_quest_screen.dart';

class DailyQuestScreen extends StatefulWidget {
  final String uid;
  final UserProfileData profile;
  final VoidCallback onQuestComplete;
  final Function(int) onExpEarned;

  const DailyQuestScreen({
    super.key,
    required this.uid,
    required this.profile,
    required this.onQuestComplete,
    required this.onExpEarned,
  });

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> with SingleTickerProviderStateMixin {
  List<DailyQuest> _quests = [];
  Map<String, QuestProgress> _progress = {};
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _restModeActive = false;
  String _currentLang = 'id';
  int _dailyExpEarned = 0;

  // Animation for lock icon
  late AnimationController _lockAnimController;
  late Animation<double> _lockAnimation;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();

    // Lock animation
    _lockAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _lockAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _lockAnimController, curve: Curves.easeInOut),
    );

    _loadQuests();
  }

  @override
  void dispose() {
    _lockAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    setState(() => _isLoading = true);

    try {
      // Load rest mode status
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        _restModeActive = userDoc.data()?['restModeActive'] ?? false;
      }

      // Generate quests dari AI berdasarkan profil
      final quests = await QuestGenerationService.generateDailyQuests(
        uid: widget.uid,
        profile: widget.profile,
      );

      // Load progress
      final progress = await QuestGenerationService.getQuestProgress(widget.uid);

      // Load daily exp
      final dailyExp = await QuestGenerationService.getDailyExpEarned(widget.uid);

      setState(() {
        _quests = quests;
        _progress = progress;
        _dailyExpEarned = dailyExp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading quests: $e');
    }
  }

  Future<void> _regenerateQuests() async {
    if (_restModeActive) {
      _showRestModeWarning();
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Hapus quest hari ini
      await QuestGenerationService.saveDailyQuests(widget.uid, []);
      await QuestGenerationService.updateQuestProgress(
        uid: widget.uid,
        questId: 'regenerate_all',
        currentProgress: 0,
        isCompleted: false,
      );

      // Generate ulang
      await _loadQuests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentLang == 'id'
                ? 'Quest harian diperbarui!'
                : 'Daily quests updated!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error regenerating quests: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showRestModeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Mode Istirahat Aktif' : 'Rest Mode Active',
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Quest dikunci karena Mode Istirahat aktif.\nNonaktifkan Mode Istirahat untuk menjalankan quest.'
              : 'Quests are locked because Rest Mode is active.\nDeactivate Rest Mode to start quests.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? 'OK' : 'OK',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  void _onQuestPressed(DailyQuest quest) {
    // Cek rest mode
    if (_restModeActive) {
      _showRestModeWarning();
      return;
    }

    if (_isQuestCompleted(quest.id)) return;

    switch (quest.type) {
      case QuestType.walk:
        _startWalkQuest(quest);
        break;
      case QuestType.water:
        _startWaterQuest(quest);
        break;
      case QuestType.plank:
        _startPlankQuest(quest);
        break;
      case QuestType.exercise:
        _startExerciseQuest(quest);
        break;
    }
  }

  void _startWalkQuest(DailyQuest quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestWalkScreen(
          uid: widget.uid,
          targetSteps: quest.target,
          expReward: quest.expReward,
          questId: quest.id,
          onSuccess: () => _onQuestCompleted(quest),
        ),
      ),
    );
  }

  void _startWaterQuest(DailyQuest quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HydrationQuestScreen(
          uid: widget.uid,
          dailyTargetMl: widget.profile.weightKg != null
              ? (widget.profile.weightKg! * 32.5).toInt()
              : quest.target,
          expReward: quest.expReward,
          questId: quest.id,
          onSuccess: () => _onQuestCompleted(quest),
        ),
      ),
    );
  }

  void _startPlankQuest(DailyQuest quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlankQuestScreen(
          targetSeconds: quest.target,
          expReward: quest.expReward,
          questId: quest.id,
          uid: widget.uid,
          onSuccess: () => _onQuestCompleted(quest),
        ),
      ),
    );
  }

  void _startExerciseQuest(DailyQuest quest) {
    if (quest.exerciseId == null) return;

    final exercise = ExerciseDatabase.getExerciseById(quest.exerciseId!);
    if (exercise == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseQuestScreen(
          uid: widget.uid,
          exercise: exercise,
          sets: quest.sets ?? 3,
          reps: quest.reps ?? 10,
          restSeconds: 30,
          expReward: quest.expReward,
          questId: quest.id,
          onSuccess: () => _onQuestCompleted(quest),
        ),
      ),
    );
  }

  void _onQuestCompleted(DailyQuest quest) async {
    // Check daily EXP limit
    final dailyLimit = UserProfileService.getDailyExpLimit(widget.profile.level);
    if (_dailyExpEarned + quest.expReward > dailyLimit) {
      _showExpLimitDialog();
      return;
    }

    // Add EXP to history
    await QuestGenerationService.addExpToHistory(
      uid: widget.uid,
      amount: quest.expReward,
      source: quest.titleId,
    );

    // Add to quest history
    await QuestGenerationService.addQuestToHistory(
      uid: widget.uid,
      questId: quest.id,
      questName: quest.titleId,
      expReward: quest.expReward,
      exerciseType: quest.type.name,
    );

    // Update quest progress
    await QuestGenerationService.updateQuestProgress(
      uid: widget.uid,
      questId: quest.id,
      currentProgress: quest.target,
      isCompleted: true,
    );

    setState(() {
      _dailyExpEarned += quest.expReward;
    });

    widget.onExpEarned(quest.expReward);
    widget.onQuestComplete();

    // Refresh progress
    QuestGenerationService.getQuestProgress(widget.uid).then((progress) {
      if (mounted) {
        setState(() => _progress = progress);
      }
    });
  }

  void _showExpLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Batas EXP Tercapai' : 'EXP Limit Reached',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Batas EXP harian telah tercapai!\n\nIstirahat dulu dan lanjutkan besok.'
              : 'Daily EXP limit reached!\n\nRest and continue tomorrow.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? 'OK' : 'OK',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  bool _isQuestCompleted(String questId) {
    return _progress[questId]?.isCompleted ?? false;
  }

  int _getQuestProgress(String questId) {
    return _progress[questId]?.currentProgress ?? 0;
  }

  double _getQuestProgressPercent(DailyQuest quest) {
    final progress = _getQuestProgress(quest.id);
    if (quest.type == QuestType.water) {
      // Progress dalam ml
      final targetMl = widget.profile.weightKg != null
          ? (widget.profile.weightKg! * 32.5)
          : quest.target.toDouble();
      return (progress / targetMl).clamp(0.0, 1.0);
    }
    return (progress / quest.target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final dailyLimit = UserProfileService.getDailyExpLimit(widget.profile.level);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Quest Harian' : 'Daily Quests',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
              onPressed: _restModeActive ? _showRestModeWarning : _regenerateQuests,
              tooltip: _currentLang == 'id' ? 'Perbarui Quest' : 'Refresh Quests',
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Column(
              children: [
                // Rest Mode Banner
                if (_restModeActive)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _lockAnimation,
                          child: const Icon(Icons.lock, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentLang == 'id' ? 'Mode Istirahat Aktif' : 'Rest Mode Active',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _currentLang == 'id'
                                    ? 'Nonaktifkan untuk menjalankan quest'
                                    : 'Deactivate to start quests',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Daily EXP Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                _currentLang == 'id' ? 'EXP Harian' : 'Daily EXP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$_dailyExpEarned / $dailyLimit',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_dailyExpEarned / dailyLimit).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          color: _dailyExpEarned >= dailyLimit
                              ? Colors.orange
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quest List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quests.length,
                    itemBuilder: (context, index) {
                      final quest = _quests[index];
                      final isCompleted = _isQuestCompleted(quest.id);
                      final progressPercent = _getQuestProgressPercent(quest);

                      return _buildQuestCard(quest, isCompleted, progressPercent);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestCard(DailyQuest quest, bool isCompleted, double progressPercent) {
    final isIndonesian = _currentLang == 'id';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Main card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : _getDifficultyColor(quest.difficulty).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(quest.difficulty).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(quest.difficulty).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          quest.icon,
                          color: isCompleted
                              ? Colors.green
                              : _getDifficultyColor(quest.difficulty),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.getTitle(_currentLang),
                              style: TextStyle(
                                color: isCompleted ? Colors.grey : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildDifficultyBadge(quest.difficulty),
                                const SizedBox(width: 8),
                                _buildTypeBadge(quest.type),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${quest.expReward}',
                            style: TextStyle(
                              color: isCompleted ? Colors.grey : const Color(0xFF10B981),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'EXP',
                            style: TextStyle(
                              color: isCompleted ? Colors.grey : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        quest.getDescription(_currentLang),
                        style: TextStyle(
                          color: isCompleted ? Colors.grey : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      if (!isCompleted && progressPercent > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_getQuestProgress(quest.id)} / ${quest.target} ${quest.unit}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              '${(progressPercent * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 6,
                            backgroundColor: Colors.white10,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Action Button
                      Row(
                        children: [
                          if (quest.exerciseId != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final exercise = ExerciseDatabase.getExerciseById(quest.exerciseId!);
                                  if (exercise != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(
                                          exercise: exercise,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _getDifficultyColor(quest.difficulty)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  isIndonesian ? 'Detail' : 'Details',
                                  style: TextStyle(color: _getDifficultyColor(quest.difficulty)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: quest.exerciseId != null ? 1 : 2,
                            child: ElevatedButton(
                              onPressed: () => _onQuestPressed(quest),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.grey
                                    : _getDifficultyColor(quest.difficulty),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                isCompleted
                                    ? (isIndonesian ? 'Selesai' : 'Done')
                                    : _getActionText(quest),
                                style: TextStyle(
                                  color: isCompleted ? Colors.white54 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lock overlay when rest mode is active
          if (_restModeActive && !isCompleted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _lockAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _currentLang == 'id'
                            ? 'Nonaktifkan Mode Istirahat untuk menjalankan quest'
                            : 'Deactivate Rest Mode to start quest',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case 'easy':
        color = Colors.green;
        text = _currentLang == 'id' ? 'Mudah' : 'Easy';
        break;
      case 'medium':
        color = Colors.orange;
        text = _currentLang == 'id' ? 'Sedang' : 'Medium';
        break;
      case 'hard':
        color = Colors.red;
        text = _currentLang == 'id' ? 'Sulit' : 'Hard';
        break;
      default:
        color = Colors.grey;
        text = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }

  Widget _buildTypeBadge(QuestType type) {
    Color color;
    String text;

    switch (type) {
      case QuestType.walk:
        color = Colors.blue;
        text = _currentLang == 'id' ? 'Jalan' : 'Walk';
        break;
      case QuestType.water:
        color = Colors.cyan;
        text = _currentLang == 'id' ? 'Air' : 'Water';
        break;
      case QuestType.plank:
        color = Colors.purple;
        text = 'Plank';
        break;
      case QuestType.exercise:
        color = Colors.orange;
        text = _currentLang == 'id' ? 'Latihan' : 'Exercise';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionText(DailyQuest quest) {
    final isIndonesian = _currentLang == 'id';
    switch (quest.type) {
      case QuestType.walk:
        return isIndonesian ? 'Mulai Jalan' : 'Start Walk';
      case QuestType.water:
        return isIndonesian ? 'Catat Air' : 'Log Water';
      case QuestType.plank:
        return isIndonesian ? 'Mulai Plank' : 'Start Plank';
      case QuestType.exercise:
        return isIndonesian ? 'Mulai Latihan' : 'Start Exercise';
    }
  }
}

// Extended PlankQuestScreen with EXP and Quest ID support
class PlankQuestScreen extends StatefulWidget {
  final int targetSeconds;
  final int expReward;
  final String questId;
  final String uid;
  final VoidCallback onSuccess;

  const PlankQuestScreen({
    super.key,
    required this.targetSeconds,
    required this.expReward,
    required this.questId,
    required this.uid,
    required this.onSuccess,
  });

  @override
  State<PlankQuestScreen> createState() => _PlankQuestScreenState();
}

class _PlankQuestScreenState extends State<PlankQuestScreen> {
  int plankTimeLeft = 0;
  Timer? mainTimer;
  bool isStarted = false;
  bool isCompleted = false;
  String _currentLang = 'id';

  @override
  void initState() {
    super.initState();
    plankTimeLeft = widget.targetSeconds;
    _currentLang = LanguageService.getCurrentLanguage();
  }

  void startPlank() {
    setState(() => isStarted = true);
    mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (plankTimeLeft > 0) {
        setState(() {
          plankTimeLeft--;
        });
      } else {
        timer.cancel();
        _onPlankComplete();
      }
    });
  }

  void _onPlankComplete() async {
    setState(() => isCompleted = true);

    // Save progress
    await QuestGenerationService.updateQuestProgress(
      uid: widget.uid,
      questId: widget.questId,
      currentProgress: widget.targetSeconds,
      isCompleted: true,
    );

    // Add to EXP history
    await QuestGenerationService.addExpToHistory(
      uid: widget.uid,
      amount: widget.expReward,
      source: 'Plank Quest',
    );

    // Add to quest history
    await QuestGenerationService.addQuestToHistory(
      uid: widget.uid,
      questId: widget.questId,
      questName: 'Plank ${widget.targetSeconds}s',
      expReward: widget.expReward,
      exerciseType: 'plank',
    );

    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'QUEST SELESAI!' : 'QUEST COMPLETE!',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLang == 'id'
                  ? 'Kamu berhasil bertahan ${widget.targetSeconds} detik!'
                  : 'You survived ${widget.targetSeconds} seconds!',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    '+${widget.expReward} EXP',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(_currentLang == 'id' ? 'OK' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mainTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Quest Plank' : 'Plank Quest',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentLang == 'id' ? 'TETAPKAN POSISI PLANK' : 'HOLD PLANK POSITION',
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              '${plankTimeLeft}s',
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 40),
            if (!isStarted)
              ElevatedButton(
                onPressed: startPlank,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentLang == 'id' ? 'MULAI' : 'START',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (!isCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      _currentLang == 'id' ? 'Tahan plank...' : 'Hold plank...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
