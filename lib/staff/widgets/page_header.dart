import 'package:flutter/material.dart';
import 'portal_theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String description;
  final List<String> breadcrumbs;
  final Widget? actionButton;

  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    required this.breadcrumbs,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: const BoxDecoration(
        color: PortalColors.surface,
        border: Border(bottom: BorderSide(color: PortalColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < breadcrumbs.length; i++) ...[
                Text(
                  breadcrumbs[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: i == breadcrumbs.length - 1 ? PortalColors.primary : PortalColors.textMuted,
                    fontWeight: i == breadcrumbs.length - 1 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (i < breadcrumbs.length - 1) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded, size: 14, color: PortalColors.textMuted),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: PortalColors.textDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PortalColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionButton != null) actionButton!,
            ],
          ),
        ],
      ),
    );
  }
}
