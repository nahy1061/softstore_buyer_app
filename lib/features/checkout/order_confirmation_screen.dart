import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String invoiceNumber;

  const OrderConfirmationScreen({super.key, required this.invoiceNumber});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success animation ring
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle, color: AppColors.success, size: 64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Placed!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thank you for your order. We\'ll confirm it shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  // Invoice card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(children: [
                      const Text(
                        'Invoice / Order Number',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        invoiceNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Save this number to track your order.',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  // Cash on delivery note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.brandAmber.withOpacity(0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.payments_outlined, color: AppColors.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cash on Delivery — please have exact change ready.',
                          style: TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 36),
                  // Continue shopping
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goHome(context),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
