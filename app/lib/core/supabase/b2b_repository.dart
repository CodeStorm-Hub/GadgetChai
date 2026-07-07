import 'package:supabase_flutter/supabase_flutter.dart';

class B2bRepository {
  B2bRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitInquiry({
    String? userId,
    required String companyName,
    required String contactName,
    required String contactPhone,
    String? contactEmail,
    required int deviceCount,
    required List<String> deviceTypes,
    String? notes,
  }) async {
    await _client.from('b2b_inquiries').insert({
      'user_id': ?userId,
      'company_name': companyName,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'device_count': deviceCount,
      'device_types': deviceTypes,
      'notes': notes,
    });
  }

  Future<Map<String, dynamic>> applyDiscountProgram({
    required String accountType,
    required String identifier,
  }) async {
    final result = await _client.rpc('apply_discount_program', params: {
      'p_account_type': accountType,
      'p_identifier': identifier,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> fetchSustainabilityStats(String userId) async {
    final result = await _client.rpc('user_sustainability_stats', params: {
      'p_user_id': userId,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}
