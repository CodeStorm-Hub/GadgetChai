import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  AdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchDeviceLedger() async {
    final response = await _client
        .from('device_items')
        .select('*, devices(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchPendingKycReviews() async {
    final response = await _client
        .from('kyc_reviews')
        .select('*, profiles(*)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateKycStatus(String reviewId, String status) async {
    await _client.from('kyc_reviews').update({'status': status}).eq('id', reviewId);
  }

  Future<void> updateDeviceCondition(String itemId, String grade) async {
    await _client
        .from('device_items')
        .update({'condition_grade': grade})
        .eq('id', itemId);
  }

  Future<void> dispatchRental(String rentalId, String deliveryOtp) async {
    await _client.from('rentals').update({
      'status': 'in_transit',
      'delivery_otp': deliveryOtp,
    }).eq('id', rentalId);
  }

  Future<void> activateRental(String rentalId) async {
    await _client.from('rentals').update({'status': 'active'}).eq('id', rentalId);
  }
}
