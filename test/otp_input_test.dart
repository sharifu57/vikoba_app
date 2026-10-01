import 'package:flutter_test/flutter_test.dart';
import 'package:vikoba_app/features/auth/presentation/otp_input.dart';

void main() {
  test('extracts a code without losing leading zeros', () {
    expect(
      extractOtp(
        'VIKOBA360 verification code: 001234\nInaisha baada ya dakika 5.',
      ),
      '001234',
    );
    expect(extractOtp(' 001234 '), '001234');
    expect(extractOtp('255712345678'), isNull);
    expect(extractOtp('123456 or 654321'), isNull);
    expect(extractOtp('12345'), isNull);
  });
  test('paste accepts the whole SMS and typing stays six digits', () {
    final formatter = OtpInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'VIKOBA360 verification code: 001234. Expires in 5 minutes.',
      ),
    );
    expect(result.text, '001234');
    expect(result.selection.extentOffset, 6);
    expect(
      formatter.formatEditUpdate(
        result,
        const TextEditingValue(text: '1234567'),
      ),
      result,
    );
    expect(formatter.formatEditUpdate(result, TextEditingValue.empty).text, '');
    expect(
      formatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '00'),
          )
          .text,
      '00',
    );
  });
}
