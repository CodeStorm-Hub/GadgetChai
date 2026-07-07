import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  ReviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> fetchDeviceRating(String deviceId) async {
    final result = await _client.rpc('device_rating_summary', params: {
      'p_device_id': deviceId,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> fetchDeviceReviews(String deviceId, {int limit = 5}) async {
    final response = await _client
        .from('device_reviews')
        .select('*, profiles(full_name)')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> submitReview({
    required String rentalId,
    required int rating,
    String? reviewText,
  }) async {
    await _client.rpc('submit_device_review', params: {
      'p_rental_id': rentalId,
      'p_rating': rating,
      'p_review_text': reviewText,
    });
  }
}
