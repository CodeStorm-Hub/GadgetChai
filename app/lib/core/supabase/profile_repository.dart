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

  Future<void> ensureProfile(
    String userId, {
    String? phone,
    String? fullName,
  }) async {
    final existing = await fetchProfile(userId);
    if (existing != null) {
      final updates = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty && (existing['phone'] as String?)?.isEmpty != false) {
        updates['phone'] = phone;
      }
      if (fullName != null &&
          fullName.isNotEmpty &&
          (existing['full_name'] as String?)?.isEmpty != false) {
        updates['full_name'] = fullName;
      }
      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', userId);
      }
      return;
    }

    await _client.from('profiles').insert({
      'id': userId,
      'role': 'customer',
      'phone': ?phone,
      'full_name': fullName ?? '',
      'kyc_status': 'pending',
      'trust_score': 50,
    });
  }

  Future<void> updatePhone(String userId, String phone) async {
    await _client.from('profiles').update({'phone': phone}).eq('id', userId);
  }

  Future<void> updateTrustScore(String userId, int trustScore) async {
    await _client
        .from('profiles')
        .update({'trust_score': trustScore.clamp(0, 100)})
        .eq('id', userId);
  }

  Future<void> updateFulfillmentDetails({
    required String userId,
    required String deliveryAddress,
    required String emergencyContact,
  }) async {
    await _client.from('profiles').update({
      'delivery_address': deliveryAddress,
      'emergency_contact': emergencyContact,
    }).eq('id', userId);
  }
}

/// Normalizes Bangladesh mobile numbers to local `01XXXXXXXXX` format.
String normalizeBdPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('880')) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0')) {
    return digits;
  }
  if (digits.length == 10) {
    return '0$digits';
  }
  return digits;
}

bool isValidBdPhone(String input) {
  final normalized = normalizeBdPhone(input);
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(normalized);
}
