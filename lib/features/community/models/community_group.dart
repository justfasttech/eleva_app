import 'package:flutter/material.dart';

class CommunityGroup {
  final String id;
  final String creatorId;
  final String name;
  final String description;
  final String iconName;
  final int membersCount;
  final DateTime createdAt;

  const CommunityGroup({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.description,
    required this.iconName,
    required this.membersCount,
    required this.createdAt,
  });

  factory CommunityGroup.fromMap(Map<String, dynamic> map) {
    return CommunityGroup(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'groups_rounded',
      membersCount: map['members_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'icon_name': iconName,
    };
  }

  static const iconMap = <String, IconData>{
    'wb_sunny_rounded': Icons.wb_sunny_rounded,
    'nightlight_rounded': Icons.nightlight_rounded,
    'menu_book_rounded': Icons.menu_book_rounded,
    'spa_rounded': Icons.spa_rounded,
    'people_rounded': Icons.people_rounded,
    'quiz_rounded': Icons.quiz_rounded,
    'settings_rounded': Icons.settings_rounded,
    'groups_rounded': Icons.groups_rounded,
    'favorite_rounded': Icons.favorite_rounded,
    'church_rounded': Icons.church_rounded,
  };

  IconData get icon => iconMap[iconName] ?? Icons.groups_rounded;
}
