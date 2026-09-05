import 'dart:async';

import 'package:get/get.dart';

class SplashController extends GetxController {
  final progress = 0.0.obs;
  final reveal = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    reveal.value = true;
    const total = 2600;
    const tick = 40;
    var elapsed = 0;

    _timer = Timer.periodic(const Duration(milliseconds: tick), (timer) {
      elapsed += tick;
      progress.value = (elapsed / total).clamp(0.0, 1.0);
      if (elapsed >= total) {
        timer.cancel();
        Get.offNamed('/welcome');
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
