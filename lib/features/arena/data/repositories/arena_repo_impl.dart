import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';
import '../../domain/repositories/arena_repo.dart';
import '../models/arena_model.dart';

class ArenaRepoImpl implements ArenaRepo {
  final SupabaseClient _supabase;

  ArenaRepoImpl(this._supabase);

  @override
  Future<List<ArenaEntity>> getArenas() async {
    final response = await _supabase.from('venues').select();
    return (response as List).map((json) => ArenaModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<ArenaDetailsEntity?> getArenaDetails(String id) async {
    final response = await _supabase
        .from('venues')
        .select('*, services(*, service_units(*))')
        .eq('id', id)
        .single();
    
    return ArenaDetailsModel.fromJson(response);
  }

  @override
  Future<List<ArenaDevice>> getAvailableUnits({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _supabase.rpc<List<dynamic>>('get_available_units', params: {
      'p_service_id': serviceId,
      'p_start_time': startTime.toIso8601String(),
      'p_end_time': endTime.toIso8601String(),
    });

    return response
        .map<ArenaDevice>((json) => ArenaDeviceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
