import 'package:flutter/material.dart';

class CouponCodeSection extends StatelessWidget {
  final TextEditingController couponController;
  final bool isValidating;
  final String? message;
  final bool isValid;
  final VoidCallback onApply;

  const CouponCodeSection({
    super.key,
    required this.couponController,
    required this.isValidating,
    this.message,
    this.isValid = false,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -0.2,
                child: const Icon(
                  Icons.local_offer,
                  color: Color(0xFFFF5722),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Coupon Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              const Text(
                'Optional',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputWrapper(
            child: TextFormField(
              controller: couponController,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Enter coupon code',
                prefixIcon: Icons.confirmation_number_outlined,
                suffix: InkWell(
                  onTap: isValidating ? null : onApply,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF5722),
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isValid
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ],
        ],
      ),
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
