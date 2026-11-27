import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../../core/widgets/requested_date_time_field.dart';
import '../data/order.dart';
import '../data/order_providers.dart';
import '../data/order_status.dart';

class AdminOrderDetailsScreen extends ConsumerStatefulWidget {
  final CustomerOrder order;

  const AdminOrderDetailsScreen({super.key, required this.order}) : super();

  @override
  ConsumerState<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState
    extends ConsumerState<AdminOrderDetailsScreen> {
  late TextEditingController _deliveryPersonController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _deliveryPersonController = TextEditingController(
      text: widget.order.deliveryPerson ?? '',
    );
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

  OrderStatus? _statusFromLabel(String label) {
    for (final status in OrderStatus.values) {
      if (status.label == label) return status;
    }
    return null;
  }

  String? _adminUid() => AuthScope.of(context).backend.currentUserId;

  Future<void> _updateOrderStatus(
    String newStatus, {
    String? cancellationReason,
  }) async {
    final nextStatus = _statusFromLabel(newStatus);
    if (nextStatus == null || !_canTransitionTo(nextStatus)) {
      _showMessage('This status transition is not valid.');
      return;
    }
    final userId = _adminUid();
    if (userId == null || userId.trim().isEmpty) {
      _showMessage('Could not identify the signed-in administrator.');
      return;
    }
    final repository = ref.read(orderRepositoryProvider);

    try {
      setState(() => _isUpdating = true);
      await repository.updateOrderStatus(
        widget.order.id,
        newStatus,
        userId,
        cancellationReason: cancellationReason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
        // Refresh by popping and re-opening
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('Could not update order status: $e\n$stackTrace');
      if (mounted) {
        _showMessage('Error updating status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showConfirmationDialog() async {
    if (!_canTransitionTo(OrderStatus.confirmed)) {
      _showMessage('This order cannot be confirmed from its current status.');
      return;
    }
    final confirmation = await showDialog<_OrderConfirmation>(
      context: context,
      builder: (_) => _ConfirmOrderDialog(order: widget.order),
    );
    if (confirmation == null || !mounted) return;
    final changedBy = _adminUid();
    if (changedBy == null || changedBy.trim().isEmpty) {
      _showMessage('Could not identify the signed-in administrator.');
      return;
    }
    try {
      setState(() => _isUpdating = true);
      await ref
          .read(orderRepositoryProvider)
          .confirmOrder(
            order: widget.order,
            changedBy: changedBy,
            deliveryScheduledAt: confirmation.deliveryScheduledAt,
            pickupScheduledAt: confirmation.pickupScheduledAt,
            totalAmount: confirmation.totalAmount,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order confirmed.')));
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not confirm order: $error\n$stackTrace');
      if (mounted) {
        _showMessage('Error confirming order: $error');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveDeliveryPerson() async {
    final repository = ref.read(orderRepositoryProvider);
    final personName = _deliveryPersonController.text.trim();

    if (personName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery person name')),
      );
      return;
    }

    try {
      setState(() => _isUpdating = true);
      await repository.updateDeliveryPerson(widget.order.id, personName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Delivery person saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showStatusDialog(String newStatus) async {
    final nextStatus = _statusFromLabel(newStatus);
    if (nextStatus == null || !_canTransitionTo(nextStatus)) {
      _showMessage('This status transition is not valid.');
      return;
    }
    if (nextStatus == OrderStatus.cancelled) {
      await _showRejectDialog();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm status change'),
        content: Text('Update order status to $newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateOrderStatus(newStatus);
  }

  Future<void> _showRejectDialog() async {
    if (!_canTransitionTo(OrderStatus.cancelled)) {
      _showMessage('This order cannot be rejected from its current status.');
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectOrderDialog(),
    );
    if (reason != null && mounted) {
      await _updateOrderStatus(
        OrderStatus.cancelled.label,
        cancellationReason: reason,
      );
    }
  }

  List<Widget> _itemRows() {
    if (widget.order.items.isEmpty) {
      if (!widget.order.isRefill) return [const Text('No items recorded.')];
      return [
        Text('Water type: ${widget.order.waterType}'),
        Text('Container size: ${widget.order.containerSize ?? '—'}'),
        Text('Quantity: ${widget.order.containerCount ?? '—'}'),
        const Text('Unit price: Price to be confirmed'),
      ];
    }
    return [
      for (final entry in widget.order.items.asMap().entries)
        Column(
          children: [
            if (entry.key > 0) const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        entry.value.sizeLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Water type: ${entry.value.waterType}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.value.unitPrice == null
                          ? '${entry.value.quantity}x Price to be confirmed'
                          : '${entry.value.quantity}x ₱${entry.value.unitPrice}',
                    ),
                    if (entry.value.lineTotal != null)
                      Text(
                        '= ₱${entry.value.lineTotal}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _canTransitionTo(OrderStatus.confirmed);
    final canPickUp = _canTransitionTo(OrderStatus.pickedUp);
    final canStartPreparing = _canTransitionTo(OrderStatus.preparing);
    final canMarkOutForDelivery = _canTransitionTo(OrderStatus.outForDelivery);
    final canMarkDelivered = _canTransitionTo(OrderStatus.delivered);
    final canReject = _canTransitionTo(OrderStatus.cancelled);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), elevation: 0),
      body: SingleChildScrollView(
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
                              widget.order.orderNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${widget.order.status}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            widget.order.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _getStatusColor(widget.order.status),
                        ),
                      ],
                    ),
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
                      value: widget.order.isRefill ? 'Refill' : 'Purchase',
                    ),
                    if (widget.order.isRefill) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Water type',
                        value: widget.order.waterType,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Container',
                        value:
                            '${widget.order.containerSize ?? '—'} × '
                            '${widget.order.containerCount ?? '—'}',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Requested pickup',
                        value: _formatOptional(widget.order.pickupRequestedAt),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Scheduled pickup',
                        value: _formatOptional(widget.order.pickupScheduledAt),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Requested delivery',
                      value: _formatOptional(widget.order.deliveryRequestedAt),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Scheduled delivery',
                      value: _formatOptional(widget.order.deliveryScheduledAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Customer Information
            _SectionTitle(title: 'Customer Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: widget.order.customerName),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Phone', value: widget.order.phone),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Address', value: widget.order.address),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Items
            _SectionTitle(title: 'Items (${widget.order.items.length})'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: _itemRows()),
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
                          widget.order.totalAmount == 'Price to be confirmed'
                              ? widget.order.totalAmount
                              : '₱${widget.order.totalAmount}',
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
                        Text(widget.order.paymentMethod),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes
            _SectionTitle(title: 'Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.order.notes.isEmpty ? '—' : widget.order.notes,
                ),
              ),
            ),
            if (widget.order.cancellationReason != null) ...[
              const SizedBox(height: 16),
              _SectionTitle(title: 'Rejection reason'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.order.cancellationReason!),
                ),
              ),
            ],

            // Delivery Person
            _SectionTitle(title: 'Delivery Person (Optional)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _deliveryPersonController,
                      decoration: InputDecoration(
                        hintText: 'Enter delivery person name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _saveDeliveryPerson,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status History
            _SectionTitle(title: 'Status History'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.order.statusHistory.asMap().entries.map((
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(
                                    'by ${history.changedBy}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
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

            // Action Buttons
            _SectionTitle(title: 'Actions'),
            Column(
              children: [
                if (canConfirm)
                  _ActionButton(
                    label: 'Confirm',
                    color: Colors.blue,
                    onPressed: _isUpdating ? null : _showConfirmationDialog,
                  ),
                if (canPickUp)
                  _ActionButton(
                    label: 'Mark Picked Up',
                    color: Colors.deepOrange,
                    onPressed: _isUpdating
                        ? null
                        : () => _showStatusDialog(OrderStatus.pickedUp.label),
                  ),
                if (canStartPreparing)
                  _ActionButton(
                    label: 'Start Preparing',
                    color: Colors.purple,
                    onPressed: _isUpdating
                        ? null
                        : () => _showStatusDialog(OrderStatus.preparing.label),
                  ),
                if (canMarkOutForDelivery)
                  _ActionButton(
                    label: 'Mark Out for Delivery',
                    color: Colors.cyan,
                    onPressed: _isUpdating
                        ? null
                        : () => _showStatusDialog(
                            OrderStatus.outForDelivery.label,
                          ),
                  ),
                if (canMarkDelivered)
                  _ActionButton(
                    label: 'Mark Delivered',
                    color: Colors.green,
                    onPressed: _isUpdating
                        ? null
                        : () => _showStatusDialog(OrderStatus.delivered.label),
                  ),
                if (canReject)
                  _ActionButton(
                    label: 'Reject',
                    color: Colors.red,
                    onPressed: _isUpdating
                        ? null
                        : () => _showStatusDialog(OrderStatus.cancelled.label),
                  ),
                if (!canConfirm &&
                    !canPickUp &&
                    !canStartPreparing &&
                    !canMarkOutForDelivery &&
                    !canMarkDelivered &&
                    !canReject)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No actions available for ${widget.order.status} orders',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
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
      dateTime == null ? 'Not scheduled' : _formatDateTime(dateTime);
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderConfirmation {
  const _OrderConfirmation({
    required this.deliveryScheduledAt,
    this.pickupScheduledAt,
    this.totalAmount,
  });

  final DateTime deliveryScheduledAt;
  final DateTime? pickupScheduledAt;
  final String? totalAmount;
}

class _ConfirmOrderDialog extends StatefulWidget {
  const _ConfirmOrderDialog({required this.order});

  final CustomerOrder order;

  @override
  State<_ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends State<_ConfirmOrderDialog> {
  DateTime? _pickup;
  DateTime? _delivery;
  final _totalController = TextEditingController();

  bool get _needsPrice => widget.order.totalAmount == 'Price to be confirmed';

  @override
  void initState() {
    super.initState();
    _pickup = widget.order.pickupRequestedAt;
    _delivery = widget.order.deliveryRequestedAt;
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  void _confirm() {
    final now = DateTime.now();
    final finalAmount = num.tryParse(_totalController.text.trim());
    if (_delivery == null ||
        !_delivery!.isAfter(now) ||
        (widget.order.isRefill &&
            (_pickup == null ||
                !_pickup!.isAfter(now) ||
                !_delivery!.isAfter(_pickup!))) ||
        (_needsPrice &&
            (finalAmount == null ||
                !finalAmount.isFinite ||
                finalAmount <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid future schedules and total.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _OrderConfirmation(
        deliveryScheduledAt: _delivery!,
        pickupScheduledAt: _pickup,
        totalAmount: _needsPrice ? _totalController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirm order'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.order.isRefill)
            RequestedDateTimeField(
              label: 'Scheduled pickup',
              value: _pickup,
              onChanged: (value) => setState(() => _pickup = value),
            ),
          const SizedBox(height: 8),
          RequestedDateTimeField(
            label: 'Scheduled delivery',
            value: _delivery,
            mustBeAfter: widget.order.isRefill ? _pickup : null,
            onChanged: (value) => setState(() => _delivery = value),
          ),
          if (_needsPrice) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Final total amount',
                prefixText: '₱',
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text('The customer requested these times.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
    ],
  );
}

class _RejectOrderDialog extends StatefulWidget {
  const _RejectOrderDialog();

  @override
  State<_RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<_RejectOrderDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _reject() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a reason before rejecting.')),
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reject order'),
    content: TextField(
      controller: _reasonController,
      autofocus: true,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Reason for rejection',
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep order'),
      ),
      ElevatedButton(onPressed: _reject, child: const Text('Reject')),
    ],
  );
}
