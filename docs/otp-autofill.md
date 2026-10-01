# OTP autofill

Android uses Google Play services SMS User Consent (no SMS inbox permissions or app hash). The listener starts before requesting/resending the SMS and stops when the number changes, verification succeeds, the screen closes, or the native listener times out. The user permits access to one message, then taps Verify and continue. Only a message mentioning VIKOBA360 with one unambiguous six-digit code is filled.

iOS and supported Android keyboards receive Flutter's oneTimeCode autofill hint. Paste code reads the clipboard only when tapped; it accepts the six-digit code or the whole SMS, including codes beginning with zero. Manual typing and long-press paste remain available.

The backend sends `VIKOBA360 verification code: 001234` followed by a Swahili expiry and privacy reminder. Copy-code actions in the SMS application/notification depend on that application and the operating system.

## Device check

Rebuild/install the Android app after the native change, and restart the backend for the new SMS text. On a phone with Google Play services, request an OTP for the same phone, allow the single-message prompt, confirm six digits appear, then verify. Test declining the prompt, pasting the whole SMS, resend, changing the phone number, and leaving the screen. On iPhone, tap the keyboard's suggested code. Real carrier delivery and iOS require physical-device verification.

References:
- https://developers.google.com/identity/sms-retriever/user-consent/request
- https://api.flutter.dev/flutter/services/AutofillHints/oneTimeCode-constant.html
