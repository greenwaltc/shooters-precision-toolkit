import 'package:flutter/material.dart';

import '../../../shared/l10n/app_copy.dart';
import '../api/auth_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.signedOutBuilder,
    required this.verifyEmailBuilder,
    required this.signedInBuilder,
  });

  final AuthRepository auth;
  final WidgetBuilder signedOutBuilder;
  final WidgetBuilder verifyEmailBuilder;
  final Widget Function(BuildContext, AuthAccount) signedInBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // StreamBuilder owns its subscription. Rebuilds keep the same stream rather
  // than re-registering SDK listeners; replacing auth replaces that stream.
  late Stream<AuthAccount?> _users;

  @override
  void initState() {
    super.initState();
    _users = widget.auth.userChanges();
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth != widget.auth) {
      _users = widget.auth.userChanges();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthAccount?>(
    stream: _users,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: Text(AppCopy.english.unableToRestoreYourSession),
            ),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      final user = snapshot.data;
      if (user == null) {
        return widget.signedOutBuilder(context);
      }
      if (!user.emailVerified) {
        return widget.verifyEmailBuilder(context);
      }
      return KeyedSubtree(
        key: ValueKey('${widget.auth.sessionNamespace}/${user.uid}'),
        child: _VerifiedSession(
          user: user,
          auth: widget.auth,
          verifiedBuilder: (context) => widget.signedInBuilder(context, user),
          unverifiedBuilder: widget.verifyEmailBuilder,
        ),
      );
    },
  );
}

/// Wait for verified token claims before opening Firestore listeners. The user
/// profile may already be verified while a restored session still has old claims.
class _VerifiedSession extends StatefulWidget {
  const _VerifiedSession({
    required this.user,
    required this.auth,
    required this.verifiedBuilder,
    required this.unverifiedBuilder,
  });
  final AuthAccount user;
  final AuthRepository auth;
  final WidgetBuilder verifiedBuilder;
  final WidgetBuilder unverifiedBuilder;

  @override
  State<_VerifiedSession> createState() => _VerifiedSessionState();
}

class _VerifiedSessionState extends State<_VerifiedSession> {
  late Future<bool> _verification;

  @override
  void initState() {
    super.initState();
    _verification = _refresh();
  }

  // Stable across the userChanges event emitted by token refresh.
  Future<bool> _refresh() => widget.auth.verifiedToken(widget.user);

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _verification,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return snapshot.data == true
            ? widget.verifiedBuilder(context)
            : widget.unverifiedBuilder(context);
      }
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppCopy.english.unableToConfirmYourSession),
                      TextButton(
                        onPressed: () => setState(() {
                          _verification = _refreshAfterError(snapshot.error);
                        }),
                        child: Text(
                          _isExpired(snapshot.error)
                              ? AppCopy.english.signOut
                              : AppCopy.english.retry,
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );

  bool _isExpired(Object? error) =>
      error is AuthFailure && error.code == AuthFailureCode.expiredSession;

  Future<bool> _refreshAfterError(Object? error) async {
    if (_isExpired(error)) {
      await widget.auth.signOut();
      return false;
    }
    return _refresh();
  }
}
