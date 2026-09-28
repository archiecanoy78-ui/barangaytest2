import 'package:flutter/material.dart';

/// Standardized badge/pill widget used across the Barangay Admin Web Portal.
/// Guarantees consistent typography, padding, border radius, and WCAG contrast.
class BadgePill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;

  const BadgePill({
    super.key,
    required this.text,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.iconColor,
  });

  /// Factory for 'Assigned' status badge
  factory BadgePill.assigned({String? staffName}) {
    return BadgePill(
      text: staffName ?? 'Assigned Staff',
      icon: Icons.how_to_reg_rounded,
      backgroundColor: const Color(0xFFDCFCE7), // Light green
      textColor: const Color(0xFF15803D), // Dark green
    );
  }

  /// Factory for 'Unassigned' status badge
  factory BadgePill.unassigned() {
    return const BadgePill(
      text: 'Unassigned',
      icon: Icons.person_off_rounded,
      backgroundColor: Color(0xFFFEE2E2), // Light red/coral
      textColor: Color(0xFF991B1B), // Dark red
    );
  }

  /// Factory for Announcement Priority badges
  factory BadgePill.priority(String priority) {
    final normalized = priority.trim().toLowerCase();
    if (normalized == 'high') {
      return const BadgePill(
        text: 'High',
        icon: Icons.priority_high_rounded,
        backgroundColor: Color(0xFFFEE2E2), // Light red/coral
        textColor: Color(0xFF991B1B), // Dark red
      );
    } else if (normalized == 'low') {
      return const BadgePill(
        text: 'Low',
        icon: Icons.arrow_downward_rounded,
        backgroundColor: Color(0xFFF1F5F9), // Light gray
        textColor: Color(0xFF475569), // Dark slate gray
      );
    } else {
      // Medium / Normal
      final label = priority.isEmpty ? 'Medium' : priority;
      return BadgePill(
        text: label,
        icon: Icons.remove_rounded,
        backgroundColor: const Color(0xFFFEF3C7), // Light amber
        textColor: const Color(0xFFB45309), // Dark amber
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: iconColor ?? textColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
