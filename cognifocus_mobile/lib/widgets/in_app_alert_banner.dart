import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import '../models/alert_model.dart';

/// InAppAlertBanner: Floating Claymorphism banner displayed when a new alert occurs
class InAppAlertBanner extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  const InAppAlertBanner({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 7),
  });

  @override
  State<InAppAlertBanner> createState() => _InAppAlertBannerState();
}

class _InAppAlertBannerState extends State<InAppAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.autoDismissDuration, () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;
    final alert = widget.alert;

    final classroomStr = (alert.classroomId != null && alert.classroomId!.isNotEmpty)
        ? 'Classroom: ${alert.classroomId}'
        : 'Classroom: Active Room';
    final seatStr = (alert.seatId != null && alert.seatId!.isNotEmpty)
        ? 'Seat: ${alert.seatId}'
        : 'Camera: ${alert.cameraId}';
    final durationStr = alert.duration.isNotEmpty
        ? ' • Dur: ${alert.duration}'
        : '';

    return SafeArea(
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _dismissTimer?.cancel();
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: ClayStyles.raised(
                    color: isDark ? const Color(0xFF241C2B) : const Color(0xFFFFF4F2),
                    radius: 18,
                    depth: 6,
                    border: Border.all(
                      color: palette.softCoral.withOpacity(0.6),
                      width: 1.5,
                    ),
                    isDark: isDark,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: palette.softCoral.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smartphone_rounded,
                          color: palette.softCoral,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.alertType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.softCoral,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    alert.severity.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$classroomStr • $seatStr$durationStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View action button
                      InkWell(
                        onTap: () {
                          _dismissTimer?.cancel();
                          widget.onTap();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: palette.textMuted,
                        ),
                        onPressed: _dismissWithAnimation,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
