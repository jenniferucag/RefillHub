import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/requested_date_time_field.dart';
import '../../auth/auth_controller.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../cart/data/cart_item.dart';
import '../../cart/data/cart_provider.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/data/order_providers.dart';
import '../../products/data/product_providers.dart';
import '../data/checkout.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  bool _prefilled = false;
  bool _submitting = false;
  String? _error;
  DateTime? _deliveryRequestedAt;

  @override
  void dispose() {
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
    final address = data['address'];
    final phone = data['phone'];
    if (address is String) _address.text = address;
    if (phone is String) _phone.text = phone;
  }

  Future<void> _submit(String uid, List<CartItem> items) async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_deliveryRequestedAt == null) {
      setState(() => _error = 'Choose a requested delivery date and time.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final products = await ref.refresh(cartProductCheckProvider.future);
      final problem = items.any((i) => cartItemWarning(i, products) != null);
      if (problem) {
        throw const CheckoutException(
          'Some cart items changed or are unavailable. Review your cart first.',
        );
      }

      final repository = ref.read(orderRepositoryProvider);
      final order = await repository.placeOrder(
        CheckoutRequest(
          items: items,
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          notes: _notes.text.trim(),
          deliveryFee: ref.read(deliveryFeeProvider),
          deliveryRequestedAt: _deliveryRequestedAt,
        ),
      );

      await ref.read(cartProvider(uid).notifier).clear();

      if (!mounted) return;

      // Navigate to order confirmation screen with the order details
      // ignore: use_build_context_synchronously
      context.pushReplacement('/order-confirmation', extra: order);
    } on FirebaseException catch (error) {
      debugPrint('Checkout Firebase error (${error.code}): ${error.message}');
      if (!mounted) return;
      setState(() => _error = 'Could not place your order. Please try again.');
    } catch (error) {
      debugPrint('Checkout failed: $error');
      if (!mounted) return;
      setState(
        () => _error = error is CheckoutException
            ? error.message
            : 'Could not place your order. Please review your details and try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final uid = auth.status == AuthStatus.customer
        ? auth.backend.currentUserId
        : null;
    final appBar = AppBar(
      title: const Text('Checkout'),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
        icon: const Icon(Icons.arrow_back),
      ),
    );
    if (uid == null || auth.profile?.data == null) {
      return Scaffold(
        appBar: appBar,
        body: const LoadingView(message: 'Loading checkout...'),
      );
    }
    _prefill(auth);
    final cart = ref.watch(cartProvider(uid));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: cart.when(
          loading: () => const LoadingView(message: 'Loading cart...'),
          error: (error, stack) =>
              Center(child: Text('Could not load your cart: $error')),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Your cart is empty',
                message: 'Add a product before checking out.',
                icon: Icons.shopping_cart_outlined,
              );
            }
            final subtotal = cartTotal(items);
            final fee = ref.watch(deliveryFeeProvider);
            final total = fee == null ? subtotal : addDecimals(subtotal, fee);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Delivery details',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Delivery address',
                            controller: _address,
                            enabled: !_submitting,
                            keyboardType: TextInputType.streetAddress,
                            textInputAction: TextInputAction.next,
                            validator: AuthValidators.required,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Contact phone',
                            controller: _phone,
                            enabled: !_submitting,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: AuthValidators.philippinePhone,
                          ),
                          const SizedBox(height: 12),
                          RequestedDateTimeField(
                            label: 'Requested delivery',
                            value: _deliveryRequestedAt,
                            onChanged: (value) =>
                                setState(() => _deliveryRequestedAt = value),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'The station will confirm your schedule.',
                            ),
                          ),
                          if (_deliveryRequestedAt == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Select a requested delivery time to continue.',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Notes (optional)',
                            controller: _notes,
                            enabled: !_submitting,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Payment method', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined),
                          SizedBox(width: 12),
                          Text('Cash on Delivery'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Order summary', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.productName} (${item.sizeLabel}) '
                                      '× ${item.quantity}',
                                    ),
                                  ),
                                  Text(cartTotal([item])),
                                ],
                              ),
                            ),
                          const Divider(),
                          _SummaryRow('Subtotal', subtotal),
                          if (fee != null) _SummaryRow('Delivery fee', fee),
                          _SummaryRow('Total', total, bold: true),
                          if (_deliveryRequestedAt != null) ...[
                            const Divider(),
                            Text(
                              'Requested delivery: '
                              '${_formatDateTime(context, _deliveryRequestedAt!)}',
                            ),
                            const Text(
                              'The station will confirm your schedule.',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Place order',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : () => _submit(uid, items),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime dateTime) =>
    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
    '${dateTime.day.toString().padLeft(2, '0')} '
    '${TimeOfDay.fromDateTime(dateTime).format(context)}';
