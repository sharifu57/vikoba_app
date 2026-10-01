import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoba_app/config/app_client.dart';
import 'package:vikoba_app/features/auth/presentation/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vikoba/otp_sms');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test(
    'listener starts before SMS request; paste preserves zeros and change number stops listener',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      dotenv.loadFromString(envString: 'API_URL=https://example.test');
      final events = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        events.add(call.method);
        return call.method == 'start' ? true : null;
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return {
            'text':
                'VIKOBA360 verification code: 001234\nExpires in 5 minutes.',
          };
        }
        return null;
      });
      AppClient.dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              events.add('request');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'status': true},
                ),
              );
            },
          ),
        );
      final controller = AuthController()..onInit();
      try {
        controller.phoneController.text = '712345678';
        await controller.requestOtp();
        expect(events.take(2), ['start', 'request']);
        expect(controller.otpSent.value, isTrue);
        await controller.pasteCode();
        expect(controller.otpController.text, '001234');
        expect(events.where((event) => event == 'request'), hasLength(1));
        controller.changeNumber();
        await Future<void>.delayed(Duration.zero);
        expect(controller.otpController.text, isEmpty);
        expect(events.last, 'stop');
      } finally {
        controller.onClose();
        await Future<void>.delayed(Duration.zero);
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
