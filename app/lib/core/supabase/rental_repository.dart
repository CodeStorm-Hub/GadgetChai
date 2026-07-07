import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/uuid_v4.dart';

class CheckoutRentalItem {
  const CheckoutRentalItem({
    required this.deviceId,
    required this.planMonths,
    required this.monthlyPrice,
    this.selectedColor = 'Silver',
    this.carePlusMonthly = 0,
    this.deliveryFee = 0,
  });

  final String deviceId;
  final int planMonths;
  final double monthlyPrice;
  final String selectedColor;
  final double carePlusMonthly;
  final double deliveryFee;
}

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
    String? selectedColor,
    double carePlusMonthly = 0,
    double deliveryFee = 0,
    String? checkoutGroupId,
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
          'care_plus_monthly': carePlusMonthly,
          'delivery_fee': deliveryFee,
          'selected_color': selectedColor,
          'checkout_group_id': checkoutGroupId,
          'status': 'pending_kyc',
          'end_date': endDate.toIso8601String(),
        })
        .select()
        .single();
  }

  /// Creates one rental per cart line; returns primary (first) rental + group id.
  Future<({String groupId, Map<String, dynamic> primaryRental})> createCheckoutRentals({
    required String userId,
    required List<CheckoutRentalItem> items,
    required double securityDeposit,
    double deliveryFee = 200,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('At least one checkout item is required');
    }

    final groupId = generateUuidV4();
    Map<String, dynamic>? primary;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final rental = await createRental(
        userId: userId,
        deviceId: item.deviceId,
        planMonths: item.planMonths,
        monthlyPrice: item.monthlyPrice,
        securityDeposit: i == 0 ? securityDeposit : 0,
        selectedColor: item.selectedColor,
        carePlusMonthly: item.carePlusMonthly,
        deliveryFee: i == 0 ? deliveryFee : 0,
        checkoutGroupId: groupId,
      );
      primary ??= rental;
    }

    return (groupId: groupId, primaryRental: primary!);
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

  Future<Map<String, dynamic>> scheduleReturnWithPickup(
    String rentalId,
    DateTime pickupDate,
  ) async {
    final result = await _client.rpc('schedule_rental_return', params: {
      'p_rental_id': rentalId,
      'p_pickup_date': pickupDate.toIso8601String(),
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> extendRental(String rentalId, int extraMonths) async {
    final result = await _client.rpc('extend_rental', params: {
      'p_rental_id': rentalId,
      'p_extra_months': extraMonths,
    });
    return Map<String, dynamic>.from(result as Map);
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
