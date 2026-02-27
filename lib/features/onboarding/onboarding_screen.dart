import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persistence/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.wifi_tethering,
      title: 'Host or Join',
      body:
          'One player hosts — others scan and connect over Bluetooth. No internet needed. Works for 4 to 6 players at the same table.',
      color: AppTheme.accent,
    ),
    _OnboardingSlide(
      icon: Icons.favorite,
      title: 'Track Your Life',
      body:
          'Tap +/- to change life. Hold for +5/-5 jumps. Swipe up/down for quick changes. Long-press to enter an exact number. Tap the undo button to fix mistakes.',
      color: AppTheme.accent,
    ),
    _OnboardingSlide(
      icon: Icons.timer_outlined,
      title: 'Phase Bar & Turns',
      body:
          'The phase bar shows every step of the turn — from Untap to Cleanup. Hold Priority to pause progression. Hit Timeout to pause the whole game.',
      color: Color(0xFF81C784),
    ),
    _OnboardingSlide(
      icon: Icons.shield_outlined,
      title: 'Commander & Counters',
      body:
          'Track commander damage per opponent — 21 kills. Track poison (10 kills), energy, experience, and rad counters. Use Proliferate to add 1 to all at once.',
      color: Color(0xFFFFD54F),
    ),
    _OnboardingSlide(
      icon: Icons.handshake_outlined,
      title: 'Alliances & Politics',
      body:
          'Propose secret alliances with other players. They expire automatically or break when you attack each other. Track the Monarch and Initiative with a single tap.',
      color: Color(0xFFCE93D8),
    ),
  ];

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).markOnboardingCompleted();
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? _slides[i].color
                        : AppTheme.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? 'Enter the Battlefield'
                        : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.color.withValues(alpha: 0.25),
                  slide.color.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.color.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 52, color: slide.color),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            slide.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
