import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';

/// VIKOBA's community-circle loader. Use size 18?24 in buttons, 48?64 on pages.
class VikobaLoader extends StatefulWidget {
  const VikobaLoader({
    super.key,
    this.size = 48,
    this.color,
    this.onDark = false,
    this.label = 'Loading',
    this.value,
  }) : assert(size > 0),
       assert(value == null || (value >= 0 && value <= 1));

  final double size;
  final Color? color;
  final bool onDark;
  final String label;

  /// Optional progress for accessibility, e.g. splash initialization.
  final double? value;

  @override
  State<VikobaLoader> createState() => _VikobaLoaderState();
}

class _VikobaLoaderState extends State<VikobaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        widget.onDark || Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: widget.label,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
              painter: _CirclePainter(
                motion: _motion,
                color:
                    widget.color ??
                    (dark ? const Color(0xFF9CDDC1) : AppColors.primary),
                accent: widget.color ?? AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.motion,
    required this.color,
    required this.accent,
  }) : super(repaint: motion);
  final Animation<double> motion;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final phase = motion.value * math.pi * 2;
    final pulse = (math.sin(phase) + 1) / 2;
    final paint = Paint()..isAntiAlias = true;
    canvas.drawCircle(
      center,
      side * (.18 + .025 * pulse),
      paint..color = color.withValues(alpha: .10),
    );
    canvas.drawCircle(
      center,
      side * (.085 + .012 * pulse),
      paint..color = color,
    );
    for (var i = 0; i < 6; i++) {
      final angle = phase + i * math.pi / 3 - math.pi / 2;
      final wave = (math.cos(phase - i * math.pi / 3) + 1) / 2;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * side * .35;
      paint
        ..color = color.withValues(alpha: .08 + .09 * wave)
        ..strokeWidth = side * .025;
      canvas.drawLine(center, point, paint);
      paint.color = (i.isEven ? color : accent).withValues(
        alpha: .45 + .55 * wave,
      );
      canvas.drawCircle(point, side * (.047 + .025 * wave), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.accent != accent ||
      oldDelegate.motion != motion;
}

/// Pull-to-refresh using the same community-circle animation as the rest of the app.
class VikobaRefreshIndicator extends StatefulWidget {
  const VikobaRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<VikobaRefreshIndicator> createState() => _VikobaRefreshIndicatorState();
}

class _VikobaRefreshIndicatorState extends State<VikobaRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      RefreshIndicator.noSpinner(
        onRefresh: widget.onRefresh,
        onStatusChange: (status) {
          if (mounted) setState(() => _status = status);
        },
        child: widget.child,
      ),
      if (_status != null &&
          _status != RefreshIndicatorStatus.done &&
          _status != RefreshIndicatorStatus.canceled)
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Material(
                elevation: 3,
                shadowColor: Colors.black26,
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: VikobaLoader(size: 32, label: 'Refreshing'),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
