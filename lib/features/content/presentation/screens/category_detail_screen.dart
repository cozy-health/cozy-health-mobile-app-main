import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/article_card_compact.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> extra;

  const CategoryDetailScreen({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final title = extra['title'] as String? ?? 'Category';
    final id = extra['id'] as String? ?? '';
    
    // Mock data based on id
    String description = 'Understanding and managing your feelings.';
    List<Map<String, String>> articles = [];
    
    if (id == 'anxiety') {
      description = 'Understanding and managing anxious moments.';
      articles = [
        {'title': 'What Anxiety Actually Is', 'readTime': '5 min read'},
        {'title': 'The 5-4-3-2-1 Grounding Technique', 'readTime': '4 min read'},
        {'title': 'When Worry Becomes a Loop', 'readTime': '6 min read'},
        {'title': 'Anxiety in the Body', 'readTime': '3 min read'},
        {'title': 'Talking to Someone About Your Anxiety', 'readTime': '5 min read'},
      ];
    } else if (id == 'sleep') {
      description = 'Rest and recovery.';
      articles = [
        {'title': 'Why Sleep Affects Mood', 'readTime': '4 min read'},
        {'title': 'A Gentle Wind-Down Routine', 'readTime': '6 min read'},
      ];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.heading1.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              
              if (articles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No articles yet. Check back soon.',
                      style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return ArticleCardCompact(
                      title: article['title']!,
                      metadata: article['readTime']!,
                      onTap: () {
                        context.push(AppRouter.articleDetail, extra: {
                          'title': article['title'],
                          'category': title,
                          'readTime': article['readTime'],
                        });
                      },
                    );
                  },
                ),
                
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
