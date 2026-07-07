import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralRepository {
  ReferralRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String?> fetchReferralCode(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('referral_code')
        .eq('id', userId)
        .maybeSingle();
    return profile?['referral_code'] as String?;
  }

  Future<int> countReferrals(String userId) async {
    final rows = await _client
        .from('referrals')
        .select('id')
        .eq('referrer_id', userId);
    return (rows as List).length;
  }

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final result = await _client.rpc('apply_referral_code', params: {
      'p_code': code.trim().toUpperCase(),
    });
    return Map<String, dynamic>.from(result as Map);
  }
}
