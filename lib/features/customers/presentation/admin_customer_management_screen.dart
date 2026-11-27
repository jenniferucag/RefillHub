import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../data/customer.dart';
import '../data/customer_providers.dart';

class AdminCustomerManagementScreen extends ConsumerStatefulWidget {
  const AdminCustomerManagementScreen({super.key});

  @override
  ConsumerState<AdminCustomerManagementScreen> createState() =>
      _AdminCustomerManagementScreenState();
}

class _AdminCustomerManagementScreenState
    extends ConsumerState<AdminCustomerManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customersAsync = ref.watch(watchAllCustomersProvider);
    final query = _searchQuery.trim().toLowerCase();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Customer Management',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'View, search, and manage registered customers.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              customersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) {
                  debugPrint('Customer stream failed: $error\n$stack');
                  return ErrorView(
                    message:
                        'Could not load customers: ${_errorMessage(error)}',
                    retryLabel: 'Retry',
                    onRetry: () => ref.invalidate(watchAllCustomersProvider),
                  );
                },
                data: (customers) {
                  final filteredCustomers = customers.where((customer) {
                    if (query.isEmpty) return true;
                    return customer.name.toLowerCase().contains(query) ||
                        customer.email.toLowerCase().contains(query) ||
                        customer.phone.toLowerCase().contains(query);
                  }).toList();
                  if (filteredCustomers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              query.isEmpty
                                  ? 'No customers found'
                                  : 'No results for "$_searchQuery"',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Total: ${filteredCustomers.length} customer${filteredCustomers.length == 1 ? '' : 's'}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (_searchQuery.trim().isNotEmpty)
                              Chip(
                                label: Text(
                                  'Search: ${_searchQuery.trim()}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onDeleted: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                          ],
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredCustomers.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: scheme.outlineVariant),
                            itemBuilder: (context, index) => _CustomerRow(
                              customer: filteredCustomers[index],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerRow extends ConsumerStatefulWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends ConsumerState<_CustomerRow> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ordersAsync = ref.watch(customerOrderCountProvider(customer.id));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showCustomerDetails(context, customer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        customer.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        customer.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !_updating,
                  onSelected: (value) {
                    if (value == 'details') {
                      _showCustomerDetails(context, customer);
                    } else if (value == 'toggle') {
                      _toggleStatus(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('View Details')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            customer.isActive
                                ? Icons.block
                                : Icons.check_circle,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer.isActive ? 'Deactivate' : 'Activate',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ordersAsync.when(
                  loading: () => const Chip(label: Text('Loading orders')),
                  error: (error, stack) =>
                      const Chip(label: Text('Orders unavailable')),
                  data: (orderCount) => Chip(
                    label: Text(
                      '$orderCount ${orderCount == 1 ? 'order' : 'orders'}',
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    customer.isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: customer.isActive
                          ? scheme.onTertiaryContainer
                          : scheme.onErrorContainer,
                    ),
                  ),
                  backgroundColor: customer.isActive
                      ? scheme.tertiaryContainer
                      : scheme.errorContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final ordersAsync = ref.watch(
            customerOrderCountProvider(customer.id),
          );
          return AlertDialog(
            title: Text(customer.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DetailRow('Email', customer.email),
                  _DetailRow('Phone', customer.phone),
                  _DetailRow('Address', customer.address),
                  _DetailRow(
                    'Status',
                    customer.isActive ? 'Active' : 'Inactive',
                    valueColor: customer.isActive
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Orders',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ordersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Text(
                      'Could not load order count: ${_errorMessage(error)}',
                    ),
                    data: (orderCount) => Text('Total orders: $orderCount'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final customer = widget.customer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          customer.isActive ? 'Deactivate Customer?' : 'Activate Customer?',
        ),
        content: Text(
          customer.isActive
              ? 'This customer will not be able to place orders.'
              : 'This customer will be able to place orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(customer.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await ref
          .read(customerRepositoryProvider)
          .toggleCustomerStatus(customer.id, !customer.isActive);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer ${customer.isActive ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } catch (error, stack) {
      debugPrint('Customer status update failed: $error\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update customer: ${_errorMessage(error)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

String _errorMessage(Object error) {
  if (error is FirebaseException) {
    final message = error.message?.trim();
    return message == null || message.isEmpty ? error.code : message;
  }
  return error.toString();
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: valueColor)),
        ),
      ],
    ),
  );
}
