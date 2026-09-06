import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  @override
  void onInit() {
    super.onInit();
    _api = AuthApiClient(AppClient.dio);
  }

  Future<void> requestOtp() async {
    final normalized = _normalizePhone(phoneController.text);
    if (normalized == null) {
      errorMessage.value = 'Enter 9 digits after the 255 prefix.';
      return;
    }

    await _run(() async {
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
  }

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      errorMessage.value = 'Enter the 6-digit code sent to your phone.';
      return;
    }

    await _run(() async {
      final response = await _api.verifyOtp(phone: phone.value, code: code);
      final success = response['status'] == true;
      if (!success) {
        throw Exception(response['message'] ?? 'Unable to verify OTP.');
      }
      await TokenStorage.saveSession(response);
      await TokenStorage.navigateAfterLogin();
    });
  }

  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0 || phone.value.isEmpty) {
      return;
    }
    isResending.value = true;
    errorMessage.value = null;
    try {
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
    _countdown?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
