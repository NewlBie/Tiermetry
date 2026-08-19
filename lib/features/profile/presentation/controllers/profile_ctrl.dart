import 'package:flutter/foundation.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repo.dart';

class ProfileCtrl extends ChangeNotifier {
  final ProfileRepo repo;

  ProfileCtrl(this.repo);

  ProfileEntity? _profile;
  ProfileEntity? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await repo.getProfileData();
    } catch (e) {
      _errorMessage = ErrorMapper.map(e);
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? location,
    int? age,
    String? image,
  }) async {
    if (_profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      String? finalImageUrl = image;

      // If the image is a local file path, upload it first
      if (image != null && !image.startsWith('http')) {
        finalImageUrl = await repo.uploadAvatar(image);
      }

      final updated = _profile!.copyWith(
        name: name,
        location: location,
        age: age,
        image: finalImageUrl,
      );
      await repo.updateProfile(updated);
      _profile = updated;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
