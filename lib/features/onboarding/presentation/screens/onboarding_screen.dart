import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final List<OnboardingData> _pages = OnboardingData.pages;

  late final AnimationController _textRevealController;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _bodyOpacity;
  late final Animation<Offset> _bodyOffset;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _titleOpacity = CurvedAnimation(
      parent: _textRevealController,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(_titleOpacity);

    _bodyOpacity = CurvedAnimation(
      parent: _textRevealController,
      curve: const Interval(0.32, 1, curve: Curves.easeOutCubic),
    );
    _bodyOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(_bodyOpacity);

    _textRevealController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textRevealController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage == _pages.length - 1) {
      context.go(AppRouter.welcome);
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLastPage() async {
    if (_currentPage == _pages.length - 1) return;

    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _textRevealController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skipToLastPage,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        final pageValue = _pageController.hasClients
                            ? (_pageController.page ?? _currentPage.toDouble())
                            : _currentPage.toDouble();
                        final delta = pageValue - index;

                        return _OnboardingSlide(
                          page: _pages[index],
                          pageIndex: index,
                          pageDelta: delta,
                          imageHeight: size.height * 0.38,
                          titleOpacity: _titleOpacity,
                          titleOffset: _titleOffset,
                          bodyOpacity: _bodyOpacity,
                          bodyOffset: _bodyOffset,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _MorphingPillIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
              ),
              const SizedBox(height: 34),
              AppButton(
                text: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                trailingIcon: _currentPage == _pages.length - 1
                    ? null
                    : Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final OnboardingData page;
  final int pageIndex;
  final double pageDelta;
  final double imageHeight;
  final Animation<double> titleOpacity;
  final Animation<Offset> titleOffset;
  final Animation<double> bodyOpacity;
  final Animation<Offset> bodyOffset;

  const _OnboardingSlide({
    required this.page,
    required this.pageIndex,
    required this.pageDelta,
    required this.imageHeight,
    required this.titleOpacity,
    required this.titleOffset,
    required this.bodyOpacity,
    required this.bodyOffset,
  });

  @override
  Widget build(BuildContext context) {
    final parallaxX = pageDelta * -56;
    final imageX = pageDelta * -39.2;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(parallaxX, 0),
                child: _SlideBackdrop(index: pageIndex),
              ),
              Transform.translate(
                offset: Offset(imageX, 0),
                child: page.pngAsset.image(
                  height: imageHeight.clamp(250, 330),
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        FadeTransition(
          opacity: titleOpacity,
          child: SlideTransition(
            position: titleOffset,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: bodyOpacity,
          child: SlideTransition(
            position: bodyOffset,
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideBackdrop extends StatelessWidget {
  final int index;

  const _SlideBackdrop({required this.index});

  @override
  Widget build(BuildContext context) {
    final palettes = [
      (
        const Color(0xFFE7F1FF),
        const Color(0xFFFFF1D8),
        const Color(0xFFDDFBE8),
      ),
      (
        const Color(0xFFFFECE9),
        const Color(0xFFE9F4FF),
        const Color(0xFFFFF7CF),
      ),
      (
        const Color(0xFFEAF8F0),
        const Color(0xFFFFEFE2),
        const Color(0xFFEAF1FF),
      ),
    ];
    final palette = palettes[index % palettes.length];

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 52,
            left: 18,
            child: _SoftShape(
              width: 132,
              height: 118,
              color: palette.$1,
              angle: -0.18,
            ),
          ),
          Positioned(
            top: 88,
            right: 2,
            child: _SoftShape(
              width: 116,
              height: 150,
              color: palette.$2,
              angle: 0.22,
            ),
          ),
          Positioned(
            bottom: 34,
            left: 34,
            child: _SoftShape(
              width: 118,
              height: 86,
              color: palette.$3,
              angle: 0.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double angle;

  const _SoftShape({
    required this.width,
    required this.height,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }
}

class _MorphingPillIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _MorphingPillIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = currentPage == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isActive ? 78 : 38,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFCDDFF7),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
