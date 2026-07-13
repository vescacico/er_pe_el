import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/avatar_service.dart';

/// Widget untuk menampilkan avatar preview dengan animasi
class AvatarPreview extends StatelessWidget {
  final UserAvatar avatar;
  final double size;
  final bool showAura;
  final bool animate;

  const AvatarPreview({
    super.key,
    required this.avatar,
    this.size = 120,
    this.showAura = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aura (if enabled and not none)
          if (showAura && avatar.aura != null && avatar.aura!.id != 'aura_none')
            _buildAura(),

          // Base/Body
          _buildAvatarBody(),

          // Outfit overlay
          if (avatar.outfit != null)
            _buildOutfitOverlay(),

          // Badge (if any)
          if (avatar.unlockedBadgeIds.isNotEmpty)
            _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildAura() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 2 * math.pi),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                avatar.aura!.primaryColor.withOpacity(0.3),
                avatar.aura!.primaryColor.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: avatar.aura!.primaryColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildAvatarBody() {
    return Container(
      width: size * 0.7,
      height: size * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatar.base?.primaryColor ?? Colors.grey[300],
        border: Border.all(
          color: avatar.outfit?.primaryColor ?? const Color(0xFF10B981),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Face features
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hair
                if (avatar.hair != null && avatar.hair!.id != 'acc_none')
                  Container(
                    height: size * 0.15,
                    decoration: BoxDecoration(
                      color: avatar.hair!.primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(100),
                      ),
                    ),
                  ),

                // Eyes
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(size * 0.12),
                      SizedBox(width: size * 0.08),
                      _buildEye(size * 0.12),
                    ],
                  ),
                ),

                // Mouth
                Container(
                  width: size * 0.15,
                  height: size * 0.05,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),

          // Accessory overlay
          if (avatar.accessory != null && avatar.accessory!.id != 'acc_none')
            _buildAccessory(),
        ],
      ),
    );
  }

  Widget _buildEye(double eyeSize) {
    return Container(
      width: eyeSize,
      height: eyeSize * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(eyeSize / 2),
        border: Border.all(
          color: avatar.eyes?.primaryColor ?? Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: eyeSize * 0.5,
          height: eyeSize * 0.5,
          decoration: BoxDecoration(
            color: avatar.eyes?.primaryColor ?? Colors.grey[700],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitOverlay() {
    return Positioned(
      bottom: 0,
      child: Container(
        width: size * 0.65,
        height: size * 0.25,
        decoration: BoxDecoration(
          color: avatar.outfit!.primaryColor,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          border: Border.all(
            color: avatar.outfit!.secondaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAccessory() {
    IconData icon;
    switch (avatar.accessory!.id) {
      case 'acc_bandana':
        icon = Icons.drafts;
        break;
      case 'acc_glasses':
        icon = Icons.visibility;
        break;
      case 'acc_headband':
        icon = Icons.sports_tennis;
        break;
      case 'acc_crown':
        icon = Icons.military_tech;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: size * 0.05,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: avatar.accessory!.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: avatar.accessory!.primaryColor.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.12,
        ),
      ),
    );
  }

  Widget _buildBadge() {
    final badgeId = avatar.unlockedBadgeIds.first;
    final badge = AvatarDatabase.getAvatarById(badgeId);

    if (badge == null) return const SizedBox.shrink();

    return Positioned(
      right: 0,
      bottom: size * 0.2,
      child: Container(
        width: size * 0.25,
        height: size * 0.25,
        decoration: BoxDecoration(
          color: badge.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: badge.primaryColor.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.star,
          color: Colors.white,
          size: size * 0.12,
        ),
      ),
    );
  }
}

/// Simple avatar display for lists
class SimpleAvatarDisplay extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double radius;
  final Color? borderColor;

  const SimpleAvatarDisplay({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 24,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              _getInitials(),
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );
  }

  String _getInitials() {
    if (displayName == null || displayName!.isEmpty) return '?';
    final words = displayName!.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }
}
