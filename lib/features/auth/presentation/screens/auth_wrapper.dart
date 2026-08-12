import 'package:flutter/material.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/root.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = locator.authCtrl;

    return ListenableBuilder(
      listenable: authCtrl,
      builder: (context, _) {
        if (authCtrl.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authCtrl.isAuthenticated) {
          return const Root();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
