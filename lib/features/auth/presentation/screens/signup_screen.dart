import 'package:flutter/material.dart';

import 'package:tiermetry/components/buttons/tiermetry_buttons.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authCtrl = locator.authCtrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await _authCtrl.signUp(email, password, name);
    if (_authCtrl.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authCtrl.error!)));
    } else if (mounted) {
      // On success, Supabase might send a confirmation email or login immediately depending on config
      // If confirmation is required, show a message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please check your email for confirmation.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TiermetryColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _authCtrl,
        builder: (context, _) {
          return Center(
            child: SingleChildScrollView(
              padding: TiermetrySpacing.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(('Create Account').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TiermetryTypography.display(
                      color: TiermetryColors.white,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppSurface(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your name',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Min. 6 characters',
                          obscureText: true,
                        ),
                        const SizedBox(height: 32),
                        if (_authCtrl.isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: TiermetryColors.accentNeonGreen,
                            ),
                          )
                        else
                          TiermetryPrimaryButton(
                            text: 'Create Account',
                            onPressed: _onSignup,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TiermetryTypography.label(
            color: TiermetryColors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: TiermetryColors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: TiermetryColors.white.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: TiermetryColors.surfaceElement,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TiermetryRadii.sm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
