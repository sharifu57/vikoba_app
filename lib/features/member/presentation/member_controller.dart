import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:vikoba_app/config/app_client.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';
import 'package:vikoba_app/features/member/data/member_dashboard_api.dart';

class MemberController extends GetxController {
  late final MemberDashboardApi _api;
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final groupName = 'Vikoba group'.obs;
  final currency = 'TZS'.obs;
  final overview = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _api = MemberDashboardApi(AppClient.dio);
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final groupId = await TokenStorage.getCurrentGroupId();
      groupName.value = await TokenStorage.getCurrentGroupName();
      currency.value = await TokenStorage.getCurrentGroupCurrency();
      if (groupId == null || groupId <= 0) {
        throw Exception('No group is linked to this member account.');
      }
      overview.assignAll(await _api.getOverview(groupId));
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
      return 'We could not load your group dashboard.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Map<String, dynamic> get summary => _map(overview['summary']);
  Map<String, dynamic> get finance => _map(overview['finance']);
  Map<String, dynamic> get actions => _map(overview['actions']);
  List<Map<String, dynamic>> get contributionTrend =>
      _list(overview['contributionTrend']);
  List<Map<String, dynamic>> get activities =>
      _list(overview['recentActivities']);
  List<Map<String, dynamic>> get meetings => _list(overview['nextMeetings']);

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}
