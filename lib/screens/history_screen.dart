import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/language_service.dart';

class HistoryScreen extends StatelessWidget {
  final String uid;

  const HistoryScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.getCurrentLanguage();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            lang == 'id' ? 'Riwayat' : 'History',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: lang == 'id' ? 'EXP' : 'EXP'),
              Tab(text: lang == 'id' ? 'Quest' : 'Quest'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExpHistory(context, lang),
            _buildQuestHistory(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildExpHistory(BuildContext context, String lang) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exp_history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  lang == 'id' ? 'Belum ada riwayat EXP.' : 'No EXP history yet.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group by date
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'];
          String dateKey;
          if (timestamp is Timestamp) {
            final date = timestamp.toDate();
            dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } else {
            dateKey = 'Unknown';
          }
          grouped.putIfAbsent(dateKey, () => []);
          grouped[dateKey]!.add(doc);
        }

        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final dayDocs = grouped[dateKey]!;
            final totalExp = dayDocs.fold<int>(
              0,
              (sum, doc) {
                final data = doc.data();
                return sum + ((data['amount'] as num?)?.toInt() ?? 0);
              },
            );

            // Format date
            final parts = dateKey.split('-');
            final formattedDate = parts.length == 3
                ? '${parts[2]}/${parts[1]}/${parts[0]}'
                : dateKey;

            return Card(
              color: const Color(0xFF111111),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: ExpansionTile(
                collapsedIconColor: Colors.grey,
                iconColor: const Color(0xFF10B981),
                title: Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '+ $totalExp EXP',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                ),
                children: dayDocs.map((doc) {
                  final data = doc.data();
                  final source = data['source'] as String? ?? 'Unknown';
                  final amount = data['amount'] as int? ?? 0;

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.stars, color: Color(0xFF10B981), size: 20),
                    title: Text(
                      source,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    trailing: Text(
                      '+$amount',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestHistory(BuildContext context, String lang) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quest_history')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  lang == 'id' ? 'Belum ada riwayat quest.' : 'No quest history yet.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group by date
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final timestamp = data['completedAt'];
          String dateKey;
          if (timestamp is Timestamp) {
            final date = timestamp.toDate();
            dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } else {
            dateKey = 'Unknown';
          }
          grouped.putIfAbsent(dateKey, () => []);
          grouped[dateKey]!.add(doc);
        }

        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final dayDocs = grouped[dateKey]!;
            final completedCount = dayDocs.length;

            // Format date
            final parts = dateKey.split('-');
            final formattedDate = parts.length == 3
                ? '${parts[2]}/${parts[1]}/${parts[0]}'
                : dateKey;

            return Card(
              color: const Color(0xFF111111),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: ExpansionTile(
                collapsedIconColor: Colors.grey,
                iconColor: const Color(0xFF10B981),
                leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                title: Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$completedCount ${lang == 'id' ? 'quest selesai' : 'quests completed'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                children: dayDocs.map((doc) {
                  final data = doc.data();
                  final questName = data['questName'] as String? ?? 'Unknown Quest';
                  final expReward = data['expReward'] as int? ?? 0;
                  final exerciseType = data['exerciseType'] as String? ?? 'exercise';

                  IconData icon;
                  switch (exerciseType) {
                    case 'walk':
                      icon = Icons.directions_walk;
                      break;
                    case 'water':
                      icon = Icons.water_drop;
                      break;
                    case 'plank':
                      icon = Icons.timer;
                      break;
                    default:
                      icon = Icons.fitness_center;
                  }

                  return ListTile(
                    dense: true,
                    leading: Icon(icon, color: const Color(0xFF10B981), size: 20),
                    title: Text(
                      questName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    trailing: Text(
                      '+$expReward EXP',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
