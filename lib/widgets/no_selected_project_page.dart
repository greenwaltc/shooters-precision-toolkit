import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';

class NoSelectedProjectPage extends StatelessWidget {
  const NoSelectedProjectPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.projects,
              (_) => false,
            );
          },
          icon: const Icon(Icons.home_outlined),
          label: const Text('Projects'),
        ),
      ),
    );
  }
}
