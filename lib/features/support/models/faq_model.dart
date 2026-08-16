class FaqCategory {
  final String title;
  final List<FaqItem> items;

  const FaqCategory({required this.title, required this.items});
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

// All FAQ content lives here — no API needed, hardcoded for MVP
const List<FaqCategory> kFaqData = [
  FaqCategory(
    title: 'Orders & Delivery',
    items: [
      FaqItem(
        question: 'How do I track my order?',
        answer:
            'Go to My Orders and tap on any order to see its live status. You can also track without an account using your invoice number and phone number on the Track Order page.',
      ),
      FaqItem(
        question: 'How long does delivery take?',
        answer:
            'Delivery times depend on the seller\'s location and your city. Most orders are delivered within 3–7 business days. The seller manages their own fulfillment.',
      ),
      FaqItem(
        question: 'What if my order is late?',
        answer:
            'If your order hasn\'t arrived by the estimated date, please contact the seller first via the Order Detail screen. If the issue isn\'t resolved, open a support ticket and we\'ll step in.',
      ),
      FaqItem(
        question: 'Can I change my delivery address after placing an order?',
        answer:
            'You can request an address change if the order hasn\'t been packed yet. Go to Order Detail and tap "Contact Seller" to request the change immediately.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Returns & Refunds',
    items: [
      FaqItem(
        question: 'How do I return an item?',
        answer:
            'Go to My Orders → Order Detail → tap "Return Item". Fill in the reason, describe the issue, and optionally upload photos. The seller reviews your request within 2 business days.',
      ),
      FaqItem(
        question: 'What is the return window?',
        answer:
            'Most items can be returned within 7 days of delivery. Some categories (e.g. perishables, digital items) may not be eligible. Check the product listing for seller-specific return policies.',
      ),
      FaqItem(
        question: 'When will I get my refund?',
        answer:
            'Since all orders are Cash on Delivery, refunds are issued as store credit or bank transfer within 3–5 business days after the seller confirms the return.',
      ),
      FaqItem(
        question: 'What if the seller rejects my return?',
        answer:
            'If you believe the rejection is unfair, open a support ticket referencing your order number. Our team will review the case and mediate within 48 hours.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Payment',
    items: [
      FaqItem(
        question: 'What payment methods are accepted?',
        answer:
            'Currently only Cash on Delivery (COD) is supported. You pay the rider when your order arrives. No cards or online payment required.',
      ),
      FaqItem(
        question: 'Is COD available for all cities?',
        answer:
            'COD availability depends on the seller\'s delivery zones. If COD isn\'t available for your area, you\'ll see a message at checkout before placing the order.',
      ),
      FaqItem(
        question: 'What if I overpay or underpay at delivery?',
        answer:
            'Always pay the exact amount shown in your order summary. If there\'s a discrepancy, don\'t pay — contact us immediately by opening a support ticket.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Account & Security',
    items: [
      FaqItem(
        question: 'How do I change my password?',
        answer:
            'Go to Profile → Settings → Change Password. Enter your current password, then your new password twice. If you\'ve forgotten your password, use the "Forgot password?" link on the login screen.',
      ),
      FaqItem(
        question: 'How do I update my phone number or email?',
        answer:
            'Go to Profile → Edit Profile. Note that changing your email requires OTP verification on the new address.',
      ),
      FaqItem(
        question: 'Is my personal data safe?',
        answer:
            'Yes. All data is encrypted in transit (TLS). Your password is hashed and never stored in plain text. We do not share your personal information with third parties.',
      ),
      FaqItem(
        question: 'How do I delete my account?',
        answer:
            'Go to Profile → Settings → Delete Account. Note this is permanent — all your order history and saved addresses will be removed. Open a support ticket if you need help.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Shopping',
    items: [
      FaqItem(
        question: 'How do I use a coupon code?',
        answer:
            'On the checkout screen, you\'ll see a "Coupon code" field. Enter your code there and tap Apply. The discount will be applied to your order total if the code is valid.',
      ),
      FaqItem(
        question: 'How do I save items for later?',
        answer:
            'Tap the heart icon on any product card or product detail page to add it to your Wishlist. Access your wishlist from the bottom navigation bar.',
      ),
      FaqItem(
        question: 'How do I contact a seller?',
        answer:
            'On any product detail page, tap the seller name to visit their store page. From there you can view their products and contact them directly.',
      ),
    ],
  ),
];
