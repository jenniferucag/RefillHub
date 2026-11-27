import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:refillhub/features/products/data/product_image_data.dart';

void main() {
  test('compresses picked photos to at most 300 KB', () {
    final source = image_codec.Image(width: 800, height: 800);
    var seed = 7;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        source.setPixelRgba(
          x,
          y,
          seed & 0xff,
          (seed >> 8) & 0xff,
          (seed >> 16) & 0xff,
          255,
        );
      }
    }
    final original = Uint8List.fromList(image_codec.encodePng(source));
    expect(original.lengthInBytes, greaterThan(maxProductImageBytes));

    final compressed = compressProductImage(original);
    expect(compressed.lengthInBytes, lessThanOrEqualTo(maxProductImageBytes));
    expect(image_codec.decodeImage(compressed), isNotNull);
  });
}
