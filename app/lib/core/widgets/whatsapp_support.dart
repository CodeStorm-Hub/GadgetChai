import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

Future<void> openWhatsappSupport(BuildContext context) async {
  final uri = Uri.parse(
    'https://wa.me/${AppConfig.supportWhatsapp}?text=${Uri.encodeComponent(AppConfig.supportWhatsappMessage)}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }
}
