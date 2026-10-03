import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/reading_progress_bar.dart';
import '../widgets/inline_cta.dart';
import '../widgets/save_button.dart';
import '../widgets/article_card_compact.dart';
import '../../data/content_repository.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const ArticleDetailScreen({super.key, required this.extra});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSaved = false;
  late final String _articleId;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _articleId = widget.extra['id'] as String? ?? 'mock-id';
    _title = widget.extra['title'] as String? ?? 'Article';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSave() async {
    final articleData = {
      'id': _articleId,
      'title': _title,
      'excerpt': 'Anxiety isn\'t weakness. It\'s your nervous system doing its job...',
    };
    await ContentRepository().toggleSave(articleData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Removed from library' : 'Saved to your library'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.extra['title'] as String? ?? 'Article';
    final category = widget.extra['category'] as String? ?? 'Anxiety';
    final readTime = widget.extra['readTime'] as String? ?? '5 min read';
    
    // For body text, using a serif fallback
    const serifStyle = TextStyle(
      fontFamily: 'Georgia', // standard serif
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: AppColors.text,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ReadingProgressBar(scrollController: _scrollController),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: () => context.pop(),
              ),
              actions: [
                StreamBuilder<bool>(
                  stream: ContentRepository().isSaved(_articleId),
                  builder: (context, snapshot) {
                    _isSaved = snapshot.data ?? false;
                    return SaveButton(
                      isSaved: _isSaved,
                      onToggle: _toggleSave,
                      isIconOnly: true,
                    );
                  }
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      title,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      '$readTime · Sarah Chen\nOctober 1, 2026',
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Anxiety isn\'t weakness. It\'s your nervous system doing its job — just a little too well.\n\nWhen you feel anxious, your body is trying to protect you from something it thinks is a threat. Sometimes that threat is real. Sometimes it isn\'t. Either way, the feeling is valid.',
                      style: serifStyle,
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'What it feels like',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Anxiety can show up as:', style: serifStyle),
                    const SizedBox(height: 8),
                    _buildBullet('Racing thoughts', serifStyle),
                    _buildBullet('Tight chest or short breath', serifStyle),
                    _buildBullet('Restlessness', serifStyle),
                    _buildBullet('Trouble sleeping', serifStyle),
                    _buildBullet('A sense of dread', serifStyle),
                    const SizedBox(height: 32),
                    
                    Text(
                      'What helps',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 16),
                    const Text('You don\'t have to fix it. You just have to be with it — gently.', style: serifStyle),
                    const SizedBox(height: 24),
                    
                    InlineCTA(
                      text: 'Try a breathing exercise',
                      onTap: () => context.push(AppRouter.breathing), // From crisis hub/tools
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Remember that feelings are visitors. They don\'t stay forever, even when it feels like they might.', style: serifStyle),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Take care of yourself.',
                      style: AppTextStyles.body1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    StreamBuilder<bool>(
                      stream: ContentRepository().isSaved(_articleId),
                      builder: (context, snapshot) {
                        return SaveButton(
                          isSaved: snapshot.data ?? false,
                          onToggle: _toggleSave,
                        );
                      }
                    ),
                    const SizedBox(height: 48),
                    
                    Text('More in $category', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                    const SizedBox(height: 16),
                    
                    ArticleCardCompact(
                      title: 'The 5-4-3-2-1 Grounding Technique',
                      metadata: '4 min read',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    ArticleCardCompact(
                      title: 'Anxiety in the Body',
                      metadata: '3 min read',
                      onTap: () {},
                    ),
                    
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
