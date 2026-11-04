import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactVerification extends StatelessWidget {
  const ContactVerification({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    icon: const Icon(Icons.open_in_new),
    label: const Text('Verify and reveal email'),
    onPressed: () async {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open verification. Please try again.'),
          ),
        );
      }
    },
  );
}
