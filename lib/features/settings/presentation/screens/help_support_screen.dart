import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I log my mood?',
      'a': 'Tap \'Log your mood\' on the Home screen. You can select how you\'re feeling, add details, and save. Takes about 30 seconds.',
    },
    {
      'q': 'Is my data private?',
      'a': 'Yes. Your journal and mood entries are private to you. We never share them, and you can export or delete everything anytime in Settings.',
    },
    {
      'q': 'How do I cancel?',
      'a': 'Go to Settings → Subscription → Cancel subscription. No phone calls, no hoops.',
    },
    {
      'q': 'Can I export my data?',
      'a': 'Yes. Settings → Data → Export My Data. We\'ll email you a copy in PDF or JSON.',
    },
    {
      'q': 'Is Cozy a therapist?',
      'a': 'No. Cozy is a warm companion for reflection — not a replacement for professional care. If you need human support, we\'ll help you find it.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Help & support',
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
              ),
              const SizedBox(height: 24),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search help...',
                    hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textSubtle),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Common questions',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: _faqs.where((faq) => 
                    faq['q']!.toLowerCase().contains(_searchController.text.toLowerCase())
                  ).map((faq) {
                    final isLast = faq == _faqs.last;
                    return Column(
                      children: [
                        _FaqAccordion(question: faq['q']!, answer: faq['a']!),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Still need help?',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _ContactRow(
                      icon: Icons.email_outlined,
                      label: 'Email support',
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _ContactRow(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat with us',
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _ContactRow(
                      icon: Icons.bug_report_outlined,
                      label: 'Report a problem',
                      onTap: () => context.push(AppRouter.reportProblem),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqAccordion extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqAccordion({required this.question, required this.answer});

  @override
  State<_FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<_FaqAccordion> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedRotation(
                    turns: _expanded ? 0.125 : 0, // 45 degrees
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.add, color: AppColors.textMuted),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0, width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.answer,
                    style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 400),
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.text, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}