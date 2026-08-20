import 'package:flutter/material.dart';

class OrderNotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const OrderNotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Notes',
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
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: _buildInputDecoration(
                hintText: 'e.g. leave at gate, call before delivery...',
                prefixIcon: Icons.chat_bubble_outline_rounded,
              ),
            ),
          ),
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
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280), size: 20),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
