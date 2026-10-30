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
        return const Center(child: Text('Unable to restore your session.'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final user = snapshot.data;
      if (user == null) return signedOutBuilder(context);
      if (!user.emailVerified) return verifyEmailBuilder(context);
      return KeyedSubtree(
        key: ValueKey('${auth.app.options.projectId}/${user.uid}'),
        child: signedInBuilder(context, user),
      );
    },
  );
}
