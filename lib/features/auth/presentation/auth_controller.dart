import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'otp_input.dart';
import 'package:get/get.dart';

import 'package:vikoba_app/config/app_client.dart';
import 'package:vikoba_app/features/auth/data/auth_api.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

class AuthController extends GetxController {
  late final AuthApiClient _api;
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final isLoading = false.obs;
  final isResending = false.obs;
  final errorMessage = RxnString();
  final phone = ''.obs;
  final secondsRemaining = 0.obs;
  final otpSent = false.obs;
  Timer? _countdown;
  static const _smsChannel = MethodChannel('vikoba/otp_sms');
  bool _acceptSms = false;
  final codeHint = RxnString();

  Future<void> _listenForCode() async {
    _acceptSms = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _smsChannel.setMethodCallHandler((call) async {
      if (call.method != 'sms' || !_acceptSms || isClosed) return;
      final message = call.arguments?.toString() ?? '';
      if (!message.toUpperCase().contains('VIKOBA360')) return;
      final code = extractOtp(message);
      if (code != null) {
        _fillCode(code, 'Code filled from SMS. Tap Verify and continue.');
      }
    });
    try {
      await _smsChannel
          .invokeMethod<bool>('start')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Keyboard autofill, paste and manual entry remain available.
    }
  }

  Future<void> _stopListening() async {
    _acceptSms = false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _smsChannel.setMethodCallHandler(null);
    try {
      await _smsChannel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  void _fillCode(String code, String message) {
    otpController.value = TextEditingValue(
      text: code,
      selection: const TextSelection.collapsed(offset: 6),
    );
    errorMessage.value = null;
    codeHint.value = message;
  }

  Future<void> pasteCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (isClosed || !otpSent.value) return;
      final code = extractOtp(data?.text ?? '');
      if (code == null) {
        errorMessage.value =
            'Copy the 6-digit code or its SMS, then tap Paste code.';
        return;
      }
      _fillCode(code, 'Code pasted. Tap Verify and continue.');
    } catch (_) {
      if (!isClosed) {
        errorMessage.value =
            'Unable to paste. Touch and hold the code field to paste, or type the code.';
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _api = AuthApiClient(AppClient.dio);
  }

  Future<void> requestOtp() async {
    if (isLoading.value || isResending.value) return;
    final normalized = _normalizePhone(phoneController.text);
    if (normalized == null) {
      errorMessage.value = 'Enter 9 digits after the 255 prefix.';
      return;
    }

    await _run(() async {
      otpController.clear();
      codeHint.value = null;
      await _listenForCode();
      final response = await _api.requestOtp(normalized);
      if (response['status'] != true) {
        throw Exception(
          response['message'] ?? 'This phone number cannot log in yet.',
        );
      }
      phone.value = normalized;
      otpSent.value = true;
      _startCountdown();
    });
    if (!otpSent.value) await _stopListening();
  }

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      errorMessage.value = 'Enter the 6-digit code sent to your phone.';
      return;
    }

    await _run(() async {
      final response = await _api.verifyOtp(phone: phone.value, code: code);
      final success = response['status'] == true;
      if (!success) {
        throw Exception(response['message'] ?? 'Unable to verify OTP.');
      }
      await _stopListening();
      TextInput.finishAutofillContext(shouldSave: false);
      await TokenStorage.saveSession(response);
      await TokenStorage.navigateAfterLogin();
    });
  }

  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0 ||
        phone.value.isEmpty ||
        isResending.value ||
        isLoading.value) {
      return;
    }
    isResending.value = true;
    errorMessage.value = null;
    try {
      otpController.clear();
      codeHint.value = null;
      await _listenForCode();
      final response = await _api.resendOtp(phone.value);
      if (response['status'] != true) {
        throw Exception(response['message'] ?? 'Unable to resend OTP.');
      }
      _startCountdown();
    } catch (error) {
      errorMessage.value = _message(error);
    } finally {
      isResending.value = false;
    }
  }

  void changeNumber() {
    if (isLoading.value || isResending.value) return;
    unawaited(_stopListening());
    codeHint.value = null;
    otpSent.value = false;
    otpController.clear();
    errorMessage.value = null;
    _countdown?.cancel();
  }

  String? _normalizePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final fullNumber = cleaned.startsWith('255') ? cleaned : '255$cleaned';
    if (!RegExp(r'^255[67][0-9]{8}$').hasMatch(fullNumber)) {
      return null;
    }
    return fullNumber;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading.value || isResending.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await action();
    } catch (error) {
      errorMessage.value = _message(error);
    } finally {
      isLoading.value = false;
    }
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'We could not reach Vikoba. Check your connection and try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _startCountdown() {
    _countdown?.cancel();
    secondsRemaining.value = 45;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        secondsRemaining.value = 0;
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }

  @override
  void onClose() {
    unawaited(_stopListening());
    _countdown?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
