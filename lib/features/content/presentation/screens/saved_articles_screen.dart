import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/saved_article.dart';
import '../../data/content_repository.dart';
import '../widgets/article_card_compact.dart';

class SavedArticlesScreen extends StatefulWidget {
  const SavedArticlesScreen({super.key});

  @override
  State<SavedArticlesScreen> createState() => _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends State<SavedArticlesScreen> {
  void _removeArticle(SavedArticle article) async {
    await ContentRepository().toggleSave({'id': article.articleId});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from library'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Saved', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<SavedArticle>>(
          stream: ContentRepository().watchSavedArticles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final articles = snapshot.data ?? [];
            if (articles.isEmpty) return _buildEmptyState();
            return _buildList(articles);
          }
        ),
      ),
    );
  }

  Widget _buildList(List<SavedArticle> articles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saved articles',
            style: AppTextStyles.heading1.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return ArticleCardCompact(
                title: article.title,
                metadata: 'Saved for later', // Can format based on actual data
                onTap: () {
                  context.push(AppRouter.articleDetail, extra: {
                    'id': article.articleId,
                    'title': article.title,
                  });
                },
                trailing: IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSubtle),
                  onPressed: () => _removeArticle(article),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: const Text('🔖', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved articles yet.',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any article to save it for later.',
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
