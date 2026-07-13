import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart' show HomeScreen;
import '../services/language_service.dart';
import '../services/sick_mode_service.dart';
import '../services/user_profile_service.dart';
import '../services/avatar_service.dart';
import '../widgets/avatar_preview.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'sick_mode_screen.dart';
import 'avatar_screen.dart';
import 'achievement_screen.dart';
import 'fitness_chatbot_screen.dart';

class MainNavScreen extends StatefulWidget {
  final String uid;
  final String displayName;

  const MainNavScreen({super.key, required this.uid, required this.displayName});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  String _currentLang = 'id';
  String? _photoUrl;
  String? _username;
  bool _isSickModeActive = false;
  UserAvatar? _userAvatar;

  // User stats for Achievement screen
  int _userLevel = 1;
  int _userExp = 0;
  int _userStreak = 0;
  int _questsCompleted = 0;
  int _friendsCount = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _tabs = [
      HomeScreen(uid: widget.uid, displayName: widget.displayName),
      HistoryScreen(uid: widget.uid),
      LeaderboardScreen(
        currentUid: widget.uid,
        currentUsername: _username ?? '',
        currentDisplayName: widget.displayName,
      ),
    ];
    _loadProfileData();
    _loadAvatarData();
    _checkSickMode();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _photoUrl = data['photoUrl'] as String?;
          _username = data['username'] as String?;
          _userLevel = data['level'] ?? 1;
          _userExp = data['totalExp'] ?? 0;
          _userStreak = data['streak'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadAvatarData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('avatar')
          .doc('current')
          .get();

      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          _userAvatar = UserAvatar.fromMap(widget.uid, doc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Load quest completion count
      final questHistory = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('quest_history')
          .get();
      _questsCompleted = questHistory.size;

      // Load friends count
      final friends = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('friends')
          .get();
      _friendsCount = friends.size;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _checkSickMode() async {
    final isActive = await SickModeService.isSickModeActive(widget.uid);
    if (mounted) {
      setState(() => _isSickModeActive = isActive);
    }
  }

  void _refreshLanguage() {
    setState(() => _currentLang = LanguageService.getCurrentLanguage());
  }

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return _currentLang == 'id' ? 'Riwayat' : 'History';
      case 2:
        return _currentLang == 'id' ? 'Papan Peringkat' : 'Leaderboard';
      default:
        return 'FitTask';
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          uid: widget.uid,
          onLanguageChanged: _refreshLanguage,
          onProfileUpdated: _loadProfileData,
        ),
      ),
    ).then((_) {
      _loadProfileData();
      _refreshLanguage();
    });
  }

  void _openAvatar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarScreen(
          uid: widget.uid,
          userLevel: _userLevel,
          userExp: _userExp,
        ),
      ),
    ).then((_) {
      _loadAvatarData(); // Refresh avatar after changes
    });
  }

  void _openAchievements() async {
    // Load stats first
    await _loadUserStats();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementScreen(
          uid: widget.uid,
          userLevel: _userLevel,
          userExp: _userExp,
          userStreak: _userStreak,
          questsCompleted: _questsCompleted,
          friendsCount: _friendsCount,
          walkingQuests: 0, // Will be loaded in AchievementScreen
          hydrationQuests: 0,
          exerciseQuests: 0,
        ),
      ),
    );
  }

  void _openSickMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SickModeScreen(uid: widget.uid),
      ),
    ).then((_) {
      _checkSickMode();
    });
  }

  void _openFitnessChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FitnessChatbotScreen(uid: widget.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _openProfile,
            child: _userAvatar != null
                ? AvatarPreview(
                    avatar: _userAvatar!,
                    size: 40,
                    showAura: false,
                    animate: false,
                  )
                : CircleAvatar(
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF10B981))
                        : null,
                  ),
          ),
        ),
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Fitness Chatbot Button
          IconButton(
            onPressed: _openFitnessChatbot,
            icon: const Icon(Icons.chat_bubble, color: Color(0xFF10B981)),
            tooltip: _currentLang == 'id' ? 'Asisten Kebugaran' : 'Fitness Assistant',
          ),

          // Achievement Button
          IconButton(
            onPressed: _openAchievements,
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            tooltip: _currentLang == 'id' ? 'Achievement' : 'Achievements',
          ),

          // Avatar Button
          IconButton(
            onPressed: _openAvatar,
            icon: const Icon(Icons.face, color: Color(0xFF10B981)),
            tooltip: _currentLang == 'id' ? 'Avatar' : 'Avatar',
          ),

          // Sick Mode Button
          GestureDetector(
            onTap: _openSickMode,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isSickModeActive
                    ? Colors.orange.withOpacity(0.2)
                    : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isSickModeActive
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSickModeActive ? Icons.healing : Icons.medical_services,
                    color: _isSickModeActive ? Colors.orange : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSickModeActive
                        ? (_currentLang == 'id' ? 'Terbatas' : 'Limited')
                        : (_currentLang == 'id' ? 'Mode' : 'Mode'),
                    style: TextStyle(
                      color: _isSickModeActive ? Colors.orange : Colors.grey,
                      fontSize: 12,
                      fontWeight: _isSickModeActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF111111),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _currentLang == 'id' ? 'Home' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: _currentLang == 'id' ? 'Riwayat' : 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard),
            label: _currentLang == 'id' ? 'Peringkat' : 'Leaderboard',
          ),
        ],
      ),
    );
  }
}