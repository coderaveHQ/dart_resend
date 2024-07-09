# dart_resend

Resend made easy! 💎

A Dart package for interacting with the Resend API. It provides a set of utilities and models to facilitate integration with Resend's powerful email capabilities.

[![pub package](https://img.shields.io/pub/v/shelf.svg)](https://pub.dev/packages/dart_resend)
[![License](https://img.shields.io/badge/License-GNU%20GPL-blue)](https://opensource.org/license/gpl-3-0)

Developed with 💙 and maintained by [scial.app](https://scial.app)

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/scial.app)

## Supported features

### Email

| Feature           | Available          |
| ----------------- | ------------------ |
| Send Email        | :white_check_mark: |
| Retrieve Email    | :white_check_mark: |
| Send Batch Emails | :white_check_mark: |

### Domains

| Feature         | Available          |
| --------------- | ------------------ |
| Add Domain      | :white_check_mark: |
| Retrieve Domain | :white_check_mark: |
| Verify Domain   | :white_check_mark: |
| Update Domain   | :white_check_mark: |
| List Domains    | :white_check_mark: |
| Delete Domain   | :white_check_mark: |

### API Keys

| Feature        | Available          |
| -------------- | ------------------ |
| Create API key | :white_check_mark: |
| List API keys  | :white_check_mark: |
| Delete API key | :white_check_mark: |

### Audiences

| Feature           | Available          |
| ----------------- | ------------------ |
| Add Audience      | :white_check_mark: |
| Retrieve Audience | :white_check_mark: |
| Delete Audience   | :white_check_mark: |
| List Audiences    | :white_check_mark: |

### Contacts

| Feature          | Available          |
| ---------------- | ------------------ |
| Add Contact      | :white_check_mark: |
| Retrieve Contact | :white_check_mark: |
| Update Contact   | :white_check_mark: |
| Delete Contact   | :white_check_mark: |
| List Contacts    | :white_check_mark: |

## Quick Start 🚀

### Installation 🧑‍💻

In the `dependencies` section of your `pubspec.yaml`, add the following line:

```yaml
dependencies:
  dart_resend: <latest_version>
```

### Usage 👽

Import the package:

```dart
import 'package:dart_resend/dart_resend.dart';
```

Create an instance:

```dart
late final ResendClient resend;

void main() async {
    final Resend result = Resend.initialize(apiKey: '...');
    resend = result.client;
}
```

Make use of one of the many methods provided by this package e.g.:

```dart
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
```

## Contribution 💙

Always open for contribution! Contributors will be listed here.