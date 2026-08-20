import 'package:flutter/material.dart';

class DeliveryAddressSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const DeliveryAddressSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.priority_high_rounded,
            iconBg: const Color(0xFFFF5722),
            iconShape: BoxShape.circle,
            title: 'Delivery Address',
          ),
          const SizedBox(height: 14),
          _buildInputWrapper(
            child: TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full Name is required' : null,
            ),
          ),
          const SizedBox(height: 12),
          _buildInputWrapper(
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Phone (03XXXXXXXXX)',
                prefixIcon: Icons.phone_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) {
                  return 'Phone number must have at least 10 digits';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildInputWrapper(
            child: TextFormField(
              controller: addressController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Full delivery address',
                prefixIcon: Icons.near_me_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Delivery address is required' : null,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader({
    required IconData icon,
    required Color iconBg,
    BoxShape iconShape = BoxShape.circle,
    BorderRadius? iconRadius,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: iconBg,
            shape: iconShape,
            borderRadius: iconRadius,
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  static Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _buildInputWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
      ),
      child: child,
    );
  }

  static InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280), size: 20),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
          : null,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
