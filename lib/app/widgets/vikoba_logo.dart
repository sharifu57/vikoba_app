import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vikoba_app/app/constants/app_colors.dart';

class VikobaLogo extends StatelessWidget {
  const VikobaLogo({
    super.key,
    this.size = 64,
    this.onDark = false,
    this.showName = false,
    this.nameSize = 20,
  });

  final double size;
  final bool onDark;
  final bool showName;
  final double nameSize;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: .1)
            : AppColors.primary.withValues(alpha: .08),
        shape: BoxShape.circle,
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: .2)
              : AppColors.primary.withValues(alpha: .16),
          width: size * .011,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: onDark ? .08 : .12),
            blurRadius: size * .16,
            offset: Offset(0, size * .06),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size.w * .68,
          height: size.w * .68,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hub_rounded,
            size: size.sp * .39,
            color: AppColors.primary,
          ),
        ),
      ),
    );

    if (!showName) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: 10.w),
        Text(
          'Vikoba 360',
          style: TextStyle(
            color: onDark ? Colors.white : AppColors.primary,
            fontSize: nameSize.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
      ],
    );
  }
}
