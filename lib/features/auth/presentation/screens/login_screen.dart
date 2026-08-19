import 'package:flutter/material.dart';

import 'package:tiermetry/components/buttons/tiermetry_buttons.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authCtrl = locator.authCtrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await _authCtrl.signIn(email, password);
    if (_authCtrl.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authCtrl.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
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
                  Text(('TIERMETRY').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TiermetryTypography.display(
                      color: TiermetryColors.white,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.sm),
                  Text(
                    'Level up your gaming experience',
                    textAlign: TextAlign.center,
                    style: TiermetryTypography.caption(
                      color: TiermetryColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 60),
                  AppSurface(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(('Sign In').toUpperCase(),
                          style: TiermetryTypography.title(
                            color: TiermetryColors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
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
                          hint: 'Enter your password',
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
                            text: 'Login',
                            onPressed: _onLogin,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TiermetryTypography.caption(
                          color: TiermetryColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TiermetryTypography.caption(
                            color: TiermetryColors.accentNeonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
