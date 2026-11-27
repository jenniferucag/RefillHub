import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_chip.dart' as status_presentation;
import '../data/order.dart';
import '../data/order_providers.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersListScreen extends ConsumerStatefulWidget {
  const AdminOrdersListScreen({super.key});

  @override
  ConsumerState<AdminOrdersListScreen> createState() =>
      _AdminOrdersListScreenState();
}

class _AdminOrdersListScreenState extends ConsumerState<AdminOrdersListScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedType = 'All';
  String? _selectedWaterType;
  final _searchController = TextEditingController();

  static const _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Picked Up',
    'Preparing',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerOrder> _getFilteredOrders(List<CustomerOrder> orders) {
    var filtered = List<CustomerOrder>.of(orders);
    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((order) => order.status == _selectedStatus)
          .toList();
    }
    if (_selectedType != 'All') {
      filtered = filtered
          .where((order) => order.orderType == _selectedType)
          .toList();
    }
    if (_selectedWaterType != null) {
      filtered = filtered.where((order) {
        if (order.isRefill) return order.waterType == _selectedWaterType;
        return order.items.any((item) => item.waterType == _selectedWaterType);
      }).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order.orderNumber.toLowerCase().contains(query) ||
                order.customerName.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(watchAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Management'), elevation: 0),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('Admin orders stream failed: $error\n$stack');
          final message = error is FirebaseException
              ? error.message ?? error.code
              : error.toString();
          return ErrorView(
            message: 'Could not load orders: $message',
            onRetry: () => ref.invalidate(watchAllOrdersProvider),
          );
        },
        data: (orders) {
          final waterTypes =
              <String>{
                for (final order in orders)
                  if (order.isRefill)
                    order.waterType
                  else
                    ...order.items.map((item) => item.waterType),
              }.toList()..sort(
                (first, second) =>
                    first.toLowerCase().compareTo(second.toLowerCase()),
              );
          final filteredOrders = _getFilteredOrders(orders);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by order # or customer name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              _FilterRow(
                options: _statusOptions,
                selected: _selectedStatus,
                labelFor: (value) => value,
                onSelected: (value) => setState(() => _selectedStatus = value),
              ),
              _FilterRow(
                options: const ['All', 'refill', 'purchase'],
                selected: _selectedType,
                labelFor: (value) => switch (value) {
                  'All' => 'All types',
                  'refill' => 'Refill',
                  _ => 'Purchase',
                },
                onSelected: (value) => setState(() => _selectedType = value),
              ),
              _FilterRow(
                options: ['', ...waterTypes],
                selected: _selectedWaterType ?? '',
                labelFor: (value) => value.isEmpty ? 'All water types' : value,
                onSelected: (value) => setState(
                  () => _selectedWaterType = value.isEmpty ? null : value,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: orders.isEmpty
                    ? const Center(child: Text('No orders yet'))
                    : filteredOrders.isEmpty
                    ? const Center(
                        child: Text('No orders match the selected filters.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminOrderDetailsScreen(order: order),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final String Function(String) labelFor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labelFor(option)),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
            ),
          ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerOrder order;
  final VoidCallback onTap;

  String _waterTypeLabel() {
    if (order.isRefill) return order.waterType;
    final types = order.items.map((item) => item.waterType).toSet().toList()
      ..sort();
    return types.isEmpty ? 'Unspecified' : types.join(', ');
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';

  status_presentation.OrderStatus? _presentationStatus() {
    for (final status in status_presentation.OrderStatus.values) {
      if (status.label == order.status) return status;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(order.isRefill ? 'Refill' : 'Purchase'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            if (_presentationStatus() case final status?)
              status_presentation.StatusChip(status: status)
            else
              Chip(label: Text(order.status)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Water type: ${_waterTypeLabel()}'),
              Text(
                order.totalAmount == 'Price to be confirmed'
                    ? order.totalAmount
                    : '₱${order.totalAmount}',
              ),
              Text(
                '${order.deliveryScheduledAt == null ? 'Requested' : 'Scheduled'} '
                'delivery: ${_formatDateTime(order.deliveryScheduledAt ?? order.deliveryRequestedAt ?? order.createdAt)}',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
