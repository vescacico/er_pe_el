import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/language_service.dart';
import 'friend_list_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final String currentUid;
  final String currentUsername;
  final String currentDisplayName;

  const LeaderboardScreen({
    super.key,
    required this.currentUid,
    required this.currentUsername,
    required this.currentDisplayName,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentLang = 'id';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Friend> _friends = [];
  bool _isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FriendService.getFriends(widget.currentUid);
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
      setState(() => _isLoadingFriends = false);
    }
  }

  void _openFriendList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendListScreen(
          uid: widget.currentUid,
          currentUsername: widget.currentUsername,
          currentDisplayName: widget.currentDisplayName,
        ),
      ),
    ).then((_) => _loadFriends());
  }

  // Send nudge to friend
  Future<void> _sendNudge(Friend friend) async {
    final success = await FriendService.sendNudge(
      fromUid: widget.currentUid,
      fromName: widget.currentDisplayName,
      toUid: friend.uid,
      toName: friend.displayName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLang == 'id'
                  ? 'Nudge terkirim ke ${friend.displayName}! 💪'
                  : 'Nudge sent to ${friend.displayName}! 💪',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLang == 'id'
                  ? 'Gagal mengirim nudge'
                  : 'Failed to send nudge',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Papan Peringkat' : 'Leaderboard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Color(0xFF10B981)),
            onPressed: _openFriendList,
            tooltip: _currentLang == 'id' ? 'Daftar Teman' : 'Friends',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              text: _currentLang == 'id'
                  ? 'Teman (${_friends.length})'
                  : 'Friends (${_friends.length})',
            ),
            Tab(
              text: _currentLang == 'id' ? 'Global' : 'Global',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar (only in Global tab)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111111),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: _currentLang == 'id' ? 'Cari username...' : 'Search username...',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsLeaderboard(),
                _buildGlobalLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsLeaderboard() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _currentLang == 'id' ? 'Belum ada teman' : 'No friends yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _currentLang == 'id'
                  ? 'Tambahkan teman untuk melihat peringkat mereka!'
                  : 'Add friends to see their rankings!',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openFriendList,
              icon: const Icon(Icons.person_add),
              label: Text(_currentLang == 'id' ? 'Tambah Teman' : 'Add Friend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    // Sort friends by EXP
    final sortedFriends = List<Friend>.from(_friends)
      ..sort((a, b) => b.totalExp.compareTo(a.totalExp));

    return RefreshIndicator(
      onRefresh: _loadFriends,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedFriends.length,
        itemBuilder: (context, index) {
          final friend = sortedFriends[index];
          return _buildFriendLeaderboardItem(friend, index + 1);
        },
      ),
    );
  }

  Widget _buildFriendLeaderboardItem(Friend friend, int rank) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = Colors.amber;
    else if (rank == 2) rankColor = Colors.grey.shade300;
    else if (rank == 3) rankColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColor.withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.15),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _sendNudge(friend),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rankColor != Colors.grey ? rankColor : Colors.black,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor != Colors.grey ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (friend.username != null && friend.username!.isNotEmpty)
                                Text(
                                  '@${friend.username}',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${friend.totalExp} EXP',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lv. ${friend.level}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          friend.rank,
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nudge button
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalExp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _currentLang == 'id' ? 'Belum ada data.' : 'No data yet.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        // Filter by search query
        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
        if (_searchQuery.isEmpty) {
          docs = snapshot.data!.docs;
        } else {
          docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final username = (data['username'] as String?)?.toLowerCase() ?? '';
            final displayName = (data['displayName'] as String?)?.toLowerCase() ?? '';
            return username.contains(_searchQuery) || displayName.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  _currentLang == 'id' ? 'Tidak ditemukan' : 'Not found',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final isMe = docs[index].id == widget.currentUid;
            final rankNumber = index + 1;

            Color medalColor = Colors.transparent;
            if (rankNumber == 1) medalColor = Colors.amber;
            else if (rankNumber == 2) medalColor = Colors.grey.shade300;
            else if (rankNumber == 3) medalColor = Colors.brown.shade300;

            final username = data['username'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF10B981)
                      : medalColor != Colors.transparent
                          ? medalColor.withOpacity(0.5)
                          : const Color(0xFF10B981).withOpacity(0.15),
                  width: isMe ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: medalColor != Colors.transparent ? medalColor : Colors.black,
                  ),
                  child: Center(
                    child: Text(
                      '$rankNumber',
                      style: TextStyle(
                        color: medalColor != Colors.transparent ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['displayName'] ?? 'Hunter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (username != null && username.isNotEmpty)
                            Text(
                              '@$username',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentLang == 'id' ? 'Kamu' : 'You',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${data['rank'] ?? 'E - Awakening'} · Lv. ${data['level'] ?? 1}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Text(
                  '${data['totalExp'] ?? 0} EXP',
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
