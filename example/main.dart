import 'package:dart_resend/dart_resend.dart';
import 'package:dart_resend/src/enums/resend_error.dart';

late final ResendClient resend;

void main() async {
  final Resend result = Resend.initialize(apiKey: '...');
  resend = result.client;

  final ResendResult<ResendSendEmailResponse> response = await resend.email
      .sendEmail(
          from: 'scial Developer <dev@scial.app>',
          to: <String>['fleeser@scial.app', 'sroepges@scial.app'],
          subject: 'Check out this package',
          text: 'WOW! This package is awesome!');

  response.fold(
      onSuccess: (ResendSendEmailResponse data) => print('E-Mail sent!'),
      onFailure: (ResendError? error, String? message) =>
          print('Error occured.'));
}
