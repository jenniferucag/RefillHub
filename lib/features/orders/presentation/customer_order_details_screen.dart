import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../data/order.dart';
import '../data/order_providers.dart';
import '../data/order_status.dart';

class CustomerOrderDetailsScreen extends ConsumerStatefulWidget {
  final CustomerOrder initialOrder;

  const CustomerOrderDetailsScreen({super.key, required this.initialOrder});

  @override
  ConsumerState<CustomerOrderDetailsScreen> createState() =>
      _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState
    extends ConsumerState<CustomerOrderDetailsScreen> {
  bool _isCancelling = false;

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final repository = ref.read(orderRepositoryProvider);
      final userId = widget.initialOrder.customerId;

      await repository.updateOrderStatus(
        widget.initialOrder.id,
        'Cancelled',
        userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for real-time updates
    final orderAsync = ref.watch(watchOrderProvider(widget.initialOrder.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), elevation: 0),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Could not load order: $error',
          onRetry: () =>
              ref.invalidate(watchOrderProvider(widget.initialOrder.id)),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(order.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Chip(
                              label: Text(
                                order.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _getStatusColor(order.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Status Stepper
                _StatusStepper(status: order.status, isRefill: order.isRefill),

                const SizedBox(height: 20),

                // Cancelled State (if applicable)
                if (order.status == 'Cancelled')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Cancelled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This order was cancelled by you.',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Items Section
                _SectionTitle(
                  title: order.items.isEmpty
                      ? 'Refill details'
                      : 'Items (${order.items.length})',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: order.items.isEmpty
                          ? const [Text('Container details are shown above.')]
                          : order.items.asMap().entries.map((entry) {
                              final item = entry.value;
                              return Column(
                                children: [
                                  if (entry.key > 0) const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              item.sizeLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Water type: ${item.waterType}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            item.unitPrice == null
                                                ? '${item.quantity}x Price to be confirmed'
                                                : '${item.quantity}x ₱${item.unitPrice}',
                                          ),
                                          if (item.lineTotal != null)
                                            Text(
                                              '= ₱${item.lineTotal}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Information
                _SectionTitle(title: 'Delivery Information'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Name', value: order.customerName),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Phone', value: order.phone),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Address', value: order.address),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _SectionTitle(title: 'Order type and requested schedule'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'Type',
                          value: order.isRefill ? 'Refill' : 'Purchase',
                        ),
                        if (order.isRefill) ...[
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Water type', value: order.waterType),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Container',
                            value:
                                '${order.containerSize ?? '—'} × '
                                '${order.containerCount ?? '—'}',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Requested pickup',
                            value: _formatOptional(order.pickupRequestedAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Confirmed pickup',
                            value: _formatOptional(order.pickupScheduledAt),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Requested delivery',
                          value: _formatOptional(order.deliveryRequestedAt),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Confirmed delivery',
                          value: _formatOptional(order.deliveryScheduledAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Order Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:'),
                            Text(
                              order.totalAmount == 'Price to be confirmed'
                                  ? order.totalAmount
                                  : '₱${order.totalAmount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Method:'),
                            Text(order.paymentMethod),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Notes (if present)
                if (order.notes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Notes'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(order.notes),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Status History
                _SectionTitle(title: 'Status History'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: order.statusHistory.asMap().entries.map((
                        entry,
                      ) {
                        final history = entry.value;
                        final isFirst = entry.key == 0;
                        return Column(
                          children: [
                            if (!isFirst) const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(history.status),
                                      ),
                                    ),
                                    if (!isFirst)
                                      Container(
                                        width: 2,
                                        height: 20,
                                        color: Colors.grey[300],
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        history.status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(history.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cancel Button (only for Pending orders)
                if (order.status == 'Pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : _cancelOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isCancelling ? 'Cancelling...' : 'Cancel Order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pending' => Colors.orange,
      'Confirmed' => Colors.blue,
      'Picked Up' => Colors.deepOrange,
      'Preparing' => Colors.purple,
      'Out for Delivery' => Colors.cyan,
      'Delivered' => Colors.green,
      'Cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatOptional(DateTime? dateTime) =>
      dateTime == null ? 'Not confirmed' : _formatDateTime(dateTime);
}

class _StatusStepper extends StatelessWidget {
  final String status;
  final bool isRefill;

  const _StatusStepper({required this.status, required this.isRefill});

  int _getStatusIndex(String status) {
    if (status == 'Cancelled') return -1;
    return orderStatusPath(
      isRefill: isRefill,
    ).indexWhere((step) => step.label == status);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStatusIndex(status);
    final isCancelled = status == 'Cancelled';
    final statusSequence = [
      for (final step in orderStatusPath(isRefill: isRefill)) step.label,
    ];

    if (isCancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(statusSequence.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? _getStatusColor(statusSequence[stepIndex])
                            : Colors.grey[300],
                      ),
                      child: Center(
                        child: Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCompleted || isCurrent
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusSequence[stepIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? _getStatusColor(statusSequence[stepIndex])
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < currentIndex;

              return Container(
                height: 2,
                color: isCompleted ? Colors.green : Colors.grey[300],
              );
            }
          }),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pending' => Colors.orange,
      'Confirmed' => Colors.blue,
      'Picked Up' => Colors.deepOrange,
      'Preparing' => Colors.purple,
      'Out for Delivery' => Colors.cyan,
      'Delivered' => Colors.green,
      _ => Colors.grey,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
