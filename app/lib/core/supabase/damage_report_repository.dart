import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class DamageReportRepository {
  DamageReportRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitReport({
    required String rentalId,
    required String userId,
    required String description,
    required String localPhotoPath,
  }) async {
    final file = File(localPhotoPath);
    final bytes = await file.readAsBytes();
    final ext = localPhotoPath.split('.').last;
    final storagePath =
        '$userId/$rentalId-${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('damage-reports').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );

    await _client.from('damage_reports').insert({
      'rental_id': rentalId,
      'user_id': userId,
      'description': description,
      'photo_url': storagePath,
      'status': 'submitted',
    });
  }

  Future<String?> signedPhotoUrl(String storagePath) async {
    return _client.storage
        .from('damage-reports')
        .createSignedUrl(storagePath, 3600);
  }
}
