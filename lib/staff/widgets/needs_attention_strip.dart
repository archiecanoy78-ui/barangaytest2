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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PortalColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_rounded, color: PortalColors.danger, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Needs Attention',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PortalColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Priority follow-ups and action items requiring a response this week.',
                  style: const TextStyle(fontSize: 12, color: PortalColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: items.map((item) {
              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.color.withOpacity(0.18)),
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
                        style: TextStyle(color: item.color, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(color: item.color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
