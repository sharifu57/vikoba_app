import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vikoba_app/features/member/data/member_dashboard_api.dart';
import 'package:vikoba_app/features/member/presentation/member_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'member dashboard uses authenticated membership and personal data even for an officer',
    () async {
      dotenv.loadFromString(envString: 'API_URL=http://localhost:8050');
      SharedPreferences.setMockInitialValues({
        'current_group_id': 7,
        'current_group_role': 'ACCOUNTANT',
        'full_name': 'Duplicate Name',
        'current_group_settings': '{"jamiiContributionPerSharePayment":100}',
      });
      final paths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            final path = Uri.parse(options.path).path;
            final Object data;
            switch (path) {
              case '/api/groups/7':
                data = {
                  'settings': {
                    'sharePrice': 1000,
                    'jamiiContributionPerSharePayment': 2000,
                  },
                };
              case '/api/members/group/7/my-access':
                data = {'id': 42, 'fullName': 'Duplicate Name'};
              case '/api/members/42/360':
                data = {
                  'sharesOwned': 2.5,
                  'fines': [
                    {'id': 8, 'amount': 100},
                  ],
                  'upcomingMeetings': [
                    {'id': 3, 'title': 'Next meeting'},
                  ],
                };
              case '/api/shares/group/7/summary':
                data = {'unitPrice': 1000};
              case '/api/shares/group/7/ledger':
                data = [
                  {'groupMemberId': 42, 'quantity': 2.5},
                  {'groupMemberId': 99, 'quantity': 100},
                ];
              case '/api/share-purchase-requests/group/7/mine':
                data = [
                  {'id': 5, 'status': 'PENDING'},
                ];
              case '/api/loans/group/7/application-context':
                data = {'groupMemberId': 42};
              case '/api/loans/group/7':
                data = [
                  {'id': 1, 'groupMemberId': 42},
                  {'id': 2, 'groupMemberId': 99, 'canApprove': true},
                ];
              case '/api/loans/group/7/guarantees/mine':
                data = [];
              default:
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 403,
                      data: {
                        'message':
                            'You do not have access to the group dashboard',
                      },
                    ),
                  ),
                );
                return;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'data': data},
              ),
            );
          },
        ),
      );
      final controller = MemberController(api: MemberDashboardApi(dio));
      await controller.loadDashboard();
      expect(controller.errorMessage.value, isNull);
      expect(controller.currentMemberId, 42);
      expect(controller.shareSummary['jamiiContributionPerSharePayment'], 2000);
      expect(controller.shareSummary['totalShares'], 2.5);
      expect(controller.shareSummary['totalCapital'], 2500);
      expect(controller.shareLedger, hasLength(1));
      expect(controller.memberFines.single['id'], 8);
      expect(controller.meetings.single['id'], 3);
      expect(controller.shareRequests.single['status'], 'PENDING');
      expect(controller.loanApplications.single['id'], 1);
      expect(paths.any((path) => path.contains('/dashboard/group/')), isFalse);
      expect(paths.any((path) => path.endsWith('/members/group/7')), isFalse);
    },
  );
}
