import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> ensureProfile(String userId, {String? phone}) async {
    final existing = await fetchProfile(userId);
    if (existing != null) return;

    await _client.from('profiles').insert({
      'id': userId,
      'role': 'customer',
      'phone': ?phone,
      'kyc_status': 'pending',
      'trust_score': 50,
    });
  }

  Future<void> updateTrustScore(String userId, int trustScore) async {
    await _client
        .from('profiles')
        .update({'trust_score': trustScore.clamp(0, 100)})
        .eq('id', userId);
  }
}
