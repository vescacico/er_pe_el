import 'package:flutter/material.dart';

/// Avatar model representing a user's character appearance
class Avatar {
  final String id;
  final String nameId;
  final String nameEn;
  final AvatarCategory category;
  final String assetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final int price;
  final bool isDefault;
  final int requiredLevel;

  const Avatar({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.category,
    required this.assetPath,
    required this.primaryColor,
    required this.secondaryColor,
    this.price = 0,
    this.isDefault = false,
    this.requiredLevel = 1,
  });

  String getName(String langCode) => langCode == 'id' ? nameId : nameEn;
}

/// Categories of avatar customization
enum AvatarCategory {
  base,
  hair,
  eyes,
  outfit,
  accessory,
  aura,
  badge,
}

extension AvatarCategoryExtension on AvatarCategory {
  String getNameId() {
    switch (this) {
      case AvatarCategory.base:
        return 'Wajah';
      case AvatarCategory.hair:
        return 'Rambut';
      case AvatarCategory.eyes:
        return 'Mata';
      case AvatarCategory.outfit:
        return 'Pakaian';
      case AvatarCategory.accessory:
        return 'Aksesori';
      case AvatarCategory.aura:
        return 'Aura';
      case AvatarCategory.badge:
        return 'Lencana';
    }
  }

  String getNameEn() {
    switch (this) {
      case AvatarCategory.base:
        return 'Face';
      case AvatarCategory.hair:
        return 'Hair';
      case AvatarCategory.eyes:
        return 'Eyes';
      case AvatarCategory.outfit:
        return 'Outfit';
      case AvatarCategory.accessory:
        return 'Accessory';
      case AvatarCategory.aura:
        return 'Aura';
      case AvatarCategory.badge:
        return 'Badge';
    }
  }

  IconData getIcon() {
    switch (this) {
      case AvatarCategory.base:
        return Icons.face;
      case AvatarCategory.hair:
        return Icons.face_retouching_natural;
      case AvatarCategory.eyes:
        return Icons.visibility;
      case AvatarCategory.outfit:
        return Icons.checkroom;
      case AvatarCategory.accessory:
        return Icons.auto_awesome;
      case AvatarCategory.aura:
        return Icons.blur_on;
      case AvatarCategory.badge:
        return Icons.military_tech;
    }
  }
}

/// Database of all available avatars
class AvatarDatabase {
  // Base face/skin tones
  static const List<Avatar> baseAvatars = [
    Avatar(
      id: 'base_light',
      nameId: 'Kulit Terang',
      nameEn: 'Light Skin',
      category: AvatarCategory.base,
      assetPath: 'assets/avatars/base_light.png',
      primaryColor: Color(0xFFFFDBB4),
      secondaryColor: Color(0xFFEDB98A),
      isDefault: true,
    ),
    Avatar(
      id: 'base_medium',
      nameId: 'Kulit Sawo Matang',
      nameEn: 'Medium Skin',
      category: AvatarCategory.base,
      assetPath: 'assets/avatars/base_medium.png',
      primaryColor: Color(0xFFD08B5B),
      secondaryColor: Color(0xFFAE5D29),
    ),
    Avatar(
      id: 'base_dark',
      nameId: 'Kulit Gelap',
      nameEn: 'Dark Skin',
      category: AvatarCategory.base,
      assetPath: 'assets/avatars/base_dark.png',
      primaryColor: Color(0xFF5C3317),
      secondaryColor: Color(0xFF3E220D),
    ),
  ];

  // Hair styles
  static const List<Avatar> hairAvatars = [
    Avatar(
      id: 'hair_short',
      nameId: 'Rambut Pendek',
      nameEn: 'Short Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_short.png',
      primaryColor: Color(0xFF2C1810),
      secondaryColor: Color(0xFF1A0F0A),
    ),
    Avatar(
      id: 'hair_long',
      nameId: 'Rambut Panjang',
      nameEn: 'Long Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_long.png',
      primaryColor: Color(0xFF2C1810),
      secondaryColor: Color(0xFF1A0F0A),
    ),
    Avatar(
      id: 'hair_spiky',
      nameId: 'Rambut Spike',
      nameEn: 'Spiky Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_spiky.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      requiredLevel: 5,
    ),
    Avatar(
      id: 'hair_blonde',
      nameId: 'Rambut Pirang',
      nameEn: 'Blonde Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_blonde.png',
      primaryColor: Color(0xFFE5C100),
      secondaryColor: Color(0xFFB8960A),
      requiredLevel: 10,
    ),
    Avatar(
      id: 'hair_red',
      nameId: 'Rambut Merah',
      nameEn: 'Red Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_red.png',
      primaryColor: Color(0xFFDC2626),
      secondaryColor: Color(0xFFB91C1C),
      requiredLevel: 15,
    ),
    Avatar(
      id: 'hair_white',
      nameId: 'Rambut Putih',
      nameEn: 'White Hair',
      category: AvatarCategory.hair,
      assetPath: 'assets/avatars/hair_white.png',
      primaryColor: Color(0xFFE5E5E5),
      secondaryColor: Color(0xFFCCCCCC),
      price: 500,
      requiredLevel: 20,
    ),
  ];

  // Eye styles
  static const List<Avatar> eyeAvatars = [
    Avatar(
      id: 'eyes_normal',
      nameId: 'Mata Normal',
      nameEn: 'Normal Eyes',
      category: AvatarCategory.eyes,
      assetPath: 'assets/avatars/eyes_normal.png',
      primaryColor: Color(0xFF4A5568),
      secondaryColor: Color(0xFF2D3748),
      isDefault: true,
    ),
    Avatar(
      id: 'eyes_sharp',
      nameId: 'Mata Tajam',
      nameEn: 'Sharp Eyes',
      category: AvatarCategory.eyes,
      assetPath: 'assets/avatars/eyes_sharp.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      requiredLevel: 5,
    ),
    Avatar(
      id: 'eyes_glow',
      nameId: 'Mata Glow',
      nameEn: 'Glow Eyes',
      category: AvatarCategory.eyes,
      assetPath: 'assets/avatars/eyes_glow.png',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF6D28D9),
      requiredLevel: 15,
    ),
    Avatar(
      id: 'eyes_red',
      nameId: 'Mata Merah',
      nameEn: 'Red Eyes',
      category: AvatarCategory.eyes,
      assetPath: 'assets/avatars/eyes_red.png',
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
      price: 1000,
      requiredLevel: 25,
    ),
  ];

  // Outfits
  static const List<Avatar> outfitAvatars = [
    Avatar(
      id: 'outfit_training',
      nameId: 'Seragam Training',
      nameEn: 'Training Uniform',
      category: AvatarCategory.outfit,
      assetPath: 'assets/avatars/outfit_training.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      isDefault: true,
    ),
    Avatar(
      id: 'outfit_warrior',
      nameId: 'Armor Warrior',
      nameEn: 'Warrior Armor',
      category: AvatarCategory.outfit,
      assetPath: 'assets/avatars/outfit_warrior.png',
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF4F46E5),
      requiredLevel: 10,
    ),
    Avatar(
      id: 'outfit_dragon',
      nameId: 'Armor Naga',
      nameEn: 'Dragon Armor',
      category: AvatarCategory.outfit,
      assetPath: 'assets/avatars/outfit_dragon.png',
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
      requiredLevel: 20,
    ),
    Avatar(
      id: 'outfit_elite',
      nameId: 'Elite Suit',
      nameEn: 'Elite Suit',
      category: AvatarCategory.outfit,
      assetPath: 'assets/avatars/outfit_elite.png',
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFF59E0B),
      price: 2000,
      requiredLevel: 30,
    ),
    Avatar(
      id: 'outfit_legendary',
      nameId: 'Armor Legendaris',
      nameEn: 'Legendary Armor',
      category: AvatarCategory.outfit,
      assetPath: 'assets/avatars/outfit_legendary.png',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF7C3AED),
      price: 5000,
      requiredLevel: 50,
    ),
  ];

  // Accessories
  static const List<Avatar> accessoryAvatars = [
    Avatar(
      id: 'acc_none',
      nameId: 'Tanpa Aksesori',
      nameEn: 'No Accessory',
      category: AvatarCategory.accessory,
      assetPath: '',
      primaryColor: Colors.transparent,
      secondaryColor: Colors.transparent,
      isDefault: true,
    ),
    Avatar(
      id: 'acc_bandana',
      nameId: 'Bandana',
      nameEn: 'Bandana',
      category: AvatarCategory.accessory,
      assetPath: 'assets/avatars/acc_bandana.png',
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
      requiredLevel: 5,
    ),
    Avatar(
      id: 'acc_glasses',
      nameId: 'Kacamata',
      nameEn: 'Glasses',
      category: AvatarCategory.accessory,
      assetPath: 'assets/avatars/acc_glasses.png',
      primaryColor: Color(0xFF1F2937),
      secondaryColor: Color(0xFF374151),
      requiredLevel: 10,
    ),
    Avatar(
      id: 'acc_headband',
      nameId: 'Headband',
      nameEn: 'Headband',
      category: AvatarCategory.accessory,
      assetPath: 'assets/avatars/acc_headband.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      requiredLevel: 15,
    ),
    Avatar(
      id: 'acc_crown',
      nameId: 'Mahkota',
      nameEn: 'Crown',
      category: AvatarCategory.accessory,
      assetPath: 'assets/avatars/acc_crown.png',
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFF59E0B),
      price: 3000,
      requiredLevel: 40,
    ),
  ];

  // Auras (effects around avatar)
  static const List<Avatar> auraAvatars = [
    Avatar(
      id: 'aura_none',
      nameId: 'Tanpa Aura',
      nameEn: 'No Aura',
      category: AvatarCategory.aura,
      assetPath: '',
      primaryColor: Colors.transparent,
      secondaryColor: Colors.transparent,
      isDefault: true,
    ),
    Avatar(
      id: 'aura_green',
      nameId: 'Aura Hijau',
      nameEn: 'Green Aura',
      category: AvatarCategory.aura,
      assetPath: 'assets/avatars/aura_green.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      requiredLevel: 10,
    ),
    Avatar(
      id: 'aura_blue',
      nameId: 'Aura Biru',
      nameEn: 'Blue Aura',
      category: AvatarCategory.aura,
      assetPath: 'assets/avatars/aura_blue.png',
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF2563EB),
      requiredLevel: 20,
    ),
    Avatar(
      id: 'aura_gold',
      nameId: 'Aura Emas',
      nameEn: 'Gold Aura',
      category: AvatarCategory.aura,
      assetPath: 'assets/avatars/aura_gold.png',
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFF59E0B),
      price: 2000,
      requiredLevel: 30,
    ),
    Avatar(
      id: 'aura_purple',
      nameId: 'Aura Ungu',
      nameEn: 'Purple Aura',
      category: AvatarCategory.aura,
      assetPath: 'assets/avatars/aura_purple.png',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF7C3AED),
      price: 3000,
      requiredLevel: 40,
    ),
    Avatar(
      id: 'aura_legendary',
      nameId: 'Aura Legendaris',
      nameEn: 'Legendary Aura',
      category: AvatarCategory.aura,
      assetPath: 'assets/avatars/aura_legendary.png',
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFDB2777),
      price: 5000,
      requiredLevel: 50,
    ),
  ];

  // Achievement badges displayed on avatar
  static const List<Avatar> badgeAvatars = [
    Avatar(
      id: 'badge_none',
      nameId: 'Tanpa Lencana',
      nameEn: 'No Badge',
      category: AvatarCategory.badge,
      assetPath: '',
      primaryColor: Colors.transparent,
      secondaryColor: Colors.transparent,
      isDefault: true,
    ),
    Avatar(
      id: 'badge_first_quest',
      nameId: 'Quest Pertama',
      nameEn: 'First Quest',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_first.png',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      price: 0,
      requiredLevel: 1,
    ),
    Avatar(
      id: 'badge_streak_7',
      nameId: '7 Hari Streak',
      nameEn: '7 Day Streak',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_streak7.png',
      primaryColor: Color(0xFFF97316),
      secondaryColor: Color(0xFFEA580C),
      requiredLevel: 5,
    ),
    Avatar(
      id: 'badge_streak_30',
      nameId: '30 Hari Streak',
      nameEn: '30 Day Streak',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_streak30.png',
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
      requiredLevel: 15,
    ),
    Avatar(
      id: 'badge_level_10',
      nameId: 'Level 10',
      nameEn: 'Level 10',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_lv10.png',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF7C3AED),
      requiredLevel: 10,
    ),
    Avatar(
      id: 'badge_level_50',
      nameId: 'Level 50',
      nameEn: 'Level 50',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_lv50.png',
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFF59E0B),
      requiredLevel: 50,
    ),
    Avatar(
      id: 'badge_master',
      nameId: 'Master',
      nameEn: 'Master',
      category: AvatarCategory.badge,
      assetPath: 'assets/avatars/badge_master.png',
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFDB2777),
      price: 5000,
      requiredLevel: 75,
    ),
  ];

  // Get all avatars
  static List<Avatar> getAllAvatars() {
    return [
      ...baseAvatars,
      ...hairAvatars,
      ...eyeAvatars,
      ...outfitAvatars,
      ...accessoryAvatars,
      ...auraAvatars,
      ...badgeAvatars,
    ];
  }

  // Get avatars by category
  static List<Avatar> getAvatarsByCategory(AvatarCategory category) {
    switch (category) {
      case AvatarCategory.base:
        return baseAvatars;
      case AvatarCategory.hair:
        return hairAvatars;
      case AvatarCategory.eyes:
        return eyeAvatars;
      case AvatarCategory.outfit:
        return outfitAvatars;
      case AvatarCategory.accessory:
        return accessoryAvatars;
      case AvatarCategory.aura:
        return auraAvatars;
      case AvatarCategory.badge:
        return badgeAvatars;
    }
  }

  // Get avatar by ID
  static Avatar? getAvatarById(String id) {
    try {
      return getAllAvatars().firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get unlocked avatars based on level
  static List<Avatar> getUnlockedAvatars(int level) {
    return getAllAvatars().where((a) => a.requiredLevel <= level).toList();
  }

  // Check if avatar is unlocked
  static bool isAvatarUnlocked(Avatar avatar, int level, int exp) {
    if (avatar.requiredLevel > level) return false;
    // Could add exp-based unlocking here
    return true;
  }

  // Get all categories
  static List<AvatarCategory> getCategories() {
    return AvatarCategory.values;
  }
}

/// User's current avatar configuration
class UserAvatar {
  final String uid;
  String baseId;
  String hairId;
  String eyesId;
  String outfitId;
  String accessoryId;
  String auraId;
  List<String> unlockedBadgeIds;

  UserAvatar({
    required this.uid,
    this.baseId = 'base_light',
    this.hairId = 'hair_short',
    this.eyesId = 'eyes_normal',
    this.outfitId = 'outfit_training',
    this.accessoryId = 'acc_none',
    this.auraId = 'aura_none',
    List<String>? unlockedBadgeIds,
  }) : unlockedBadgeIds = unlockedBadgeIds ?? [];

  Avatar? get base => AvatarDatabase.getAvatarById(baseId);
  Avatar? get hair => AvatarDatabase.getAvatarById(hairId);
  Avatar? get eyes => AvatarDatabase.getAvatarById(eyesId);
  Avatar? get outfit => AvatarDatabase.getAvatarById(outfitId);
  Avatar? get accessory => AvatarDatabase.getAvatarById(accessoryId);
  Avatar? get aura => AvatarDatabase.getAvatarById(auraId);

  Map<String, dynamic> toMap() {
    return {
      'baseId': baseId,
      'hairId': hairId,
      'eyesId': eyesId,
      'outfitId': outfitId,
      'accessoryId': accessoryId,
      'auraId': auraId,
      'unlockedBadgeIds': unlockedBadgeIds,
    };
  }

  factory UserAvatar.fromMap(String uid, Map<String, dynamic> map) {
    return UserAvatar(
      uid: uid,
      baseId: map['baseId'] ?? 'base_light',
      hairId: map['hairId'] ?? 'hair_short',
      eyesId: map['eyesId'] ?? 'eyes_normal',
      outfitId: map['outfitId'] ?? 'outfit_training',
      accessoryId: map['accessoryId'] ?? 'acc_none',
      auraId: map['auraId'] ?? 'aura_none',
      unlockedBadgeIds: List<String>.from(map['unlockedBadgeIds'] ?? []),
    );
  }

  UserAvatar copyWith({
    String? baseId,
    String? hairId,
    String? eyesId,
    String? outfitId,
    String? accessoryId,
    String? auraId,
    List<String>? unlockedBadgeIds,
  }) {
    return UserAvatar(
      uid: uid,
      baseId: baseId ?? this.baseId,
      hairId: hairId ?? this.hairId,
      eyesId: eyesId ?? this.eyesId,
      outfitId: outfitId ?? this.outfitId,
      accessoryId: accessoryId ?? this.accessoryId,
      auraId: auraId ?? this.auraId,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
    );
  }
}
