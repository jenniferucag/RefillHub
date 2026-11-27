import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => AppLogo(size: compact ? 140 : 180);
}
