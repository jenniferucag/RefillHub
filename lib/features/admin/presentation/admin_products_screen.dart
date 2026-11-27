import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../products/data/product.dart';
import '../../products/data/product_image_data.dart';
import '../../products/data/product_providers.dart';
import '../../products/presentation/product_image.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _search = TextEditingController();
  final _updating = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductForm(product: product),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Product added.' : 'Product updated.',
          ),
        ),
      );
    }
  }

  Future<void> _setActive(Product product, bool active) async {
    if (_updating.contains(product.id)) return;
    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate product?'),
          content: Text(
            '${product.name} will be hidden from customers, but not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _updating.add(product.id));
    try {
      await ref.read(productRepositoryProvider).setActive(product.id, active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Product activated.' : 'Product deactivated.'),
        ),
      );
    } catch (error, stack) {
      debugPrint('Product status update failed: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update product status. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _updating.remove(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(allProductsProvider);
    final query = _search.text.trim().toLowerCase();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Product Management',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('admin-products-search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: 'Add product',
                        icon: Icons.add,
                        onPressed: () => _edit(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.when(
                  loading: () =>
                      const LoadingView(message: 'Loading products...'),
                  error: (error, stack) => ErrorView(
                    message: 'Could not load products: $error',
                    onRetry: () => ref.invalidate(allProductsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        title: 'No products yet',
                        message: 'Add a product to get started.',
                      );
                    }
                    final filtered = items
                        .where(
                          (product) =>
                              product.name.toLowerCase().contains(query) ||
                              product.description.toLowerCase().contains(query),
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        title: 'No products match your search.',
                        message: 'Try a different search.',
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductImage(
                                imageUrl: product.imageUrl,
                                imageBytes: product.imageBytes,
                                size: 80,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text('Water type: ${product.waterType}'),
                              if (product.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text('${product.sizes.length} sizes'),
                              Row(
                                children: [
                                  Expanded(
                                    child: SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        product.isActive
                                            ? 'Active'
                                            : 'Inactive',
                                      ),
                                      value: product.isActive,
                                      onChanged: _updating.contains(product.id)
                                          ? null
                                          : (value) =>
                                                _setActive(product, value),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _updating.contains(product.id)
                                        ? null
                                        : () => _edit(product),
                                    child: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeFields {
  _SizeFields([ProductSize? size])
    : label = TextEditingController(text: size?.label ?? ''),
      price = TextEditingController(text: size?.price.toString() ?? ''),
      refillPrice = TextEditingController(
        text: size?.refillPrice?.toString() ?? '',
      ),
      available = size?.isAvailable ?? true,
      existing = size != null;

  final TextEditingController label;
  final TextEditingController price;
  final TextEditingController refillPrice;
  bool available;
  final bool existing;

  void dispose() {
    label.dispose();
    price.dispose();
    refillPrice.dispose();
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  static const _addNewWaterType = '';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _newWaterType;
  late final List<_SizeFields> _sizes;
  Uint8List? _imageBytes;
  String? _imageBase64;
  String? _selectedWaterType;
  bool _saving = false;
  bool _picking = false;
  bool _removePhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _description = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _imageBytes = widget.product?.imageBytes;
    _imageBase64 = widget.product?.imageBase64;
    _newWaterType = TextEditingController();
    _selectedWaterType = widget.product?.waterType;
    _sizes = [
      for (final size in widget.product?.sizes ?? <ProductSize>[])
        _SizeFields(size),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _newWaterType.dispose();
    for (final size in _sizes) {
      size.dispose();
    }
    super.dispose();
  }

  String? _validatePrice(String? value) {
    final price = num.tryParse(value?.trim() ?? '');
    return price == null || !price.isFinite || price <= 0
        ? 'Enter a price greater than 0.'
        : null;
  }

  String? _validateWaterType(String? value) {
    if (value == null) return 'Choose a water type.';
    if (value == _addNewWaterType && _newWaterType.text.trim().isEmpty) {
      return AuthValidators.required(_newWaterType.text);
    }
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_saving || _picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final compressed = compressProductImage(bytes);
      if (compressed.lengthInBytes > maxProductImageBytes) {
        throw const ProductImageTooLargeException();
      }
      if (!mounted) return;
      setState(() {
        _imageBytes = compressed;
        _imageBase64 = base64Encode(compressed);
        _removePhoto = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Picking product photo failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = _photoErrorMessage(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String _photoErrorMessage(Object error) {
    if (error is ProductImageTooLargeException) {
      return 'That photo is too large. Choose a smaller image and try again.';
    }
    if (error is PlatformException &&
        (error.code.toLowerCase().contains('denied') ||
            error.code.toLowerCase().contains('permission'))) {
      return 'Gallery access was denied. Allow photo access and try again.';
    }
    return 'Could not load that photo. Choose another image and try again.';
  }

  void _removePickedPhoto() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
      _removePhoto = true;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || _picking || !_formKey.currentState!.validate()) return;
    final waterType = _selectedWaterType == _addNewWaterType
        ? _newWaterType.text.trim()
        : _selectedWaterType!.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final sizes = [
      for (final size in _sizes)
        ProductSize(
          label: size.label.text.trim(),
          price: num.parse(size.price.text.trim()),
          refillPrice: size.refillPrice.text.trim().isEmpty
              ? null
              : num.parse(size.refillPrice.text.trim()),
          isAvailable: size.available,
        ),
    ];
    try {
      final repository = ref.read(productRepositoryProvider);
      if (widget.product case final product?) {
        await repository.updateProduct(
          product.id,
          name: _name.text,
          waterType: waterType,
          description: _description.text,
          imageBase64: _imageBase64,
          removeImage: _removePhoto,
          sizes: sizes,
        );
      } else {
        await repository.createProduct(
          name: _name.text,
          waterType: waterType,
          description: _description.text,
          imageBase64: _imageBase64,
          sizes: sizes,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error, stack) {
      debugPrint('Product save failed: $error\n$stack');
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message?.toString() ?? 'Invalid product data.'
              : 'Could not save product. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final waterTypes = <String>{
      for (final product in productsAsync.asData?.value ?? <Product>[])
        product.waterType,
      if (widget.product != null) widget.product!.waterType,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return PopScope(
      canPop: !_saving && !_picking,
      child: AlertDialog(
        title: Text(widget.product == null ? 'Add product' : 'Edit product'),
        content: SizedBox(
          width: 600,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.product == null) ...[
                    const Text(
                      'New products start inactive. Activate them when ready.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    label: 'Product name',
                    controller: _name,
                    enabled: !_saving,
                    validator: AuthValidators.required,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedWaterType,
                    decoration: const InputDecoration(labelText: 'Water type'),
                    items: [
                      for (final type in waterTypes)
                        DropdownMenuItem(value: type, child: Text(type)),
                      const DropdownMenuItem(
                        value: _addNewWaterType,
                        child: Text('Add new type'),
                      ),
                    ],
                    validator: _validateWaterType,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _selectedWaterType = value;
                          }),
                  ),
                  if (productsAsync.hasError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Could not load existing water types: '
                      '${productsAsync.error}',
                    ),
                  ],
                  if (_selectedWaterType == _addNewWaterType) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'New water type',
                      controller: _newWaterType,
                      enabled: !_saving,
                      validator: (value) =>
                          _selectedWaterType == _addNewWaterType
                          ? AuthValidators.required(value)
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Description',
                    controller: _description,
                    enabled: !_saving,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Product photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ProductImage(
                      imageUrl: _removePhoto ? null : widget.product?.imageUrl,
                      imageBytes: _imageBytes,
                      size: 160,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving || _picking ? null : _pickPhoto,
                        icon: _picking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose from gallery'),
                      ),
                      TextButton.icon(
                        onPressed: _saving || _picking
                            ? null
                            : _removePickedPhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Sizes', style: Theme.of(context).textTheme.titleMedium),
                  for (final size in _sizes) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      key: ObjectKey(size),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'Size label',
                            controller: size.label,
                            enabled: !_saving,
                            validator: AuthValidators.required,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Price',
                            controller: size.price,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validatePrice,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Refill price (optional)',
                            controller: size.refillPrice,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return _validatePrice(value);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Available'),
                            value: size.available,
                            onChanged: _saving
                                ? null
                                : (value) =>
                                      setState(() => size.available = value),
                          ),
                          if (!size.existing)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      setState(() => _sizes.remove(size));
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                            (_) => size.dispose(),
                                          );
                                    },
                              child: const Text('Remove new size'),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Add size',
                    variant: AppButtonVariant.secondary,
                    onPressed: _saving
                        ? null
                        : () => setState(() => _sizes.add(_SizeFields())),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save product',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
