import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/language_service.dart';

class FriendListScreen extends StatefulWidget {
  final String uid;
  final String currentUsername;
  final String currentDisplayName;

  const FriendListScreen({
    super.key,
    required this.uid,
    required this.currentUsername,
    required this.currentDisplayName,
  });

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentLang = 'id';

  List<Friend> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final friends = await FriendService.getFriends(widget.uid);
      final incoming = await FriendService.getIncomingRequests(widget.uid);
      final outgoing = await FriendService.getOutgoingRequests(widget.uid);

      setState(() {
        _friends = friends;
        _incomingRequests = incoming;
        _outgoingRequests = outgoing;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading friend data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        title: Row(
          children: [
            const Icon(Icons.person_add, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Tambah Teman' : 'Add Friend',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLang == 'id'
                  ? 'Masukkan username hunter yang ingin ditambahkan'
                  : 'Enter the username of the hunter you want to add',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111111),
                prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF10B981)),
                hintText: _currentLang == 'id' ? 'Username' : 'Username',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? 'Batal' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isEmpty) return;

              Navigator.pop(context);
              await _sendFriendRequest(username);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(
              _currentLang == 'id' ? 'Kirim Permintaan' : 'Send Request',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(String username) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      // Get user by username
      final user = await FriendService.getUserByUsername(username);

      if (user == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          _showErrorDialog(
            _currentLang == 'id' ? 'Username Tidak Ditemukan' : 'Username Not Found',
            _currentLang == 'id'
                ? 'Hunter dengan username "$username" tidak ditemukan.'
                : 'No hunter found with username "$username".',
          );
        }
        return;
      }

      if (user.uid == widget.uid) {
        if (mounted) {
          Navigator.pop(context);
          _showErrorDialog(
            _currentLang == 'id' ? 'Tidak Valid' : 'Invalid',
            _currentLang == 'id'
                ? 'Kamu tidak bisa menambahkan dirimu sendiri!'
                : 'You cannot add yourself!',
          );
        }
        return;
      }

      // Send friend request
      final result = await FriendService.sendFriendRequest(
        fromUid: widget.uid,
        fromName: widget.currentDisplayName,
        fromUsername: widget.currentUsername.isNotEmpty ? widget.currentUsername : null,
        toUid: user.uid,
        toName: user.displayName,
        toUsername: user.username,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result == null) {
          _showSuccessDialog(
            _currentLang == 'id' ? 'Permintaan Terkirim!' : 'Request Sent!',
            _currentLang == 'id'
                ? 'Permintaan pertemanan ke ${user.displayName} telah dikirim.'
                : 'Friend request to ${user.displayName} has been sent.',
          );
          _loadData();
        } else if (result == 'already_friends') {
          _showErrorDialog(
            _currentLang == 'id' ? 'Sudah Teman' : 'Already Friends',
            _currentLang == 'id'
                ? 'Kamu sudah berteman dengan hunter ini.'
                : 'You are already friends with this hunter.',
          );
        } else if (result == 'request_exists') {
          _showErrorDialog(
            _currentLang == 'id' ? 'Permintaan Sudah Ada' : 'Request Exists',
            _currentLang == 'id'
                ? 'Kamu sudah pernah mengirim permintaan ke hunter ini.'
                : 'You have already sent a request to this hunter.',
          );
        } else {
          _showErrorDialog(
            _currentLang == 'id' ? 'Gagal' : 'Failed',
            _currentLang == 'id'
                ? 'Gagal mengirim permintaan pertemanan.'
                : 'Failed to send friend request.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(
          _currentLang == 'id' ? 'Error' : 'Error',
          e.toString(),
        );
      }
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final success = await FriendService.acceptFriendRequest(
      requestId: request.id,
      fromUid: request.fromUid,
      fromName: request.fromName,
      fromUsername: request.fromUsername,
      fromPhotoUrl: request.fromPhotoUrl,
      toUid: widget.uid,
      toName: widget.currentDisplayName,
      toUsername: widget.currentUsername.isNotEmpty ? widget.currentUsername : null,
    );

    if (success) {
      _loadData();
      _showSuccessDialog(
        _currentLang == 'id' ? 'Teman Baru!' : 'New Friend!',
        _currentLang == 'id'
            ? 'Kamu sekarang berteman dengan ${request.fromName}!'
            : 'You are now friends with ${request.fromName}!',
      );
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          _currentLang == 'id' ? 'Tolak Permintaan?' : 'Reject Request?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Tolak permintaan dari ${request.fromName}?'
              : 'Reject request from ${request.fromName}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _currentLang == 'id' ? 'Batal' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _currentLang == 'id' ? 'Tolak' : 'Reject',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FriendService.rejectFriendRequest(
        requestId: request.id,
        fromUid: request.fromUid,
        toUid: widget.uid,
      );
      _loadData();
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          _currentLang == 'id' ? 'Hapus Teman?' : 'Remove Friend?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _currentLang == 'id'
              ? 'Hapus ${friend.displayName} dari daftar teman?'
              : 'Remove ${friend.displayName} from friends?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _currentLang == 'id' ? 'Batal' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _currentLang == 'id' ? 'Hapus' : 'Remove',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FriendService.removeFriend(
        uid: widget.uid,
        friendUid: friend.uid,
      );
      _loadData();
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF10B981)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
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
        title: Text(
          _currentLang == 'id' ? 'Daftar Teman' : 'Friends',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF10B981)),
            onPressed: _showAddFriendDialog,
            tooltip: _currentLang == 'id' ? 'Tambah Teman' : 'Add Friend',
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
              text: _currentLang == 'id'
                  ? 'Masuk (${_incomingRequests.length})'
                  : 'Incoming (${_incomingRequests.length})',
            ),
            Tab(
              text: _currentLang == 'id'
                  ? 'Kirim (${_outgoingRequests.length})'
                  : 'Sent (${_outgoingRequests.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildIncomingRequests(),
                _buildOutgoingRequests(),
              ],
            ),
    );
  }

  Widget _buildFriendsList() {
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
                  ? 'Tambahkan teman dengan username!'
                  : 'Add friends by username!',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
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

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.2),
            border: Border.all(color: const Color(0xFF10B981)),
          ),
          child: Center(
            child: Text(
              friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                friend.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv. ${friend.level}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend.username != null && friend.username!.isNotEmpty)
              Text(
                '@${friend.username}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              '${friend.rank} · ${friend.totalExp} EXP',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          color: Colors.black87,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  const Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _currentLang == 'id' ? 'Hapus Teman' : 'Remove Friend',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _removeFriend(friend);
            }
          },
        ),
      ),
    );
  }

  Widget _buildIncomingRequests() {
    if (_incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _currentLang == 'id' ? 'Tidak ada permintaan' : 'No incoming requests',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingRequests.length,
        itemBuilder: (context, index) {
          final request = _incomingRequests[index];
          return _buildRequestCard(request, isIncoming: true);
        },
      ),
    );
  }

  Widget _buildOutgoingRequests() {
    if (_outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _currentLang == 'id' ? 'Belum ada permintaan terkirim' : 'No sent requests',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outgoingRequests.length,
        itemBuilder: (context, index) {
          final request = _outgoingRequests[index];
          return _buildRequestCard(request, isIncoming: false);
        },
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request, {required bool isIncoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncoming
              ? Colors.orange.withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isIncoming
                ? Colors.orange.withOpacity(0.2)
                : const Color(0xFF10B981).withOpacity(0.2),
            border: Border.all(
              color: isIncoming ? Colors.orange : const Color(0xFF10B981),
            ),
          ),
          child: Icon(
            isIncoming ? Icons.person_add : Icons.send,
            color: isIncoming ? Colors.orange : const Color(0xFF10B981),
            size: 24,
          ),
        ),
        title: Text(
          request.fromName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.fromUsername != null && request.fromUsername!.isNotEmpty)
              Text(
                '@${request.fromUsername}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(request.sentAt),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: isIncoming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _acceptRequest(request),
                    tooltip: _currentLang == 'id' ? 'Terima' : 'Accept',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => _rejectRequest(request),
                    tooltip: _currentLang == 'id' ? 'Tolak' : 'Reject',
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentLang == 'id' ? 'Menunggu' : 'Pending',
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return _currentLang == 'id' ? 'Baru saja' : 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ${_currentLang == 'id' ? 'yang lalu' : 'ago'}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ${_currentLang == 'id' ? 'yang lalu' : 'ago'}';
    } else {
      return '${diff.inDays}d ${_currentLang == 'id' ? 'yang lalu' : 'ago'}';
    }
  }
}
