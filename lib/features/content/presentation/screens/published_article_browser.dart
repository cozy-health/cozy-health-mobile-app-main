import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/published_articles_repository.dart';
import 'article_detail_screen.dart';

class PublishedArticleBrowser extends StatefulWidget {
  const PublishedArticleBrowser({
    super.key,
    this.category,
    this.search = false,
    this.repository,
  });
  final String? category;
  final bool search;
  final PublishedArticlesRepository? repository;
  @override
  State<PublishedArticleBrowser> createState() =>
      _PublishedArticleBrowserState();
}

class _PublishedArticleBrowserState extends State<PublishedArticleBrowser> {
  late final _repository = widget.repository ?? PublishedArticlesRepository();
  final _query = TextEditingController();
  final _rows = <PublishedArticle>[];
  List<Map<String, String>> _categories = [];
  late String? _category = widget.category;
  bool _loading = false, _cached = false;
  int _request = 0, _page = 0, _lastPage = 1;
  String? _error;
  StreamSubscription<void>? _sessions;
  @override
  void initState() {
    super.initState();
    _sessions = TokenStorage.sessionChanges.listen((_) {
      _query.clear();
      _load();
    });
    _load();
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request, generation = TokenStorage.generation;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _rows.clear();
        _page = 0;
        _lastPage = 1;
      }
    });
    try {
      final page = await _repository.browse(
        page: more ? _page + 1 : 1,
        query: _query.text.trim(),
        category: _category,
      );
      if (!mounted ||
          request != _request ||
          generation != TokenStorage.generation) {
        return;
      }
      setState(() {
        for (final article in page.articles) {
          if (!_rows.any((row) => row.id == article.id)) _rows.add(article);
        }
        _page = page.page;
        _lastPage = page.lastPage;
        _cached = page.cached;
      });
      if (_categories.isEmpty) {
        try {
          final categories = await _repository.categories();
          if (mounted &&
              request == _request &&
              generation == TokenStorage.generation) {
            setState(() => _categories = categories);
          }
        } catch (_) {
          /* Articles remain readable if category metadata is unavailable. */
        }
      }
    } catch (_) {
      if (mounted &&
          request == _request &&
          generation == TokenStorage.generation) {
        setState(
          () => _error = 'Could not load published articles. Please retry.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sessions?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.search ? 'Search articles' : 'Library'),
        leading: AppPressable(
          label: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRouter.home),
          child: SizedBox(
            width: w.touch,
            height: w.touch,
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.all(w.page),
            children: [
              TextField(
                controller: _query,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Search published articles',
                ),
                onSubmitted: (_) => _load(),
              ),
              WellnessAction(
                key: const ValueKey('article-search'),
                label: 'Search',
                icon: Icons.search,
                onPressed: _loading ? null : () => _load(),
              ),
              SizedBox(height: w.gap),
              Wrap(
                spacing: w.small,
                runSpacing: w.small,
                children: [
                  WellnessAction(
                    label: 'All',
                    selected: _category == null,
                    onPressed: () {
                      setState(() => _category = null);
                      _load();
                    },
                  ),
                  for (final category in _categories)
                    WellnessAction(
                      label: category['name']!,
                      selected: _category == category['slug'],
                      onPressed: () {
                        setState(() => _category = category['slug']);
                        _load();
                      },
                    ),
                ],
              ),
              if (_cached)
                const Text(
                  'Showing saved catalogue information. Reconnect to refresh.',
                ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(_error!),
                WellnessAction(
                  label: 'Retry',
                  onPressed: () => _load(more: _page > 0),
                ),
              ],
              if (!_loading && _error == null && _rows.isEmpty)
                const Text('No published articles match your selection.'),
              for (final article in _rows)
                Padding(
                  padding: EdgeInsets.only(top: w.gap),
                  child: AppPressable(
                    label: 'Read ${article.title}',
                    onPressed: () => context.push(
                      AppRouter.articleDetail,
                      extra: article.toJson(),
                    ),
                    child: WellnessPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (article.excerpt.isNotEmpty) Text(article.excerpt),
                          if (article.category != null) Text(article.category!),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!_loading && _page < _lastPage)
                WellnessAction(
                  label: 'Load more articles',
                  onPressed: () => _load(more: true),
                ),
              SizedBox(height: w.gap),
              WellnessAction(
                label: 'Saved articles',
                icon: Icons.bookmark_outline,
                onPressed: () => context.push(AppRouter.savedArticles),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Always resolves normal-mode links against the published server catalogue.
class PublishedArticleLoader extends StatefulWidget {
  const PublishedArticleLoader({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<PublishedArticleLoader> createState() => _PublishedArticleLoaderState();
}

class _PublishedArticleLoaderState extends State<PublishedArticleLoader> {
  late Future<PublishedArticle> _article = _load();
  Future<PublishedArticle> _load() {
    final id = widget.extra['id'];
    if (id == null || id.toString().trim().isEmpty) {
      return Future.error(StateError('Missing article identity'));
    }
    return PublishedArticlesRepository().detail(
      PublishedArticle.fromJson(widget.extra),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PublishedArticle>(
    future: _article,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ArticleDetailScreen(extra: snapshot.data!.detail);
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Article'),
          leading: AppPressable(
            label: 'Back',
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRouter.contentHome),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This article is unavailable. It may have been unpublished, or your connection may be offline.',
                    ),
                    WellnessAction(
                      label: 'Retry',
                      onPressed: () => setState(() => _article = _load()),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
