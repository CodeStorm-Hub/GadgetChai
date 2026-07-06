import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  HomeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPromos() async {
    final response = await _client
        .from('promos')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }
}
