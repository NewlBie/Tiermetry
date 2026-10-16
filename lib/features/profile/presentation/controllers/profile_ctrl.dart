import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_avatars.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repo.dart';

class ProfileCtrl extends ChangeNotifier {
  final ProfileRepo repo;

  ProfileCtrl(this.repo);

  ProfileEntity? _profile;
  ProfileEntity? get profile => _profile;
  String? get profileUserId => _profile?.id;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await repo.getProfileData().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your internet connection and try again.',
          );
        },
      );
    } catch (e) {
      _profile = null;
      _errorMessage = ErrorMapper.map(e);
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isUsernameAvailable(String username) {
    return repo.isUsernameAvailable(username);
  }

  Future<void> updateProfile({
    String? name,
    String? location,
    int? age,
    bool clearAge = false,
    int? avatarId,
    String? image,
    String? username,
    String? phoneNumber,
    String? dob,
    List<String>? platforms,
    List<String>? interests,
    List<String>? preferredGames,
    bool? profileSetupCompleted,
  }) async {
    if (_profile == null) {
      await loadProfile();
      if (_profile == null) {
        throw Exception('Profile could not be loaded. Please try again.');
      }
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final resolvedAvatarId =
        avatarId ?? AppAvatar.idFromAssetOrString(image) ?? _profile!.avatarId;

    final updated = _profile!.copyWith(
      name: name,
      location: location,
      age: age,
      clearAge: clearAge,
      avatarId: resolvedAvatarId,
      image: AppAvatar.assetForId(resolvedAvatarId),
      username: username,
      phoneNumber: phoneNumber,
      dob: dob,
      platforms: platforms,
      interests: interests,
      preferredGames: preferredGames,
      profileSetupCompleted: profileSetupCompleted,
    );

    // Optimistically update in-memory profile so UI updates immediately across all screens
    final previous = _profile;
    _profile = updated;
    notifyListeners();

    try {
      await repo.updateProfile(updated);
    } catch (e) {
      _profile = previous;
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation(String location) async {
    final normalizedLocation = location.trim();
    if (normalizedLocation.isEmpty) {
      throw ArgumentError.value(location, 'location', 'Location is required.');
    }
    if (_profile == null) {
      await loadProfile();
      if (_profile == null) {
        throw Exception('Profile could not be loaded. Please try again.');
      }
    }

    _isSaving = true;
    _errorMessage = null;
    final previous = _profile;
    _profile = _profile!.copyWith(location: normalizedLocation);
    notifyListeners();

    try {
      await repo.updateLocation(normalizedLocation);
    } catch (e) {
      _profile = previous;
      debugPrint('Error updating location: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<List<ProfileAddress>> getSavedAddresses() => repo.getSavedAddresses();

  Future<void> saveAddress(ProfileAddress address) => repo.saveAddress(address);

  Future<void> deleteAddress(String addressId) => repo.deleteAddress(addressId);

  Future<AccountDeletionRequest?> getDeletionRequest() =>
      repo.getDeletionRequest();

  Future<void> requestAccountDeletion(String? reason) =>
      repo.requestAccountDeletion(reason);

  Future<List<SupportRequestEntity>> getSupportRequests() =>
      repo.getSupportRequests();

  Future<SupportRequestEntity> submitSupportRequest({
    required String category,
    required String message,
    String? bookingId,
    String? paymentOrderId,
  }) => repo.submitSupportRequest(
    category: category,
    message: message,
    bookingId: bookingId,
    paymentOrderId: paymentOrderId,
  );

  void clear() {
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
