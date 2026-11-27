import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../orders/data/order.dart';
import '../../orders/data/order_providers.dart';
import '../../orders/data/order_status.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ordersAsync = ref.watch(watchAllOrdersProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Operations overview',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'A quick view of order activity for your team.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ordersAsync.when(
                loading: () => const _DashboardLoading(),
                error: (error, stack) {
                  debugPrint('Dashboard order stream failed: $error\n$stack');
                  final message = error is FirebaseException
                      ? error.message ?? error.code
                      : error.toString();
                  return ErrorView(
                    message: 'Could not load dashboard orders: $message',
                    retryLabel: 'Retry',
                    onRetry: () => ref.invalidate(watchAllOrdersProvider),
                  );
                },
                data: (orders) => _DashboardData(orders: orders),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData extends StatelessWidget {
  const _DashboardData({required this.orders});

  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final todayOrders =
        orders
            .where(
              (order) =>
                  !order.createdAt.isBefore(startOfToday) &&
                  order.createdAt.isBefore(startOfTomorrow),
            )
            .toList()
          ..sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
    final visibleTodayOrders = todayOrders.take(10).toList();
    final upcoming = _upcomingSchedule(orders, now);
    final inProgressStatuses = {
      OrderStatus.confirmed.label,
      OrderStatus.pickedUp.label,
      OrderStatus.preparing.label,
      OrderStatus.outForDelivery.label,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              label: 'Total Orders',
              count: orders.length,
              icon: Icons.receipt_long_outlined,
            ),
            _MetricData(
              label: 'Pending',
              count: orders.where((order) => order.status == 'Pending').length,
              icon: Icons.schedule_outlined,
            ),
            _MetricData(
              label: 'In Progress',
              count: orders
                  .where((order) => inProgressStatuses.contains(order.status))
                  .length,
              icon: Icons.local_shipping_outlined,
            ),
            _MetricData(
              label: 'Delivered',
              count: orders
                  .where((order) => order.status == OrderStatus.delivered.label)
                  .length,
              icon: Icons.task_alt_outlined,
            ),
            _MetricData(
              label: "Today's Orders",
              count: todayOrders.length,
              icon: Icons.today_outlined,
            ),
            _MetricData(
              label: 'Refill Orders',
              count: orders.where((order) => order.isRefill).length,
              icon: Icons.water_drop_outlined,
            ),
            _MetricData(
              label: 'Purchase Orders',
              count: orders.where((order) => !order.isRefill).length,
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DashboardSection(
          title: "Today's Orders",
          child: todayOrders.isEmpty
              ? _EmptyMessage(
                  message: orders.isEmpty
                      ? 'No orders yet.'
                      : 'No orders placed today.',
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < visibleTodayOrders.length;
                      index++
                    ) ...[
                      _TodayOrderRow(order: visibleTodayOrders[index]),
                      if (index < visibleTodayOrders.length - 1)
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 20),
        _DashboardSection(
          title: 'Upcoming schedule',
          child: upcoming.isEmpty
              ? const _EmptyMessage(
                  message: 'No upcoming scheduled pickups or deliveries.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < upcoming.length; index++) ...[
                      _UpcomingScheduleRow(entry: upcoming[index]),
                      if (index < upcoming.length - 1)
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int? count;
  final IconData icon;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 14.0;
      final columns = (constraints.maxWidth / 220).floor().clamp(1, 5);
      final cardWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: cardWidth,
              child: _MetricCard(metric: metric),
            ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: scheme.primary),
          const SizedBox(height: 18),
          Text(metric.label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (metric.count == null)
            SizedBox(
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            )
          else
            Text(
              metric.count.toString(),
              style: theme.textTheme.headlineMedium,
            ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class _TodayOrderRow extends StatelessWidget {
  const _TodayOrderRow({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = order.totalAmount == 'Price to be confirmed'
        ? order.totalAmount
        : '₱${order.totalAmount}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.customerName} · ${order.isRefill ? 'Refill' : 'Purchase'}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: order.status),
          const SizedBox(width: 12),
          Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pending' => Colors.orange,
      'Confirmed' => Colors.blue,
      'Picked Up' => Colors.indigo,
      'Preparing' => Colors.purple,
      'Out for Delivery' => Colors.cyan,
      'Delivered' => Colors.green,
      'Cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
    );
  }
}

enum _ScheduleEventType {
  pickup('Pickup', Icons.inventory_2_outlined),
  delivery('Delivery', Icons.local_shipping_outlined);

  const _ScheduleEventType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _ScheduleEntry {
  const _ScheduleEntry({
    required this.order,
    required this.scheduledAt,
    required this.type,
  });

  final CustomerOrder order;
  final DateTime scheduledAt;
  final _ScheduleEventType type;
}

List<_ScheduleEntry> _upcomingSchedule(
  List<CustomerOrder> orders,
  DateTime now,
) {
  final entries = <_ScheduleEntry>[];
  const activeStatuses = {
    'Confirmed',
    'Picked Up',
    'Preparing',
    'Out for Delivery',
  };
  for (final order in orders) {
    if (!activeStatuses.contains(order.status)) continue;
    final pickupAt = order.pickupScheduledAt;
    if (order.isRefill &&
        order.status == OrderStatus.confirmed.label &&
        pickupAt != null &&
        !pickupAt.isBefore(now)) {
      entries.add(
        _ScheduleEntry(
          order: order,
          scheduledAt: pickupAt,
          type: _ScheduleEventType.pickup,
        ),
      );
    }
    final deliveryAt = order.deliveryScheduledAt;
    if (deliveryAt != null && !deliveryAt.isBefore(now)) {
      entries.add(
        _ScheduleEntry(
          order: order,
          scheduledAt: deliveryAt,
          type: _ScheduleEventType.delivery,
        ),
      );
    }
  }
  entries.sort((first, second) {
    final byTime = first.scheduledAt.compareTo(second.scheduledAt);
    if (byTime != 0) return byTime;
    final byOrder = first.order.orderNumber.compareTo(second.order.orderNumber);
    if (byOrder != 0) return byOrder;
    return first.type.index.compareTo(second.type.index);
  });
  return entries.take(5).toList();
}

class _UpcomingScheduleRow extends StatelessWidget {
  const _UpcomingScheduleRow({required this.entry});

  final _ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(entry.type.icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.type.label} · ${entry.order.orderNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.order.customerName} · ${entry.order.isRefill ? 'Refill' : 'Purchase'}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(entry.scheduledAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) =>
    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
    '${dateTime.day.toString().padLeft(2, '0')} '
    '${dateTime.hour.toString().padLeft(2, '0')}:'
    '${dateTime.minute.toString().padLeft(2, '0')}';

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    final metrics = [
      for (final data in const [
        ('Total Orders', Icons.receipt_long_outlined),
        ('Pending', Icons.schedule_outlined),
        ('In Progress', Icons.local_shipping_outlined),
        ('Delivered', Icons.task_alt_outlined),
        ("Today's Orders", Icons.today_outlined),
        ('Refill Orders', Icons.water_drop_outlined),
        ('Purchase Orders', Icons.shopping_bag_outlined),
      ])
        _MetricData(label: data.$1, count: null, icon: data.$2),
    ];
    return Column(
      children: [
        _MetricGrid(metrics: metrics),
        const SizedBox(height: 20),
        const _DashboardSection(
          title: "Today's Orders",
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 20),
        const _DashboardSection(
          title: 'Upcoming schedule',
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
