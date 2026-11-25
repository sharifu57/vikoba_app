import 'package:get/get.dart';

import 'member_controller.dart';

class MemberBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MemberController>()) {
      Get.lazyPut<MemberController>(MemberController.new, fenix: true);
    }
  }
}
