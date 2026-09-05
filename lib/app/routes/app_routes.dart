import 'package:get/get.dart';
import 'package:vikoba_app/features/splash/presentation/splash_binding.dart';
import 'package:vikoba_app/features/splash/presentation/splash_page.dart';
import 'package:vikoba_app/features/welcome/presentation/welcome_page.dart';

class AppRoutes {
  AppRoutes._();

  static final pages = <GetPage>[
    GetPage(
      name: '/splash',
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(name: '/welcome', page: () => const WelcomePage()),
  ];
}
