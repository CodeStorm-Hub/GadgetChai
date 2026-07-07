import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../features/auth/login_screen.dart';
import '../features/catalog/device_details_screen.dart';
import '../features/checkout/cart_provider.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/camera_kyc_screen.dart';
import '../features/checkout/bkash_agreement_webview.dart';
import '../features/rentals/my_tech_screen.dart';
import '../features/rentals/damage_report_screen.dart';
import '../features/business/business_portal_screen.dart';
import '../features/catalog/device_comparison_screen.dart';
import '../features/catalog/wishlist_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/navigation/main_navigation_frame.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';

// Simple Auth state providers using Riverpod
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final userRoleProvider = FutureProvider<String>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 'customer';

  final res = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
      
  return res?['role'] as String? ?? 'customer';
});

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authStream.value),
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final loggingIn = state.matchedLocation == '/auth';
      final publicRoutes = ['/splash', '/onboarding', '/auth'];

      if (publicRoutes.contains(state.matchedLocation)) {
        return null;
      }

      // 1. If not logged in, redirect to /auth when accessing guarded customer/admin routes
      final guardedRoutes = ['/checkout', '/my-tech', '/admin'];
      final isGuarded = guardedRoutes.any((route) => state.matchedLocation.startsWith(route));
      
      if (user == null && isGuarded) {
        return '/auth';
      }

      // 2. If logged in and going to /auth, redirect back to / (catalog)
      if (user != null && loggingIn) {
        return '/';
      }

      // 3. Admin guard: restrict /admin paths to admin users only
      if (state.matchedLocation.startsWith('/admin')) {
        final role = await ref.read(userRoleProvider.future);
        if (role != 'admin') {
          return '/'; // Send normal user back to catalog home
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationFrame(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/device/:id',
        builder: (context, state) {
          final deviceId = state.pathParameters['id']!;
          return DeviceDetailsScreen(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final cartItems = extra?['cartItems'] as List<CartItem>?;
          final deviceId = extra?['deviceId'] as String?;
          final planMonths = extra?['planMonths'] as int?;
          return CheckoutScreen(
            cartItems: cartItems,
            deviceId: deviceId,
            planMonths: planMonths,
          );
        },
        routes: [
          GoRoute(
            path: 'camera',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final cameraType = extra?['type'] as String? ?? 'front';
              final onCapture = extra?['onCapture'] as void Function(String path)?;
              return CameraKycScreen(cameraType: cameraType, onCapture: onCapture ?? (_) {});
            },
          ),
          GoRoute(
            path: 'bkash-webview',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final redirectUrl = extra?['redirectUrl'] as String? ?? '';
              final rentalId = extra?['rentalId'] as String? ?? '';
              return BkashAgreementWebview(redirectUrl: redirectUrl, rentalId: rentalId);
            },
          ),
          GoRoute(
            path: 'status',
            builder: (context, state) {
              final status = state.uri.queryParameters['status'] ?? 'failed';
              final rentalId = state.uri.queryParameters['rental_id'] ?? '';
              final message = state.uri.queryParameters['message'] ?? '';
              return CheckoutStatusScreen(status: status, rentalId: rentalId, message: message);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/my-tech',
        builder: (context, state) => const MyTechScreen(),
        routes: [
          GoRoute(
            path: 'damage-report',
            builder: (context, state) {
              final rentalId = state.uri.queryParameters['rental_id'] ?? '';
              return DamageReportScreen(rentalId: rentalId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/compare',
        builder: (context, state) => const DeviceComparisonScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessPortalScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});

// Helper class to convert stream to Listenable for GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(AuthState? authState) {
    notifyListeners();
    // Subscribe to auth state updates to trigger routing evaluations
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
