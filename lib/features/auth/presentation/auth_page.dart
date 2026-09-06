import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/app/widgets/vikoba_logo.dart';
import 'auth_controller.dart';

class AuthPage extends GetView<AuthController> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VikobaLogo(size: 48, showName: true, nameSize: 19),
              SizedBox(height: 54.h),
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: controller.otpSent.value
                      ? const _OtpStep()
                      : const _PhoneStep(),
                ),
              ),
              SizedBox(height: 28.h),
              Obx(
                () => controller.errorMessage.value == null
                    ? const SizedBox.shrink()
                    : _ErrorBanner(message: controller.errorMessage.value!),
              ),
              SizedBox(height: 30.h),
              Center(
                child: Text(
                  'Secure access for your financial circle.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends GetView<AuthController> {
  const _PhoneStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: 'WELCOME BACK'),
        SizedBox(height: 12.h),
        Text(
          'Your circle is\nwaiting for you.',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 34.sp,
            height: 1.06,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Enter your phone number and we will send a secure one-time code.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
            height: 1.45,
          ),
        ),
        SizedBox(height: 34.h),
        Text('Phone number', style: _labelStyle),
        SizedBox(height: 8.h),
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '700 000 000',
            prefixText: '255 ',
            prefixIcon: Icon(Icons.phone_outlined),
            counterText: 'Tanzania mobile number',
          ),
          onSubmitted: (_) => controller.requestOtp(),
        ),
        SizedBox(height: 20.h),
        _ActionButton(
          label: 'Send verification code',
          icon: Icons.arrow_forward_rounded,
          onPressed: controller.requestOtp,
          loading: controller.isLoading,
        ),
      ],
    );
  }
}

class _OtpStep extends GetView<AuthController> {
  const _OtpStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: 'VERIFY YOUR NUMBER'),
        SizedBox(height: 12.h),
        Text(
          'One small step\ninto your circle.',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 34.sp,
            height: 1.06,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 16.h),
        Obx(
          () => Text(
            'We sent a 6-digit code to ${controller.phone.value}.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
              height: 1.45,
            ),
          ),
        ),
        SizedBox(height: 34.h),
        Text('Verification code', style: _labelStyle),
        SizedBox(height: 8.h),
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
          onSubmitted: (_) => controller.verifyOtp(),
        ),
        SizedBox(height: 20.h),
        _ActionButton(
          label: 'Verify and continue',
          icon: Icons.lock_open_rounded,
          onPressed: controller.verifyOtp,
          loading: controller.isLoading,
        ),
        SizedBox(height: 18.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => TextButton(
                onPressed:
                    controller.secondsRemaining.value == 0 &&
                        !controller.isResending.value
                    ? controller.resendOtp
                    : null,
                child: Text(
                  controller.secondsRemaining.value == 0
                      ? 'Resend code'
                      : 'Resend in ${controller.secondsRemaining.value}s',
                ),
              ),
            ),
            Container(width: 1, height: 16, color: AppColors.border),
            TextButton(
              onPressed: controller.changeNumber,
              child: const Text('Change number'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.secondary,
        fontSize: 10.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.loading,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final RxBool loading;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56.h,
        child: FilledButton.icon(
          onPressed: loading.value ? null : onPressed,
          icon: loading.value
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.secondary.withValues(alpha: .6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _labelStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 12.sp,
  fontWeight: FontWeight.w800,
);
