import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusPresentation on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.outForDelivery => 'Out for Delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  Color get foregroundColor => switch (this) {
    OrderStatus.pending => AppColors.pendingForeground,
    OrderStatus.confirmed => AppColors.confirmedForeground,
    OrderStatus.preparing => AppColors.preparingForeground,
    OrderStatus.outForDelivery => AppColors.outForDeliveryForeground,
    OrderStatus.delivered => AppColors.deliveredForeground,
    OrderStatus.cancelled => AppColors.cancelledForeground,
  };

  Color get backgroundColor => switch (this) {
    OrderStatus.pending => AppColors.pendingBackground,
    OrderStatus.confirmed => AppColors.confirmedBackground,
    OrderStatus.preparing => AppColors.preparingBackground,
    OrderStatus.outForDelivery => AppColors.outForDeliveryBackground,
    OrderStatus.delivered => AppColors.deliveredBackground,
    OrderStatus.cancelled => AppColors.cancelledBackground,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      backgroundColor: status.backgroundColor,
      side: BorderSide.none,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: status.foregroundColor),
    );
  }
}
