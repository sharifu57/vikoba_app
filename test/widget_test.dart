import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenStorage greeting logic', () {
    test('returns a morning greeting for the member before noon', () {
      final greeting = TokenStorage.getGreetingForTime(9, 'Asha');
      expect(greeting, 'Good morning, Asha');
    });

    test('returns an evening greeting for the member after sunset', () {
      final greeting = TokenStorage.getGreetingForTime(20, 'Juma');
      expect(greeting, 'Good evening, Juma');
    });

    test(
      'uses the OTP username and active group settings from the login payload',
      () async {
        SharedPreferences.setMockInitialValues({});

        await TokenStorage.saveSession({
          'token': 'abc',
          'refreshToken': 'xyz',
          'expired': '86400000000',
          'data': {
            'user': {
              'id': 11,
              'username': 'Kizigo Kidogo',
              'email': 'kizigo@gmail.com',
              'phone': '255888888888',
            },
            'groups': [
              {
                'group': {
                  'groupId': 26,
                  'groupName': 'KIZIGO INK',
                  'currency': 'TZS',
                },
                'settings': {
                  'sharePrice': 5000.00,
                  'maximumSharesPerMember': 20,
                  'minimumContribution': 5.00,
                },
                'settingsConfigured': true,
              },
            ],
          },
        });

        expect(await TokenStorage.getDisplayName(), 'Kizigo Kidogo');
        expect(await TokenStorage.getCurrentGroupName(), 'KIZIGO INK');
        expect(await TokenStorage.getCurrentGroupCurrency(), 'TZS');

        final settings = await TokenStorage.getCurrentGroupSettings();
        expect(settings['sharePrice'], 5000.0);
        expect(settings['maximumSharesPerMember'], 20);
      },
    );
  });
}
