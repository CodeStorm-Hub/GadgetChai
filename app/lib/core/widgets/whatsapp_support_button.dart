import 'package:flutter/material.dart';
import '../../core/design/app_spacing.dart';
import 'whatsapp_support.dart';

class WhatsappSupportButton extends StatelessWidget {
  const WhatsappSupportButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.chat_rounded),
        tooltip: 'WhatsApp support',
        onPressed: () => openWhatsappSupport(context),
      );
    }

    return FloatingActionButton.extended(
      heroTag: 'whatsapp_support',
      onPressed: () => openWhatsappSupport(context),
      icon: const Icon(Icons.chat_rounded),
      label: const Text('WhatsApp'),
    );
  }
}

class WhatsappSupportBanner extends StatelessWidget {
  const WhatsappSupportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: ListTile(
        leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
        title: const Text('Need help?'),
        subtitle: const Text('Chat with GadgetChai support on WhatsApp'),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: () => openWhatsappSupport(context),
      ),
    );
  }
}
