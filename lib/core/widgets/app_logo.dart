import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  static const assetPath = 'assets/images/refillhub_logo.jpg';

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    assetPath,
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'RefillHub logo',
    errorBuilder: (context, error, stackTrace) => Icon(
      Icons.water_drop_outlined,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
