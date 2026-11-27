import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/products/data/product.dart';
import 'package:refillhub/features/products/data/product_repository.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final products = _Collection();
  String? collectionPath;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    this.collectionPath = collectionPath;
    return products;
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final active = _Query();
  final all = _Query();
  final filter = <Object?>[];
  final documents = <String, _WritableDocument>{};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      documents.putIfAbsent(path ?? 'new', () => _WritableDocument());

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    filter.addAll([field, isEqualTo]);
    return active;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => all.snapshots();
}

class _WritableDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _WritableDocument({this.initialData});

  final Map<String, dynamic>? initialData;
  final writes = <Map<String, dynamic>>[];
  Map<String, dynamic>? get written => writes.isEmpty ? null : writes.last;
  Map<String, dynamic>? get storedData {
    if (initialData == null && writes.isEmpty) return null;
    final result = <String, dynamic>{...?initialData};
    for (final write in writes) {
      for (final entry in write.entries) {
        if (entry.value is FieldValue) {
          result.remove(entry.key);
        } else {
          result[entry.key] = entry.value;
        }
      }
    }
    return result;
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    writes.add(data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    writes.add(Map<String, dynamic>.from(data));
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _WritableSnapshot(storedData);
}

class _WritableSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _WritableSnapshot(this._data);

  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;
}

class _Query extends Fake implements Query<Map<String, dynamic>> {
  final events = StreamController<QuerySnapshot<Map<String, dynamic>>>();
  final getOptions = <GetOptions?>[];

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getOptions.add(options);
    return _Snapshot([]);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Document extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Document(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}

void main() {
  test(
    'stores bounded base64 photos and removes both current and legacy data',
    () async {
      final firestore = _Firestore();
      final repository = ProductRepository(firestore);
      final encodedPhoto = base64Encode([1, 2, 3]);
      await repository.createProduct(
        name: 'New product',
        waterType: 'Purified',
        description: '',
        imageBase64: encodedPhoto,
        sizes: const [
          ProductSize(label: 'Bottle', price: 10, isAvailable: true),
        ],
      );
      expect(
        firestore.products.documents['new']!.written!['imageBase64'],
        encodedPhoto,
      );

      firestore.products.documents['test'] = _WritableDocument(
        initialData: {
          'name': 'Legacy product',
          'imageUrl': 'https://example.test/legacy-image',
          'imageBase64': base64Encode([4, 5]),
        },
      );

      await repository.updateProduct(
        'test',
        name: 'Updated',
        waterType: 'Purified',
        description: '',
        imageBase64: encodedPhoto,
        removeImage: false,
        sizes: const [
          ProductSize(label: 'Bottle', price: 10, isAvailable: true),
        ],
      );
      expect(
        firestore.products.documents['test']!.storedData!['imageBase64'],
        encodedPhoto,
      );

      await repository.updateProduct(
        'test',
        name: 'Updated',
        waterType: 'Purified',
        description: '',
        imageBase64: null,
        removeImage: true,
        sizes: const [
          ProductSize(label: 'Bottle', price: 10, isAvailable: true),
        ],
      );
      expect(
        firestore.products.documents['test']!.storedData!.containsKey(
          'imageBase64',
        ),
        isFalse,
      );
      expect(
        firestore.products.documents['test']!.storedData!.containsKey(
          'imageUrl',
        ),
        isFalse,
      );

      await expectLater(
        repository.createProduct(
          name: 'Product',
          waterType: 'Purified',
          description: '',
          imageBase64: base64Encode(List<int>.filled(300 * 1024 + 1, 0)),
          sizes: const [
            ProductSize(label: 'Bottle', price: 10, isAvailable: true),
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test('cart product check queries active products from the server', () async {
    final firestore = _Firestore();
    final repository = ProductRepository(firestore);
    expect(await repository.getActiveProductsFromServer(), isEmpty);
    expect(firestore.products.filter, ['isActive', true]);
    expect(firestore.products.active.getOptions.single?.source, Source.server);
  });

  test('writes valid products and rejects invalid names and prices', () async {
    final firestore = _Firestore();
    final repository = ProductRepository(firestore);
    const size = ProductSize(
      label: ' TEST size ',
      price: 12.5,
      isAvailable: false,
    );
    await repository.createProduct(
      name: ' TEST product ',
      waterType: ' Purified ',
      description: ' TEST description ',
      imageBase64: ' ',
      sizes: [size],
    );
    final created = firestore.products.documents['new']!.written!;
    expect(created['name'], 'TEST product');
    expect(created['waterType'], 'Purified');
    expect(created.containsKey('imageBase64'), isFalse);
    expect(created['isActive'], isFalse);
    expect(created['createdAt'], isA<Timestamp>());
    expect(created['sizes'], [
      {'label': 'TEST size', 'price': 12.5, 'isAvailable': false},
    ]);

    firestore.products.documents['test'] = _WritableDocument(
      initialData: {
        'name': 'Legacy product',
        'imageUrl': 'https://example.test/legacy-image',
      },
    );
    await repository.updateProduct(
      'test',
      name: 'Updated',
      waterType: 'Mineral',
      description: '',
      imageBase64: null,
      removeImage: false,
      sizes: [
        const ProductSize(
          label: 'TEST size',
          price: 12.5,
          refillPrice: 4.5,
          isAvailable: false,
        ),
      ],
    );
    expect(firestore.products.documents['test']!.written!['sizes'], [
      {
        'label': 'TEST size',
        'price': 12.5,
        'refillPrice': 4.5,
        'isAvailable': false,
      },
    ]);
    expect(
      firestore.products.documents['test']!.written!.keys,
      unorderedEquals(['name', 'waterType', 'description', 'sizes']),
    );
    expect(
      firestore.products.documents['test']!.storedData!['imageUrl'],
      'https://example.test/legacy-image',
    );
    expect(
      firestore.products.documents['test']!.written!['waterType'],
      'Mineral',
    );
    await repository.setActive('test', false);
    expect(firestore.products.documents['test']!.written, {'isActive': false});

    for (final invalid in [
      const ProductSize(label: 'x', price: 0, isAvailable: true),
      const ProductSize(label: 'x', price: -1, isAvailable: true),
      const ProductSize(label: 'x', price: double.nan, isAvailable: true),
      const ProductSize(label: ' ', price: 1, isAvailable: true),
    ]) {
      await expectLater(
        repository.createProduct(
          name: 'name',
          waterType: 'Purified',
          description: '',
          imageBase64: null,
          sizes: [invalid],
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      repository.updateProduct(
        'test',
        name: ' ',
        waterType: 'Purified',
        description: '',
        imageBase64: null,
        removeImage: false,
        sizes: [],
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.createProduct(
        name: 'name',
        waterType: ' ',
        description: '',
        imageBase64: null,
        sizes: [],
      ),
      throwsArgumentError,
    );
  });

  test(
    'customer and admin streams map updates and surface invalid data',
    () async {
      final firestore = _Firestore();
      final repository = ProductRepository(firestore);
      final activeStream = repository.watchActiveProducts();
      final allStream = repository.watchAllProducts();
      expect(firestore.collectionPath, 'products');
      expect(firestore.products.filter, ['isActive', true]);

      Map<String, dynamic> data(bool active) => {
        'name': 'TEST product',
        'description': 'TEST description',
        'isActive': active,
        'createdAt': Timestamp.fromDate(DateTime.utc(2025)),
        'sizes': [
          {'label': 'TEST size', 'price': 10, 'isAvailable': true},
        ],
      };

      final activeResult = expectLater(
        activeStream.map(
          (products) => products.map((product) => product.id).toList(),
        ),
        emitsInOrder([
          ['active'],
          emitsError(isA<FormatException>()),
          <String>[],
          emitsDone,
        ]),
      );
      final allResult = expectLater(
        allStream.map(
          (products) => products.map((product) => product.id).toList(),
        ),
        emitsInOrder([
          ['active', 'inactive'],
          ['inactive'],
          emitsDone,
        ]),
      );
      firestore.products.active.events.add(
        _Snapshot([_Document('active', data(true))]),
      );
      firestore.products.all.events.add(
        _Snapshot([
          _Document('active', data(true)),
          _Document('inactive', data(false)),
        ]),
      );
      firestore.products.active.events.add(
        _Snapshot([_Document('broken', {})]),
      );
      firestore.products.active.events.add(_Snapshot([]));
      firestore.products.all.events.add(
        _Snapshot([_Document('inactive', data(false))]),
      );
      await firestore.products.active.events.close();
      await firestore.products.all.events.close();
      await Future.wait([activeResult, allResult]);
    },
  );
}

// Firestore's sealed interfaces are implemented here only as test doubles.
// ignore_for_file: subtype_of_sealed_class
