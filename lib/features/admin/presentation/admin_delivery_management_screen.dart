import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/auth_controller.dart';
import '../../orders/data/order.dart';
import '../../orders/data/order_providers.dart';
import '../../orders/data/order_status.dart';

class AdminDeliveryManagementScreen extends ConsumerStatefulWidget {
  const AdminDeliveryManagementScreen({super.key});

  @override
  ConsumerState<AdminDeliveryManagementScreen> createState() =>
      _AdminDeliveryManagementScreenState();
}

class _AdminDeliveryManagementScreenState
    extends ConsumerState<AdminDeliveryManagementScreen> {
  String _selectedStatus = 'All';

  static const _statusOptions = [
    'All',
    'Confirmed',
    'Picked Up',
    'Preparing',
    'Out for Delivery',
  ];

  DateTime? _scheduleFor(CustomerOrder order) =>
      order.isRefill ? order.pickupScheduledAt : order.deliveryScheduledAt;

  int _compareOrders(CustomerOrder first, CustomerOrder second) {
    final firstTime = _scheduleFor(first);
    final secondTime = _scheduleFor(second);
    if (firstTime == null) return secondTime == null ? 0 : 1;
    if (secondTime == null) return -1;
    final byTime = firstTime.compareTo(secondTime);
    return byTime == 0
        ? first.orderNumber.compareTo(second.orderNumber)
        : byTime;
  }

  int _compareDays(DateTime? first, DateTime? second) {
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }

  Map<DateTime?, List<CustomerOrder>> _groupByScheduleDay(
    List<CustomerOrder> orders,
  ) {
    final groups = <DateTime?, List<CustomerOrder>>{};
    for (final order in orders) {
      final schedule = _scheduleFor(order);
      final day = schedule == null
          ? null
          : DateTime(schedule.year, schedule.month, schedule.day);
      groups.putIfAbsent(day, () => []).add(order);
    }
    for (final group in groups.values) {
      group.sort(_compareOrders);
    }
    return groups;
  }

  String _dayLabel(DateTime? day) {
    if (day == null) return 'Schedule not set';
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(watchAllOrdersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              debugPrint('Delivery order stream failed: $error\n$stack');
              final message = error is FirebaseException
                  ? error.message ?? error.code
                  : error.toString();
              return ErrorView(
                message: 'Could not load delivery orders: $message',
                retryLabel: 'Retry',
                onRetry: () => ref.invalidate(watchAllOrdersProvider),
              );
            },
            data: (orders) {
              final deliveryOrders = orders
                  .where(
                    (order) => const {
                      'Confirmed',
                      'Picked Up',
                      'Preparing',
                      'Out for Delivery',
                    }.contains(order.status),
                  )
                  .toList();
              final filteredOrders =
                  deliveryOrders
                      .where(
                        (order) =>
                            _selectedStatus == 'All' ||
                            order.status == _selectedStatus,
                      )
                      .toList()
                    ..sort(_compareOrders);
              final groups = _groupByScheduleDay(filteredOrders);
              final days = groups.keys.toList()..sort(_compareDays);

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Management',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage order delivery status and assign delivery personnel.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final status in _statusOptions)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: _selectedStatus == status,
                              onSelected: (selected) => setState(
                                () =>
                                    _selectedStatus = selected ? status : 'All',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DeliverySummary(orders: deliveryOrders),
                  const SizedBox(height: 20),
                  if (deliveryOrders.isEmpty)
                    _EmptyDeliveryState(
                      title: 'No orders to deliver',
                      message: 'There are no active delivery orders.',
                    )
                  else if (filteredOrders.isEmpty)
                    _EmptyDeliveryState(
                      title: 'No orders with this status',
                      message: 'Choose another status to see active orders.',
                    )
                  else
                    for (final day in days) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Text(
                          _dayLabel(day),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      for (final order in groups[day]!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeliveryOrderCard(
                            key: ValueKey(order.id),
                            order: order,
                          ),
                        ),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyDeliveryState extends StatelessWidget {
  const _EmptyDeliveryState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({required this.orders});

  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Confirmed', Colors.blue),
      ('Picked Up', Colors.deepOrange),
      ('Preparing', Colors.purple),
      ('Out for Delivery', Colors.cyan),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final columns = (constraints.maxWidth / 160).floor().clamp(1, 4);
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (label, color) in metrics)
              SizedBox(
                width: cardWidth,
                child: _DeliveryMetricCard(
                  label: label,
                  value: orders.where((order) => order.status == label).length,
                  color: color,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DeliveryMetricCard extends StatelessWidget {
  const _DeliveryMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.local_shipping_outlined, color: color),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text('$value', style: theme.textTheme.headlineLarge),
        ],
      ),
    );
  }
}

class _DeliveryOrderCard extends ConsumerStatefulWidget {
  const _DeliveryOrderCard({required this.order, super.key});

  final CustomerOrder order;

  @override
  ConsumerState<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends ConsumerState<_DeliveryOrderCard> {
  late final TextEditingController _deliveryPersonController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _deliveryPersonController = TextEditingController(
      text: widget.order.deliveryPerson ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _DeliveryOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.deliveryPerson != widget.order.deliveryPerson) {
      _deliveryPersonController.text = widget.order.deliveryPerson ?? '';
    }
  }

  @override
  void dispose() {
    _deliveryPersonController.dispose();
    super.dispose();
  }

  bool _canTransitionTo(OrderStatus next) => canTransitionOrderStatus(
    orderType: widget.order.orderType,
    current: widget.order.status,
    next: next.label,
  );

  OrderStatus? _availableDeliveryAction() {
    final actions = [
      if (widget.order.isRefill) OrderStatus.pickedUp,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    for (final action in actions) {
      if (_canTransitionTo(action)) return action;
    }
    return null;
  }

  Future<void> _updateDeliveryPerson() async {
    final personName = _deliveryPersonController.text.trim();
    if (personName.isEmpty) {
      _showMessage('Please enter a delivery person name.');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateDeliveryPerson(widget.order.id, personName);
      if (mounted) _showMessage('Delivery person updated.');
    } catch (error, stackTrace) {
      debugPrint('Could not update delivery person: $error\n$stackTrace');
      if (mounted) _showMessage('Could not update delivery person: $error');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(OrderStatus nextStatus) async {
    if (!_canTransitionTo(nextStatus)) {
      _showMessage('This status transition is not valid.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update to ${nextStatus.label}?'),
        content: Text(
          'Are you sure you want to change status to ${nextStatus.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!_canTransitionTo(nextStatus)) {
      _showMessage('This status transition is no longer valid.');
      return;
    }

    final changedBy = AuthScope.of(context).backend.currentUserId;
    if (changedBy == null || changedBy.trim().isEmpty) {
      _showMessage('An admin session is required.');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(widget.order.id, nextStatus.label, changedBy);
      if (mounted) _showMessage('Order status updated to ${nextStatus.label}.');
    } catch (error, stackTrace) {
      debugPrint('Could not update delivery status: $error\n$stackTrace');
      if (mounted) _showMessage('Could not update order status: $error');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not scheduled';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) => switch (status) {
    'Confirmed' => Colors.blue,
    'Picked Up' => Colors.deepOrange,
    'Preparing' => Colors.purple,
    'Out for Delivery' => Colors.cyan,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);
    final nextAction = _availableDeliveryAction();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.orderNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.customerName,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        widget.order.isRefill ? 'Refill' : 'Purchase',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  widget.order.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow('Address', widget.order.address),
          _DetailRow('Phone', widget.order.phone),
          _DetailRow(
            'Scheduled pickup',
            widget.order.isRefill
                ? _formatDateTime(widget.order.pickupScheduledAt)
                : 'Not applicable',
          ),
          _DetailRow(
            'Scheduled delivery',
            _formatDateTime(widget.order.deliveryScheduledAt),
          ),
          _DetailRow(
            'Assigned person',
            widget.order.deliveryPerson?.trim().isNotEmpty == true
                ? widget.order.deliveryPerson!
                : 'Not assigned',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deliveryPersonController,
                  decoration: InputDecoration(
                    hintText: 'Assign delivery person',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  enabled: !_isUpdating,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isUpdating ? null : _updateDeliveryPerson,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.order.deliveryPerson?.trim().isNotEmpty == true
                      ? 'Save'
                      : 'Assign',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (nextAction != null)
                ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _updateStatus(nextAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(nextAction.label),
                  ),
                  child: Text(switch (nextAction) {
                    OrderStatus.pickedUp => 'Mark Picked Up',
                    OrderStatus.outForDelivery => 'Mark Out for Delivery',
                    OrderStatus.delivered => 'Mark Delivered',
                    _ => nextAction.label,
                  }, style: const TextStyle(color: Colors.white)),
                ),
              TextButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _showOrderDetails(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Order ${widget.order.orderNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Type', widget.order.isRefill ? 'Refill' : 'Purchase'),
              _DetailRow('Customer', widget.order.customerName),
              _DetailRow('Phone', widget.order.phone),
              _DetailRow('Address', widget.order.address),
              _DetailRow(
                'Pickup',
                widget.order.isRefill
                    ? _formatDateTime(widget.order.pickupScheduledAt)
                    : 'Not applicable',
              ),
              _DetailRow(
                'Delivery',
                _formatDateTime(widget.order.deliveryScheduledAt),
              ),
              _DetailRow(
                'Delivery person',
                widget.order.deliveryPerson ?? 'Not assigned',
              ),
              const SizedBox(height: 12),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final item in widget.order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${item.quantity}x ${item.productName} (${item.sizeLabel}) · '
                    '${item.waterType} · '
                    '${item.lineTotal == null ? 'Price to be confirmed' : '₱${item.lineTotal}'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (widget.order.items.isEmpty && widget.order.isRefill)
                Text(
                  '${widget.order.containerCount ?? 0}x '
                  '${widget.order.containerSize ?? 'Container'} · '
                  '${widget.order.waterType}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
