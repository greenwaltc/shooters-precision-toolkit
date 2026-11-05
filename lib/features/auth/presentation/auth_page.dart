import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/foundation/behavior_policy.dart';
import '../../../shared/l10n/app_copy.dart';
import '../../../shared/ui/app_background.dart';
import '../../../shared/ui/app_bar_actions.dart';
import '../../../shared/ui/app_brand_bar.dart';
import '../../../shared/ui/app_copyright_footer.dart';
import '../../../shared/ui/navigation/app_routes.dart';
import '../../../shared/ui/theme/app_theme.dart';
import '../../../shared/ui/theme/layout/app_layout.dart';
import '../../../shared/ui/theme/tokens/app_spacing.dart';
import '../api/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.verification = false,
    required this.contactBuilder,
  });

  final bool verification;
  final WidgetBuilder contactBuilder;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _registering = false;
  bool _busy = false;
  String? _message;
  DateTime? _nextEmailAt;
  Timer? _timer;

  int get _emailWait {
    final next = _nextEmailAt;
    if (next == null) {
      return 0;
    }

    final seconds =
        next.difference(context.read<AuthRepository>().clock.now()).inSeconds +
        1;
    return seconds > 0 ? seconds : 0;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(BehaviorPolicy.emailCountdownRefresh, (_) {
      if (_nextEmailAt != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@')) {
      return AppCopy.english.enterYourEmailAddress;
    }
    return null;
  }

  Future<void> _run(
    Future<String?> Function(AuthRepository service) action, {
    bool sendsEmail = false,
  }) async {
    if (_busy || (sendsEmail && _emailWait > 0)) {
      return;
    }

    final service = context.read<AuthRepository>();

    setState(() {
      _busy = true;
      _message = null;
      if (sendsEmail) {
        _nextEmailAt = context.read<AuthRepository>().clock.now().add(
          context.read<AuthRepository>().emailCooldown,
        );
      }
    });

    try {
      final message = await action(service);
      if (mounted) {
        setState(() => _message = message);
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyError(error.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = AppCopy.english.unableToCompleteThatActionPleaseTryAgain;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    // Capture values before awaiting; the gate may dispose this page.
    final email = _email.text.trim();
    final password = _password.text;
    final registering = _registering;

    await _run((service) async {
      if (registering) {
        await service.register(email, password);
      } else {
        await service.signIn(email, password);
      }
      return null;
    });
  }

  Future<void> _resetPassword() async {
    if (_validateEmail(_email.text) != null) {
      setState(() => _message = AppCopy.english.enterYourEmailAddressFirst);
      return;
    }

    final email = _email.text.trim();

    await _run((service) async {
      await service.resetPassword(email);
      return AppCopy.english.ifThatAddressHasAnAccountAReset;
    }, sendsEmail: true);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    routes: {AppRoutes.contact: widget.contactBuilder},
    builder: (context, child) => AppBackground(child: child),
    home: Builder(
      builder: (context) => AppLayoutBuilder(
        builder: (context, layout) {
          final actions = <AppBarActionItem>[
            AppBarActionBar.contact(context),
            AppBarActionBar.donations(context),
            if (widget.verification)
              AppBarActionItem(
                label: AppCopy.english.signOut,
                icon: Icons.logout,
                tooltip: AppCopy.english.signOut,
                onPressed: () => _run((service) async {
                  await service.signOut();
                  return null;
                }),
              ),
          ];
          final actionsMetrics = AppBarActionsMetrics.of(
            context,
            layout: layout,
            items: actions,
          );
          return Scaffold(
            appBar: ProjectsBannerAppBar(
              metrics: ProjectsBannerMetrics.of(
                context,
                actionsWidth: actionsMetrics.actionsWidth,
              ),
              actions: AppBarActionBar.build(
                context,
                layout: layout,
                items: actions,
              ),
            ),
            body: _buildBody(context),
            bottomNavigationBar: const AppCopyrightFooter(),
          );
        },
      ),
    ),
  );

  Widget _buildBody(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.verification
                      ? AppCopy.english.verifyYourEmail
                      : _registering
                      ? AppCopy.english.createAnAccount
                      : AppCopy.english.signIn,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                if (widget.verification) ...[
                  Text(
                    AppCopy.english.verifyAddress(
                      user?.email ?? AppCopy.english.emailAddressFallback,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _busy || _emailWait > 0
                        ? null
                        : () => _run((service) async {
                            await service.sendVerification();
                            return AppCopy.english.verificationEmailRequested;
                          }, sendsEmail: true),
                    child: Text(
                      _emailWait > 0
                          ? AppCopy.english.sendAgainSeconds(_emailWait)
                          : AppCopy.english.sendVerificationEmail,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run((service) async {
                            final verified = await service
                                .refreshVerification();
                            return verified
                                ? null
                                : AppCopy
                                      .english
                                      .notVerifiedYetOpenTheEmailLinkAnd;
                          }),
                    child: Text(AppCopy.english.iHaveVerifiedMyEmail),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run((service) async {
                            await service.signOut();
                            return null;
                          }),
                    child: Text(AppCopy.english.useADifferentAccount),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: AppCopy.english.email,
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppCopy.english.password,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppCopy.english.enterYourPassword;
                      }
                      return null;
                    },
                  ),
                  if (_registering) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppCopy
                          .english
                          .passwordRequirementsMustBeAtLeast10Characters,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppCopy.english.confirmPassword,
                      ),
                      validator: (value) => value != _password.text
                          ? AppCopy.english.thePasswordsDoNotMatch
                          : null,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _registering
                          ? AppCopy.english.createAccount
                          : AppCopy.english.signIn,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _registering = !_registering;
                              _message = null;
                              _password.clear();
                              _confirmation.clear();
                            });
                          },
                    child: Text(
                      _registering
                          ? AppCopy.english.alreadyHaveAnAccountSignIn
                          : AppCopy.english.createAnAccount,
                    ),
                  ),
                  if (!_registering)
                    TextButton(
                      onPressed: _busy || _emailWait > 0
                          ? null
                          : _resetPassword,
                      child: Text(
                        _emailWait > 0
                            ? AppCopy.english.requestAnotherEmailSeconds(
                                _emailWait,
                              )
                            : AppCopy.english.forgotPassword,
                      ),
                    ),
                ],

                if (_busy) const LinearProgressIndicator(),
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(_message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyError(AuthFailureCode code) => switch (code) {
  AuthFailureCode.invalidEmail => AppCopy.english.enterAValidEmailAddress,
  AuthFailureCode.passwordPolicy =>
    AppCopy.english.chooseAPasswordThatMeetsThePasswordRequirements,
  AuthFailureCode.accountExists =>
    AppCopy.english.unableToCreateThisAccountTrySigningIn,
  AuthFailureCode.invalidCredentials || AuthFailureCode.expiredSession =>
    AppCopy.english.unableToSignInWithThoseDetails,
  AuthFailureCode.rateLimited =>
    AppCopy.english.tooManyAttemptsWaitAWhileBeforeTrying,
  AuthFailureCode.unavailable => AppCopy.english.checkYourConnectionAndTryAgain,
  AuthFailureCode.unknown =>
    AppCopy.english.unableToCompleteThatActionPleaseTryAgain,
};
