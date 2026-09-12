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
  final memberName = 'Member'.obs;
  final overview = <String, dynamic>{}.obs;
  final memberProfile = <String, dynamic>{}.obs;
  final shareSummary = <String, dynamic>{}.obs;
  final shareLedger = <Map<String, dynamic>>[].obs;
  final memberList = <Map<String, dynamic>>[].obs;
  final currentGroupRole = 'MEMBER'.obs;
  final currentGroupPermissions = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _api = MemberDashboardApi(AppClient.dio);
    loadDashboard();
  }

  Future<void> loadDashboard({bool showError = true}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final groupId = await TokenStorage.getCurrentGroupId();
      groupName.value = await TokenStorage.getCurrentGroupName();
      currency.value = await TokenStorage.getCurrentGroupCurrency();
      memberName.value = await TokenStorage.getDisplayName();
      currentGroupRole.value = await TokenStorage.getCurrentGroupRole();
      currentGroupPermissions.assignAll(
        await TokenStorage.getCurrentGroupPermissions(),
      );
      final settings = await TokenStorage.getCurrentGroupSettings();
      final sharePrice = _number(settings['sharePrice']);
      shareSummary.assignAll({
        'sharePrice': sharePrice,
        'minimumSharePurchaseAmount': _number(
          settings['minimumSharePurchaseAmount'],
        ),
        'jamiiContributionPerSharePayment': _number(
          settings['jamiiContributionPerSharePayment'],
        ),
      });
      if (groupId == null || groupId <= 0) {
        throw Exception('No group is linked to this member account.');
      }
      overview.assignAll(await _api.getOverview(groupId));
      memberList.assignAll(await _api.getMembersByGroup(groupId));
      final latestShareSummary = await _api.getShareSummary(groupId);
      final savedPhone = (await TokenStorage.getPhone()) ?? '';
      final savedName = (await TokenStorage.getDisplayName()).trim();
      final activeMember = memberList.firstWhere((member) {
        final phone = (member['phone'] ?? '').toString().trim();
        final fullName =
            (member['fullName'] ??
                    '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}')
                .toString()
                .trim();
        return phone == savedPhone || fullName == savedName;
      }, orElse: () => <String, dynamic>{});
      if (activeMember.isNotEmpty) {
        memberProfile.assignAll(activeMember);
      }

      final memberId = _memberId;
      final ledger = await _api.getShareLedger(groupId);
      final personalLedger = memberId == null
          ? <Map<String, dynamic>>[]
          : ledger
                .where(
                  (entry) =>
                      _number(entry['groupMemberId']).toInt() == memberId,
                )
                .toList();
      shareLedger.assignAll(personalLedger);

      final totalShares = _calculateShareBalance(personalLedger);
      final unitPrice = _number(
        latestShareSummary['unitPrice'] ?? shareSummary['sharePrice'],
      );
      shareSummary.assignAll({
        'sharePrice': unitPrice,
        'unitPrice': unitPrice,
        'totalShares': totalShares,
        'totalCapital': unitPrice * totalShares,
      });
    } catch (error) {
      if (showError) {
        errorMessage.value = _message(error);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> purchaseShares({
    required int quantity,
    required double amount,
    String paymentMethod = 'Cash',
    String? reference,
  }) async {
    final groupId = await TokenStorage.getCurrentGroupId();
    if (groupId == null || groupId <= 0) {
      throw Exception('No group selected for share purchase.');
    }

    final memberId = _memberId;

    if (memberId == null) {
      throw Exception('Your member profile could not be identified.');
    }

    try {
      await _api.purchaseShares(
        groupId,
        groupMemberId: memberId,
        quantity: quantity,
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
      );
    } catch (error) {
      throw Exception(_message(error));
    }

    await loadDashboard();
  }

  Future<void> submitSharePurchaseProof({
    required int quantity,
    required double amount,
    required String paymentMethod,
    String? paymentReference,
    String? proofText,
    String? proofFilePath,
    double? jamiiAmount,
  }) async {
    final groupId = await TokenStorage.getCurrentGroupId();
    final memberId = _memberId;
    if (groupId == null || groupId <= 0) {
      throw Exception('No group selected for share purchase.');
    }
    if (memberId == null) {
      throw Exception('Your member profile could not be identified.');
    }
    try {
      await _api.submitSharePurchaseProof(
        groupId,
        groupMemberId: memberId,
        quantity: quantity,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        proofText: proofText,
        proofFilePath: proofFilePath,
        jamiiAmount: jamiiAmount,
      );
    } catch (error) {
      throw Exception(_message(error, operation: 'submit payment proof'));
    }

    await loadDashboard(showError: false);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    Get.offAllNamed('/login');
  }

  String _message(
    Object error, {
    String operation = 'load your group dashboard',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message =
            data['message'] ??
            (data['error'] is Map ? data['error']['message'] : null);
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      return 'We could not $operation (${error.response?.statusCode ?? 'network error'}).';
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

  int? get _memberId {
    final value = memberProfile['id'] ?? memberProfile['groupMemberId'];
    return value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  }

  int _calculateShareBalance(List<Map<String, dynamic>> ledger) {
    var balance = 0;
    for (final entry in ledger) {
      final quantity = _number(entry['quantity']).toInt();
      final type = entry['type']?.toString().toUpperCase();
      balance += switch (type) {
        'REDEMPTION' || 'TRANSFER_OUT' => -quantity,
        _ => quantity,
      };
    }
    return balance;
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
      
  double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
