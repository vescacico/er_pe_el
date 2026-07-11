import 'package:flutter/material.dart';
import '../services/exercise_database.dart';
import '../services/language_service.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.getCurrentLanguage();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          exercise.getName(langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    exercise.color.withOpacity(0.3),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: exercise.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: exercise.color,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      exercise.icon,
                      size: 60,
                      color: exercise.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    exercise.getName(langCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildDifficultyBadge(langCode),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    exercise.getDescription(langCode),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Starting & Ending Position
                  Text(
                    t('starting_position'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: exercise.color.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.accessibility_new,
                            size: 40,
                            color: exercise.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getStartingInstruction(langCode),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Arrow
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    t('ending_position'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: exercise.color.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 40,
                            color: exercise.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getEndingInstruction(langCode),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Target Muscles
                  Text(
                    t('target_muscles'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: exercise.getTargetMuscles(langCode).map((muscle) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: exercise.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: exercise.color.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          muscle,
                          style: TextStyle(
                            color: exercise.color,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Secondary Muscles
                  if (exercise.getSecondaryMuscles(langCode).isNotEmpty) ...[
                    Text(
                      t('secondary_muscles'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.getSecondaryMuscles(langCode).map((muscle) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            muscle,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Equipment
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${t('equipment')}: ',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        exercise.equipment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Text(
                    t('instructions'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...exercise.getInstructions(langCode).asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: exercise.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  color: exercise.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Tips
                  Text(
                    t('tips'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: exercise.getTips(langCode).map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String langCode) {
    String difficulty;
    Color color;

    switch (exercise.difficulty) {
      case 'beginner':
        difficulty = t('beginner');
        color = Colors.green;
        break;
      case 'intermediate':
        difficulty = t('intermediate');
        color = Colors.orange;
        break;
      case 'advanced':
        difficulty = t('advanced');
        color = Colors.red;
        break;
      default:
        difficulty = exercise.difficulty;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            difficulty,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStartingInstruction(String langCode) {
    final instructions = exercise.getInstructions(langCode);
    if (instructions.isNotEmpty) {
      // Extract the first line which is typically the starting position
      final firstInstruction = instructions.first;
      if (firstInstruction.startsWith('START:') || firstInstruction.startsWith('MULAI:')) {
        return firstInstruction.split(':').last.trim();
      }
    }
    return exercise.getDescription(langCode);
  }

  String _getEndingInstruction(String langCode) {
    final instructions = exercise.getInstructions(langCode);
    if (instructions.isNotEmpty) {
      // Extract the last line which is typically the ending position
      final lastInstruction = instructions.last;
      if (lastInstruction.startsWith('ENDING:') || lastInstruction.startsWith('BERAKHIR:')) {
        return lastInstruction.split(':').last.trim();
      }
    }
    return 'Return to starting position';
  }
}
