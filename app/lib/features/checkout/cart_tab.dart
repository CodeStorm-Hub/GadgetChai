import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../navigation/main_navigation_frame.dart';
import 'cart_provider.dart';

class CartTab extends ConsumerStatefulWidget {
  const CartTab({super.key});

  @override
  ConsumerState<CartTab> createState() => _CartTabState();
}

class _CartTabState extends ConsumerState<CartTab> {
  bool _isBreakdownExpanded = false;

  void _showColorPicker(BuildContext context, CartItem item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        const colors = ['Silver', 'Space Gray', 'Gold', 'Midnight'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device color', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ...colors.map(
                (color) => ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(color),
                  trailing: item.selectedColor == color
                      ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
                      : null,
                  onTap: () {
                    ref.read(cartProvider.notifier).updateColor(item.id, color);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermPicker(BuildContext context, CartItem item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        const terms = [1, 3, 6, 12];
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan term', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ...terms.map((term) {
                final price = ref.read(cartProvider.notifier).getPriceForTerm(item.device, term);
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text('$term months'),
                  subtitle: Text('৳${price.toInt()}/month'),
                  trailing: item.selectedTerm == term
                      ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
                      : null,
                  onTap: () {
                    ref.read(cartProvider.notifier).updateTerm(item.id, term);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartList = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final monthlyRent = cartList.fold<double>(
      0.0,
      (sum, item) => sum + cartNotifier.getPriceForTerm(item.device, item.selectedTerm) * item.quantity,
    );
    final carePlusRent = cartList.fold<double>(
      0.0,
      (sum, item) => sum + (item.addCarePlus ? 450.0 : 0.0) * item.quantity,
    );
    final deliveryCharge = cartNotifier.getOneTimeDelivery();
    final totalAmount = cartNotifier.getTotalAmount();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: cartList.isEmpty
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.lg,
                      AppSpacing.pageHorizontal,
                      AppSpacing.md,
                    ),
                    child: Text('Your cart', style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: GcEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Cart is empty',
                    message: 'Browse our catalog and add devices to start renting.',
                    actionLabel: 'Explore catalog',
                    onAction: () => ref.read(activeTabProvider.notifier).state = 1,
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: gcBottomNavScrollPadding(context))),
              ],
            )
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal,
                          AppSpacing.lg,
                          AppSpacing.pageHorizontal,
                          AppSpacing.md,
                        ),
                        child: Text(
                          'Your cart (${cartList.length})',
                          style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildCartItemCard(cartList[index]),
                          childCount: cartList.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                      sliver: SliverToBoxAdapter(
                        child: _buildBreakdownPanel(monthlyRent, carePlusRent, deliveryCharge, totalAmount),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    SliverToBoxAdapter(child: SizedBox(height: gcBottomNavScrollPadding(context))),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 12,
                    color: context.colors.surfaceContainerHigh,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isBreakdownExpanded = !_isBreakdownExpanded),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Total', style: context.text.labelMedium),
                                        Icon(
                                          _isBreakdownExpanded
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    GcPriceTag(amount: totalAmount, suffix: '', compact: true, emphasized: true),
                                  ],
                                ),
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(120, 48),
                                shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
                              ),
                              onPressed: () {
                                final mainItem = cartList.first;
                                context.push('/checkout', extra: {
                                  'deviceId': mainItem.device['id'],
                                  'planMonths': mainItem.selectedTerm,
                                });
                              },
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final itemRate = ref.read(cartProvider.notifier).getPriceForTerm(item.device, item.selectedTerm);
    final scheme = context.colors;

    return GcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppShapes.image,
                child: Image.network(
                  item.device['image_url'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 80,
                    height: 80,
                    color: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.device['name'], style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIconTag(Icons.verified_rounded, 'Excellent condition'),
                    _buildIconTag(Icons.local_shipping_outlined, 'Delivery in 1–3 days'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: Icon(Icons.circle, size: 12, color: _colorValueFromName(item.selectedColor)),
                label: Text(item.selectedColor),
                onPressed: () => _showColorPicker(context, item),
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text('${item.selectedTerm} mo'),
                onPressed: () => _showTermPicker(context, item),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Care Plus', style: context.text.titleSmall),
                      Text(
                        'Screen & spill protection — ৳450/mo',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: item.addCarePlus,
                  onChanged: (val) => ref.read(cartProvider.notifier).toggleCarePlus(item.id, val),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => ref.read(cartProvider.notifier).removeFromCart(item.id),
              ),
              GcPriceTag(amount: itemRate * item.quantity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownPanel(double monthlyRent, double carePlusRent, double delivery, double total) {
    if (!_isBreakdownExpanded) return const SizedBox.shrink();

    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Charge breakdown', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          _buildSummaryLine('Monthly rent', '৳${monthlyRent.toInt()}'),
          if (carePlusRent > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSummaryLine('Care Plus', '৳${carePlusRent.toInt()}', valueColor: context.colors.primary),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryLine('Delivery (one-time)', '৳${delivery.toInt()}'),
          const Divider(height: AppSpacing.xl),
          _buildSummaryLine('First month total', '৳${total.toInt()}', bold: true, valueColor: context.colors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.text.bodyMedium),
        Text(
          value,
          style: context.text.titleMedium?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildIconTag(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: context.text.bodySmall)),
        ],
      ),
    );
  }

  Color _colorValueFromName(String name) {
    switch (name.toLowerCase()) {
      case 'space gray':
        return Colors.grey.shade700;
      case 'gold':
        return Colors.amber.shade300;
      case 'midnight':
        return Colors.blueGrey.shade900;
      default:
        return Colors.grey.shade300;
    }
  }
}
