import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class DailyAffirmationScreen extends StatefulWidget {
  const DailyAffirmationScreen({super.key});

  @override
  State<DailyAffirmationScreen> createState() => _DailyAffirmationScreenState();
}

class _DailyAffirmationScreenState extends State<DailyAffirmationScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _affirmations = [
    {
      'icon': '💛',
      'title': 'You\'re doing great.',
      'subtitle': 'Small steps count.',
    },
    {
      'icon': '🌿',
      'title': 'Feelings are visitors.',
      'subtitle': 'Let them come and go.',
    },
    {
      'icon': '🌙',
      'title': 'It\'s okay to rest.',
      'subtitle': 'You are allowed to take up space.',
    },
  ];

  void _copyToClipboard() {
    final affirmation = _affirmations[_currentIndex];
    final text = '${affirmation['title']} ${affirmation['subtitle']}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affirmation copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _affirmations.length,
                itemBuilder: (context, index) {
                  final affirmation = _affirmations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            affirmation['icon']!,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          affirmation['title']!,
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 28,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          affirmation['subtitle']!,
                          style: AppTextStyles.body1.copyWith(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _affirmations.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: 'Copy affirmation',
                    isOutlined: true,
                    onPressed: _copyToClipboard,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Read related articles',
                    onPressed: () {
                      context.push(AppRouter.categoryDetail, extra: {
                        'id': 'self-compassion',
                        'title': 'Self-compassion',
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
