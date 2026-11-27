import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    required this.imageBytes,
    this.size = 72,
    super.key,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl;
    Widget placeholder() => Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary),
    );
    final bytes = imageBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        ),
      );
    }
    if (url == null || url.trim().isEmpty) return placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      ),
    );
  }
}
