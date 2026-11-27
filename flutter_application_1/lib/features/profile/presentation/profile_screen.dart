import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: EmptyState(
      title: 'Your profile',
      message: 'Profile information is not yet provided.',
      icon: Icons.person_outline,
    ),
  );
}
