import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secure = FlutterSecureStorage();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('tokens are saved in secure storage, not preferences', () async {
    await TokenStorage.updateTokens(
      token: 'access',
      refreshToken: 'refresh',
      expires: '3600000',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('access_token'), isFalse);
    expect(prefs.containsKey('refresh_token'), isFalse);
    expect(await secure.read(key: 'access_token'), 'access');
    expect(await secure.read(key: 'refresh_token'), 'refresh');
  });

  test('legacy tokens migrate and plaintext copies are removed', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
    });
    expect(await TokenStorage.getToken(), 'old-access');
    expect(await TokenStorage.getRefreshToken(), 'old-refresh');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('access_token'), isFalse);
    expect(prefs.containsKey('refresh_token'), isFalse);
  });

  test('legacy tokens cannot replace a newer secure token', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'old-access'});
    FlutterSecureStorage.setMockInitialValues({'access_token': 'new-access'});
    expect(await TokenStorage.getToken(), 'new-access');
  });

  test('logout removes both tokens and pending migration sources', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'old-access'});
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    await TokenStorage.clear();
    expect(await TokenStorage.isLoggedIn(), isFalse);
    expect(await TokenStorage.getRefreshToken(), isNull);
  });

  test('logout queued after migration cannot resurrect a token', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'old-access'});
    await Future.wait([TokenStorage.getToken(), TokenStorage.clear()]);
    expect(await TokenStorage.getToken(), isNull);
  });
}
