import 'package:flutter/material.dart';

import '../../../shared/foundation/app_failure.dart';
import '../../../shared/l10n/app_copy.dart';
import '../../../shared/ui/app_bar_actions.dart';
import '../../../shared/ui/app_brand_bar.dart';
import '../../../shared/ui/app_copyright_footer.dart';
import '../../../shared/ui/theme/components/outlined_surface_card.dart';
import '../../../shared/ui/theme/layout/app_layout.dart';
import '../../../shared/ui/theme/tokens/app_spacing.dart';
import '../api/contact_sender.dart';

/// A public contact screen with a form when sending is configured.
class ContactPage extends StatelessWidget {
  /// Creates the contact screen. A null [sender] displays an unavailable
  /// notice.
  const ContactPage({super.key, this.sender});

  final ContactSender? sender;

  @override
  Widget build(BuildContext context) => AppLayoutBuilder(
    builder: (context, layout) {
      final actions = [
        AppBarActionBar.instructions(context),
        AppBarActionBar.donations(context),
      ];
      final metrics = AppBarActionsMetrics.of(
        context,
        layout: layout,
        items: actions,
        hasLeading: true,
      );
      final titleMetrics = AppBrandTitleMetrics.of(
        context,
        label: context.l10n.contact,
        titleMaxWidth: metrics.titleMaxWidth,
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: titleMetrics.toolbarHeight,
          title: AppBrandTitle(
            label: context.l10n.contact,
            metrics: titleMetrics,
          ),
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
              child: OutlinedSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.contactDentonBramwell,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (sender case final sender?)
                      _ContactForm(sender: sender)
                    else
                      Text(context.l10n.contactUnavailable),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppCopyrightFooter(),
      );
    },
  );
}

enum _Submission { idle, sending, sent, failed }

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.sender});

  final ContactSender sender;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  _Submission _submission = _Submission.idle;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Keeps the message available until the service confirms receipt.
  ///
  /// The request can outlive this route. A late completion must leave the
  /// disposed form and its text controllers alone.
  Future<void> _send() async {
    if (_submission == _Submission.sending || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submission = _Submission.sending);
    try {
      await widget.sender.send(
        ContactMessage(
          name: _name.text,
          email: _email.text,
          message: _message.text,
        ),
      );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _message.clear();
      setState(() => _submission = _Submission.sent);
    } on AppFailure {
      if (mounted) setState(() => _submission = _Submission.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final theme = Theme.of(context);
    final busy = _submission == _Submission.sending;
    final status = switch (_submission) {
      _Submission.sent => copy.contactSent,
      _Submission.failed => copy.contactSendFailed,
      _ => null,
    };
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.contactDeliveryNotice),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _name,
            readOnly: busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: ContactPolicy.maxNameLength,
            decoration: InputDecoration(
              labelText: copy.contactName,
              counterText: '',
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              return name.isEmpty || name.length > ContactPolicy.maxNameLength
                  ? copy.contactNameInvalid
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _email,
            readOnly: busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            maxLength: ContactPolicy.maxEmailLength,
            decoration: InputDecoration(
              labelText: copy.contactEmail,
              counterText: '',
            ),
            validator: (value) => ContactPolicy.validEmail(value?.trim() ?? '')
                ? null
                : copy.contactEmailInvalid,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _message,
            readOnly: busy,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            maxLength: ContactPolicy.maxMessageLength,
            decoration: InputDecoration(
              labelText: copy.contactMessage,
              alignLabelWithHint: true,
            ),
            validator: (value) {
              final message = value?.trim() ?? '';
              return message.isEmpty ||
                      message.length > ContactPolicy.maxMessageLength
                  ? copy.contactMessageInvalid
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: busy ? null : _send,
              child: Text(busy ? copy.contactSending : copy.contactSend),
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                style: _submission == _Submission.failed
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
