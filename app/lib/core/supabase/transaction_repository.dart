import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  TransactionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchForRental(String rentalId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('rental_id', rentalId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchForUser(String userId) async {
    final rentals = await _client
        .from('rentals')
        .select('id')
        .eq('user_id', userId);

    final rentalIds = rentals.map((r) => r['id'] as String).toList();
    if (rentalIds.isEmpty) return [];

    final response = await _client
        .from('transactions')
        .select('*, rentals(device_id, devices(name))')
        .inFilter('rental_id', rentalIds)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
