import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/session_store.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';

/// Auth bottom sheet — shown when a guest tries a protected action (checkout, wishlist).
/// Returns true if the user ends up signed in.
class AuthFlowView extends StatefulWidget {
  final String? contextMessage;
  const AuthFlowView({super.key, this.contextMessage});

  static Future<bool> showAuthSheet(BuildContext context, {String? contextMessage}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthFlowView(contextMessage: contextMessage),
    );
    return result == true;
  }

  @override
  State<AuthFlowView> createState() => _AuthFlowViewState();
}

class _AuthFlowViewState extends State<AuthFlowView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _showRegister = false;

  // Register fields
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [_emailCtrl, _passCtrl, _firstCtrl, _lastCtrl, _regPassCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final buyer = await _auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      await context.read<SessionStore>().signIn(buyer);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.register(_firstCtrl.text.trim(), _lastCtrl.text.trim(), _emailCtrl.text.trim(), _regPassCtrl.text.trim());
      if (!mounted) return;
      setState(() { _loading = false; _showRegister = false; _error = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Check your email to verify.')));
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          // Logo row
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.brandOrange, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 10),
            Text(_showRegister ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          if (widget.contextMessage != null) ...[
            const SizedBox(height: 8),
            Text(widget.contextMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Form(
            key: _formKey,
            child: _showRegister ? _registerForm() : _loginForm(),
          ),
        ]),
      ),
    );
  }

  Widget _loginForm() => Column(children: [
    TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _passCtrl,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure = !_obscure)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
    ),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())); },
        child: const Text('Forgot password?', style: TextStyle(color: AppColors.brandOrange, fontSize: 12)),
      ),
    ),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("Don't have an account? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
      GestureDetector(
        onTap: () => setState(() { _showRegister = true; _error = null; }),
        child: const Text('Register', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ]),
  ]);

  Widget _registerForm() => Column(children: [
    Row(children: [
      Expanded(child: TextFormField(controller: _firstCtrl, decoration: const InputDecoration(hintText: 'First Name'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
      const SizedBox(width: 10),
      Expanded(child: TextFormField(controller: _lastCtrl, decoration: const InputDecoration(hintText: 'Last Name'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
    ]),
    const SizedBox(height: 12),
    TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v?.contains('@') == true ? null : 'Valid email required'),
    const SizedBox(height: 12),
    TextFormField(
      controller: _regPassCtrl,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'Password (min 8 chars)',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure = !_obscure)),
      ),
      validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null,
    ),
    const SizedBox(height: 16),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Already have an account? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
      GestureDetector(
        onTap: () => setState(() { _showRegister = false; _error = null; }),
        child: const Text('Sign In', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ]),
  ]);
}
