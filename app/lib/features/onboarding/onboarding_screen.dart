import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../core/design/app_spacing.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/onboarding/onboarding_prefs.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.devices_rounded,
      title: 'Rent premium tech',
      description:
          'Phones, laptops, cameras and consoles — curated for Bangladesh, delivered to your door.',
      accent: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: 'Flexible monthly plans',
      description:
          'Choose 1, 3, 6 or 12-month rentals. Upgrade, swap, or return when your needs change.',
      accent: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.verified_user_rounded,
      title: 'Secure e-KYC checkout',
      description:
          'Fast identity verification and bKash payments so you can start renting in minutes.',
      accent: AppColors.tertiary,
    ),
  ];

  Future<void> _finish() async {
    await markOnboardingComplete();
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: page.accent.withValues(alpha: 0.14),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(36),
                            ),
                          ),
                          child: Icon(page.icon, size: 56, color: page.accent),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                0,
                AppSpacing.pageHorizontal,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  GcCarouselIndicator(count: _pages.length, activeIndex: _currentPage),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ButtonM3E(
                      onPressed: _next,
                      style: ButtonM3EStyle.filled,
                      size: ButtonM3ESize.lg,
                      shape: ButtonM3EShape.round,
                      label: Text(isLast ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
}
