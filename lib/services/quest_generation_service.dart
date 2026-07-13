import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'user_profile_service.dart';
import 'exercise_database.dart';
import 'sick_mode_service.dart';

/// Service untuk generate quest harian berdasarkan profil pengguna (BMI & Usia)
/// Menggunakan GEMINI AI untuk rekomendasi personal
class QuestGenerationService {
  // Jangan hardcode API key di sini! Ambil dari --dart-define saat build/run:
  // flutter run --dart-define=GEMINI_API_KEY=xxxxx
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate daily quests berdasarkan profil pengguna
  /// Returns list of quests yang di-generate oleh AI
  /// Reset setiap 24 jam dari waktu registrasi user
  static Future<List<DailyQuest>> generateDailyQuests({
    required String uid,
    required UserProfileData profile,
  }) async {
    // Initialize reset time untuk user baru
    await initializeQuestResetTime(uid);

    final bmi = profile.bmi;
    final age = profile.age;
    final weight = profile.weightKg ?? 70.0;
    final height = profile.heightCm ?? 170.0;
    final bmiCategory = bmi != null ? UserProfileService.getBMICategory(bmi) : null;
    final ageCategory = age != null ? UserProfileService.getAgeCategory(age) : null;

    // Cek apakah user sedang dalam mode terbatas (sick mode)
    SickModeData? sickModeData;
    try {
      sickModeData = await SickModeService.getSickModeData(uid);
    } catch (e) {
      debugPrint('Error checking sick mode: $e');
    }

    // Check apakah perlu regenerate (quest sudah untuk hari ini) atau sudah 24 jam
    final timeUntilReset = await getTimeUntilNextReset(uid);
    final todayQuests = await getTodayQuests(uid);

    // Jika belum 24 jam dan ada quest, return quest yang ada
    if (timeUntilReset.inHours < 24 && todayQuests.isNotEmpty) {
      // Apply sick mode adjustments if needed
      if (sickModeData != null && sickModeData.isActive) {
        return _applySickModeToQuests(todayQuests, sickModeData);
      }
      return todayQuests;
    }

    // Sudah 24 jam, regenerate quest
    debugPrint('Regenerating quests - 24 hours passed');

    // Generate quest baru menggunakan AI
    try {
      final quests = await _generateQuestsWithAI(
        uid: uid,
        bmi: bmi,
        bmiCategory: bmiCategory,
        age: age,
        ageCategory: ageCategory,
        weight: weight,
        height: height,
        profile: profile,
      );

      // Update reset time ke 24 jam dari sekarang
      await updateNextQuestResetTime(uid);

      // Apply sick mode adjustments if needed
      final adjustedQuests = sickModeData != null && sickModeData.isActive
          ? _applySickModeToQuests(quests, sickModeData)
          : quests;

      // Simpan quest ke Firestore
      await saveDailyQuests(uid, adjustedQuests);

      return adjustedQuests;
    } catch (e) {
      // Fallback: generate quest default jika AI gagal
      debugPrint('AI Quest Generation failed: $e');
      final defaultQuests = _generateDefaultQuests(weight, bmiCategory, ageCategory);

      // Update reset time
      await updateNextQuestResetTime(uid);

      final adjustedQuests = sickModeData != null && sickModeData.isActive
          ? _applySickModeToQuests(defaultQuests, sickModeData)
          : defaultQuests;

      await saveDailyQuests(uid, adjustedQuests);
      return adjustedQuests;
    }
  }

  /// Apply sick mode adjustments to generated quests
  static List<DailyQuest> _applySickModeToQuests(
    List<DailyQuest> quests,
    SickModeData sickModeData,
  ) {
    if (!sickModeData.isActive || sickModeData.conditions.isEmpty) {
      return quests;
    }

    final reduction = SickModeService.calculateDifficultyReduction(sickModeData.conditions);

    return quests.map((quest) {
      // Apply adjustments based on reduction
      int newSets = (quest.sets ?? 3);
      int newTarget = quest.target;

      if (quest.type == QuestType.exercise || quest.type == QuestType.plank) {
        // Reduce sets by reduction * 0.3
        newSets = (newSets * (1 - reduction * 0.3)).round().clamp(1, 10);
        // Reduce target reps by reduction * 0.5
        newTarget = (newTarget * (1 - reduction * 0.5)).round().clamp(5, 100);
      }

      // Adjust exp reward proportionally
      int newExpReward = (quest.expReward * (1 - reduction * 0.3)).round().clamp(5, 200);

      return DailyQuest(
        id: quest.id,
        titleId: quest.titleId,
        titleEn: quest.titleEn,
        descriptionId: quest.descriptionId,
        descriptionEn: quest.descriptionEn,
        type: quest.type,
        difficulty: quest.difficulty,
        target: newTarget,
        unit: quest.unit,
        expReward: newExpReward,
        exerciseId: quest.exerciseId,
        sets: newSets,
        reps: newTarget,
        icon: quest.icon,
      );
    }).toList();
  }

  /// Generate quest menggunakan GEMINI AI
  static Future<List<DailyQuest>> _generateQuestsWithAI({
    required String uid,
    double? bmi,
    BMICategory? bmiCategory,
    int? age,
    AgeCategory? ageCategory,
    required double weight,
    required double height,
    required UserProfileData profile,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    final langCode = profile.language;
    final isIndonesian = langCode == 'id';

    // Buat prompt berdasarkan profil pengguna
    final prompt = isIndonesian
        ? _buildIndonesianPrompt(bmi, bmiCategory, age, ageCategory, weight, height, profile)
        : _buildEnglishPrompt(bmi, bmiCategory, age, ageCategory, weight, height, profile);

    final response = await model.generateContent([Content.text(prompt)]);

    // Parse response dari AI
    return _parseAIResponse(response.text ?? '', profile);
  }

  static String _buildIndonesianPrompt(
    double? bmi,
    BMICategory? bmiCategory,
    int? age,
    AgeCategory? ageCategory,
    double weight,
    double height,
    UserProfileData profile,
  ) {
    final bmiInfo = bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)' : 'BMI: Tidak tersedia';
    final ageInfo = age != null ? 'Usia: $age tahun' : 'Usia: Tidak tersedia';
    final categoryInfo = ageCategory != null ? 'Kategori Usia: $ageCategory' : '';

    return '''
Kamu adalah AI Trainer untuk aplikasi fitness FitTask. Buat 5 quest harian personal untuk pengguna ini:

Profil Pengguna:
- Nama: ${profile.displayName}
- $bmiInfo
- $ageInfo
- $categoryInfo
- Berat: ${weight}kg
- Tinggi: ${height}cm
- Level: ${profile.level}
- Rank: ${profile.rank}

BMI Categories:
- Underweight (< 18.5): Fokus gain weight dengan strength training
- Normal (18.5-25): Maintenance dan cardio
- Overweight (25-30): Fokus fat burning dan cardio
- Obese (> 30): Low impact exercises dan gradual progress

Age Categories:
- Teenager (< 18): High energy activities, fun exercises
- Young Adult (18-29): All types of exercises, high intensity ok
- Adult (30-44): Balance strength dan cardio, moderate intensity
- Middle Age (45-59): Low impact, focus flexibility dan cardio
- Senior (60+): Very gentle exercises, walking, stretching

Kebutuhan Air Harian: ${(weight * 32.5).toStringAsFixed(0)} ml

Buat 5 quest harian dalam format JSON seperti ini:
[
  {
    "id": "quest_1",
    "title_id": "Quest Nama Bahasa Indonesia",
    "title_en": "Quest Name English",
    "description_id": "Deskripsi dalam Bahasa Indonesia",
    "description_en": "Description in English",
    "type": "exercise|walk|water|plank",
    "difficulty": "easy|medium|hard",
    "target": 5000,
    "unit": "steps|ml|seconds|reps",
    "exp_reward": 50,
    "exercise_id": "push_up|null",
    "sets": 3,
    "reps": 10
  }
]

Rules:
1. Exercise quests harus berdasarkan BMI dan usia
2. Walking target berdasarkan level (5000-15000 steps)
3. Water quest berdasarkan berat badan
4. Semua quest harus achievable dalam 1 hari
5. Total EXP reward per hari: ${UserProfileService.getDailyExpLimit(profile.level)} (MAX)
6. Balance antara cardio, strength, dan hydration
7. Return hanya JSON, tidak ada teks lain
''';
  }

  static String _buildEnglishPrompt(
    double? bmi,
    BMICategory? bmiCategory,
    int? age,
    AgeCategory? ageCategory,
    double weight,
    double height,
    UserProfileData profile,
  ) {
    final bmiInfo = bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)' : 'BMI: Not available';
    final ageInfo = age != null ? 'Age: $age years' : 'Age: Not available';
    final categoryInfo = ageCategory != null ? 'Age Category: $ageCategory' : '';

    return '''
You are an AI Trainer for FitTask fitness app. Create 5 personalized daily quests for this user:

User Profile:
- Name: ${profile.displayName}
- $bmiInfo
- $ageInfo
- $categoryInfo
- Weight: ${weight}kg
- Height: ${height}cm
- Level: ${profile.level}
- Rank: ${profile.rank}

BMI Categories:
- Underweight (< 18.5): Focus on weight gain with strength training
- Normal (18.5-25): Maintenance and cardio
- Overweight (25-30): Focus on fat burning and cardio
- Obese (> 30): Low impact exercises and gradual progress

Age Categories:
- Teenager (< 18): High energy activities, fun exercises
- Young Adult (18-29): All types of exercises, high intensity ok
- Adult (30-44): Balance strength and cardio, moderate intensity
- Middle Age (45-59): Low impact, focus on flexibility and cardio
- Senior (60+): Very gentle exercises, walking, stretching

Daily Water Need: ${(weight * 32.5).toStringAsFixed(0)} ml

Create 5 daily quests in JSON format:
[
  {
    "id": "quest_1",
    "title_id": "Quest Name in Indonesian",
    "title_en": "Quest Name in English",
    "description_id": "Description in Bahasa Indonesia",
    "description_en": "Description in English",
    "type": "exercise|walk|water|plank",
    "difficulty": "easy|medium|hard",
    "target": 5000,
    "unit": "steps|ml|seconds|reps",
    "exp_reward": 50,
    "exercise_id": "push_up|null",
    "sets": 3,
    "reps": 10
  }
]

Rules:
1. Exercise quests must be based on BMI and age
2. Walking target based on level (5000-15000 steps)
3. Water quest based on body weight
4. All quests must be achievable in 1 day
5. Total EXP reward per day: ${UserProfileService.getDailyExpLimit(profile.level)} (MAX)
6. Balance between cardio, strength, and hydration
7. Return only JSON, no other text
''';
  }

  /// Parse response dari AI ke list DailyQuest
  static List<DailyQuest> _parseAIResponse(String response, UserProfileData profile) {
    try {
      // Bersihkan response dari markdown code blocks
      String cleanResponse = response.trim();
      if (cleanResponse.contains("```json")) {
        cleanResponse = cleanResponse.replaceAll(RegExp(r'```json\s*'), '');
        cleanResponse = cleanResponse.replaceAll(RegExp(r'\s*```'), '');
      } else if (cleanResponse.contains("```")) {
        cleanResponse = cleanResponse.replaceAll(RegExp(r'```\s*'), '');
        cleanResponse = cleanResponse.replaceAll(RegExp(r'\s*```'), '');
      }

      cleanResponse = cleanResponse.trim();

      // Parse JSON
      final List<dynamic> jsonList = _parseJSON(cleanResponse);
      final List<DailyQuest> quests = [];

      for (final questJson in jsonList) {
        final quest = DailyQuest.fromJSON(questJson, profile);
        quests.add(quest);
      }

      // Pastikan minimal ada 5 quest
      if (quests.length < 5) {
        quests.addAll(_generateDefaultQuests(
          profile.weightKg ?? 70,
          profile.bmi != null ? UserProfileService.getBMICategory(profile.bmi!) : null,
          profile.age != null ? UserProfileService.getAgeCategory(profile.age!) : null,
        ).take(5 - quests.length));
      }

      return quests.take(5).toList();
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return _generateDefaultQuests(
        profile.weightKg ?? 70,
        profile.bmi != null ? UserProfileService.getBMICategory(profile.bmi!) : null,
        profile.age != null ? UserProfileService.getAgeCategory(profile.age!) : null,
      );
    }
  }

  /// Parse JSON string dengan aman
  static List<dynamic> _parseJSON(String jsonString) {
    try {
      // Try to find JSON array in the response
      String cleanJson = jsonString.trim();

      // Remove markdown code blocks if present
      if (cleanJson.contains("```json")) {
        cleanJson = cleanJson.replaceAll(RegExp(r'```json\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'\s*```'), '');
      } else if (cleanJson.contains("```")) {
        cleanJson = cleanJson.replaceAll(RegExp(r'```\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'\s*```'), '');
      }

      cleanJson = cleanJson.trim();

      // Find JSON array
      int startIndex = cleanJson.indexOf('[');
      int endIndex = cleanJson.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        String jsonArray = cleanJson.substring(startIndex, endIndex + 1);
        return json.decode(jsonArray) as List<dynamic>;
      }

      return [];
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return [];
    }
  }

  /// Generate default quests jika AI gagal
  static List<DailyQuest> _generateDefaultQuests(
    double weight,
    BMICategory? bmiCategory,
    AgeCategory? ageCategory,
  ) {
    final waterNeed = (weight * 32.5).toInt();

    // Tentukan difficulty berdasarkan kategori
    String difficulty = 'medium';
    if (ageCategory == AgeCategory.senior || ageCategory == AgeCategory.middleAge) {
      difficulty = 'easy';
    } else if (ageCategory == AgeCategory.youngAdult) {
      difficulty = 'hard';
    }

    // Tentukan walking target berdasarkan difficulty
    int walkTarget = 5000;
    if (difficulty == 'medium') walkTarget = 7500;
    if (difficulty == 'hard') walkTarget = 10000;

    return [
      DailyQuest(
        id: 'daily_walk',
        titleId: 'Jalan Kaki $walkTarget Langkah',
        titleEn: 'Walk $walkTarget Steps',
        descriptionId: 'Selesaikan target langkah kaki harian untuk kesehatan jantung',
        descriptionEn: 'Complete your daily step target for heart health',
        type: QuestType.walk,
        difficulty: difficulty,
        target: walkTarget,
        unit: 'steps',
        expReward: 50,
        exerciseId: null,
        sets: null,
        reps: null,
        icon: Icons.directions_walk,
      ),
      DailyQuest(
        id: 'daily_water',
        titleId: 'Minum Air $waterNeed ml',
        titleEn: 'Drink $waterNeed ml Water',
        descriptionId: 'Penuhi kebutuhan hidrasi harian Anda',
        descriptionEn: 'Meet your daily hydration needs',
        type: QuestType.water,
        difficulty: 'easy',
        target: waterNeed,
        unit: 'ml',
        expReward: 20,
        exerciseId: null,
        sets: null,
        reps: null,
        icon: Icons.water_drop,
      ),
      DailyQuest(
        id: 'daily_plank',
        titleId: 'Plank 60 Detik',
        titleEn: 'Hold Plank for 60 Seconds',
        descriptionId: 'Latihan core yang efektif untuk stabilitas tubuh',
        descriptionEn: 'Effective core exercise for body stability',
        type: QuestType.plank,
        difficulty: difficulty,
        target: 60,
        unit: 'seconds',
        expReward: 40,
        exerciseId: 'plank',
        sets: 1,
        reps: 60,
        icon: Icons.fitness_center,
      ),
      DailyQuest(
        id: 'daily_squat',
        titleId: 'Squat Challenge',
        titleEn: 'Squat Challenge',
        descriptionId: 'Kuatkan otot kaki dan bokong dengan squat',
        descriptionEn: 'Strengthen leg and glute muscles with squats',
        type: QuestType.exercise,
        difficulty: difficulty,
        target: 30,
        unit: 'reps',
        expReward: 35,
        exerciseId: 'squat',
        sets: 3,
        reps: 10,
        icon: Icons.accessibility_new,
      ),
      DailyQuest(
        id: 'daily_cardio',
        titleId: 'Jumping Jack 50x',
        titleEn: 'Jumping Jack 50x',
        descriptionId: 'Latihan kardio untuk membakar kalori',
        descriptionEn: 'Cardio exercise to burn calories',
        type: QuestType.exercise,
        difficulty: difficulty,
        target: 50,
        unit: 'reps',
        expReward: 30,
        exerciseId: 'jumping_jack',
        sets: 2,
        reps: 25,
        icon: Icons.directions_run,
      ),
    ];
  }

  /// Get today's quests dari Firestore (berdasarkan waktu reset user)
  static Future<List<DailyQuest>> getTodayQuests(String uid) async {
    try {
      // Dapatkan waktu reset user
      final resetTime = await _getUserQuestResetTime(uid);
      final now = DateTime.now();

      // Cek apakah sudah 24 jam sejak reset terakhir
      final timeSinceReset = now.difference(resetTime);

      // Jika belum 24 jam, load quest dari document ID lama
      // Jika sudah 24 jam, load dari document ID baru
      String docId;
      if (timeSinceReset.inHours < 24) {
        // Gunakan document dengan waktu reset terakhir
        docId = _getDateKeyFromDateTime(resetTime);
      } else {
        // Sudah 24 jam, buat document baru
        docId = _getDateKeyFromDateTime(now);
      }

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_quests')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final questsData = data['quests'] as List<dynamic>? ?? [];
        return questsData.map((q) => DailyQuest.fromMap(q)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting today quests: $e');
      return [];
    }
  }

  /// Get user's quest reset time
  static Future<DateTime> _getUserQuestResetTime(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['questResetTime'] != null) {
          return (data['questResetTime'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      debugPrint('Error getting quest reset time: $e');
    }
    // Default: registration time atau jam 00:00 hari ini
    return DateTime.now();
  }

  /// Set user's quest reset time (dipanggil saat registrasi)
  static Future<void> initializeQuestResetTime(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['questResetTime'] == null) {
          // Set ke waktu sekarang + 24 jam
          final resetTime = DateTime.now().add(const Duration(hours: 24));
          await _firestore.collection('users').doc(uid).update({
            'questResetTime': Timestamp.fromDate(resetTime),
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing quest reset time: $e');
    }
  }

  /// Update next quest reset time (dipanggil setelah 24 jam)
  static Future<void> updateNextQuestResetTime(String uid) async {
    try {
      final nextReset = DateTime.now().add(const Duration(hours: 24));
      await _firestore.collection('users').doc(uid).update({
        'questResetTime': Timestamp.fromDate(nextReset),
      });
    } catch (e) {
      debugPrint('Error updating quest reset time: $e');
    }
  }

  /// Check dan regenerate quests jika sudah 24 jam
  static Future<List<DailyQuest>> checkAndRegenerateQuests({
    required String uid,
    required UserProfileData profile,
  }) async {
    try {
      final resetTime = await _getUserQuestResetTime(uid);
      final now = DateTime.now();
      final timeSinceReset = now.difference(resetTime);

      // Jika sudah 24 jam, regenerate
      if (timeSinceReset.inHours >= 24) {
        debugPrint('24 hours passed, regenerating quests...');

        // Hapus quest lama
        final oldDocId = _getDateKeyFromDateTime(resetTime.subtract(const Duration(hours: 1)));
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('daily_quests')
              .doc(oldDocId)
              .delete();
        } catch (e) {
          // Ignore delete errors
        }

        // Update reset time
        await updateNextQuestResetTime(uid);

        // Generate quest baru
        final quests = await generateDailyQuests(uid: uid, profile: profile);
        return quests;
      }

      // Belum 24 jam, load quest yang ada
      return await getTodayQuests(uid);
    } catch (e) {
      debugPrint('Error checking quest regeneration: $e');
      return [];
    }
  }

  /// Helper: Get date key string dari DateTime
  static String _getDateKeyFromDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}-${dateTime.hour.toString().padLeft(2, '0')}';
  }

  /// Helper: Get time remaining until next reset
  static Future<Duration> getTimeUntilNextReset(String uid) async {
    try {
      final resetTime = await _getUserQuestResetTime(uid);
      final now = DateTime.now();
      final remaining = resetTime.difference(now);
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return const Duration(hours: 24);
    }
  }

  /// Simpan daily quests ke Firestore
  static Future<void> saveDailyQuests(String uid, List<DailyQuest> quests) async {
    try {
      // Gunakan date key berdasarkan reset time user
      final resetTime = await _getUserQuestResetTime(uid);
      final docId = _getDateKeyFromDateTime(resetTime);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_quests')
          .doc(docId)
          .set({
        'generatedAt': FieldValue.serverTimestamp(),
        'quests': quests.map((q) => q.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving daily quests: $e');
    }
  }

  /// Get today's date string for quest progress scope
  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get quest progress untuk user (scoped per date)
  static Future<Map<String, QuestProgress>> getQuestProgress(String uid) async {
    try {
      final today = _getTodayDateString();
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quest_progress')
          .doc(today)
          .collection('quests')
          .get();

      final progress = <String, QuestProgress>{};
      for (final doc in snapshot.docs) {
        progress[doc.id] = QuestProgress.fromMap(doc.data());
      }
      return progress;
    } catch (e) {
      return {};
    }
  }

  /// Update progress quest (scoped per date)
  static Future<void> updateQuestProgress({
    required String uid,
    required String questId,
    required int currentProgress,
    required bool isCompleted,
  }) async {
    try {
      final today = _getTodayDateString();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('quest_progress')
          .doc(today)
          .collection('quests')
          .doc(questId)
          .set({
        'currentProgress': currentProgress,
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
    }
  }

  /// Get daily EXP earned today
  static Future<int> getDailyExpEarned(String uid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('exp_history')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['amount'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Add EXP to daily history
  static Future<void> addExpToHistory({
    required String uid,
    required int amount,
    required String source,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).collection('exp_history').add({
        'amount': amount,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding EXP to history: $e');
    }
  }

  /// Add quest completion to quest history
  static Future<void> addQuestToHistory({
    required String uid,
    required String questId,
    required String questName,
    required int expReward,
    required String exerciseType,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).collection('quest_history').add({
        'questId': questId,
        'questName': questName,
        'expReward': expReward,
        'exerciseType': exerciseType,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding quest to history: $e');
    }
  }

  /// Complete quest with batched writes (optimized for performance)
  static Future<void> completeQuest({
    required String uid,
    required String questId,
    required String questName,
    required int expReward,
    required String exerciseType,
    required int currentProgress,
    required String source,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add to exp history
      final expHistoryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('exp_history')
          .doc();
      batch.set(expHistoryRef, {
        'amount': expReward,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add to quest history
      final questHistoryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('quest_history')
          .doc();
      batch.set(questHistoryRef, {
        'questId': questId,
        'questName': questName,
        'expReward': expReward,
        'exerciseType': exerciseType,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update quest progress (per-date scoped)
      final today = _getTodayDateString();
      final progressRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('quest_progress')
          .doc(today)
          .collection('quests')
          .doc(questId);
      batch.set(progressRef, {
        'currentProgress': currentProgress,
        'isCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'expEarned': expReward,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error completing quest: $e');
    }
  }
}

/// Tipe Quest
enum QuestType {
  walk,
  water,
  plank,
  exercise;

  IconData getIcon() {
    switch (this) {
      case QuestType.walk:
        return Icons.directions_walk;
      case QuestType.water:
        return Icons.water_drop;
      case QuestType.plank:
        return Icons.fitness_center;
      case QuestType.exercise:
        return Icons.fitness_center;
    }
  }
}

/// Daily Quest Model
class DailyQuest {
  final String id;
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;
  final QuestType type;
  final String difficulty;
  final int target;
  final String unit;
  final int expReward;
  final String? exerciseId;
  final int? sets;
  final int? reps;
  final IconData icon;

  DailyQuest({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.type,
    required this.difficulty,
    required this.target,
    required this.unit,
    required this.expReward,
    this.exerciseId,
    this.sets,
    this.reps,
    required this.icon,
  });

  String getTitle(String langCode) => langCode == 'id' ? titleId : titleEn;
  String getDescription(String langCode) => langCode == 'id' ? descriptionId : descriptionEn;

  factory DailyQuest.fromJSON(Map<String, dynamic> json, UserProfileData profile) {
    final typeStr = json['type'] as String? ?? 'exercise';
    final exerciseId = json['exercise_id'] as String?;

    // Get icon from exercise or type
    IconData icon = Icons.fitness_center;
    if (exerciseId != null) {
      final exercise = ExerciseDatabase.getExerciseById(exerciseId);
      if (exercise != null) {
        icon = exercise.icon;
      }
    } else {
      switch (typeStr) {
        case 'walk':
          icon = Icons.directions_walk;
          break;
        case 'water':
          icon = Icons.water_drop;
          break;
        case 'plank':
          icon = Icons.timer;
          break;
      }
    }

    return DailyQuest(
      id: json['id'] as String? ?? 'quest_${DateTime.now().millisecondsSinceEpoch}',
      titleId: json['title_id'] as String? ?? 'Quest',
      titleEn: json['title_en'] as String? ?? 'Quest',
      descriptionId: json['description_id'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      type: QuestType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => QuestType.exercise,
      ),
      difficulty: json['difficulty'] as String? ?? 'medium',
      target: json['target'] as int? ?? 10,
      unit: json['unit'] as String? ?? 'reps',
      expReward: json['exp_reward'] as int? ?? 30,
      exerciseId: exerciseId,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      icon: icon,
    );
  }

  factory DailyQuest.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'exercise';
    return DailyQuest(
      id: map['id'] as String? ?? '',
      titleId: map['title_id'] as String? ?? '',
      titleEn: map['title_en'] as String? ?? '',
      descriptionId: map['description_id'] as String? ?? '',
      descriptionEn: map['description_en'] as String? ?? '',
      type: QuestType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => QuestType.exercise,
      ),
      difficulty: map['difficulty'] as String? ?? 'medium',
      target: map['target'] as int? ?? 10,
      unit: map['unit'] as String? ?? 'reps',
      expReward: map['exp_reward'] as int? ?? 30,
      exerciseId: map['exercise_id'] as String?,
      sets: map['sets'] as int?,
      reps: map['reps'] as int?,
      icon: _getIconFromString(map['icon'] as String?),
    );
  }

  static IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'water_drop':
        return Icons.water_drop;
      case 'directions_run':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  Map<String, dynamic> toMap() {
    String iconName = 'fitness_center';
    if (icon == Icons.directions_walk) iconName = 'directions_walk';
    if (icon == Icons.water_drop) iconName = 'water_drop';
    if (icon == Icons.directions_run) iconName = 'directions_run';

    return {
      'id': id,
      'title_id': titleId,
      'title_en': titleEn,
      'description_id': descriptionId,
      'description_en': descriptionEn,
      'type': type.name,
      'difficulty': difficulty,
      'target': target,
      'unit': unit,
      'exp_reward': expReward,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'icon': iconName,
    };
  }
}

/// Quest Progress Model
class QuestProgress {
  final int currentProgress;
  final bool isCompleted;
  final DateTime? updatedAt;

  QuestProgress({
    required this.currentProgress,
    required this.isCompleted,
    this.updatedAt,
  });

  factory QuestProgress.fromMap(Map<String, dynamic> map) {
    return QuestProgress(
      currentProgress: map['currentProgress'] as int? ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
