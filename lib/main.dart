import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vikoba_app/app/constants/app_theme.dart';
import 'package:vikoba_app/app/routes/app_routes.dart';
import 'package:vikoba_app/config/app_client.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);
  await AppClient.init();
  final darkThemeEnabled = await TokenStorage.getDarkTheme();

  runApp(MyApp(darkThemeEnabled: darkThemeEnabled));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.darkThemeEnabled, super.key});

  final bool darkThemeEnabled;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),

      minTextAdapt: true,

      splitScreenMode: true,

      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vikoba 360',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: darkThemeEnabled ? ThemeMode.dark : ThemeMode.light,
          defaultTransition: Transition.fade,
          initialRoute: '/splash',
          getPages: AppRoutes.pages,
        );
      },
    );
  }
}
