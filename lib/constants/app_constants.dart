import 'package:flutter/material.dart';

class CategoryItem {
  final String key;
  final String displayName;
  final IconData icon;

  const CategoryItem({
    required this.key,
    required this.displayName,
    required this.icon,
  });
}

class AppConstants {
  static const List<CategoryItem> categoryItems = [
    CategoryItem(
      key: 'noise_complaint',
      displayName: 'Noise Complaint',
      icon: Icons.volume_up_outlined,
    ),
    CategoryItem(
      key: 'waste_management',
      displayName: 'Waste Management',
      icon: Icons.delete_outline_rounded,
    ),
    CategoryItem(
      key: 'road_infrastructure',
      displayName: 'Road / Infrastructure',
      icon: Icons.add_road_rounded,
    ),
    CategoryItem(
      key: 'drainage',
      displayName: 'Drainage / Flooding',
      icon: Icons.water_damage_outlined,
    ),
    CategoryItem(
      key: 'street_lighting',
      displayName: 'Street Lighting',
      icon: Icons.lightbulb_outline_rounded,
    ),
    CategoryItem(
      key: 'public_safety',
      displayName: 'Public Safety',
      icon: Icons.shield_outlined,
    ),
    CategoryItem(
      key: 'animal_concern',
      displayName: 'Animal Concern',
      icon: Icons.pets_outlined,
    ),
    CategoryItem(
      key: 'neighborhood_dispute',
      displayName: 'Neighborhood Dispute',
      icon: Icons.handshake_outlined,
    ),
    CategoryItem(
      key: 'emergency',
      displayName: 'Emergency / SOS',
      icon: Icons.crisis_alert_rounded,
    ),
    CategoryItem(
      key: 'other',
      displayName: 'Other / General',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  static List<String> get categories =>
      categoryItems.map((c) => c.displayName).toList();

  static const List<String> purokOptions = [
    'Purok 1',
    'Purok 2',
    'Purok 3',
    'Purok 4',
    'Purok 5',
    'Purok 6',
  ];

  /// Normalizes legacy or mismatched category inputs to a canonical Display Name
  static String normalizeCategory(String input) {
    if (input.trim().isEmpty) return 'Other / General';
    final cleaned = input.trim().toLowerCase();

    if (cleaned.contains('noise') || cleaned.contains('disturbance')) {
      return 'Noise Complaint';
    }
    if (cleaned.contains('waste') || cleaned.contains('garbage') || cleaned.contains('trash')) {
      return 'Waste Management';
    }
    if (cleaned.contains('road') || cleaned.contains('infra')) {
      return 'Road / Infrastructure';
    }
    if (cleaned.contains('drain') || cleaned.contains('flood')) {
      return 'Drainage / Flooding';
    }
    if (cleaned.contains('light')) {
      return 'Street Lighting';
    }
    if (cleaned.contains('safety') || cleaned.contains('security') || cleaned.contains('patrol')) {
      return 'Public Safety';
    }
    if (cleaned.contains('animal') || cleaned.contains('dog') || cleaned.contains('pet')) {
      return 'Animal Concern';
    }
    if (cleaned.contains('dispute') || cleaned.contains('neighbor')) {
      return 'Neighborhood Dispute';
    }
    if (cleaned.contains('emergency') || cleaned.contains('sos') || cleaned.contains('urgent')) {
      return 'Emergency / SOS';
    }

    // Try direct match with display names
    for (final item in categoryItems) {
      if (item.displayName.toLowerCase() == cleaned || item.key.toLowerCase() == cleaned) {
        return item.displayName;
      }
    }

    return input.trim();
  }

  /// Normalizes legacy purok inputs (e.g., 'purok 2', '2', 'Purok 02') to 'Purok X'
  static String normalizePurok(String input) {
    if (input.trim().isEmpty) return 'Purok 1';
    final cleaned = input.trim().toLowerCase();

    final match = RegExp(r'\d+').firstMatch(cleaned);
    if (match != null) {
      final numberStr = match.group(0)!;
      final num = int.tryParse(numberStr);
      if (num != null && num >= 1 && num <= 6) {
        return 'Purok $num';
      }
    }

    for (final p in purokOptions) {
      if (p.toLowerCase() == cleaned) return p;
    }

    return input.trim();
  }
}
