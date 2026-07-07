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
    await _client.rpc('review_kyc', params: {
      'p_review_id': reviewId,
      'p_status': status,
    });
  }

  Future<String?> signedKycDocumentUrl(String storagePath) async {
    if (storagePath.isEmpty) return null;
    if (storagePath.startsWith('http')) return storagePath;
    return _client.storage
        .from('kyc-documents')
        .createSignedUrl(storagePath, 3600);
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

  Future<List<Map<String, dynamic>>> fetchDamageReports() async {
    final response = await _client
        .from('damage_reports')
        .select('*, rentals(*, devices(name)), profiles(full_name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> reviewDamageReport(String reportId, String status, {String? notes}) async {
    await _client.rpc('review_damage_report', params: {
      'p_report_id': reportId,
      'p_status': status,
      'p_admin_notes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMrrTrend({int months = 6}) async {
    final response = await _client.rpc('admin_mrr_trend', params: {'p_months': months});
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<String?> signedStorageUrl(String bucket, String path) async {
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return _client.storage.from(bucket).createSignedUrl(path, 3600);
  }
}
