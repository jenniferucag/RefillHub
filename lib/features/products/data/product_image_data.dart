import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image_codec;

const maxProductImageBytes = 300 * 1024;

Uint8List? decodeProductImage(String? imageBase64) {
  if (imageBase64 == null || imageBase64.trim().isEmpty) return null;
  try {
    return base64Decode(imageBase64);
  } on FormatException {
    return null;
  }
}

Uint8List compressProductImage(Uint8List bytes) {
  if (bytes.lengthInBytes <= maxProductImageBytes) return bytes;
  final decoded = image_codec.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('The selected photo could not be decoded.');
  }

  for (final dimension in [800, 640, 512, 400, 320, 256, 192]) {
    final resized = image_codec.copyResize(
      decoded,
      width: dimension,
      height: dimension,
      maintainAspect: true,
    );
    for (final quality in [60, 45, 30, 20]) {
      final compressed = Uint8List.fromList(
        image_codec.encodeJpg(resized, quality: quality),
      );
      if (compressed.lengthInBytes <= maxProductImageBytes) {
        return compressed;
      }
    }
  }

  throw const ProductImageTooLargeException();
}

class ProductImageTooLargeException implements Exception {
  const ProductImageTooLargeException();

  @override
  String toString() => 'Photo cannot be compressed below 300 KB.';
}
