import 'package:flutter/material.dart';
import 'portal_theme.dart';

/// Reusable metric stat card widget for the Barangay Admin Web Portal.
/// Designed for high readability, responsive bounds, and zero horizontal overflows.
class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final List<Color> colors;
  final bool positive;
  final String? tooltip;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.colors,
    this.positive = true,
    this.tooltip,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.positive ? PortalColors.successBg : PortalColors.warningBg;
    final deltaColor = widget.positive ? PortalColors.successText : PortalColors.warningText;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered ? widget.colors.first.withOpacity(0.5) : PortalColors.border,
          width: _isHovered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isHovered ? widget.colors.first.withOpacity(0.08) : const Color(0x0A000000),
            blurRadius: _isHovered ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Icon Box + Delta Pill (Flexible bounds)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: glow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.positive ? PortalColors.successBorder : PortalColors.warningBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.delta,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Count Value
          Text(
            widget.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: PortalColors.textDark,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          // Title Label with 2-line Wrapping
          SizedBox(
            height: 36, // Guarantees consistent height for 1 or 2 lines
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PortalColors.textMuted,
                  height: 1.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Sparkline Painter
          SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniSparklinePainter(
                values: List.generate(
                  8,
                  (index) => (index + 1) * (index.isEven ? 0.8 : 1.2) + (widget.positive ? 0.2 : 0.0),
                ),
                color: widget.colors.first,
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      cardContent = Tooltip(
        message: widget.tooltip!,
        child: cardContent,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: cardContent,
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _MiniSparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final path = Path();
    final max = values.reduce((a, b) => a > b ? a : b).clamp(0.1, double.infinity);
    final min = values.reduce((a, b) => a < b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / span) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
