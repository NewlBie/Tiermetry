import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repo.dart';
import '../models/profile_model.dart';

class ProfileRepoImpl implements ProfileRepo {
  final SupabaseClient _supabase;

  ProfileRepoImpl(this._supabase);

  @override
  Future<ProfileEntity> getProfileData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(response);
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    await _supabase.from('profiles').update({
      'name': profile.name,
      'location': profile.location,
      'avatar_url': profile.image,
      'age': profile.age,
    }).eq('id', profile.id);
  }
}
