import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/address.dart';
import '../../services/account_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _svc = AccountService();
  List<Address> _addresses = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final addrs = await _svc.addresses();
      setState(() { _addresses = addrs; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _addAddress() {
    _showAddressForm();
  }

  Future<void> _showAddressForm({Address? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(existing: existing, svc: _svc),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Address addr) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Address'),
      content: const Text('Delete this address?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Delete', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok == true) {
      await _svc.deleteAddress(addr.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Addresses'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addAddress),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _addresses.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No saved addresses', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(onPressed: _addAddress, icon: const Icon(Icons.add), label: const Text('Add Address')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (_, i) {
                    final addr = _addresses[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: addr.isDefault ? AppColors.brandOrange : Colors.grey[200]!),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.brandOrange),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Default', style: TextStyle(color: AppColors.brandOrange, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          Text(addr.formatted, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                          Text(addr.phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ])),
                        PopupMenuButton<String>(
                          onSelected: (v) { if (v == 'delete') _delete(addr); },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppColors.danger, size: 18), SizedBox(width: 6), Text('Delete', style: TextStyle(color: AppColors.danger))])),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
      floatingActionButton: _addresses.isNotEmpty ? FloatingActionButton(
        onPressed: _addAddress,
        backgroundColor: AppColors.brandOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Address? existing;
  final AccountService svc;
  const _AddressFormSheet({this.existing, required this.svc});
  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addr1Ctrl;
  late final TextEditingController _addr2Ctrl;
  late final TextEditingController _cityCtrl;
  bool _isDefault = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _nameCtrl = TextEditingController(text: a?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _addr1Ctrl = TextEditingController(text: a?.addressLine1 ?? '');
    _addr2Ctrl = TextEditingController(text: a?.addressLine2 ?? '');
    _cityCtrl = TextEditingController(text: a?.city ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _addr1Ctrl, _addr2Ctrl, _cityCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final address = Address(
        id: widget.existing?.id ?? 0,
        recipientName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine1: _addr1Ctrl.text.trim(),
        addressLine2: _addr2Ctrl.text.trim().isEmpty ? null : _addr2Ctrl.text.trim(),
        city: _cityCtrl.text.trim(),
        isDefault: _isDefault,
      );
      await widget.svc.addAddress(address);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Add Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Recipient Name'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _addr1Ctrl, decoration: const InputDecoration(hintText: 'Address Line 1'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _addr2Ctrl, decoration: const InputDecoration(hintText: 'Address Line 2 (optional)')),
            const SizedBox(height: 10),
            TextFormField(controller: _cityCtrl, decoration: const InputDecoration(hintText: 'City'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
              title: const Text('Set as default address', style: TextStyle(fontSize: 14)),
              activeColor: AppColors.brandOrange,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
