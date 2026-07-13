import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model untuk teman
class Friend {
  final String uid;
  final String displayName;
  final String? username;
  final String rank;
  final int level;
  final int totalExp;
  final String? photoUrl;
  final DateTime? friendsSince;
  final bool isOnline;

  Friend({
    required this.uid,
    required this.displayName,
    this.username,
    required this.rank,
    required this.level,
    required this.totalExp,
    this.photoUrl,
    this.friendsSince,
    this.isOnline = false,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'Unknown',
      username: map['username'],
      rank: map['rank'] ?? 'E - Awakening',
      level: map['level'] ?? 1,
      totalExp: map['totalExp'] ?? 0,
      photoUrl: map['photoUrl'],
      friendsSince: map['friendsSince'] != null
          ? (map['friendsSince'] as Timestamp).toDate()
          : null,
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'rank': rank,
      'level': level,
      'totalExp': totalExp,
      'photoUrl': photoUrl,
      'friendsSince': friendsSince != null ? Timestamp.fromDate(friendsSince!) : null,
      'isOnline': isOnline,
    };
  }
}

/// Pending friend request
class FriendRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String? fromUsername;
  final String? fromPhotoUrl;
  final DateTime sentAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    this.fromUsername,
    this.fromPhotoUrl,
    required this.sentAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      fromUid: map['fromUid'] ?? '',
      fromName: map['fromName'] ?? 'Unknown',
      fromUsername: map['fromUsername'],
      fromPhotoUrl: map['fromPhotoUrl'],
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Service untuk mengelola teman
class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cek apakah username tersedia
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  /// Update username user
  static Future<bool> updateUsername(String uid, String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Cek lagi apakah username tersedia
      if (!await isUsernameAvailable(username)) {
        return false;
      }

      await _firestore.collection('users').doc(uid).update({
        'username': username.trim(),
        'usernameLower': normalizedUsername,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }

  /// Get user by username
  static Future<Friend?> getUserByUsername(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('users')
          .where('usernameLower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return Friend(
        uid: snapshot.docs.first.id,
        displayName: data['displayName'] ?? 'Unknown',
        username: data['username'],
        rank: data['rank'] ?? 'E - Awakening',
        level: data['level'] ?? 1,
        totalExp: data['totalExp'] ?? 0,
        photoUrl: data['photoUrl'],
      );
    } catch (e) {
      debugPrint('Error getting user by username: $e');
      return null;
    }
  }

  /// Get user's friends list
  static Future<List<Friend>> getFriends(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .orderBy('displayName')
          .get();

      final friends = <Friend>[];
      for (final doc in snapshot.docs) {
        friends.add(Friend.fromMap(doc.data()));
      }
      return friends;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests (incoming)
  static Future<List<FriendRequest>> getIncomingRequests(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      final requests = <FriendRequest>[];
      for (final doc in snapshot.docs) {
        requests.add(FriendRequest(
          id: doc.id,
          fromUid: doc.data()['fromUid'] ?? '',
          fromName: doc.data()['fromName'] ?? 'Unknown',
          fromUsername: doc.data()['fromUsername'],
          fromPhotoUrl: doc.data()['fromPhotoUrl'],
          sentAt: doc.data()['sentAt'] != null
              ? (doc.data()['sentAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }
      return requests;
    } catch (e) {
      debugPrint('Error getting incoming requests: $e');
      return [];
    }
  }

  /// Get sent friend requests (outgoing)
  static Future<List<FriendRequest>> getOutgoingRequests(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sent_requests')
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      final requests = <FriendRequest>[];
      for (final doc in snapshot.docs) {
        requests.add(FriendRequest(
          id: doc.id,
          fromUid: doc.data()['toUid'] ?? '',
          fromName: doc.data()['toName'] ?? 'Unknown',
          fromUsername: doc.data()['toUsername'],
          sentAt: doc.data()['sentAt'] != null
              ? (doc.data()['sentAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }
      return requests;
    } catch (e) {
      debugPrint('Error getting outgoing requests: $e');
      return [];
    }
  }

  /// Send friend request (uses batch for atomicity)
  static Future<String?> sendFriendRequest({
    required String fromUid,
    required String fromName,
    String? fromUsername,
    String? fromPhotoUrl,
    required String toUid,
    required String toName,
    String? toUsername,
  }) async {
    try {
      // Cek apakah sudah teman
      final existing = await _firestore
          .collection('users')
          .doc(fromUid)
          .collection('friends')
          .doc(toUid)
          .get();

      if (existing.exists) {
        return 'already_friends';
      }

      // Cek apakah sudah ada request
      final existingRequest = await _firestore
          .collection('users')
          .doc(toUid)
          .collection('friend_requests')
          .where('fromUid', isEqualTo: fromUid)
          .where('toUid', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return 'request_exists';
      }

      final requestId = _firestore.collection('friend_requests').doc().id;
      final now = Timestamp.now();
      final batch = _firestore.batch();

      // Simpan request di penerima
      final toRequestRef = _firestore
          .collection('users')
          .doc(toUid)
          .collection('friend_requests')
          .doc(requestId);
      batch.set(toRequestRef, {
        'id': requestId,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromUsername': fromUsername,
        'fromPhotoUrl': fromPhotoUrl,
        'toUid': toUid,
        'toName': toName,
        'toUsername': toUsername,
        'status': 'pending',
        'sentAt': now,
      });

      // Simpan di pengirim (untuk tracking)
      final fromRequestRef = _firestore
          .collection('users')
          .doc(fromUid)
          .collection('sent_requests')
          .doc(requestId);
      batch.set(fromRequestRef, {
        'id': requestId,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromUsername': fromUsername,
        'toUid': toUid,
        'toName': toName,
        'toUsername': toUsername,
        'status': 'pending',
        'sentAt': now,
      });

      await batch.commit();
      return null; // Success
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return 'error';
    }
  }

  /// Accept friend request (uses batch for atomicity)
  static Future<bool> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String fromName,
    String? fromUsername,
    String? fromPhotoUrl,
    required String toUid,
    required String toName,
    String? toUsername,
  }) async {
    try {
      final now = Timestamp.now();
      final batch = _firestore.batch();

      // Tambah ke friends user pertama
      final fromFriendRef = _firestore
          .collection('users')
          .doc(fromUid)
          .collection('friends')
          .doc(toUid);
      batch.set(fromFriendRef, {
        'uid': toUid,
        'displayName': toName,
        'username': toUsername,
        'friendsSince': now,
      });

      // Tambah ke friends user kedua
      final toFriendRef = _firestore
          .collection('users')
          .doc(toUid)
          .collection('friends')
          .doc(fromUid);
      batch.set(toFriendRef, {
        'uid': fromUid,
        'displayName': fromName,
        'username': fromUsername,
        'friendsSince': now,
      });

      // Update status request
      final toRequestRef = _firestore
          .collection('users')
          .doc(toUid)
          .collection('friend_requests')
          .doc(requestId);
      batch.update(toRequestRef, {'status': 'accepted'});

      // Update sent_requests pengirim
      final fromSentRef = _firestore
          .collection('users')
          .doc(fromUid)
          .collection('sent_requests')
          .doc(requestId);
      batch.update(fromSentRef, {'status': 'accepted'});

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Reject friend request
  static Future<bool> rejectFriendRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update status request
      final toRequestRef = _firestore
          .collection('users')
          .doc(toUid)
          .collection('friend_requests')
          .doc(requestId);
      batch.update(toRequestRef, {'status': 'rejected'});

      // Delete from sent_requests pengirim
      final fromSentRef = _firestore
          .collection('users')
          .doc(fromUid)
          .collection('sent_requests')
          .doc(requestId);
      batch.delete(fromSentRef);

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      return false;
    }
  }

  /// Remove friend (uses batch for atomicity)
  static Future<bool> removeFriend({
    required String uid,
    required String friendUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // Hapus dari friends user pertama
      final userFriendRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(friendUid);
      batch.delete(userFriendRef);

      // Hapus dari friends user kedua
      final friendUserRef = _firestore
          .collection('users')
          .doc(friendUid)
          .collection('friends')
          .doc(uid);
      batch.delete(friendUserRef);

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Get friend count
  static Future<int> getFriendCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting friend count: $e');
      return 0;
    }
  }

  /// Get pending request count
  static Future<int> getPendingRequestCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting pending request count: $e');
      return 0;
    }
  }

  /// Send nudge to a friend (like Duolingo)
  static Future<bool> sendNudge({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String toName,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create nudge notification in recipient's collection
      final nudgeRef = _firestore
          .collection('users')
          .doc(toUid)
          .collection('nudges')
          .doc();
      batch.set(nudgeRef, {
        'fromUid': fromUid,
        'fromName': fromName,
        'toUid': toUid,
        'toName': toName,
        'type': 'nudge',
        'message': _getNudgeMessage(fromName),
        'createdAt': Timestamp.now(),
        'read': false,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error sending nudge: $e');
      return false;
    }
  }

  static String _getNudgeMessage(String fromName) {
    final messages = [
      'Hey $fromName! Ayo latihan bareng! 💪',
      '$fromName lagi ngejar kamu di leaderboard nih! 🏃',
      'Ayo bangun dan latihan! $fromName lagi nunggu! ⏰',
      'Kamu bisa lewatin $fromName! Coba latihan sekarang! 🎯',
      'Hey! $fromName butuh partner latihan nih! 👊',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  /// Get pending nudges count
  static Future<int> getPendingNudgesCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('nudges')
          .where('toUid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting nudges count: $e');
      return 0;
    }
  }

  /// Mark nudge as read
  static Future<void> markNudgeAsRead(String uid, String nudgeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('nudges')
          .doc(nudgeId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking nudge as read: $e');
    }
  }
}
