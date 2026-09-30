import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vikoba_app/core/formatters/money_formatter.dart';
import 'package:vikoba_app/core/formatters/money_input_formatter.dart';
import 'package:vikoba_app/features/member/data/member_dashboard_api.dart';
import 'package:vikoba_app/features/member/presentation/member_controller.dart';
import 'package:vikoba_app/features/member/presentation/member_action_pages.dart';

class TestMemberController extends MemberController {
  TestMemberController() : super(api: MemberDashboardApi(Dio()));
  @override
  Future<void> loadDashboard({bool showError = true}) async {}
  @override
  Future<void> loadSharePurchaseSettings() async {
    shareSummary.assignAll({
      'unitPrice': 1000,
      'jamiiContributionPerSharePayment': 2000,
      'minimumSharePurchaseAmount': 1000,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Get.reset());

  test(
    'money input groups digits while preserving cents and numeric payload',
    () {
      final formatter = MoneyInputFormatter();
      final input = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '10000.50',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(input.text, '10,000.50');
      expect(parseMoneyInput(input.text), 10000.5);
      expect(formatMoney(10000, currency: 'TZS'), 'TZS 10,000.00');
      expect(
        formatter.formatEditUpdate(
          input,
          const TextEditingValue(text: '10,000.501'),
        ),
        input,
      );
      expect(
        formatter.formatEditUpdate(input, TextEditingValue.empty).text,
        '',
      );
    },
  );

  testWidgets(
    'purchase form formats typed amount and shows separate Jamii and shares',
    (tester) async {
      Get.put<MemberController>(TestMemberController());
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) =>
              const GetMaterialApp(home: MemberSharePurchasePage()),
        ),
      );
      await tester.pumpAndSettle();
      final amount = find.byType(TextFormField).first;
      await tester.enterText(amount, '10000');
      await tester.pumpAndSettle();
      expect(find.text('10,000'), findsOneWidget);
      expect(find.text('TZS 10,000.00'), findsOneWidget);
      expect(find.text('TZS 2,000.00'), findsOneWidget);
      expect(find.text('TZS 8,000.00'), findsOneWidget);
      expect(find.text('8.00000000 shares'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(amount, '1000');
      await tester.pumpAndSettle();
      expect(find.text('TZS 0.00'), findsOneWidget);
      expect(find.text('0.00000000 shares'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'proof submission sends total payment and correct receipt MIME type',
    () async {
      dotenv.loadFromString(envString: 'API_URL=https://example.test');
      SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
      final dir = await Directory.systemTemp.createTemp('vikoba-proof-test-');
      try {
        final file = await File(
          '${dir.path}/receipt.png',
        ).writeAsBytes([137, 80, 78, 71]);
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final form = options.data as FormData;
              final fields = Map.fromEntries(form.fields);
              expect(fields['amount'], '10000.0');
              // The backend calculates Jamii from the group configuration, just like web.
              expect(fields.containsKey('jamiiAmount'), isFalse);
              expect(
                form.files.single.value.contentType.toString(),
                'image/png',
              );
              expect(fields['paymentMethod'], 'Mobile Money');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': {
                      'amount': 8000,
                      'jamiiAmount': 2000,
                      'status': 'PENDING',
                    },
                  },
                ),
              );
            },
          ),
        );
        final response = await MemberDashboardApi(dio).submitSharePurchaseProof(
          7,
          amount: 10000,
          paymentMethod: 'Mobile Money',
          proofFilePath: file.path,
        );
        expect(response['status'], 'PENDING');
        expect(response['amount'], 8000);
        expect(response['jamiiAmount'], 2000);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
