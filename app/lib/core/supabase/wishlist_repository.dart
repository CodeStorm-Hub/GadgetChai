import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistRepository {
  WishlistRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchWishlist(String userId) async {
    final response = await _client
        .from('wishlist_items')
        .select('*, devices(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> isWishlisted(String userId, String deviceId) async {
    final row = await _client
        .from('wishlist_items')
        .select('id')
        .eq('user_id', userId)
        .eq('device_id', deviceId)
        .maybeSingle();
    return row != null;
  }

  Future<void> add(String userId, String deviceId) async {
    await _client.from('wishlist_items').upsert({
      'user_id': userId,
      'device_id': deviceId,
    });
  }

  Future<void> remove(String userId, String deviceId) async {
    await _client
        .from('wishlist_items')
        .delete()
        .eq('user_id', userId)
        .eq('device_id', deviceId);
  }
}
