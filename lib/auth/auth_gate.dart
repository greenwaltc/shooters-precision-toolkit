import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.signedOutBuilder,
    required this.verifyEmailBuilder,
    required this.signedInBuilder,
  });

  final FirebaseAuth auth;
  final WidgetBuilder signedOutBuilder;
  final WidgetBuilder verifyEmailBuilder;
  final Widget Function(BuildContext, User) signedInBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.userChanges(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Unable to restore your session.')),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      final user = snapshot.data;
      if (user == null) return signedOutBuilder(context);
      if (!user.emailVerified) return verifyEmailBuilder(context);
      return KeyedSubtree(
        key: ValueKey('${auth.app.options.projectId}/${user.uid}'),
        child: _VerifiedSession(
          user: user,
          verifiedBuilder: (context) => signedInBuilder(context, user),
          unverifiedBuilder: verifyEmailBuilder,
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
    required this.verifiedBuilder,
    required this.unverifiedBuilder,
  });
  final User user;
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
  Future<bool> _refresh() async {
    final token = await widget.user.getIdTokenResult(true);
    return token.claims?['email_verified'] == true;
  }

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
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to confirm your session.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _verification = _refresh();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
