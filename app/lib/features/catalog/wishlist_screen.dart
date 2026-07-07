import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/app_spacing.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/supabase/wishlist_repository.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final _repository = WishlistRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    final items = await _repository.fetchWishlist(user.id);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(s.wishlist)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? GcEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Sign in to save favorites',
                  actionLabel: 'Sign in',
                  onAction: () => context.push('/auth'),
                )
              : _items.isEmpty
                  ? const GcEmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No favorites yet',
                      message: 'Tap the heart on any device to save it here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final device = item['devices'] as Map<String, dynamic>?;
                        if (device == null) return const SizedBox.shrink();
                        return GcCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                device['image_url'] as String? ?? '',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.devices),
                              ),
                            ),
                            title: Text(device['name'] as String? ?? ''),
                            subtitle: Text('৳${(device['monthly_price_3m'] as num?)?.toInt() ?? 0}/mo'),
                            trailing: IconButton(
                              icon: Icon(Icons.favorite_rounded, color: context.colors.primary),
                              onPressed: () async {
                                await _repository.remove(user.id, device['id'] as String);
                                await _load();
                              },
                            ),
                            onTap: () => context.push('/device/${device['id']}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
