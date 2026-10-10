import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
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
      ...widget.extra,
      'excerpt': widget.extra['excerpt'] as String? ?? '',
    };
    await ContentRepository().toggleSave(articleData);

    if (mounted) {
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text(
            _isSaved ? 'Removed from library' : 'Saved to your library',
          ),
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
    final serifStyle = TextStyle(
      fontFamily: 'Georgia', // standard serif
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurface,
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
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Share article',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            "$title\n\n${widget.extra['body'] ?? widget.extra['excerpt'] ?? ''}",
                      ),
                    );
                    if (context.mounted) {
                      AppSnackbar.show(
                        context,
                        AppSnackbar.info('Article copied. Paste it to share.'),
                      );
                    }
                  },
                ),
                StreamBuilder<bool>(
                  stream: ContentRepository().isSaved(_articleId),
                  builder: (context, snapshot) {
                    _isSaved = snapshot.data ?? false;
                    return SaveButton(
                      isSaved: _isSaved,
                      onToggle: _toggleSave,
                      isIconOnly: true,
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.extra['image'] != null) ...[
                      SvgPicture.asset(
                        widget.extra['image'] as String,
                        height: 160,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
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
                    SizedBox(height: 16),

                    Text(
                      title,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      '$readTime · Sarah Chen\nOctober 1, 2026',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24),

                    Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    SizedBox(height: 24),

                    if (widget.extra['body'] != null) ...[
                      SelectableText(
                        widget.extra['body'] as String,
                        style: serifStyle,
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text(
                        'Anxiety isn\'t weakness. It\'s your nervous system doing its job — just a little too well.\n\nWhen you feel anxious, your body is trying to protect you from something it thinks is a threat. Sometimes that threat is real. Sometimes it isn\'t. Either way, the feeling is valid.',
                        style: serifStyle,
                      ),
                      SizedBox(height: 32),

                      Text(
                        'What it feels like',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16),

                      Text('Anxiety can show up as:', style: serifStyle),
                      SizedBox(height: 8),
                      _buildBullet('Racing thoughts', serifStyle),
                      _buildBullet('Tight chest or short breath', serifStyle),
                      _buildBullet('Restlessness', serifStyle),
                      _buildBullet('Trouble sleeping', serifStyle),
                      _buildBullet('A sense of dread', serifStyle),
                      SizedBox(height: 32),

                      Text(
                        'What helps',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'You don\'t have to fix it. You just have to be with it — gently.',
                        style: serifStyle,
                      ),
                      SizedBox(height: 24),

                      InlineCTA(
                        text: 'Try a breathing exercise',
                        onTap: () => context.push(
                          AppRouter.breathing,
                        ), // From crisis hub/tools
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Remember that feelings are visitors. They don\'t stay forever, even when it feels like they might.',
                        style: serifStyle,
                      ),
                      SizedBox(height: 32),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Take care of yourself.',
                        style: AppTextStyles.body1.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                    StreamBuilder<bool>(
                      stream: ContentRepository().isSaved(_articleId),
                      builder: (context, snapshot) {
                        return SaveButton(
                          isSaved: snapshot.data ?? false,
                          onToggle: _toggleSave,
                        );
                      },
                    ),
                    SizedBox(height: 48),

                    Text(
                      'More in $category',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),

                    for (final article
                        in ContentRepository().catalog
                            .where((a) => a['id'] != _articleId)
                            .take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ArticleCardCompact(
                          title: article['title']!,
                          metadata: article['readTime'] ?? '',
                          onTap: () => context.push(
                            AppRouter.articleDetail,
                            extra: article,
                          ),
                        ),
                      ),

                    SizedBox(height: 64),
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
