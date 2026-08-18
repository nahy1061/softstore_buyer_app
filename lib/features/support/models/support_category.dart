/// UI labels and API values for support ticket categories.
class SupportCategory {
  final String label;
  final String apiValue;

  const SupportCategory({
    required this.label,
    required this.apiValue,
  });
}

const List<SupportCategory> kSupportCategories = [
  SupportCategory(label: 'Order issue', apiValue: 'order'),
  SupportCategory(label: 'Delivery problem', apiValue: 'order'),
  SupportCategory(label: 'Return & refund', apiValue: 'order'),
  SupportCategory(label: 'Payment issue', apiValue: 'order'),
  SupportCategory(label: 'Account problem', apiValue: 'general'),
  SupportCategory(label: 'Other', apiValue: 'general'),
];

String? supportCategoryApiValue(String? label) {
  if (label == null) return null;
  for (final category in kSupportCategories) {
    if (category.label == label) return category.apiValue;
  }
  return null;
}
