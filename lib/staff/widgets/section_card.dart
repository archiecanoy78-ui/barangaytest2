import 'package:flutter/material.dart';
import 'portal_theme.dart';

/// Reusable Section Container Card for the Barangay Admin Web Portal.
/// Handles standard card styling, header, subtitle, action widgets, and content body.
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.headerAction,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PortalColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PortalColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PortalColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) ...[
                  const SizedBox(width: 12),
                  headerAction!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: PortalColors.border),

          // Body Content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
