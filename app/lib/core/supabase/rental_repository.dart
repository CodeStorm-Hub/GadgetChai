import 'package:supabase_flutter/supabase_flutter.dart';

class RentalRepository {
  RentalRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchUserRentals(String userId) async {
    final response = await _client
        .from('rentals')
        .select('*, devices(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createRental({
    required String userId,
    required String deviceId,
    required int planMonths,
    required double monthlyPrice,
    required double securityDeposit,
  }) async {
    final endDate = DateTime.now().add(Duration(days: planMonths * 30));

    return await _client
        .from('rentals')
        .insert({
          'user_id': userId,
          'device_id': deviceId,
          'plan_months': planMonths,
          'monthly_price': monthlyPrice,
          'security_deposit': securityDeposit,
          'status': 'pending_kyc',
          'end_date': endDate.toIso8601String(),
        })
        .select()
        .single();
  }

  Future<void> updateRentalStatus(String rentalId, String status, {String? deliveryOtp}) async {
    final payload = <String, dynamic>{'status': status};
    if (deliveryOtp != null) {
      payload['delivery_otp'] = deliveryOtp;
    }
    await _client.from('rentals').update(payload).eq('id', rentalId);
  }

  Future<void> scheduleReturn(String rentalId) async {
    await updateRentalStatus(rentalId, 'returned');
  }

  Future<List<Map<String, dynamic>>> fetchAllRentals() async {
    final response = await _client
        .from('rentals')
        .select('*, devices(*), profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<double> calculateMrr() async {
    final response = await _client
        .from('rentals')
        .select('monthly_price')
        .eq('status', 'active');
    double total = 0;
    for (final row in response) {
      total += (row['monthly_price'] as num).toDouble();
    }
    return total;
  }
}
