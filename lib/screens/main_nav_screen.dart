import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart' show HomeScreen;
import '../services/language_service.dart';
import '../services/sick_mode_service.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'sick_mode_screen.dart';

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
    _checkSickMode();
  }

  Future<void> _loadProfileData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (mounted && doc.exists) {
      setState(() {
        _photoUrl = doc.data()?['photoUrl'] as String?;
        _username = doc.data()?['username'] as String?;
      });
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
            child: CircleAvatar(
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