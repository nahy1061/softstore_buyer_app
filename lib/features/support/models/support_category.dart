import 'package:flutter/material.dart';

/// UI labels and API values for support ticket categories.
class SupportCategory {
  final String label;
  final String apiValue;
  final IconData icon;

  const SupportCategory({
    required this.label,
    required this.apiValue,
    this.icon = Icons.help_outline,
  });
}

const List<SupportCategory> kSupportCategories = [
  SupportCategory(
    label: 'Order issue',
    apiValue: 'order',
    icon: Icons.shopping_bag_outlined,
  ),
  SupportCategory(
    label: 'Delivery problem',
    apiValue: 'order',
    icon: Icons.local_shipping_outlined,
  ),
  SupportCategory(
    label: 'Return & refund',
    apiValue: 'order',
    icon: Icons.assignment_return_outlined,
  ),
  SupportCategory(
    label: 'Payment issue',
    apiValue: 'order',
    icon: Icons.payment_outlined,
  ),
  SupportCategory(
    label: 'Account problem',
    apiValue: 'general',
    icon: Icons.person_outline,
  ),
  SupportCategory(
    label: 'Other',
    apiValue: 'general',
    icon: Icons.help_outline,
  ),
];

String? supportCategoryApiValue(String? label) {
  if (label == null) return null;
  for (final category in kSupportCategories) {
    if (category.label == label) return category.apiValue;
  }
  return null;
}

IconData getSupportCategoryIcon(String category) {
  for (final cat in kSupportCategories) {
    if (cat.label.toLowerCase() == category.toLowerCase()) {
      return cat.icon;
    }
  }
  return Icons.help_outline;
}
