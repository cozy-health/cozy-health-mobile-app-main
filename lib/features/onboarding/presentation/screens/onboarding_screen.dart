import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/page_indicator.dart';
import '../../data/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingData> _pages = OnboardingData.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRouter.login);
    }
  }

  void _skipOnboarding() {
    context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // PNG Illustration
                        page.pngAsset.image(
                          height: 320,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 56),

                        // Title
                        Text(
                          page.title,
                          style: AppTextStyles.heading1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page.description,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicator
                  PageIndicator(
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                  ),
                  const SizedBox(height: 48),

                  // Main button (Next/Get Started)
                  AppButton(
                    text: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _nextPage,
                    isOutlined: false,
                    trailingIcon: _currentPage == _pages.length - 1
                        ? null
                        : Icons.arrow_forward,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
