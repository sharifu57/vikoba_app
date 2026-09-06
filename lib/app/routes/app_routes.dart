import 'package:get/get.dart';
import 'package:vikoba_app/features/splash/presentation/splash_binding.dart';
import 'package:vikoba_app/features/splash/presentation/splash_page.dart';
import 'package:vikoba_app/features/welcome/presentation/welcome_page.dart';
import 'package:vikoba_app/features/auth/presentation/auth_binding.dart';
import 'package:vikoba_app/features/auth/presentation/auth_page.dart';
import 'package:vikoba_app/features/member/presentation/member_binding.dart';
import 'package:vikoba_app/features/member/presentation/member_page.dart';

class AppRoutes {
  AppRoutes._();

  static final pages = <GetPage>[
    GetPage(
      name: '/splash',
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(name: '/welcome', page: () => const WelcomePage()),
    GetPage(
      name: '/login',
      page: () => const AuthPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/member',
      page: () => const MemberPage(),
      binding: MemberBinding(),
    ),
  ];
}
