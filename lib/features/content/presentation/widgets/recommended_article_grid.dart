import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/published_articles_repository.dart';
import '../screens/article_detail_screen.dart';

class RecommendedArticles extends StatefulWidget {
  const RecommendedArticles({super.key, this.repository, this.library = false});
  final PublishedArticlesRepository? repository;
  final bool library;
  @override
  State<RecommendedArticles> createState() => _RecommendedArticlesState();
}

class _RecommendedArticlesState extends State<RecommendedArticles> {
  late final _repo = widget.repository ?? PublishedArticlesRepository();
  final _articles = <PublishedArticle>[];
  bool _loading = true, _cached = false;
  int _page = 0, _lastPage = 1;
  String? _error, _opening;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.load(page: more ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        if (!more) _articles.clear();
        _articles.addAll(
          result.articles.where((a) => !_articles.any((b) => b.id == a.id)),
        );
        _page = result.page;
        _lastPage = result.lastPage;
        _cached = result.cached;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Articles could not be loaded. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(PublishedArticle article) async {
    setState(() {
      _opening = article.id;
      _error = null;
    });
    try {
      final full = await _repo.detail(article);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArticleDetailScreen(extra: full.detail),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'This article is unavailable. Reconnect and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_cached)
          Padding(
            padding: EdgeInsets.only(bottom: w.contentGap),
            child: Text(
              'Saved articles · Reconnect for updates',
              style: t.textTheme.bodySmall,
            ),
          ),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: t.colorScheme.error)),
          WellnessAction(
            label: 'Retry articles',
            onPressed: _loading ? null : () => _load(),
          ),
          SizedBox(height: w.contentGap),
        ],
        if (_loading && _articles.isEmpty)
          const Center(child: CircularProgressIndicator()),
        if (!_loading && _error == null && _articles.isEmpty)
          WellnessPanel(
            child: Text(
              'Published articles will appear here when available.',
              style: t.textTheme.bodyMedium,
            ),
          ),
        ArticleRecommendationGrid(
          articles: widget.library ? _articles : _articles.take(4).toList(),
          onOpen: _opening == null ? _open : null,
          opening: _opening,
        ),
        if (_articles.isNotEmpty) ...[
          SizedBox(height: w.sectionSpacing),
          WellnessAction(
            label: widget.library
                ? (_loading
                      ? 'Loading…'
                      : _page < _lastPage
                      ? 'Load more articles'
                      : 'Refresh articles')
                : 'View all articles',
            icon: Icons.arrow_forward_rounded,
            onPressed: _loading
                ? null
                : widget.library
                ? () => _load(more: _page < _lastPage)
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Articles')),
                        body: SingleChildScrollView(
                          padding: EdgeInsets.all(w.page),
                          child: RecommendedArticles(
                            repository: _repo,
                            library: true,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class ArticleRecommendationGrid extends StatelessWidget {
  const ArticleRecommendationGrid({
    super.key,
    required this.articles,
    required this.onOpen,
    this.opening,
  });
  final List<PublishedArticle> articles;
  final ValueChanged<PublishedArticle>? onOpen;
  final String? opening;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final single =
            box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(w.label) > 21;
        final width = single ? box.maxWidth : (box.maxWidth - w.contentGap) / 2;
        if (articles.isEmpty) return const SizedBox.shrink();
        final textHeight = articles
            .map((a) {
              final p = TextPainter(
                text: TextSpan(
                  text: a.title,
                  style: t.textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: width - w.contentGap * 2);
              final h = p.height;
              p.dispose();
              return h;
            })
            .reduce(math.max);
        final height =
            w.floatingSize +
            w.small +
            w.contentGap * 4 +
            textHeight +
            MediaQuery.textScalerOf(context).scale(w.label) * 1.5 +
            w.small;
        return Wrap(
          spacing: w.contentGap,
          runSpacing: w.contentGap,
          children: [
            for (final article in articles)
              SizedBox(
                width: width,
                height: height,
                child: AppPressable(
                  key: ValueKey('article-${article.id}'),
                  label: 'Read ${article.title}',
                  onPressed: onOpen == null ? null : () => onOpen!(article),
                  child: Container(
                    padding: EdgeInsets.all(w.contentGap),
                    decoration: BoxDecoration(
                      color: w.accentPanel(c),
                      borderRadius: BorderRadius.circular(w.tileRadius),
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: w.artworkSurface,
                            borderRadius: BorderRadius.circular(w.small),
                          ),
                          child: Image.asset(
                            article.artwork,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        SizedBox(height: w.contentGap),
                        Text(
                          article.title,
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: c.onSurface,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(height: w.contentGap),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                opening == article.id
                                    ? 'Opening…'
                                    : 'Read article',
                                style: t.textTheme.bodySmall,
                              ),
                            ),
                            const Icon(Icons.arrow_outward_rounded, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
