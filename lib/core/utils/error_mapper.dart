import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMapper {
  static String map(dynamic e) {
    if (e is PostgrestException) {
      return _mapPostgrestError(e);
    }
    if (e is AuthException) {
      return _mapAuthError(e);
    }
    if (e is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is HttpException) {
      return 'Server is currently unreachable. Please try again later.';
    }

    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Connection lost. Please check your internet.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    // Domain specific mapping
    if (msg.contains('no longer available')) {
      return 'This slot was just taken. Please select another.';
    }
    if (msg.contains('already registered')) {
      return 'You are already registered for this event.';
    }
    if (msg.contains('event is full')) return 'This event is now full.';
    if (msg.contains('expired')) return 'The reservation has expired.';

    // General codes
    switch (e.code) {
      case '42501':
        return 'You don\'t have permission to perform this action.';
      case '23505':
        return 'This record already exists.';
      default:
        return 'Database error: We couldn\'t process your request.';
    }
  }

  static String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }

    return e.message;
  }
}
