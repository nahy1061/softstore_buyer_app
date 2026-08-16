import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/order.dart';
import '../../core/networking/api_error.dart';
import '../../services/account_service.dart';

class RequestReturnScreen extends StatefulWidget {
  final Order order;

  const RequestReturnScreen({super.key, required this.order});

  @override
  State<RequestReturnScreen> createState() => _RequestReturnScreenState();
}

class _RequestReturnScreenState extends State<RequestReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _svc = AccountService();

  String _returnType = 'refund';
  bool _loading = false;
  String? _error;

  // Item selection: productId -> selected
  late final Map<int, bool> _itemSelected;

  static const _returnTypes = [
    ('refund', 'Refund', 'Get a full refund for the returned items'),
    ('replacement', 'Replacement', 'Receive a replacement for the items'),
  ];

  @override
  void initState() {
    super.initState();
    final items = widget.order.items ?? [];
    _itemSelected = {for (final item in items) item.productId: true};
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  List<SaleItem> get _selectedItems {
    final items = widget.order.items ?? [];
    return items.where((i) => _itemSelected[i.productId] == true).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to return.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _svc.requestReturn(
        orderId: widget.order.id,
        reason: _reasonCtrl.text.trim(),
        returnType: _returnType,
        items: _selectedItems
            .map((i) => (productId: i.productId, quantity: i.quantity))
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return request submitted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not submit return request. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.order.items ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Return — #${widget.order.invoiceNumber}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: AppColors.brandOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.brandOrange, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Returns are accepted within 7 days of delivery. '
                          'Please select the items you wish to return.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.brandOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Item selection
                if (items.isNotEmpty) ...[
                  Text(
                    'Select Items to Return',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: List.generate(items.length, (i) {
                        final item = items[i];
                        final isLast = i == items.length - 1;
                        return Column(
                          children: [
                            CheckboxListTile(
                              value:
                                  _itemSelected[item.productId] ?? false,
                              onChanged: (v) => setState(
                                  () => _itemSelected[item.productId] =
                                      v ?? false),
                              title: Text(
                                item.productName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'PKR ${item.totalAmount.toStringAsFixed(0)} × ${item.quantity.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              activeColor: AppColors.brandOrange,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                  height: 1, color: theme.dividerColor),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Return type
                Text(
                  'Return Type',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: List.generate(_returnTypes.length, (i) {
                      final (value, label, desc) = _returnTypes[i];
                      final isLast = i == _returnTypes.length - 1;
                      return Column(
                        children: [
                          RadioListTile<String>(
                            value: value,
                            groupValue: _returnType,
                            onChanged: (v) =>
                                setState(() => _returnType = v ?? 'refund'),
                            title: Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              desc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            activeColor: AppColors.brandOrange,
                          ),
                          if (!isLast)
                            Divider(height: 1, color: theme.dividerColor),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Reason
                Text(
                  'Reason for Return',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe the issue with your order (e.g. damaged item, wrong size, not as described)…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Please describe the reason (at least 10 characters)';
                    }
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border:
                          Border.all(color: AppColors.danger.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Return Request'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
