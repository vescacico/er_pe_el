import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/exercise_database.dart';
import '../services/language_service.dart';
import 'exercise_detail_screen.dart';
import 'exercise_quest_screen.dart';

class QuestListScreen extends StatefulWidget {
  final String uid;
  final void Function(int) addExp;
  final VoidCallback refreshHome;
  final bool isSickModeActive; // Pass sick mode status from parent

  const QuestListScreen({
    super.key,
    required this.uid,
    required this.addExp,
    required this.refreshHome,
    this.isSickModeActive = false,
  });

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _langCode => LanguageService.getCurrentLanguage();
  String _searchQuery = '';

  // Exercise quests dengan metadata lengkap
  final List<Map<String, dynamic>> _exerciseQuests = [
    // ==================== CHEST EXERCISES ====================
    // CHEST - Beginner
    {'exercise_id': 'push_up', 'sets': 3, 'reps': 12, 'rest': 30, 'exp': 30, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'chest'},
    {'exercise_id': 'wide_push_up', 'sets': 3, 'reps': 10, 'rest': 30, 'exp': 30, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'chest'},
    {'exercise_id': 'incline_push_up', 'sets': 3, 'reps': 12, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'chest'},
    // CHEST - Intermediate
    {'exercise_id': 'diamond_push_up', 'sets': 3, 'reps': 8, 'rest': 45, 'exp': 35, 'time_limit': 210,
     'is_static': false, 'requires_gym': false, 'category': 'chest'},

    // ==================== CORE EXERCISES ====================
    // Core - Static (hold-based)
    {'exercise_id': 'plank', 'sets': 1, 'reps': 60, 'rest': 15, 'exp': 40, 'time_limit': 90,
     'is_static': true, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'side_plank', 'sets': 2, 'reps': 30, 'rest': 20, 'exp': 25, 'time_limit': 120,
     'is_static': true, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'wall_sit', 'sets': 3, 'reps': 45, 'rest': 30, 'exp': 20, 'time_limit': 120,
     'is_static': true, 'requires_gym': false, 'category': 'legs'},
    // Core - Rep-based
    {'exercise_id': 'sit_up', 'sets': 3, 'reps': 15, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'crunch', 'sets': 3, 'reps': 20, 'rest': 30, 'exp': 20, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'leg_raise', 'sets': 3, 'reps': 12, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'russian_twist', 'sets': 3, 'reps': 20, 'rest': 30, 'exp': 20, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'bicycle_crunch', 'sets': 3, 'reps': 20, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'flutter_kick', 'sets': 3, 'reps': 30, 'rest': 30, 'exp': 20, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'core'},
    {'exercise_id': 'v_up', 'sets': 3, 'reps': 10, 'rest': 45, 'exp': 30, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'core'},

    // ==================== LEG EXERCISES ====================
    // Legs - Rep-based (dengan format waktu)
    {'exercise_id': 'squat', 'sets': 3, 'reps': 15, 'rest': 30, 'exp': 25, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'legs'},
    {'exercise_id': 'lunge', 'sets': 2, 'reps': 12, 'rest': 30, 'exp': 20, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'legs'},
    {'exercise_id': 'calf_raise', 'sets': 3, 'reps': 20, 'rest': 20, 'exp': 15, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'legs'},
    {'exercise_id': 'glute_bridge', 'sets': 3, 'reps': 15, 'rest': 30, 'exp': 20, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'legs'},
    // Legs - Advanced (explosive)
    {'exercise_id': 'squat_jump', 'sets': 3, 'reps': 10, 'rest': 60, 'exp': 35, 'time_limit': 240,
     'is_static': false, 'requires_gym': false, 'category': 'legs'},

    // ==================== CARDIO EXERCISES ====================
    {'exercise_id': 'jumping_jack', 'sets': 3, 'reps': 30, 'rest': 20, 'exp': 15, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'cardio'},
    {'exercise_id': 'high_knees', 'sets': 3, 'reps': 30, 'rest': 30, 'exp': 20, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'cardio'},
    {'exercise_id': 'mountain_climber', 'sets': 3, 'reps': 20, 'rest': 30, 'exp': 25, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'cardio'},
    {'exercise_id': 'burpee', 'sets': 3, 'reps': 8, 'rest': 60, 'exp': 40, 'time_limit': 300,
     'is_static': false, 'requires_gym': false, 'category': 'cardio'},

    // ==================== BACK EXERCISES ====================
    {'exercise_id': 'superman', 'sets': 3, 'reps': 10, 'rest': 20, 'exp': 15, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'back'},

    // ==================== ARMS EXERCISES ====================
    {'exercise_id': 'tricep_dip', 'sets': 3, 'reps': 10, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'arms'},

    // ==================== SHOULDER EXERCISES ====================
    {'exercise_id': 'arm_circle', 'sets': 2, 'reps': 30, 'rest': 20, 'exp': 15, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'shoulders'},
    {'exercise_id': 'front_raise', 'sets': 3, 'reps': 12, 'rest': 30, 'exp': 20, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'shoulders'},
    {'exercise_id': 'lateral_raise', 'sets': 3, 'reps': 12, 'rest': 30, 'exp': 20, 'time_limit': 120,
     'is_static': false, 'requires_gym': false, 'category': 'shoulders'},
    {'exercise_id': 'shoulder_tap', 'sets': 3, 'reps': 20, 'rest': 30, 'exp': 25, 'time_limit': 150,
     'is_static': false, 'requires_gym': false, 'category': 'shoulders'},
    {'exercise_id': 'pike_push_up', 'sets': 3, 'reps': 10, 'rest': 45, 'exp': 35, 'time_limit': 180,
     'is_static': false, 'requires_gym': false, 'category': 'shoulders'},

    // ==================== GYM EXERCISES (requires equipment) ====================
    {'exercise_id': 'bench_press', 'sets': 3, 'reps': 10, 'rest': 60, 'exp': 40, 'time_limit': 240,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
    {'exercise_id': 'deadlift', 'sets': 3, 'reps': 8, 'rest': 90, 'exp': 50, 'time_limit': 360,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
    {'exercise_id': 'lat_pulldown', 'sets': 3, 'reps': 12, 'rest': 60, 'exp': 35, 'time_limit': 240,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
    {'exercise_id': 'leg_press', 'sets': 3, 'reps': 12, 'rest': 60, 'exp': 35, 'time_limit': 240,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
    {'exercise_id': 'bicep_curl', 'sets': 3, 'reps': 12, 'rest': 45, 'exp': 25, 'time_limit': 180,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
    {'exercise_id': 'overhead_press', 'sets': 3, 'reps': 10, 'rest': 60, 'exp': 35, 'time_limit': 240,
     'is_static': false, 'requires_gym': true, 'category': 'gym'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show sick mode warning banner
    Widget? sickModeWarning;
    if (widget.isSickModeActive) {
      sickModeWarning = Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _langCode == 'id'
                    ? 'Mode Terbatas aktif - Quest telah disesuaikan dengan kondisimu'
                    : 'Limited Mode active - Quests have been adjusted to your condition',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          t('exercise_quests'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: _langCode == 'id' ? 'Semua' : 'All'),
            Tab(text: _langCode == 'id' ? 'Tanpa Alat' : 'No Equipment'),
            Tab(text: _langCode == 'id' ? 'Alat Gym' : 'Gym Equipment'),
            Tab(text: _langCode == 'id' ? 'Dada' : 'Chest'),
            Tab(text: _langCode == 'id' ? 'Perut' : 'Core'),
            Tab(text: _langCode == 'id' ? 'Kaki' : 'Legs'),
            Tab(text: _langCode == 'id' ? 'Kardio' : 'Cardio'),
            Tab(text: _langCode == 'id' ? 'Punggung' : 'Back'),
            Tab(text: _langCode == 'id' ? 'Lengan' : 'Arms'),
            Tab(text: _langCode == 'id' ? 'Bahu' : 'Shoulders'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (sickModeWarning != null) sickModeWarning,
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _langCode == 'id' ? 'Cari latihan...' : 'Search exercises...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestList('all'),
                _buildQuestList('no_equipment'),
                _buildQuestList('gym'),
                _buildQuestList('chest'),
                _buildQuestList('core'),
                _buildQuestList('legs'),
                _buildQuestList('cardio'),
                _buildQuestList('back'),
                _buildQuestList('arms'),
                _buildQuestList('shoulders'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestList(String filter) {
    List<Map<String, dynamic>> filteredQuests;

    if (filter == 'all') {
      filteredQuests = _exerciseQuests;
    } else if (filter == 'no_equipment') {
      filteredQuests = _exerciseQuests.where((quest) {
        return quest['requires_gym'] != true;
      }).toList();
    } else if (filter == 'gym') {
      filteredQuests = _exerciseQuests.where((quest) {
        return quest['requires_gym'] == true;
      }).toList();
    } else {
      filteredQuests = _exerciseQuests.where((quest) {
        return quest['category'] == filter;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredQuests = filteredQuests.where((quest) {
        final exercise = ExerciseDatabase.getExerciseById(quest['exercise_id']);
        if (exercise == null) return false;
        final nameId = exercise.nameId.toLowerCase();
        final nameEn = exercise.nameEn.toLowerCase();
        return nameId.contains(_searchQuery) || nameEn.contains(_searchQuery);
      }).toList();
    }

    if (filteredQuests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? (_langCode == 'id' ? 'Tidak ditemukan' : 'Not found')
                  : (_langCode == 'id' ? 'Tidak ada quest tersedia' : 'No quests available'),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredQuests.length,
      itemBuilder: (context, index) {
        final quest = filteredQuests[index];
        final exercise = ExerciseDatabase.getExerciseById(quest['exercise_id']);

        if (exercise == null) {
          return const SizedBox.shrink();
        }

        return _buildQuestCard(exercise, quest);
      },
    );
  }

  /// Format waktu dari detik ke string menit:detik
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${secs}s';
  }

  /// Generate deskripsi quest yang lebih informatif
  String _getQuestDescription(Map<String, dynamic> questData) {
    final isStatic = questData['is_static'] == true;
    final sets = questData['sets'];
    final reps = questData['reps'];

    if (isStatic) {
      // Static exercises: "Hold [reps] seconds × [sets] sets"
      return _langCode == 'id'
          ? 'Tahan $reps detik × $sets set\nWaktu maksimal: 3 menit'
          : 'Hold $reps seconds × $sets sets\nMax time: 3 minutes';
    } else {
      // Rep-based exercises: show sets and reps with time
      return _langCode == 'id'
          ? '$sets set × $reps repetisi\nWaktu maksimal: 3 menit'
          : '$sets sets × $reps repetitions\nMax time: 3 minutes';
    }
  }

  Widget _buildQuestCard(Exercise exercise, Map<String, dynamic> questData) {
    final categoryColor = ExerciseDatabase.getCategoryColor(exercise.category);
    final categoryName = ExerciseDatabase.getCategoryName(exercise.category, _langCode);
    final isStatic = questData['is_static'] == true;
    final requiresGym = questData['requires_gym'] == true;
    final timeLimit = questData['time_limit'] as int;
    final sets = questData['sets'] as int;
    final reps = questData['reps'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Exercise image thumbnail from musclewiki
                _buildExerciseThumbnail(exercise, categoryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.getName(_langCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (requiresGym)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fitness_center, color: Colors.purple, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _langCode == 'id' ? 'GYM' : 'GYM',
                                    style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(color: categoryColor, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDifficultyBadge(exercise.difficulty),
                          if (isStatic) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, color: Colors.blue, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    _langCode == 'id' ? 'HOLD' : 'HOLD',
                                    style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quest description with time info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: categoryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _langCode == 'id' ? 'Detail Quest' : 'Quest Details',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getQuestDescription(questData),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.repeat,
                      '$sets ${t('sets')}',
                    ),
                    if (isStatic)
                      _buildStatItem(
                        Icons.timer,
                        '${reps}s HOLD',
                      )
                    else
                      _buildStatItem(
                        Icons.fitness_center,
                        '$reps ${t('reps')}',
                      ),
                    _buildStatItem(
                      Icons.hourglass_bottom,
                      '${questData['rest']}s',
                    ),
                    _buildStatItem(
                      Icons.stars,
                      '+${questData['exp']} EXP',
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Time limit info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _langCode == 'id'
                            ? 'Waktu maksimal: 3 menit'
                            : 'Max time: 3 minutes',
                        style: const TextStyle(color: Colors.amber, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: categoryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          t('view_details'),
                          style: TextStyle(color: categoryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isSickModeActive
                            ? null  // Disable exercise when sick mode is active
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExerciseQuestScreen(
                                      uid: widget.uid,
                                      exercise: exercise,
                                      sets: sets,
                                      reps: reps,
                                      restSeconds: questData['rest'],
                                      expReward: questData['exp'],
                                      isStaticExercise: isStatic,
                                      onSuccess: () {
                                        widget.addExp(questData['exp']);
                                        widget.refreshHome();
                                      },
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isSickModeActive
                              ? Colors.grey
                              : (requiresGym ? Colors.purple : categoryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isSickModeActive) ...[
                              const Icon(Icons.lock, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              widget.isSickModeActive
                                  ? (_langCode == 'id' ? 'Mode Terbatas' : 'Limited Mode')
                                  : t('start_exercise'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
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
    );
  }

  Widget _buildExerciseThumbnail(Exercise exercise, Color categoryColor) {
    final images = ExerciseDatabase.getExerciseImages(exercise.id);

    if (images != null && images['start'] != null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: images['start']!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(exercise.icon, color: categoryColor, size: 24),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(exercise.icon, color: categoryColor, size: 24),
    );
  }

  Widget _buildStatItem(IconData icon, String value, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case 'beginner':
        color = Colors.green;
        text = t('easy');
        break;
      case 'intermediate':
        color = Colors.orange;
        text = t('medium');
        break;
      case 'advanced':
        color = Colors.red;
        text = t('hard');
        break;
      default:
        color = Colors.grey;
        text = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
