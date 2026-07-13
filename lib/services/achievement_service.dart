import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement model representing user achievements/badges
class Achievement {
  final String id;
  final String nameId;
  final String nameEn;
  final String descriptionId;
  final String descriptionEn;
  final AchievementCategory category;
  final IconData icon;
  final Color color;
  final int requiredValue;
  final AchievementCondition condition;
  final int expReward;

  const Achievement({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.category,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.condition,
    this.expReward = 100,
  });

  String getName(String langCode) => langCode == 'id' ? nameId : nameEn;
  String getDescription(String langCode) =>
      langCode == 'id' ? descriptionId : descriptionEn;
}

/// Categories of achievements
enum AchievementCategory {
  quest,
  streak,
  level,
  social,
  special,
}

extension AchievementCategoryExtension on AchievementCategory {
  String getNameId() {
    switch (this) {
      case AchievementCategory.quest:
        return 'Quest';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.level:
        return 'Level';
      case AchievementCategory.social:
        return 'Sosial';
      case AchievementCategory.special:
        return 'Spesial';
    }
  }

  String getNameEn() {
    switch (this) {
      case AchievementCategory.quest:
        return 'Quest';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.level:
        return 'Level';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  IconData getIcon() {
    switch (this) {
      case AchievementCategory.quest:
        return Icons.flag;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.level:
        return Icons.trending_up;
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.special:
        return Icons.star;
    }
  }
}

/// Condition types for achievements
enum AchievementCondition {
  questsCompleted,
  streakDays,
  totalExp,
  levelReached,
  friendsCount,
  dailyQuestsCompleted,
  walkingQuestsCompleted,
  hydrationQuestsCompleted,
  exerciseQuestsCompleted,
  perfectStreak,
  earlyBird,
  nightOwl,
  firstQuest,
  firstFriend,
}

/// Database of all achievements
class AchievementDatabase {
  static const List<Achievement> achievements = [
    // ========== QUEST ACHIEVEMENTS ==========
    Achievement(
      id: 'first_quest',
      nameId: 'Quest Pertama',
      nameEn: 'First Quest',
      descriptionId: 'Selesaikan quest pertamamu',
      descriptionEn: 'Complete your first quest',
      category: AchievementCategory.quest,
      icon: Icons.flag,
      color: Color(0xFF10B981),
      requiredValue: 1,
      condition: AchievementCondition.firstQuest,
      expReward: 50,
    ),
    Achievement(
      id: 'quest_10',
      nameId: 'Hunter Pemula',
      nameEn: 'Novice Hunter',
      descriptionId: 'Selesaikan 10 quest',
      descriptionEn: 'Complete 10 quests',
      category: AchievementCategory.quest,
      icon: Icons.flag,
      color: Color(0xFF10B981),
      requiredValue: 10,
      condition: AchievementCondition.questsCompleted,
      expReward: 100,
    ),
    Achievement(
      id: 'quest_50',
      nameId: 'Hunter Aktif',
      nameEn: 'Active Hunter',
      descriptionId: 'Selesaikan 50 quest',
      descriptionEn: 'Complete 50 quests',
      category: AchievementCategory.quest,
      icon: Icons.flag,
      color: Color(0xFF3B82F6),
      requiredValue: 50,
      condition: AchievementCondition.questsCompleted,
      expReward: 250,
    ),
    Achievement(
      id: 'quest_100',
      nameId: 'Hunter Sejati',
      nameEn: 'True Hunter',
      descriptionId: 'Selesaikan 100 quest',
      descriptionEn: 'Complete 100 quests',
      category: AchievementCategory.quest,
      icon: Icons.military_tech,
      color: Color(0xFF8B5CF6),
      requiredValue: 100,
      condition: AchievementCondition.questsCompleted,
      expReward: 500,
    ),
    Achievement(
      id: 'quest_500',
      nameId: 'Legendary Hunter',
      nameEn: 'Legendary Hunter',
      descriptionId: 'Selesaikan 500 quest',
      descriptionEn: 'Complete 500 quests',
      category: AchievementCategory.quest,
      icon: Icons.emoji_events,
      color: Color(0xFFFBBF24),
      requiredValue: 500,
      condition: AchievementCondition.questsCompleted,
      expReward: 1000,
    ),

    // ========== WALKING QUEST ACHIEVEMENTS ==========
    Achievement(
      id: 'walk_10k',
      nameId: 'Pehatan 10K',
      nameEn: '10K Walker',
      descriptionId: 'Selesaikan walking quest pertama',
      descriptionEn: 'Complete your first walking quest',
      category: AchievementCategory.quest,
      icon: Icons.directions_walk,
      color: Color(0xFF3B82F6),
      requiredValue: 1,
      condition: AchievementCondition.walkingQuestsCompleted,
      expReward: 50,
    ),
    Achievement(
      id: 'walk_master',
      nameId: 'Master Pejalan',
      nameEn: 'Walking Master',
      descriptionId: 'Selesaikan 50 walking quest',
      descriptionEn: 'Complete 50 walking quests',
      category: AchievementCategory.quest,
      icon: Icons.directions_walk,
      color: Color(0xFF1E88E5),
      requiredValue: 50,
      condition: AchievementCondition.walkingQuestsCompleted,
      expReward: 300,
    ),

    // ========== HYDRATION QUEST ACHIEVEMENTS ==========
    Achievement(
      id: 'hydration_first',
      nameId: 'Pecinta Air',
      nameEn: 'Water Lover',
      descriptionId: 'Selesaikan quest hidrasi pertama',
      descriptionEn: 'Complete your first hydration quest',
      category: AchievementCategory.quest,
      icon: Icons.water_drop,
      color: Color(0xFF06B6D4),
      requiredValue: 1,
      condition: AchievementCondition.hydrationQuestsCompleted,
      expReward: 50,
    ),
    Achievement(
      id: 'hydration_master',
      nameId: 'Ahli Hidrasi',
      nameEn: 'Hydration Expert',
      descriptionId: 'Selesaikan 30 quest hidrasi',
      descriptionEn: 'Complete 30 hydration quests',
      category: AchievementCategory.quest,
      icon: Icons.water_drop,
      color: Color(0xFF0891B2),
      requiredValue: 30,
      condition: AchievementCondition.hydrationQuestsCompleted,
      expReward: 200,
    ),

    // ========== EXERCISE QUEST ACHIEVEMENTS ==========
    Achievement(
      id: 'exercise_first',
      nameId: 'Atlit Pemula',
      nameEn: 'Novice Athlete',
      descriptionId: 'Selesaikan exercise quest pertama',
      descriptionEn: 'Complete your first exercise quest',
      category: AchievementCategory.quest,
      icon: Icons.fitness_center,
      color: Color(0xFFF97316),
      requiredValue: 1,
      condition: AchievementCondition.exerciseQuestsCompleted,
      expReward: 50,
    ),
    Achievement(
      id: 'exercise_warrior',
      nameId: 'Guerreiro Latihan',
      nameEn: 'Exercise Warrior',
      descriptionId: 'Selesaikan 50 exercise quest',
      descriptionEn: 'Complete 50 exercise quests',
      category: AchievementCategory.quest,
      icon: Icons.fitness_center,
      color: Color(0xFFEA580C),
      requiredValue: 50,
      condition: AchievementCondition.exerciseQuestsCompleted,
      expReward: 300,
    ),
    Achievement(
      id: 'exercise_champion',
      nameId: 'Juara Latihan',
      nameEn: 'Exercise Champion',
      descriptionId: 'Selesaikan 100 exercise quest',
      descriptionEn: 'Complete 100 exercise quests',
      category: AchievementCategory.quest,
      icon: Icons.emoji_events,
      color: Color(0xFFDC2626),
      requiredValue: 100,
      condition: AchievementCondition.exerciseQuestsCompleted,
      expReward: 500,
    ),

    // ========== STREAK ACHIEVEMENTS ==========
    Achievement(
      id: 'streak_3',
      nameId: '3 Hari Beruntun',
      nameEn: '3 Day Streak',
      descriptionId: '3 hari login dan quest beruntun',
      descriptionEn: '3 consecutive days of login and quest completion',
      category: AchievementCategory.streak,
      icon: Icons.local_fire_department,
      color: Color(0xFFF97316),
      requiredValue: 3,
      condition: AchievementCondition.streakDays,
      expReward: 75,
    ),
    Achievement(
      id: 'streak_7',
      nameId: 'Mingguan',
      nameEn: 'Weekly Warrior',
      descriptionId: '7 hari login beruntun',
      descriptionEn: '7 consecutive days of login',
      category: AchievementCategory.streak,
      icon: Icons.local_fire_department,
      color: Color(0xFFEA580C),
      requiredValue: 7,
      condition: AchievementCondition.streakDays,
      expReward: 150,
    ),
    Achievement(
      id: 'streak_14',
      nameId: 'Dua Minggu',
      nameEn: 'Fortnight Fighter',
      descriptionId: '14 hari login beruntun',
      descriptionEn: '14 consecutive days of login',
      category: AchievementCategory.streak,
      icon: Icons.local_fire_department,
      color: Color(0xFFDC2626),
      requiredValue: 14,
      condition: AchievementCondition.streakDays,
      expReward: 300,
    ),
    Achievement(
      id: 'streak_30',
      nameId: 'Bulanan',
      nameEn: 'Monthly Master',
      descriptionId: '30 hari login beruntun',
      descriptionEn: '30 consecutive days of login',
      category: AchievementCategory.streak,
      icon: Icons.local_fire_department,
      color: Color(0xFFB91C1C),
      requiredValue: 30,
      condition: AchievementCondition.streakDays,
      expReward: 750,
    ),
    Achievement(
      id: 'streak_100',
      nameId: 'Tak Terbendung',
      nameEn: 'Unstoppable',
      descriptionId: '100 hari login beruntun',
      descriptionEn: '100 consecutive days of login',
      category: AchievementCategory.streak,
      icon: Icons.local_fire_department,
      color: Color(0xFFFBBF24),
      requiredValue: 100,
      condition: AchievementCondition.streakDays,
      expReward: 2000,
    ),

    // ========== LEVEL ACHIEVEMENTS ==========
    Achievement(
      id: 'level_5',
      nameId: 'Level 5',
      nameEn: 'Level 5',
      descriptionId: 'Capai Level 5',
      descriptionEn: 'Reach Level 5',
      category: AchievementCategory.level,
      icon: Icons.trending_up,
      color: Color(0xFF10B981),
      requiredValue: 5,
      condition: AchievementCondition.levelReached,
      expReward: 100,
    ),
    Achievement(
      id: 'level_10',
      nameId: 'Level 10',
      nameEn: 'Level 10',
      descriptionId: 'Capai Level 10',
      descriptionEn: 'Reach Level 10',
      category: AchievementCategory.level,
      icon: Icons.trending_up,
      color: Color(0xFF3B82F6),
      requiredValue: 10,
      condition: AchievementCondition.levelReached,
      expReward: 200,
    ),
    Achievement(
      id: 'level_25',
      nameId: 'Level 25',
      nameEn: 'Level 25',
      descriptionId: 'Capai Level 25',
      descriptionEn: 'Reach Level 25',
      category: AchievementCategory.level,
      icon: Icons.trending_up,
      color: Color(0xFF8B5CF6),
      requiredValue: 25,
      condition: AchievementCondition.levelReached,
      expReward: 500,
    ),
    Achievement(
      id: 'level_50',
      nameId: 'Level 50',
      nameEn: 'Level 50',
      descriptionId: 'Capai Level 50',
      descriptionEn: 'Reach Level 50',
      category: AchievementCategory.level,
      icon: Icons.trending_up,
      color: Color(0xFFF97316),
      requiredValue: 50,
      condition: AchievementCondition.levelReached,
      expReward: 1000,
    ),
    Achievement(
      id: 'level_100',
      nameId: 'Level 100',
      nameEn: 'Level 100',
      descriptionId: 'Capai Level 100',
      descriptionEn: 'Reach Level 100',
      category: AchievementCategory.level,
      icon: Icons.trending_up,
      color: Color(0xFFFBBF24),
      requiredValue: 100,
      condition: AchievementCondition.levelReached,
      expReward: 2500,
    ),

    // ========== EXP ACHIEVEMENTS ==========
    Achievement(
      id: 'exp_1000',
      nameId: 'EXP 1K',
      nameEn: '1K EXP',
      descriptionId: 'Kumpulkan 1,000 total EXP',
      descriptionEn: 'Collect 1,000 total EXP',
      category: AchievementCategory.level,
      icon: Icons.stars,
      color: Color(0xFF10B981),
      requiredValue: 1000,
      condition: AchievementCondition.totalExp,
      expReward: 100,
    ),
    Achievement(
      id: 'exp_10000',
      nameId: 'EXP 10K',
      nameEn: '10K EXP',
      descriptionId: 'Kumpulkan 10,000 total EXP',
      descriptionEn: 'Collect 10,000 total EXP',
      category: AchievementCategory.level,
      icon: Icons.stars,
      color: Color(0xFF3B82F6),
      requiredValue: 10000,
      condition: AchievementCondition.totalExp,
      expReward: 500,
    ),
    Achievement(
      id: 'exp_50000',
      nameId: 'EXP 50K',
      nameEn: '50K EXP',
      descriptionId: 'Kumpulkan 50,000 total EXP',
      descriptionEn: 'Collect 50,000 total EXP',
      category: AchievementCategory.level,
      icon: Icons.stars,
      color: Color(0xFF8B5CF6),
      requiredValue: 50000,
      condition: AchievementCondition.totalExp,
      expReward: 1500,
    ),

    // ========== SOCIAL ACHIEVEMENTS ==========
    Achievement(
      id: 'first_friend',
      nameId: 'Teman Pertama',
      nameEn: 'First Friend',
      descriptionId: 'Tambahkan teman pertamamu',
      descriptionEn: 'Add your first friend',
      category: AchievementCategory.social,
      icon: Icons.person_add,
      color: Color(0xFFEC4899),
      requiredValue: 1,
      condition: AchievementCondition.friendsCount,
      expReward: 50,
    ),
    Achievement(
      id: 'friend_group',
      nameId: 'Grup Hunter',
      nameEn: 'Hunter Group',
      descriptionId: 'Punya 5 teman',
      descriptionEn: 'Have 5 friends',
      category: AchievementCategory.social,
      icon: Icons.group,
      color: Color(0xFFDB2777),
      requiredValue: 5,
      condition: AchievementCondition.friendsCount,
      expReward: 200,
    ),
    Achievement(
      id: 'social_butterfly',
      nameId: 'Kupu-Kupu Sosial',
      nameEn: 'Social Butterfly',
      descriptionId: 'Punya 20 teman',
      descriptionEn: 'Have 20 friends',
      category: AchievementCategory.social,
      icon: Icons.groups,
      color: Color(0xFFBE185D),
      requiredValue: 20,
      condition: AchievementCondition.friendsCount,
      expReward: 500,
    ),

    // ========== SPECIAL ACHIEVEMENTS ==========
    Achievement(
      id: 'early_bird',
      nameId: 'Si Rajin',
      nameEn: 'Early Bird',
      descriptionId: 'Selesaikan quest sebelum jam 9 pagi',
      descriptionEn: 'Complete a quest before 9 AM',
      category: AchievementCategory.special,
      icon: Icons.wb_sunny,
      color: Color(0xFFFBBF24),
      requiredValue: 1,
      condition: AchievementCondition.earlyBird,
      expReward: 75,
    ),
    Achievement(
      id: 'night_owl',
      nameId: 'Si Pemburu Malam',
      nameEn: 'Night Owl',
      descriptionId: 'Selesaikan quest setelah jam 10 malam',
      descriptionEn: 'Complete a quest after 10 PM',
      category: AchievementCategory.special,
      icon: Icons.nightlight,
      color: Color(0xFF6366F1),
      requiredValue: 1,
      condition: AchievementCondition.nightOwl,
      expReward: 75,
    ),
  ];

  static List<Achievement> getAllAchievements() => achievements;

  static List<Achievement> getAchievementsByCategory(
      AchievementCategory category) {
    return achievements.where((a) => a.category == category).toList();
  }

  static Achievement? getAchievementById(String id) {
    try {
      return achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<AchievementCategory> getCategories() {
    return AchievementCategory.values;
  }
}

/// User's unlocked achievements
class UserAchievements {
  final String uid;
  final Set<String> unlockedIds;
  final DateTime? lastChecked;

  UserAchievements({
    required this.uid,
    Set<String>? unlockedIds,
    this.lastChecked,
  }) : unlockedIds = unlockedIds ?? {};

  Map<String, dynamic> toMap() {
    return {
      'unlockedIds': unlockedIds.toList(),
      'lastChecked': lastChecked?.toIso8601String(),
    };
  }

  factory UserAchievements.fromMap(String uid, Map<String, dynamic> map) {
    return UserAchievements(
      uid: uid,
      unlockedIds: Set<String>.from(map['unlockedIds'] ?? []),
      lastChecked: map['lastChecked'] != null
          ? DateTime.parse(map['lastChecked'])
          : null,
    );
  }

  bool isUnlocked(String achievementId) => unlockedIds.contains(achievementId);
}

/// Service untuk mengelola achievements
class AchievementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's achievements from Firestore
  static Future<UserAchievements> getUserAchievements(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc('progress')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserAchievements.fromMap(uid, doc.data()!);
      }
      return UserAchievements(uid: uid);
    } catch (e) {
      return UserAchievements(uid: uid);
    }
  }

  /// Check and unlock new achievements based on user stats
  static Future<List<Achievement>> checkAndUnlockAchievements({
    required String uid,
    required int questsCompleted,
    required int streakDays,
    required int totalExp,
    required int level,
    required int friendsCount,
    required int walkingQuestsCompleted,
    required int hydrationQuestsCompleted,
    required int exerciseQuestsCompleted,
    DateTime? questCompletedAt,
  }) async {
    final userAchievements = await getUserAchievements(uid);
    final newlyUnlocked = <Achievement>[];

    for (final achievement in AchievementDatabase.achievements) {
      // Skip if already unlocked
      if (userAchievements.isUnlocked(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.condition) {
        case AchievementCondition.questsCompleted:
          shouldUnlock = questsCompleted >= achievement.requiredValue;
          break;
        case AchievementCondition.streakDays:
          shouldUnlock = streakDays >= achievement.requiredValue;
          break;
        case AchievementCondition.totalExp:
          shouldUnlock = totalExp >= achievement.requiredValue;
          break;
        case AchievementCondition.levelReached:
          shouldUnlock = level >= achievement.requiredValue;
          break;
        case AchievementCondition.friendsCount:
          shouldUnlock = friendsCount >= achievement.requiredValue;
          break;
        case AchievementCondition.walkingQuestsCompleted:
          shouldUnlock = walkingQuestsCompleted >= achievement.requiredValue;
          break;
        case AchievementCondition.hydrationQuestsCompleted:
          shouldUnlock = hydrationQuestsCompleted >= achievement.requiredValue;
          break;
        case AchievementCondition.exerciseQuestsCompleted:
          shouldUnlock = exerciseQuestsCompleted >= achievement.requiredValue;
          break;
        case AchievementCondition.firstQuest:
          shouldUnlock = questsCompleted >= 1;
          break;
        case AchievementCondition.earlyBird:
          if (questCompletedAt != null) {
            shouldUnlock = questCompletedAt.hour < 9;
          }
          break;
        case AchievementCondition.nightOwl:
          if (questCompletedAt != null) {
            shouldUnlock = questCompletedAt.hour >= 22;
          }
          break;
        default:
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(uid, achievement.id);
        newlyUnlocked.add(achievement);

        // Award EXP for achievement
        if (achievement.expReward > 0) {
          await _awardExp(uid, achievement.expReward);
        }
      }
    }

    return newlyUnlocked;
  }

  static Future<void> _unlockAchievement(
      String uid, String achievementId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc('progress')
          .set({
        'unlockedIds': FieldValue.arrayUnion([achievementId]),
        'lastChecked': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> _awardExp(String uid, int amount) async {
    try {
      // Get current user stats
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      int currentExp = data['currentExp'] ?? 0;
      int totalExp = data['totalExp'] ?? 0;
      int level = data['level'] ?? 1;
      int expToNext = data['expToNextLevel'] ?? 100;

      // Add EXP
      currentExp += amount;
      totalExp += amount;

      // Check for level up
      while (currentExp >= expToNext) {
        level++;
        currentExp -= expToNext;
        expToNext = (expToNext * 1.5).toInt();
      }

      // Update user
      await _firestore.collection('users').doc(uid).update({
        'currentExp': currentExp,
        'totalExp': totalExp,
        'level': level,
        'expToNextLevel': expToNext,
      });
    } catch (e) {
      // Ignore
    }
  }

  /// Get progress percentage for an achievement
  static double getProgressPercentage({
    required Achievement achievement,
    required int questsCompleted,
    required int streakDays,
    required int totalExp,
    required int level,
    required int friendsCount,
    required int walkingQuestsCompleted,
    required int hydrationQuestsCompleted,
    required int exerciseQuestsCompleted,
  }) {
    int currentValue = 0;

    switch (achievement.condition) {
      case AchievementCondition.questsCompleted:
        currentValue = questsCompleted;
        break;
      case AchievementCondition.streakDays:
        currentValue = streakDays;
        break;
      case AchievementCondition.totalExp:
        currentValue = totalExp;
        break;
      case AchievementCondition.levelReached:
        currentValue = level;
        break;
      case AchievementCondition.friendsCount:
        currentValue = friendsCount;
        break;
      case AchievementCondition.walkingQuestsCompleted:
        currentValue = walkingQuestsCompleted;
        break;
      case AchievementCondition.hydrationQuestsCompleted:
        currentValue = hydrationQuestsCompleted;
        break;
      case AchievementCondition.exerciseQuestsCompleted:
        currentValue = exerciseQuestsCompleted;
        break;
      case AchievementCondition.firstQuest:
        currentValue = questsCompleted > 0 ? 1 : 0;
        break;
      default:
        return 0.0;
    }

    return (currentValue / achievement.requiredValue).clamp(0.0, 1.0);
  }
}
