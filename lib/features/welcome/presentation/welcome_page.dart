import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/app/widgets/vikoba_logo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const _background = Color(0xFFFAF8F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(
              constraints.maxHeight,
              760 * math.max(1, MediaQuery.textScalerOf(context).scale(1)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/welcome_community.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                  errorBuilder: (_, error, stackTrace) =>
                      const ColoredBox(color: _background),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .15, .43, .66, .82, 1],
                      colors: [
                        Color(0x99FAF8F2),
                        Color(0x00FAF8F2),
                        Color(0x00FAF8F2),
                        Color(0xE6FAF8F2),
                        _background,
                        _background,
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VikobaLogo(
                          size: 42,
                          showName: true,
                          nameSize: 19,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4EDE3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'SAVE. GROW. TOGETHER.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your group.\nYour shared future.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 34,
                            height: 1.1,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Buy shares, plan your next step and grow with the people you trust.',
                          style: TextStyle(
                            color: Color(0xFF526459),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Get.toNamed('/login'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Get started',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, size: 21),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Your financial circle, made visible.',
                            style: TextStyle(
                              color: Color(0xFF526459),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
