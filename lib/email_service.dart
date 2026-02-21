import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendConfirmationEmail(String email, String name) async {
  try {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
      'sendWelcomeEmail',
    );
    final result = await callable.call({'email': email, 'name': name});

    if (result.data['success']) {
      print("Email sent successfully!");
    } else {
      print("Failed to send email: ${result.data['error']}");
    }
  } catch (e) {
    print("Callable error: $e");
  }
}
