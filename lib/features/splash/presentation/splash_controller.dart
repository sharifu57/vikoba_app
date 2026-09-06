import 'dart:async';

import 'package:get/get.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

class SplashController extends GetxController {
  final progress = 0.0.obs;
  final reveal = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    reveal.value = true;
    const total = 2200;
    const tick = 30;
    var elapsed = 0;

    _timer = Timer.periodic(const Duration(milliseconds: tick), (timer) {
      elapsed += tick;
      progress.value = (elapsed / total).clamp(0.0, 1.0);
      if (elapsed >= total) {
        timer.cancel();
        _redirect();
      }
    });
  }

  Future<void> _redirect() async {
    final isLoggedIn = await TokenStorage.isLoggedIn();
    final isExpired = await TokenStorage.isAccessTokenExpired();

    if (isLoggedIn && !isExpired) {
      Get.offAllNamed('/member');
      return;
    }

    if (isLoggedIn && isExpired) {
      await TokenStorage.clear();
    }

    Get.offAllNamed('/welcome');
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
