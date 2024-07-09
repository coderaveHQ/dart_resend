import 'dart:async';

import 'package:dart_resend/src/enums/resend_error.dart';
import 'package:dart_resend/src/utils/typedefs.dart';

/// Abstract class representing the result of a Resend API request
sealed class ResendResult<S> {
  /// Constructor for ResendResult
  const ResendResult();

  /// Factory constructor to create a success result
  factory ResendResult.success(S value) => ResendSuccess<S>(value);

  /// Factory constructor to create a failure result
  factory ResendResult.failure(ResendError? error, String? message) =>
      ResendFailure<S>(error, message);

  /// Getter to check if the result is a success
  bool get isSuccess;

  /// Getter to check if the result is a failure
  bool get isFailure;

  /// Method to handle both success and failure cases
  FutureOr<R> fold<R>(
      {required FutureOr<R> Function(S value) onSuccess,
      required FutureOr<R> Function(ResendError? error, String? message)
          onFailure}) async {
    // If the result is a success, call the onSuccess function with the value
    if (this is ResendSuccess) {
      return await onSuccess((this as ResendSuccess<S>).value);
    }
    // If the result is a failure, call the onFailure function with the status code, message, and error
    else if (this is ResendFailure) {
      return await onFailure(
          (this as ResendFailure<S>).error, (this as ResendFailure<S>).message);
    }
    // Throw an exception if the result type is unexpected
    else {
      throw Exception('Unexpected result type');
    }
  }
}

/// Class representing a successful Resend API request result
final class ResendSuccess<S> extends ResendResult<S> {
  /// The value of the successful result
  final S value;

  /// Constructor for ResendSuccess
  const ResendSuccess(this.value);

  // Override to indicate this is a success
  @override
  bool get isSuccess => true;

  // Override to indicate this is not a failure
  @override
  bool get isFailure => false;
}

/// Class representing a failed Resend API request result
final class ResendFailure<S> extends ResendResult<S> {
  /// The ResendError of the failure
  final ResendError? error;

  /// The message of the failure, if any
  final String? message;

  /// Constructor for ResendFailure
  const ResendFailure(this.error, this.message);

  /// Factory constructor to create a failure result from a status code and JSON response
  factory ResendFailure.fromJson(Json json) {
    return ResendFailure<S>(
        ResendError.fromId(json['name']), json['message'] as String?);
  }

  // Override to indicate this is not a success
  @override
  bool get isSuccess => false;

  // Override to indicate this is a failure
  @override
  bool get isFailure => true;
}
