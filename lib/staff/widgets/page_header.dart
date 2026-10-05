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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 28,
            isMobile ? 16 : 22,
            isMobile ? 16 : 28,
            isMobile ? 16 : 18,
          ),
          decoration: const BoxDecoration(
            color: PortalColors.surface,
            border: Border(bottom: BorderSide(color: PortalColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breadcrumbs Row
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
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
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right_rounded, size: 14, color: PortalColors.textMuted),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 8),

              if (isMobile) ...[
                // Mobile Stacked Layout
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PortalColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PortalColors.textMuted,
                    height: 1.4,
                  ),
                ),
                if (actionButton != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: actionButton!,
                  ),
                ],
              ] else ...[
                // Desktop / Tablet Horizontal Layout
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
                              fontWeight: FontWeight.w800,
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
                    if (actionButton != null) ...[
                      const SizedBox(width: 16),
                      actionButton!,
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
