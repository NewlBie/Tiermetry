import 'package:flutter/foundation.dart';
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
      _errorMessage = 'Unable to load profile. Please try again.';
      debugPrint("Error loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
