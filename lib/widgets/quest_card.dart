import 'package:flutter/material.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final String reward;
  final double progress;
  final String difficulty;
  final IconData icon;
  final VoidCallback? onTap;

  const QuestCard({
    super.key,
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.difficulty,
    this.icon = Icons.shield,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = Color(0xFF1E1E28);
    final highlight = Color(0xFF6F53FF);
    final accent = Color(0xFF8D8CEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF191A21), Color(0xFF252538)],
          ),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(icon, color: highlight, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  reward,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: highlight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${(progress * 100).round()}% Completed',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(highlight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
