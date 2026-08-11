import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';

class AddressFormScreen extends StatefulWidget {
  final bool isEditing;
  final String? addressId;

  const AddressFormScreen({
    super.key,
    required this.isEditing,
    this.addressId,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _labelController.text = 'Home';
      _nameController.text = 'Arwah Imran';
      _phoneController.text = '03001234567';
      _addressController.text = 'House 12, Street 5, Block B, Gulberg III';
      _cityController.text = 'Lahore';
      _isDefault = true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.isEditing
              ? 'Address updated'
              : 'Address added')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add Address',
          style: AppTypography.screenTitle,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ic ons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _FieldLabel('Address Label'),
              TextFormField(
                controller: _labelController,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Enter a label (e.g. Home)' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g. Home, Office',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FieldLabel('Full Name'),
              TextFormField(
                controller: _nameController,
                validator: Validators.fullName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Recipient\'s full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FieldLabel('Phone Number'),
              TextFormField(
                controller: _phoneController,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Phone is required' : Validators.pakistaniPhone(v),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '03XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FieldLabel('Street Address'),
              TextFormField(
                controller: _addressController,
                validator: Validators.address,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'House no, street, area',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FieldLabel('City'),
              TextFormField(
                controller: _cityController,
                validator: Validators.city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lahore',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (val) =>
                        setState(() => _isDefault = val ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Set as default delivery address',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Add Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppTypography.labelLarge),
    );
  }
}
