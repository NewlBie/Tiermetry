import '../entities/profile_entity.dart';

abstract class ProfileRepo {
  Future<ProfileEntity> getProfileData();
}
