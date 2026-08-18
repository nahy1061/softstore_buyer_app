abstract final class Validators {
  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Email is required';
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
    if (!emailRegex.hasMatch(value!)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value?.isEmpty ?? true) return 'Password is required';
    if (value!.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? fullName(String? value) {
    if (value?.isEmpty ?? true) return 'Full name is required';
    if (value!.length < 3) return 'Enter your full name';
    return null;
  }

  static String? pakistaniPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return 'Phone number must be at least 11 digits';
    return null;
  }

  static String? address(String? value) {
    if (value?.isEmpty ?? true) return 'Address is required';
    if (value!.length < 8) return 'Enter a complete address';
    return null;
  }

  static String? city(String? value) {
    if (value?.isEmpty ?? true) return 'City is required';
    if (value!.length < 2) return 'Enter your city';
    return null;
  }

  static String? otp(String? value) {
    if (value?.isEmpty ?? true) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'Enter the 6-digit code';
    return null;
  }

  static String? quantity(String? value, int maxStock) {
    if (value?.isEmpty ?? true) return 'Quantity is required';
    final qty = int.tryParse(value!);
    if (qty == null || qty < 1) return 'Quantity must be at least 1';
    if (qty > maxStock) return 'Maximum $maxStock available';
    return null;
  }
}
