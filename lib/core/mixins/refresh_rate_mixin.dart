import 'package:flutter/material.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

/// A mixin that requests a high refresh rate when the screen is initialized.
mixin RefreshRateMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _setHighRefreshRate();
  }

  Future<void> _setHighRefreshRate() async {
    try {
      final control = FlutterRefreshRateControl();
      await control.requestHighRefreshRate();
    } catch (e) {
      debugPrint('Failed to set high refresh rate: $e');
    }
  }
}
