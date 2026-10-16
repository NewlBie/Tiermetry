import '../entities/profile_entity.dart';

abstract class ProfileRepo {
  Future<ProfileEntity> getProfileData();
  Future<bool> isUsernameAvailable(String username);
  Future<void> updateProfile(ProfileEntity profile);
  Future<void> updateLocation(String location);
  Future<List<ProfileAddress>> getSavedAddresses();
  Future<void> saveAddress(ProfileAddress address);
  Future<void> deleteAddress(String addressId);
  Future<AccountDeletionRequest?> getDeletionRequest();
  Future<void> requestAccountDeletion(String? reason);
  Future<List<SupportRequestEntity>> getSupportRequests();
  Future<SupportRequestEntity> submitSupportRequest({
    required String category,
    required String message,
    String? bookingId,
    String? paymentOrderId,
  });
}
