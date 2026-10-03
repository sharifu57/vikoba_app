import 'package:flutter_test/flutter_test.dart';
import 'package:vikoba_app/config/app_client.dart';

void main() {
  test('API cache keys separate accounts and do not contain bearer tokens', () {
    final url = Uri.parse('https://example.test/api/groups');
    final first = AppClient.cacheKey(
      url: url,
      headers: {'Authorization': 'Bearer account-a'},
    );
    final second = AppClient.cacheKey(
      url: url,
      headers: {'authorization': 'Bearer account-b'},
    );
    final anonymous = AppClient.cacheKey(url: url);
    expect(first, isNot(second));
    expect(first, isNot(anonymous));
    expect(first, isNot(contains('account-a')));
    expect(
      AppClient.cacheKey(
        url: url,
        headers: {'authorization': 'Bearer account-a'},
      ),
      first,
    );
  });
}
