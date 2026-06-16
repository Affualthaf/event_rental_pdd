import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String _role = 'Customer';
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _shopNameCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final service = FirebaseService();
      // 1. Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (userCredential.user != null) {
        // 2. Save user profile in Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          role: _role,
          createdAt: DateTime.now(),
          shopName: _role == 'Vendor' ? _shopNameCtrl.text.trim() : null,
          pincode: _role == 'Vendor' ? _pincodeCtrl.text.trim() : null,
        );
        await service.updateUserProfile(userModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!'), backgroundColor: AppColors.success),
          );
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Join EventSphere today',
                    style:
                        TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppInput(
                          label: 'Full Name',
                          hint: 'John Doe',
                          controller: _nameCtrl,
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                          prefix: const Icon(Icons.person_outline,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email' : null,
                          prefix: const Icon(Icons.mail_outline,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Phone Number',
                          hint: '+1 (555) 000-0000',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your phone number' : null,
                          prefix: const Icon(Icons.phone_outlined,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Location',
                          hint: 'City, Country',
                          controller: _locationCtrl,
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your location' : null,
                          prefix: const Icon(Icons.location_on_outlined,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                          prefix: const Icon(Icons.lock_outline,
                              color: AppColors.textSecondary),
                          suffix: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account Type',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            Row(
                              children: ['Customer', 'Vendor'].map((r) {
                                final selected = _role == r;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _role = r),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.accent
                                              : Colors.white.withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: selected
                                                  ? AppColors.accent
                                                  : Colors.white.withValues(alpha: 0.08),
                                              width: 1.5),
                                          boxShadow: selected ? AppColors.softShadow : null,
                                        ),
                                        child: Text(r,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: selected
                                                    ? Colors.white
                                                    : Colors.white.withValues(alpha: 0.6),
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        if (_role == 'Vendor') ...[
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Shop Name',
                            hint: 'e.g. SoundPro Rentals',
                            controller: _shopNameCtrl,
                            validator: (v) => _role == 'Vendor' && (v == null || v.isEmpty) ? 'Please enter your shop name' : null,
                            prefix: const Icon(Icons.store_outlined,
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Pincode of the Area',
                            hint: 'e.g. 123456',
                            controller: _pincodeCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (_role == 'Vendor') {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your pincode';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(v)) {
                                  return 'Please enter a valid numeric pincode';
                                }
                                if (v.length < 4 || v.length > 8) {
                                  return 'Pincode must be between 4 and 8 digits';
                                }
                              }
                              return null;
                            },
                            prefix: const Icon(Icons.pin_drop_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 32),
                        AppButton(
                          text: 'Create Account',
                          variant: ButtonVariant.accent,
                          onPressed: _loading ? null : _handleSignUp,
                          loading: _loading,
                          fullWidth: true,
                          size: ButtonSize.lg,
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('Already have an account? ',
                              style:
                                  TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text('Sign In',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
