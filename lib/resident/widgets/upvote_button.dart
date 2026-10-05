import 'package:flutter/material.dart';

/// Reusable upvote button widget with optimistic state toggle, WCAG contrast,
/// and a minimum 44x44px touch target area.
class UpvoteButton extends StatelessWidget {
  final int count;
  final bool isUpvoted;
  final VoidCallback onTap;
  final bool isLoading;

  const UpvoteButton({
    super.key,
    required this.count,
    required this.isUpvoted,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1D4ED8); // Reference Primary Blue
    final inactiveBg = const Color(0xFFF1F5F9);
    final inactiveFg = const Color(0xFF475569);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isUpvoted ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUpvoted ? activeColor : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: isUpvoted
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUpvoted ? Colors.white : activeColor,
                  ),
                ),
              )
            else
              Icon(
                isUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                size: 16,
                color: isUpvoted ? Colors.white : inactiveFg,
              ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isUpvoted ? Colors.white : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
