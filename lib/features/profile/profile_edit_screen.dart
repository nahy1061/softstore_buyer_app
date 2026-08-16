import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/session_store.dart';
import '../../services/auth_service.dart';
import '../../services/account_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  final _authSvc = AuthService();
  final _accountSvc = AccountService();
  bool _loading = false;
  bool _loadingProfile = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final buyer = context.read<SessionStore>().buyer;
    _firstCtrl = TextEditingController(text: buyer?.firstName ?? '');
    _lastCtrl = TextEditingController(text: buyer?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: buyer?.phone ?? '');
    _loadProfile();
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final buyer = await _authSvc.fetchProfile();
      if (!mounted) return;
      context.read<SessionStore>().updateBuyer(buyer);
      setState(() {
        _firstCtrl.text = buyer.firstName ?? '';
        _lastCtrl.text = buyer.lastName ?? '';
        _phoneCtrl.text = buyer.phone ?? '';
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _accountSvc.updateProfile(
        _firstCtrl.text.trim(),
        _lastCtrl.text.trim(),
        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      final updated = await _authSvc.fetchProfile();
      if (!mounted) return;
      context.read<SessionStore>().updateBuyer(updated);
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      backgroundColor: AppColors.backgroundLight,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _firstCtrl,
                      decoration: const InputDecoration(hintText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lastCtrl,
                      decoration: const InputDecoration(hintText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}
