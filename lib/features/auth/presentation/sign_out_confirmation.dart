import 'package:flutter/material.dart';

import '../auth_controller.dart';

Future<void> confirmSignOut(BuildContext context) async {
  final auth = AuthScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await auth.signOut();
  }
}
