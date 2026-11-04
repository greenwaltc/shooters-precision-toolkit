import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/layout/app_layout.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/app_brand_bar.dart';
import '../widgets/app_copyright_footer.dart';
import 'contact_verification_stub.dart'
    if (dart.library.js_interop) 'contact_verification_web.dart';

/// Contact uses a protected reveal service when configured, or a direct fallback.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const verificationUrl = String.fromEnvironment(
    'CONTACT_VERIFICATION_URL',
  );

  @override
  Widget build(BuildContext context) => AppLayoutBuilder(
    builder: (context, layout) {
      final actions = [AppBarActionBar.instructions(context)];
      final metrics = AppBarActionsMetrics.of(
        context,
        layout: layout,
        items: actions,
        hasLeading: true,
      );
      final titleMetrics = AppBrandTitleMetrics.of(
        context,
        label: 'Contact',
        titleMaxWidth: metrics.titleMaxWidth,
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: titleMetrics.toolbarHeight,
          title: AppBrandTitle(label: 'Contact', metrics: titleMetrics),
          actions: AppBarActionBar.build(
            context,
            layout: layout,
            items: actions,
            hasLeading: true,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(layout.pageGutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Denton Bramwell',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For questions or feedback, contact Denton by email.',
                  ),
                  const SizedBox(height: 16),
                  if (verificationUrl.isEmpty)
                    const _DirectContact()
                  else
                    ContactVerification(url: verificationUrl),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppCopyrightFooter(),
      );
    },
  );
}

/// Optional unprotected fallback. A configured build uses the Worker instead.
class _DirectContact extends StatefulWidget {
  const _DirectContact();
  @override
  State<_DirectContact> createState() => _DirectContactState();
}

class _DirectContactState extends State<_DirectContact> {
  bool _revealed = false;
  String get _address => ['denton', 'tutanota.com'].join('@');

  @override
  Widget build(BuildContext context) {
    if (!_revealed) {
      return FilledButton(
        onPressed: () => setState(() => _revealed = true),
        child: const Text('Reveal email address'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(_address),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email Denton Bramwell'),
          onPressed: () async {
            final opened = await launchUrl(
              Uri(scheme: 'mailto', path: _address),
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Unable to open an email app. Copy the address above instead.',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
