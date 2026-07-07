import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/adaptive_layout.dart';
import '../../core/design/app_breakpoints.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/device_repository.dart';
import '../../core/supabase/review_repository.dart';
import '../../core/supabase/wishlist_repository.dart';
import '../checkout/cart_provider.dart';
import '../../features/navigation/main_navigation_frame.dart';
import 'compare_provider.dart';

class DeviceDetailsScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailsScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends ConsumerState<DeviceDetailsScreen> {
  final _deviceRepository = DeviceRepository();
  final _reviewRepository = ReviewRepository();
  final _wishlistRepository = WishlistRepository();
  Map<String, dynamic>? _device;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTerm = 3;
  String _selectedColor = 'Silver';
  bool _showAllSpecs = false;
  bool _isWishlisted = false;
  Map<String, dynamic> _ratingSummary = {'avg_rating': 0, 'review_count': 0};
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchDeviceDetails();
  }

  Future<void> _fetchDeviceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final device = await _deviceRepository.fetchById(widget.deviceId);
      final rating = await _reviewRepository.fetchDeviceRating(widget.deviceId);
      final reviews = await _reviewRepository.fetchDeviceReviews(widget.deviceId);
      var wishlisted = false;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        wishlisted = await _wishlistRepository.isWishlisted(user.id, widget.deviceId);
      }
      setState(() {
        _device = device;
        _ratingSummary = rating;
        _reviews = reviews;
        _isWishlisted = wishlisted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load device: $e';
        _isLoading = false;
      });
    }
  }

  double _getPriceForTerm(int term) {
    if (_device == null) return 0;
    switch (term) {
      case 1: return (_device!['monthly_price_1m'] as num).toDouble();
      case 3: return (_device!['monthly_price_3m'] as num).toDouble();
      case 6: return (_device!['monthly_price_6m'] as num).toDouble();
      case 12: return (_device!['monthly_price_12m'] as num).toDouble();
      default: return (_device!['monthly_price_3m'] as num).toDouble();
    }
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.push('/auth');
      return;
    }
    final deviceId = widget.deviceId;
    if (_isWishlisted) {
      await _wishlistRepository.remove(user.id, deviceId);
    } else {
      await _wishlistRepository.add(user.id, deviceId);
    }
    setState(() => _isWishlisted = !_isWishlisted);
  }

  void _toggleCompare() {
    if (_device == null) return;
    ref.read(compareProvider.notifier).toggle(_device!);
    final count = ref.read(compareProvider).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compare list: $count/${CompareNotifier.maxDevices} devices')),
    );
  }

  void _shareDevice() {
    final link = 'gadgetchai://device/${widget.deviceId}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device link copied to clipboard')),
    );
  }

  void _addToCart() {
    if (_device == null) return;
    
    // Add item to Cart via Provider
    ref.read(cartProvider.notifier).addToCart(
      _device!,
      term: _selectedTerm,
      color: _selectedColor,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_device!['name']} to cart!'),
        backgroundColor: context.colors.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: context.colors.onSecondary,
          onPressed: () {
            ref.read(activeTabProvider.notifier).state = 2;
            context.go('/');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_device == null) {
      return Scaffold(
        body: GcEmptyState(
          icon: Icons.devices_other_rounded,
          title: 'Device unavailable',
          message: _errorMessage ?? 'We could not load this device.',
          actionLabel: 'Retry',
          onAction: _fetchDeviceDetails,
        ),
      );
    }

    final currentMonthlyPrice = _getPriceForTerm(_selectedTerm);
    final isOOS = _device!['is_out_of_stock'] == true;

    final singleMonthPrice = _getPriceForTerm(1);
    final monthlySaving = singleMonthPrice - currentMonthlyPrice;
    final totalSaving = monthlySaving * _selectedTerm;

    final isWide = AppBreakpoints.sizeClassOf(context).isMediumOrWider;

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _device!['name'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Add to compare',
            onPressed: _toggleCompare,
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _shareDevice),
          IconButton(
            icon: Icon(_isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            color: _isWishlisted ? context.colors.primary : null,
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main scrollable details body
          Positioned.fill(
            bottom: 90, // Leave room for sticky footer
            child: SingleChildScrollView(
              child: GcAdaptivePage(
                padding: const EdgeInsets.all(AppSpacing.lg),
                maxWidth: isWide ? 1100 : 800,
                alignTop: true,
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProductImageHeader(),
                                const SizedBox(height: AppSpacing.xl),
                                _buildSpecificationsCard(textTheme),
                                const SizedBox(height: AppSpacing.lg),
                                _buildInsideBoxCard(textTheme),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderDetails(textTheme),
                                const SizedBox(height: AppSpacing.xl),
                                _buildPlanSelector(textTheme),
                                const SizedBox(height: AppSpacing.xl),
                                _buildColorSelector(textTheme),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProductImageHeader(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildHeaderDetails(textTheme),
                          const SizedBox(height: AppSpacing.xl),
                          _buildPlanSelector(textTheme),
                          const SizedBox(height: AppSpacing.xl),
                          _buildColorSelector(textTheme),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSpecificationsCard(textTheme),
                          const SizedBox(height: AppSpacing.lg),
                          _buildInsideBoxCard(textTheme),
                          const SizedBox(height: AppSpacing.lg),
                          _buildReviewsSection(textTheme),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
              ),
            ),
          ),

          // Sticky Bottom Checkout Footer
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GcPriceTag(amount: currentMonthlyPrice, emphasized: true),
                            if (totalSaving > 0)
                              Text(
                                'Save ৳${totalSaving.toInt()} on this term',
                                style: context.text.labelMedium?.copyWith(color: context.colors.secondary),
                              ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 48),
                          shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
                        ),
                        onPressed: isOOS ? null : _addToCart,
                        child: Text(isOOS ? 'Out of stock' : 'Add to cart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductImageHeader() {
    return GcExpressiveSurface(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: context.expressive.featureRadius,
        child: SizedBox(
          height: context.isWide ? 360 : 300,
          width: double.infinity,
          child: Image.network(
            _device!['image_url'],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(Icons.image_outlined, size: 72, color: context.colors.outline),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderDetails(TextTheme textTheme) {
    final scheme = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _device!['brand']?.toUpperCase() ?? 'TECH',
              style: context.text.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•  ${_device!['category']}',
              style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _device!['name'],
          style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if ((_ratingSummary['review_count'] as int? ?? 0) > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded, color: context.colors.tertiary, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_ratingSummary['avg_rating']} (${_ratingSummary['review_count']} reviews)',
                style: context.text.labelLarge,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _device!['description'] ?? 'No description details listed.',
          style: context.text.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPlanSelector(TextTheme textTheme) {
    const terms = [1, 3, 6, 12];
    final selectedIndex = terms.indexOf(_selectedTerm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription term', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ButtonGroupM3E(
          selection: true,
          selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
          expanded: true,
          type: ButtonGroupM3EType.connected,
          style: ButtonM3EStyle.tonal,
          actions: [
            for (final term in terms)
              ButtonGroupM3EAction(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$term mo'),
                    Text(
                      '৳${_getPriceForTerm(term).toInt()}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
                onPressed: () => setState(() => _selectedTerm = term),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector(TextTheme textTheme) {
    const colors = ['Silver', 'Space Gray', 'Gold', 'Midnight'];
    const colorValues = {
      'Silver': Color(0xFFE5E7EB),
      'Space Gray': Color(0xFF6B7280),
      'Gold': Color(0xFFD4AF37),
      'Midnight': Color(0xFF1E293B),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select color', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            for (final color in colors)
              GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: context.expressive.motionShort,
                  curve: context.expressive.emphasizedCurve,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? context.colors.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: colorValues[color],
                    child: _selectedColor == color
                        ? Icon(Icons.check_rounded, size: 18, color: color == 'Silver' ? Colors.black87 : Colors.white)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_selectedColor, style: context.text.bodyMedium),
      ],
    );
  }

  Widget _buildSpecificationsCard(TextTheme textTheme) {
    final scheme = context.colors;
    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product specifications',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _buildSpecLine('Memory', _device!['specs_memory'] ?? '12GB RAM'),
          Divider(color: scheme.outlineVariant, height: 20),
          _buildSpecLine('Battery', _device!['specs_battery'] ?? '3988 mAh'),
          Divider(color: scheme.outlineVariant, height: 20),
          _buildSpecLine('Display', _device!['specs_display'] ?? '6.3-inch OLED Retina screen'),
          if (_showAllSpecs) ...[
            Divider(color: scheme.outlineVariant, height: 20),
            _buildSpecLine('Processor', _device!['specs_processor'] ?? 'Next-gen System chip'),
            Divider(color: scheme.outlineVariant, height: 20),
            _buildSpecLine('Camera', _device!['specs_camera'] ?? 'High definition sensor modules'),
          ],
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: () => setState(() => _showAllSpecs = !_showAllSpecs),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
              ),
              child: Text(_showAllSpecs ? 'Show less' : 'Show more'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
        ),
      ],
    );
  }

  Widget _buildInsideBoxCard(TextTheme textTheme) {
    final String deviceItemLabel = _device!['category'] == 'Phones & Tablets' ? 'Smartphone' : 'Gadget Device';
    final IconData deviceIcon = _device!['category'] == 'Phones & Tablets' ? Icons.phone_android : Icons.devices;
    final scheme = context.colors;

    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inside the box',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _buildBoxManifestItem(Icons.cable, 'Charging Cable'),
          Divider(color: scheme.outlineVariant, height: 20),
          _buildBoxManifestItem(Icons.book_outlined, 'User manual'),
          Divider(color: scheme.outlineVariant, height: 20),
          _buildBoxManifestItem(Icons.pin, 'SIM card remover pin'),
          Divider(color: scheme.outlineVariant, height: 20),
          _buildBoxManifestItem(deviceIcon, deviceItemLabel),
        ],
      ),
    );
  }

  Widget _buildBoxManifestItem(IconData icon, String label) {
    final scheme = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: scheme.surfaceContainerHigh,
          child: Icon(icon, color: scheme.onSurfaceVariant, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildReviewsSection(TextTheme textTheme) {
    if (_reviews.isEmpty) {
      return GcCard(
        child: Text(
          'No renter reviews yet. Be the first after your rental!',
          style: context.text.bodyMedium,
        ),
      );
    }

    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Renter reviews', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          ..._reviews.map((review) {
            final name = review['profiles']?['full_name'] as String? ?? 'Renter';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                            i < (review['rating'] as int? ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: context.colors.tertiary,
                          )),
                      const SizedBox(width: 8),
                      Text(name, style: context.text.labelMedium),
                    ],
                  ),
                  if (review['review_text'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(review['review_text'] as String, style: context.text.bodySmall),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
