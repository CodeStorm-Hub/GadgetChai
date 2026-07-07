import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_spacing.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import 'compare_provider.dart';

class DeviceComparisonScreen extends ConsumerWidget {
  const DeviceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(compareProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.compare} (${devices.length}/${CompareNotifier.maxDevices})'),
        actions: [
          if (devices.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(compareProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: devices.isEmpty
          ? GcEmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'No devices to compare',
              message: 'Add up to 3 devices from the catalog or device page.',
              actionLabel: s.explore,
              onAction: () => context.go('/'),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              children: [
                ...devices.map((device) => _CompareCard(device: device)),
                const SizedBox(height: AppSpacing.xl),
                if (devices.length == 1)
                  Text(
                    'Add more devices to compare specs side by side.',
                    style: context.text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
    );
  }
}

class _CompareCard extends ConsumerWidget {
  const _CompareCard({required this.device});

  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = device['id'] as String;
    return GcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device['name'] as String? ?? '',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => ref.read(compareProvider.notifier).remove(id),
              ),
            ],
          ),
          Text('${device['brand']} · ${device['category']}', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _row('1 mo', device['monthly_price_1m']),
          _row('3 mo', device['monthly_price_3m']),
          _row('6 mo', device['monthly_price_6m']),
          _row('12 mo', device['monthly_price_12m']),
          if (device['specs_processor'] != null) ...[
            const Divider(),
            _spec('Processor', device['specs_processor']),
            _spec('Display', device['specs_display']),
            _spec('Memory', device['specs_memory']),
            _spec('Battery', device['specs_battery']),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.push('/device/$id'),
            child: const Text('View details'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('৳${(price as num?)?.toInt() ?? 0}/mo'),
        ],
      ),
    );
  }

  Widget _spec(String label, dynamic value) {
    if (value == null || '$value'.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}
