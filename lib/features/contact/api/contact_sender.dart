/// Limits apply to data entered and sent by the contact form.
abstract final class ContactPolicy {
  static const maxNameLength = 120;
  static const maxEmailLength = 254;
  static const maxMessageLength = 4000;
  static const requestTimeout = Duration(seconds: 15);

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool validEmail(String value) =>
      value.length <= maxEmailLength && _emailPattern.hasMatch(value);
}

final class ContactMessage {
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

  bool get isValid =>
      name.isNotEmpty &&
      name.length <= ContactPolicy.maxNameLength &&
      ContactPolicy.validEmail(email) &&
      message.isNotEmpty &&
      message.length <= ContactPolicy.maxMessageLength;
}

abstract interface class ContactSender {
  Future<void> send(ContactMessage message);
}
