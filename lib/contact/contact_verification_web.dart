import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

class ContactVerification extends StatefulWidget {
  const ContactVerification({super.key, required this.url});
  final String url;
  @override
  State<ContactVerification> createState() => _ContactVerificationState();
}

class _ContactVerificationState extends State<ContactVerification> {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 400,
        child: HtmlElementView.fromTagName(
          tagName: 'iframe',
          onElementCreated: (element) {
            final frame = element as web.HTMLIFrameElement;
            frame
              ..src = widget.url
              ..title = 'Contact email verification'
              ..setAttribute('allow', 'private-token')
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.border = '0';
          },
        ),
      ),
      TextButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open verification in a new tab'),
        onPressed: () async {
          try {
            await launchUrl(Uri.parse(widget.url), webOnlyWindowName: '_blank');
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Unable to open verification. Please try again.',
                  ),
                ),
              );
            }
          }
        },
      ),
    ],
  );
}
