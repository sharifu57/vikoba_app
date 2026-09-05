import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/app/constants/app_strings.dart';
import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF124A3B), Color(0xFF082D24)],
          ),
        ),
        child: Stack(
          children: [
            const _BackgroundTexture(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 26.h),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        '360° GROUP FINANCE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .62),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => AnimatedOpacity(
                        opacity: controller.reveal.value ? 1 : 0,
                        duration: const Duration(milliseconds: 700),
                        child: const _BrandMark(),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    SizedBox(height: 9.h),
                    Text(
                      'Together, we grow further.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .2,
                      ),
                    ),
                    SizedBox(height: 52.h),
                    SizedBox(
                      width: 132.w,
                      child: Obx(
                        () => ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: LinearProgressIndicator(
                            minHeight: 4.h,
                            value: controller.progress.value,
                            backgroundColor: Colors.white.withValues(
                              alpha: .16,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 13.h),
                    Text(
                      'Preparing your circle',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .5),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'SMARTER GROUPS  •  STRONGER COMMUNITIES',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .42),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112.w,
      height: 112.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: .2),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Container(
          width: 76.w,
          height: 76.w,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hub_rounded, size: 43.sp, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _BackgroundTexture extends StatelessWidget {
  const _BackgroundTexture();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90.h,
            right: -70.w,
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80.h,
            left: -80.w,
            child: Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
