import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../styles/app_theme.dart';
import '../styles/layout/app_layout.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/app_brand_bar.dart';
import '../widgets/app_copyright_footer.dart';
import 'auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.verification = false});

  final bool verification;

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
    if (next == null) return 0;

    final seconds = next.difference(clock.now()).inSeconds + 1;
    return seconds > 0 ? seconds : 0;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_nextEmailAt != null && mounted) setState(() {});
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
      return 'Enter your email address.';
    }
    return null;
  }

  Future<void> _run(
    Future<String?> Function(AuthService service) action, {
    bool sendsEmail = false,
  }) async {
    if (_busy || (sendsEmail && _emailWait > 0)) return;

    final service = context.read<AuthService>();

    setState(() {
      _busy = true;
      _message = null;
      if (sendsEmail) {
        _nextEmailAt = clock.now().add(const Duration(seconds: 60));
      }
    });

    try {
      final message = await action(service);
      if (mounted) setState(() => _message = message);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyError(error.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Unable to complete that action. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

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
      setState(() => _message = 'Enter your email address first.');
      return;
    }

    final email = _email.text.trim();

    await _run((service) async {
      await service.resetPassword(email);
      return 'If that address has an account, a reset email has been sent.';
    }, sendsEmail: true);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => AppBackground(child: child),
    home: Builder(
      builder: (context) => AppLayoutBuilder(
        builder: (context, layout) {
          final actions = <AppBarActionItem>[
            if (widget.verification)
              AppBarActionItem(
                label: 'Sign out',
                icon: Icons.logout,
                tooltip: 'Sign out',
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
    final user = context.read<AuthService>().auth.currentUser;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                      ? 'Verify your email'
                      : _registering
                      ? 'Create an account'
                      : 'Sign in',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                if (widget.verification) ...[
                  Text(
                    'Verify ${user?.email ?? "your email address"} '
                    'before opening your workspace.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy || _emailWait > 0
                        ? null
                        : () => _run((service) async {
                            await service.sendVerification();
                            return 'Verification email requested.';
                          }, sendsEmail: true),
                    child: Text(
                      _emailWait > 0
                          ? 'Send again in ${_emailWait}s'
                          : 'Send verification email',
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
                                : 'Not verified yet. Open the email link '
                                      'and try again.';
                          }),
                    child: const Text('I have verified my email'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run((service) async {
                            await service.signOut();
                            return null;
                          }),
                    child: const Text('Use a different account'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password.';
                      }
                      return null;
                    },
                  ),
                  if (_registering) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Password requirements: Must be at least 10 characters',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      validator: (value) => value != _password.text
                          ? 'The passwords do not match.'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_registering ? 'Create account' : 'Sign in'),
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
                          ? 'Already have an account? Sign in'
                          : 'Create an account',
                    ),
                  ),
                  if (!_registering)
                    TextButton(
                      onPressed: _busy || _emailWait > 0
                          ? null
                          : _resetPassword,
                      child: Text(
                        _emailWait > 0
                            ? 'Request another email in ${_emailWait}s'
                            : 'Forgot password?',
                      ),
                    ),
                ],

                if (_busy) const LinearProgressIndicator(),
                if (_message != null) ...[
                  const SizedBox(height: 16),
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

String _friendlyError(String code) => switch (code) {
  'invalid-email' => 'Enter a valid email address.',
  'weak-password' || 'password-does-not-meet-requirements' =>
    'Choose a password that meets the password requirements.',
  'email-already-in-use' =>
    'Unable to create this account. Try signing in or resetting your password.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'Unable to sign in with those details.',
  'too-many-requests' => 'Too many attempts. Wait a while before trying again.',
  'network-request-failed' => 'Check your connection and try again.',
  _ => 'Unable to complete that action. Please try again.',
};
