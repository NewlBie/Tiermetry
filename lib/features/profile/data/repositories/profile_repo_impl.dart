import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repo.dart';
import '../models/profile_model.dart';

class ProfileRepoImpl implements ProfileRepo {
  final SupabaseClient _supabase;

  ProfileRepoImpl(this._supabase);

  @override
  Future<ProfileEntity> getProfileData() async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response =
        await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

    if (response == null) {
      throw Exception(
        'Your account profile is not ready yet. Please sign in again.',
      );
    }

    final data = Map<String, dynamic>.from(response);
    data['email'] = user?.email ?? data['email'];
    return ProfileModel.fromJson(data);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _supabase.rpc<bool>(
      'is_username_available',
      params: {'p_username': username},
    );
    return response;
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'name': profile.name,
      'location': profile.location,
      'avatar_id': profile.avatarId,
      'age': profile.age,
      'username': profile.username,
      'phone_number': profile.phoneNumber,
      'dob': profile.dob,
      'platforms': profile.platforms,
      'interests': profile.interests,
      'preferred_games': profile.preferredGames,
      'profile_setup_completed': profile.profileSetupCompleted,
    };

    final updated =
        await _supabase
            .from('profiles')
            .update(payload)
            .eq('id', userId)
            .select('id, profile_setup_completed')
            .maybeSingle();

    _confirmProfileUpdate(updated, profile.profileSetupCompleted);
  }

  @override
  Future<void> updateLocation(String location) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final normalizedLocation = location.trim();

    final updated =
        await _supabase
            .from('profiles')
            .update({'location': normalizedLocation})
            .eq('id', userId)
            .select('location')
            .maybeSingle();

    if (updated == null || updated['location'] != normalizedLocation) {
      throw Exception('Location could not be saved. Please try again.');
    }
  }

  void _confirmProfileUpdate(
    Map<String, dynamic>? updated,
    bool expectedSetupCompleted,
  ) {
    if (updated == null) {
      throw Exception('Profile row could not be saved. Please try again.');
    }
    if (updated['profile_setup_completed'] != expectedSetupCompleted) {
      throw Exception(
        'Profile setup status could not be saved. Please try again.',
      );
    }
  }

  @override
  Future<List<ProfileAddress>> getSavedAddresses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final rows = await _supabase
        .from('profile_addresses')
        .select('id, label, address_line, city, is_primary')
        .eq('user_id', userId)
        .order('is_primary', ascending: false)
        .order('created_at');
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => ProfileAddress(
            id: row['id'] as String,
            label: row['label'] as String,
            addressLine: row['address_line'] as String,
            city: row['city'] as String,
            isPrimary: row['is_primary'] as bool? ?? false,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveAddress(ProfileAddress address) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.rpc<void>(
      'save_profile_address',
      params: {
        'p_address_id': address.id.isEmpty ? null : address.id,
        'p_label': address.label.trim(),
        'p_address_line': address.addressLine.trim(),
        'p_city': address.city.trim(),
        'p_is_primary': address.isPrimary,
      },
    );
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase
        .from('profile_addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', userId);
  }

  @override
  Future<AccountDeletionRequest?> getDeletionRequest() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final row =
        await _supabase
            .from('account_deletion_requests')
            .select('status, reason, requested_at')
            .eq('user_id', userId)
            .maybeSingle();
    if (row == null) return null;
    return AccountDeletionRequest(
      status: row['status'] as String,
      reason: row['reason'] as String?,
      requestedAt: DateTime.parse(row['requested_at'] as String).toLocal(),
    );
  }

  @override
  Future<void> requestAccountDeletion(String? reason) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('account_deletion_requests').insert({
      'user_id': userId,
      'reason': reason?.trim().isEmpty ?? true ? null : reason!.trim(),
    });
  }

  @override
  Future<List<SupportRequestEntity>> getSupportRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final rows = await _supabase
        .from('support_requests')
        .select(
          'id, category, message, status, booking_id, payment_order_id, resolution_note, created_at, updated_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(_supportRequestFromJson)
        .toList(growable: false);
  }

  @override
  Future<SupportRequestEntity> submitSupportRequest({
    required String category,
    required String message,
    String? bookingId,
    String? paymentOrderId,
  }) async {
    if (_supabase.auth.currentUser?.id == null) {
      throw Exception('Not authenticated');
    }
    final response = await _supabase.rpc<dynamic>(
      'submit_support_request',
      params: {
        'p_category': category,
        'p_message': message.trim(),
        'p_booking_id': bookingId,
        'p_payment_order_id': paymentOrderId,
      },
    );
    final data =
        response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
    return _supportRequestFromJson(data);
  }

  SupportRequestEntity _supportRequestFromJson(Map<String, dynamic> json) {
    return SupportRequestEntity(
      id: json['id'] as String,
      category: json['category'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      bookingId: json['booking_id'] as String?,
      paymentOrderId: json['payment_order_id'] as String?,
      resolutionNote: json['resolution_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      alreadyOpen: json['already_open'] as bool? ?? false,
    );
  }
}
