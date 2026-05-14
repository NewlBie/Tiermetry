import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repo.dart';
import '../datasources/profile_source.dart';

class ProfileRepoImpl implements ProfileRepo {
  final ProfileSource source;

  ProfileRepoImpl(this.source);

  @override
  Future<ProfileEntity> getProfileData() async {
    return await source.getProfileData();
  }
}
