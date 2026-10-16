import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps various exception types to user-facing error messages.
///
/// Used across all controllers and repositories to ensure consistent,
/// human-readable error strings.
class ErrorMapper {
  static String map(dynamic e) {
    // Network & IO
    if (e is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is HttpException) {
      return 'Server is currently unreachable. Please try again later.';
    }
    if (e is TimeoutException) {
      return 'The request timed out. Please check your connection and try again.';
    }

    // Supabase typed errors
    if (e is PostgrestException) {
      return _mapPostgrestError(e);
    }
    if (e is AuthException) {
      return _mapAuthError(e);
    }
    if (e is FunctionException) {
      final details = e.details;
      if (details is Map) {
        final error = details['error'];
        if (error is String && error.trim().isNotEmpty) return error.trim();
      }
      if (e.status == 0) {
        return 'Unable to reach the payment service. Check your connection and try again.';
      }
      if (e.status >= 500) {
        return 'Payment service is temporarily unavailable. Please try again.';
      }
    }

    // Fallback string-matching for third-party exceptions
    final message = e.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('no address associated with hostname') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('clientexception')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (message.contains('jwt expired') ||
        message.contains('session expired')) {
      return 'Your session expired. Please sign in again.';
    }
    if (message.contains('unauthorized') || message.contains('401')) {
      return 'You are not authorized. Please sign in again.';
    }
    if (message.contains('403') || message.contains('forbidden')) {
      return 'Access denied. You don\'t have permission for this action.';
    }
    if (message.contains('503') || message.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    // Domain-specific booking/payment messages
    if (msg.contains('no longer available')) {
      return 'This slot was just taken. Please select another.';
    }
    if (msg.contains('venue is closed') || msg.contains('venue closed')) {
      return 'This venue is currently closed. Please check back later.';
    }
    if (msg.contains('event is full')) {
      return 'This event is now full.';
    }
    if (msg.contains('sold out') ||
        msg.contains('maximum capacity') ||
        msg.contains('capacity exceeded') ||
        msg.contains('fully booked')) {
      return 'Sorry, this is fully booked. Please choose a different time.';
    }
    if (msg.contains('price has changed') || msg.contains('price changed')) {
      return 'The price has changed since you started. Please review and confirm.';
    }
    if (msg.contains('already registered')) {
      return 'You are already registered for this event.';
    }
    if (e.code == '42703' ||
        msg.contains('column') ||
        msg.contains('schema cache') ||
        msg.contains('could not find the') ||
        msg.contains('does not exist')) {
      return 'The app is out of sync with the latest database schema.';
    }
    if (msg.contains('expired')) {
      return 'The reservation has expired.';
    }

    // HTTP/auth error codes
    switch (e.code) {
      case '42501':
        return 'You don\'t have permission to perform this action.';
      case '23505':
        if (msg.contains('profiles_username_unique_idx') ||
            msg.contains('username')) {
          return 'That username is already taken. Try another one.';
        }
        return 'This record already exists.';
      case 'PGRST301':
        // JWT expired — triggers session expiry flow
        return 'Your session expired. Please sign in again.';
      case 'P0001':
        return e.message;
      default:
        return 'Database error: We couldn\'t process your request.';
    }
  }

  static String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated with hostname') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('clientexception')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('jwt expired') || msg.contains('session')) {
      return 'Your session expired. Please sign in again.';
    }
    if (msg.contains('not authorized') || msg.contains('unauthorized')) {
      return 'You are not authorized. Please sign in again.';
    }

    return e.message;
  }
}
