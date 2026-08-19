import 'dart:io';
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

    final response =
        await _supabase.from('profiles').select().eq('id', userId).single();

    return ProfileModel.fromJson(response);
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    await _supabase
        .from('profiles')
        .update({
          'name': profile.name,
          'location': profile.location,
          'avatar_url': profile.image,
          'age': profile.age,
        })
        .eq('id', profile.id);
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final file = File(filePath);
    final fileExt = filePath.split('.').last;
    final fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = 'public/$fileName';

    await _supabase.storage
        .from('avatars')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return _supabase.storage.from('avatars').getPublicUrl(path);
  }
}
