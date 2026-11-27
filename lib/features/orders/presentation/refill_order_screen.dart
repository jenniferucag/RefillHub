import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/requested_date_time_field.dart';
import '../../auth/auth_controller.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../orders/data/order_providers.dart';
import '../../products/data/product.dart';
import '../../products/data/product_providers.dart';

class RefillOrderScreen extends ConsumerStatefulWidget {
  const RefillOrderScreen({super.key});

  @override
  ConsumerState<RefillOrderScreen> createState() => _RefillOrderScreenState();
}

class _RefillOrderScreenState extends ConsumerState<RefillOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _count = TextEditingController(text: '1');
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String? _waterType;
  String? _selectedSizeKey;
  DateTime? _pickup;
  DateTime? _delivery;
  bool _prefilled = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _count.dispose();
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _prefill(AuthController auth) {
    if (_prefilled) return;
    final data = auth.profile?.data;
    if (data == null) return;
    _prefilled = true;
    if (data['address'] is String) _address.text = data['address'] as String;
    if (data['phone'] is String) _phone.text = data['phone'] as String;
  }

  Future<void> _submit(Product product, ProductSize size) async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_pickup == null || _delivery == null) {
      setState(() => _error = 'Choose both requested dates and times.');
      return;
    }
    final count = int.parse(_count.text.trim());
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .placeRefillOrder(
            productId: product.id,
            waterType: product.waterType,
            sizeLabel: size.label,
            quantity: count,
            address: _address.text,
            phone: _phone.text,
            notes: _notes.text,
            pickupRequestedAt: _pickup!,
            deliveryRequestedAt: _delivery!,
          );
      if (mounted) context.pushReplacement('/order-confirmation', extra: order);
    } on FirebaseException catch (error) {
      debugPrint(
        'Refill order Firebase error (${error.code}): ${error.message}',
      );
      if (mounted) {
        setState(
          () => _error = 'Could not place your refill order. Please try again.',
        );
      }
    } catch (error) {
      debugPrint('Refill order placement failed: $error');
      if (mounted) {
        setState(
          () => _error =
              'Could not place your refill order. Please review your details and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (auth.profile?.data == null) {
      return const Scaffold(
        appBar: _RefillAppBar(),
        body: LoadingView(message: 'Loading your profile...'),
      );
    }
    _prefill(auth);
    final products = ref.watch(activeProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Refill my container')),
      body: products.when(
        loading: () => const LoadingView(message: 'Loading sizes...'),
        error: (error, stack) => ErrorView(
          message: 'Could not load products: $error',
          onRetry: () => ref.invalidate(activeProductsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No products available yet',
              message: 'Please check back later.',
            );
          }
          final waterTypeOptions =
              items.map((product) => product.waterType).toSet().toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final selectedWaterType = waterTypeOptions.contains(_waterType)
              ? _waterType
              : null;
          final typedProducts = selectedWaterType == null
              ? <Product>[]
              : items
                    .where((product) => product.waterType == selectedWaterType)
                    .toList();
          final sizeOptions = <_RefillSizeOption>[
            for (final product in typedProducts)
              for (var index = 0; index < product.sizes.length; index++)
                if (product.sizes[index].isAvailable)
                  _RefillSizeOption(product, product.sizes[index], index),
          ];
          final selectedMatches = sizeOptions
              .where((option) => option.key == _selectedSizeKey)
              .toList();
          final selectedOption = selectedMatches.isEmpty
              ? null
              : selectedMatches.first;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Choose water type',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWaterType,
                      decoration: const InputDecoration(
                        labelText: 'Water type',
                      ),
                      items: [
                        for (final type in waterTypeOptions)
                          DropdownMenuItem(value: type, child: Text(type)),
                      ],
                      validator: (value) =>
                          value == null ? 'Choose a water type.' : null,
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() {
                              _waterType = value;
                              _selectedSizeKey = null;
                            }),
                    ),
                    if (selectedWaterType == null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Choose a water type to see its container sizes.',
                      ),
                    ] else if (sizeOptions.isEmpty) ...[
                      const SizedBox(height: 12),
                      const EmptyState(
                        title: 'No products available for this type',
                        message: 'Choose another water type.',
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      Text(
                        'Container details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('refill-size-$selectedWaterType'),
                        initialValue: selectedOption?.key,
                        decoration: const InputDecoration(
                          labelText: 'Container size',
                        ),
                        items: [
                          for (final option in sizeOptions)
                            DropdownMenuItem(
                              value: option.key,
                              child: Text(
                                sizeOptions
                                            .where(
                                              (entry) =>
                                                  entry.size.label ==
                                                  option.size.label,
                                            )
                                            .length >
                                        1
                                    ? '${option.size.label} · '
                                          '${option.product.name}'
                                    : option.size.label,
                              ),
                            ),
                        ],
                        validator: (value) =>
                            value == null ? 'Choose a container size.' : null,
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                  setState(() => _selectedSizeKey = value),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedOption == null
                            ? 'Select a size to see its refill price.'
                            : selectedOption.size.refillPrice == null
                            ? 'Price to be confirmed'
                            : '₱${selectedOption.size.refillPrice} per container',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _count,
                        enabled: !_submitting,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Container quantity',
                        ),
                        validator: (value) {
                          final count = int.tryParse(value?.trim() ?? '');
                          return count == null || count < 1 || count > 99
                              ? 'Enter a quantity from 1 to 99.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 24),
                      Text(
                        'Requested schedule',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      RequestedDateTimeField(
                        label: 'Requested pickup',
                        value: _pickup,
                        onChanged: (value) => setState(() {
                          _pickup = value;
                          if (_delivery != null && !_delivery!.isAfter(value)) {
                            _delivery = null;
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                      RequestedDateTimeField(
                        label: 'Requested delivery',
                        value: _delivery,
                        mustBeAfter: _pickup,
                        onChanged: (value) => setState(() => _delivery = value),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('The station will confirm your schedule.'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Confirm address',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Delivery address',
                        controller: _address,
                        enabled: !_submitting,
                        keyboardType: TextInputType.streetAddress,
                        validator: AuthValidators.required,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Contact phone',
                        controller: _phone,
                        enabled: !_submitting,
                        keyboardType: TextInputType.phone,
                        validator: AuthValidators.philippinePhone,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Notes (optional)',
                        controller: _notes,
                        enabled: !_submitting,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.payments_outlined),
                        title: Text('Cash on Delivery'),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('Review refill'),
                          subtitle: Text(
                            'Water type: $selectedWaterType\n'
                            '${selectedOption?.product.name ?? 'Container'} · '
                            '${selectedOption?.size.label ?? 'Not selected'} × '
                            '${_count.text} containers\n'
                            'Pickup: ${_format(_pickup)}\n'
                            'Delivery: ${_format(_delivery)}\n'
                            '${selectedOption?.size.refillPrice == null ? 'Price to be confirmed' : '₱${selectedOption!.size.refillPrice} per container'}',
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Place refill order',
                        isLoading: _submitting,
                        onPressed: _submitting || selectedOption == null
                            ? null
                            : () => _submit(
                                selectedOption.product,
                                selectedOption.size,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _format(DateTime? date) => date == null
      ? 'Not selected'
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')} '
            '${TimeOfDay.fromDateTime(date).format(context)}';
}

class _RefillSizeOption {
  const _RefillSizeOption(this.product, this.size, this.index);

  final Product product;
  final ProductSize size;
  final int index;

  String get key => '${product.id}::$index';
}

class _RefillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _RefillAppBar();

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Refill my container'));

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
