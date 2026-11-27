import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../../core/widgets/error_view.dart';
import '../data/order.dart';
import '../data/order_providers.dart';
import 'customer_order_details_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthScope.of(context).backend.currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    final ordersAsync = ref.watch(customerOrdersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Could not load orders: $error',
          onRetry: () => ref.invalidate(customerOrdersProvider(userId)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const _EmptyOrdersView(
              message: 'You have no orders yet',
              subMessage: 'Your orders will appear here',
            );
          }

          final currentOrders = orders.where((order) {
            return order.status == 'Pending' ||
                order.status == 'Confirmed' ||
                order.status == 'Picked Up' ||
                order.status == 'Preparing' ||
                order.status == 'Out for Delivery';
          }).toList();

          final historyOrders = orders
              .where(
                (order) =>
                    order.status == 'Delivered' || order.status == 'Cancelled',
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Current Orders Tab
              currentOrders.isEmpty
                  ? const _EmptyOrdersView(
                      message: 'No active orders',
                      subMessage: 'Your active orders will appear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentOrders.length,
                      itemBuilder: (context, index) {
                        final order = currentOrders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerOrderDetailsScreen(
                                      initialOrder: order,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),

              // History Orders Tab
              historyOrders.isEmpty
                  ? const _EmptyOrdersView(
                      message: 'No order history',
                      subMessage: 'Your completed orders will appear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyOrders.length,
                      itemBuilder: (context, index) {
                        final order = historyOrders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerOrderDetailsScreen(
                                      initialOrder: order,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Row(
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
                  Text(
                    order.isRefill ? 'Refill' : 'Purchase',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.totalAmount == 'Price to be confirmed'
                        ? order.totalAmount
                        : 'Total: ₱${order.totalAmount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(
                order.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _getStatusColor(order.status),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${order.isRefill ? '${order.containerSize ?? 'Container'} × ${order.containerCount ?? 0}' : '${order.items.length} item${order.items.length != 1 ? 's' : ''}'}'
            '\nRequested delivery: ${_format(order.deliveryRequestedAt)}'
            '\nConfirmed delivery: ${_format(order.deliveryScheduledAt)}'
            '${order.isRefill ? '\nRequested pickup: ${_format(order.pickupRequestedAt)}\nConfirmed pickup: ${_format(order.pickupScheduledAt)}' : ''}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }

  String _format(DateTime? date) => date == null
      ? 'Not confirmed'
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
}

class _EmptyOrdersView extends StatelessWidget {
  final String message;
  final String subMessage;

  const _EmptyOrdersView({required this.message, required this.subMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subMessage, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
