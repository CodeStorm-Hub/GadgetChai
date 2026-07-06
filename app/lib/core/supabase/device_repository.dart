import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRepository {
  DeviceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchCatalog() async {
    final response = await _client
        .from('devices')
        .select('*')
        .order('sort_order')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchById(String deviceId) async {
    return await _client
        .from('devices')
        .select('*')
        .eq('id', deviceId)
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchFeatured({int limit = 3}) async {
    final response = await _client
        .from('devices')
        .select('*')
        .eq('is_featured', true)
        .order('sort_order')
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
