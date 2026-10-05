import 'package:flutter/material.dart';
import 'portal_theme.dart';

class NeedsAttentionItem {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  NeedsAttentionItem({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });
}

class NeedsAttentionStrip extends StatelessWidget {
  final List<NeedsAttentionItem> items;

  const NeedsAttentionStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PortalColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 768;

          Widget headerSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PortalColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PortalColors.dangerBorder.withOpacity(0.5)),
                ),
                child: const Icon(Icons.insights_rounded, color: PortalColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Needs Attention',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: PortalColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Priority follow-ups requiring prompt barangay staff action.',
                      style: TextStyle(
                        fontSize: 12,
                        color: PortalColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          Widget chipsSection = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              return Tooltip(
                message: '${item.count} ${item.label} incidents requiring attention',
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(12),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(minHeight: 38),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.color.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.count}',
                          style: TextStyle(
                            color: item.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: item.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );

          if (isNarrow) {
            // Stack vertically on narrow containers/mobile/tablet
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                headerSection,
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: chipsSection,
                ),
              ],
            );
          } else {
            // Horizontal layout on wide desktop containers
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: headerSection,
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: chipsSection,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
