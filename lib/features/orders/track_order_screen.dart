import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/account_service.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});
  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _invoiceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _svc = AccountService();
  dynamic _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _invoiceCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _track() async {
    final invoice = _invoiceCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (invoice.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Please enter both invoice number and phone.');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final r = await _svc.trackOrder(invoice, phone);
      setState(() { _result = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Track Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _invoiceCtrl,
            decoration: const InputDecoration(hintText: 'Invoice number (e.g. INV-001)', prefixIcon: Icon(Icons.receipt_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Phone number used at checkout', prefixIcon: Icon(Icons.phone_outlined)),
            onSubmitted: (_) => _track(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _track,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Track Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_result.order.invoiceNumber as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_result.order.saleStatus.label as String, style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ...(_result.statusHistory as List).map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4, right: 12), decoration: BoxDecoration(color: AppColors.brandOrange, shape: BoxShape.circle)),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.newStatus.label as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (e.notes != null) Text(e.notes as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(e.createdAt as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ])),
                  ]),
                )),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
