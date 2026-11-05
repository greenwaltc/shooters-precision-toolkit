/// Limits apply to data entered and sent by the contact form.
abstract final class ContactPolicy {
  static const maxNameLength = 120;
  static const maxEmailLength = 254;
  static const maxMessageLength = 4000;
  static const requestTimeout = Duration(seconds: 15);

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Checks whether [value] has the form of an email address accepted by the
  /// contact form.
  ///
  /// This check does not verify that the address can receive mail.
  static bool validEmail(String value) =>
      value.length <= maxEmailLength && _emailPattern.hasMatch(value);
}

/// A contact message and the reply address entered by the sender.
final class ContactMessage {
  /// Creates a message after trimming surrounding whitespace from all three
  /// fields.
  ///
  /// Check [isValid] before sending.
  ContactMessage({
    required String name,
    required String email,
    required String message,
  }) : name = name.trim(),
       email = email.trim(),
       message = message.trim();

  final String name;
  final String email;
  final String message;

  /// Whether the message has the required text and fits the contact form's
  /// limits.
  bool get isValid =>
      name.isNotEmpty &&
      name.length <= ContactPolicy.maxNameLength &&
      ContactPolicy.validEmail(email) &&
      message.isNotEmpty &&
      message.length <= ContactPolicy.maxMessageLength;
}

/// The service contract for sending a message from the contact form.
abstract interface class ContactSender {
  /// Submits a valid [message] and completes when the service confirms receipt.
  ///
  /// A failure can leave delivery uncertain, so callers should retain the input
  /// and avoid automatic retries.
  Future<void> send(ContactMessage message);
}
