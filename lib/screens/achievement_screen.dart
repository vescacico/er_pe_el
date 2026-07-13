import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../services/language_service.dart';

/// Screen untuk menampilkan achievements/badges
class AchievementScreen extends StatefulWidget {
  final String uid;
  final int userLevel;
  final int userExp;
  final int userStreak;
  final int questsCompleted;
  final int friendsCount;
  final int walkingQuests;
  final int hydrationQuests;
  final int exerciseQuests;

  const AchievementScreen({
    super.key,
    required this.uid,
    required this.userLevel,
    required this.userExp,
    required this.userStreak,
    required this.questsCompleted,
    required this.friendsCount,
    required this.walkingQuests,
    required this.hydrationQuests,
    required this.exerciseQuests,
  });

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserAchievements _userAchievements;
  bool _isLoading = true;
  String _currentLang = 'id';

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _tabController = TabController(
      length: AchievementCategory.values.length + 1,
      vsync: this,
    );
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      _userAchievements =
          await AchievementService.getUserAchievements(widget.uid);
      setState(() => _isLoading = false);
    } catch (e) {
      _userAchievements = UserAchievements(uid: widget.uid);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    final unlockedCount =
        AchievementDatabase.achievements.where((a) => _userAchievements.isUnlocked(a.id)).length;
    final totalCount = AchievementDatabase.achievements.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Achievement' : 'Achievements',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.2),
                  Colors.black,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$unlockedCount / $totalCount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentLang == 'id'
                      ? 'Achievement terbuka'
                      : 'Achievements unlocked',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: unlockedCount / totalCount,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            color: const Color(0xFF111111),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF10B981),
              labelColor: const Color(0xFF10B981),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.all_inclusive, size: 18),
                      const SizedBox(width: 8),
                      Text(_currentLang == 'id' ? 'Semua' : 'All'),
                    ],
                  ),
                ),
                ...AchievementCategory.values.map((category) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.getIcon(), size: 18),
                        const SizedBox(width: 8),
                        Text(category.getNameId()),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Achievement List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All tab
                _buildAchievementList(AchievementDatabase.achievements),
                // Category tabs
                ...AchievementCategory.values.map((category) {
                  return _buildAchievementList(
                    AchievementDatabase.getAchievementsByCategory(category),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList(List<Achievement> achievements) {
    // Sort: unlocked first, then locked
    final sorted = List<Achievement>.from(achievements)
      ..sort((a, b) {
        final aUnlocked = _userAchievements.isUnlocked(a.id);
        final bUnlocked = _userAchievements.isUnlocked(b.id);
        if (aUnlocked && !bUnlocked) return -1;
        if (!aUnlocked && bUnlocked) return 1;
        return a.requiredValue.compareTo(b.requiredValue);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final achievement = sorted[index];
        final isUnlocked = _userAchievements.isUnlocked(achievement.id);
        final progress = AchievementService.getProgressPercentage(
          achievement: achievement,
          questsCompleted: widget.questsCompleted,
          streakDays: widget.userStreak,
          totalExp: widget.userExp,
          level: widget.userLevel,
          friendsCount: widget.friendsCount,
          walkingQuestsCompleted: widget.walkingQuests,
          hydrationQuestsCompleted: widget.hydrationQuests,
          exerciseQuestsCompleted: widget.exerciseQuests,
        );

        return _buildAchievementCard(achievement, isUnlocked, progress);
      },
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool isUnlocked,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: achievement.color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAchievementDetail(achievement, isUnlocked, progress),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? achievement.color.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? achievement.color
                          : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isUnlocked ? achievement.icon : Icons.lock,
                    color: isUnlocked ? achievement.color : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.getName(_currentLang),
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.getDescription(_currentLang),
                        style: TextStyle(
                          color: isUnlocked
                              ? Colors.white70
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            color: achievement.color.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentLang == 'id'
                              ? '${(progress * 100).toInt()}% selesai'
                              : '${(progress * 100).toInt()}% complete',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // EXP Reward
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.expReward}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(
    Achievement achievement,
    bool isUnlocked,
    double progress,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked
                      ? achievement.color
                      : Colors.grey.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: achievement.color.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isUnlocked ? achievement.icon : Icons.lock,
                color: isUnlocked ? achievement.color : Colors.grey,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              achievement.getName(_currentLang),
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: achievement.category.getIcon() == Icons.local_fire_department
                    ? Colors.orange.withOpacity(0.2)
                    : achievement.category.getIcon() == Icons.trending_up
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    achievement.category.getIcon(),
                    color: achievement.color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    achievement.category.getNameId(),
                    style: TextStyle(
                      color: achievement.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              achievement.getDescription(_currentLang),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Status
            if (isUnlocked) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentLang == 'id' ? 'Sudah terbuka!' : 'Unlocked!',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Progress
              Text(
                _currentLang == 'id' ? 'Kemajuan' : 'Progress',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: achievement.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: achievement.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // EXP Reward
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.expReward} EXP',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentLang == 'id' ? 'Tutup' : 'Close',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
