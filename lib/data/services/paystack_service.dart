import 'package:cloud_functions/cloud_functions.dart';

class PaystackService {
  final FirebaseFunctions _functions;

  PaystackService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Initializes a Paystack transaction via Cloud Function.
  /// Returns the authorization_url for WebView redirect.
  Future<PaystackInitResult> initializePayment({
    required String paymentId,
    required String tenantId,
    required String email,
    required double amount,
  }) async {
    final callable = _functions.httpsCallable('initializePaystackPayment');
    final result = await callable.call<Map<String, dynamic>>({
      'paymentId': paymentId,
      'tenantId': tenantId,
      'email': email,
      'amountInKobo': (amount * 100).round(),
    });

    return PaystackInitResult(
      authorizationUrl: result.data['authorization_url'] as String,
      reference: result.data['reference'] as String,
      accessCode: result.data['access_code'] as String,
    );
  }

  /// Verifies a Paystack payment via Cloud Function.
  Future<bool> verifyPayment(String reference) async {
    final callable = _functions.httpsCallable('verifyPaystackPayment');
    final result =
        await callable.call<Map<String, dynamic>>({'reference': reference});
    return result.data['status'] == 'success';
  }
}

class PaystackInitResult {
  final String authorizationUrl;
  final String reference;
  final String accessCode;

  const PaystackInitResult({
    required this.authorizationUrl,
    required this.reference,
    required this.accessCode,
  });
}
