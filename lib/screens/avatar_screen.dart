import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/avatar_service.dart';
import '../services/language_service.dart';
import '../widgets/avatar_preview.dart';

/// Screen untuk memilih dan mengcustom avatar
class AvatarScreen extends StatefulWidget {
  final String uid;
  final int userLevel;
  final int userExp;
  final VoidCallback? onAvatarChanged;

  const AvatarScreen({
    super.key,
    required this.uid,
    required this.userLevel,
    required this.userExp,
    this.onAvatarChanged,
  });

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserAvatar _currentAvatar;
  bool _isLoading = true;
  String _currentLang = 'id';

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.getCurrentLanguage();
    _tabController = TabController(
      length: AvatarCategory.values.length,
      vsync: this,
    );
    _loadAvatar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('avatar')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        _currentAvatar = UserAvatar.fromMap(widget.uid, doc.data()!);
      } else {
        _currentAvatar = UserAvatar(uid: widget.uid);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _currentAvatar = UserAvatar(uid: widget.uid);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvatar() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('avatar')
          .doc('current')
          .set(_currentAvatar.toMap());

      widget.onAvatarChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLang == 'id' ? 'Gagal menyimpan avatar' : 'Failed to save avatar',
            ),
          ),
        );
      }
    }
  }

  void _selectAvatar(AvatarCategory category, Avatar avatar) {
    // Check if avatar is unlocked
    if (!_isAvatarUnlocked(avatar)) {
      _showUnlockDialog(avatar);
      return;
    }

    setState(() {
      switch (category) {
        case AvatarCategory.base:
          _currentAvatar.baseId = avatar.id;
          break;
        case AvatarCategory.hair:
          _currentAvatar.hairId = avatar.id;
          break;
        case AvatarCategory.eyes:
          _currentAvatar.eyesId = avatar.id;
          break;
        case AvatarCategory.outfit:
          _currentAvatar.outfitId = avatar.id;
          break;
        case AvatarCategory.accessory:
          _currentAvatar.accessoryId = avatar.id;
          break;
        case AvatarCategory.aura:
          _currentAvatar.auraId = avatar.id;
          break;
        case AvatarCategory.badge:
          // Badges are unlocked based on achievements, not selected
          break;
      }
    });
    _saveAvatar();
  }

  bool _isAvatarUnlocked(Avatar avatar) {
    return avatar.requiredLevel <= widget.userLevel;
  }

  void _showUnlockDialog(Avatar avatar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'id' ? 'Terkunci!' : 'Locked!',
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              avatar.category.getIcon(),
              color: avatar.primaryColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              avatar.getName(_currentLang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentLang == 'id'
                  ? 'Dibutuhkan Level ${avatar.requiredLevel} untuk membuka'
                  : 'Requires Level ${avatar.requiredLevel} to unlock',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  _currentLang == 'id' ? 'Level kamu: ${widget.userLevel}' : 'Your level: ${widget.userLevel}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _currentLang == 'id' ? 'OK' : 'OK',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentLang == 'id' ? 'Avatar' : 'Avatar',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Avatar Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  Colors.black,
                ],
              ),
            ),
            child: Column(
              children: [
                AvatarPreview(
                  avatar: _currentAvatar,
                  size: 180,
                  showAura: true,
                ),
                const SizedBox(height: 20),
                Text(
                  _currentLang == 'id' ? 'Preview Avatar' : 'Avatar Preview',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            color: const Color(0xFF111111),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF10B981),
              labelColor: const Color(0xFF10B981),
              unselectedLabelColor: Colors.grey,
              tabs: AvatarCategory.values.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.getIcon(), size: 18),
                      const SizedBox(width: 8),
                      Text(category.getNameId()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Avatar Selection Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: AvatarCategory.values.map((category) {
                return _buildAvatarGrid(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(AvatarCategory category) {
    final avatars = AvatarDatabase.getAvatarsByCategory(category);
    final selectedId = _getSelectedId(category);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isSelected = avatar.id == selectedId;
        final isUnlocked = _isAvatarUnlocked(avatar);

        return GestureDetector(
          onTap: () => _selectAvatar(category, avatar),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Avatar preview
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon or color swatch
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: avatar.primaryColor.withOpacity(avatar.primaryColor == Colors.transparent ? 0 : 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatar.primaryColor == Colors.transparent
                                ? Colors.grey
                                : avatar.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: avatar.primaryColor == Colors.transparent
                            ? Icon(
                                category.getIcon(),
                                color: Colors.grey,
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      // Name
                      Text(
                        avatar.getName(_currentLang),
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.grey,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Level requirement
                      if (!isUnlocked) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, color: Colors.grey, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              'Lv.${avatar.requiredLevel}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Selected indicator
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSelectedId(AvatarCategory category) {
    switch (category) {
      case AvatarCategory.base:
        return _currentAvatar.baseId;
      case AvatarCategory.hair:
        return _currentAvatar.hairId;
      case AvatarCategory.eyes:
        return _currentAvatar.eyesId;
      case AvatarCategory.outfit:
        return _currentAvatar.outfitId;
      case AvatarCategory.accessory:
        return _currentAvatar.accessoryId;
      case AvatarCategory.aura:
        return _currentAvatar.auraId;
      case AvatarCategory.badge:
        return _currentAvatar.unlockedBadgeIds.isNotEmpty
            ? _currentAvatar.unlockedBadgeIds.first
            : 'badge_none';
    }
  }
}
