import '../../data/content_repository.dart';
import '../../../../core/data/demo_mode.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/article_card_featured.dart';
import '../widgets/category_card.dart';

class ContentHomeScreen extends StatefulWidget {
  const ContentHomeScreen({super.key, this.featuredArticles});

  final List<Map<String, String>>? featuredArticles;

  @override
  State<ContentHomeScreen> createState() => _ContentHomeScreenState();
}

class _ContentHomeScreenState extends State<ContentHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedCategory = "All";
  void _refreshCatalog() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DemoMode.instance.addListener(_refreshCatalog);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    DemoMode.instance.removeListener(_refreshCatalog);
    super.dispose();
  }

  Animation<double> _createAnimation(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allArticles = widget.featuredArticles ?? ContentRepository().catalog;
    final featured = allArticles
        .where(
          (article) =>
              _selectedCategory == 'All' ||
              article['category'] == _selectedCategory,
        )
        .toList();
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

    // Header: 0 - 400ms (0.0 - 0.33)
    final headerAnim = _createAnimation(0.0, 0.33);
    // Search: 100 - 500ms (0.08 - 0.41)
    final searchAnim = _createAnimation(0.08, 0.41);
    // Featured: 200 - 800ms (0.16 - 0.66)
    final featuredAnim = _createAnimation(0.16, 0.66);
    // Categories Header: 400 - 800ms (0.33 - 0.66)
    final catHeaderAnim = _createAnimation(0.33, 0.66);
    // Categories grid: staggered starting at 500ms (0.41 - 0.83)
    final gridAnim = _createAnimation(0.41, 0.83);
    // Saved section: 1000 - 1200ms (0.83 - 1.0)
    final savedAnim = _createAnimation(0.83, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _animatedWidget(
                      reduceMotion: reduceMotion,
                      animation: headerAnim,
                      offset: const Offset(0, 8),
                      child: Text(
                        'Library',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 28,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  _animatedWidget(
                    reduceMotion: reduceMotion,
                    animation: searchAnim,
                    isScale: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.search,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => context.push(AppRouter.contentSearch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in {
                      'All',
                      ...allArticles.map((a) => a['category'] ?? 'Wellbeing'),
                    })
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Featured
              _animatedWidget(
                reduceMotion: reduceMotion,
                animation: featuredAnim,
                offset: const Offset(0, 16),
                child: featured.isEmpty
                    ? const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'New articles coming soon.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: featured
                            .map(
                              (article) => ArticleCardFeatured(
                                title: article['title']!,
                                readTime: article['readTime'] ?? '',
                                category: article['category'],
                                imageAsset: article['image'],
                                preview: article['excerpt'],
                                onTap: () => context.push(
                                  AppRouter.articleDetail,
                                  extra: article,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // Categories Header
              _animatedWidget(
                reduceMotion: reduceMotion,
                animation: catHeaderAnim,
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Categories Grid
              _animatedWidget(
                reduceMotion: reduceMotion,
                animation: gridAnim,
                offset: const Offset(0, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CategoryCard(
                      icon: '💛',
                      title: 'Anxiety',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {'id': 'anxiety', 'title': 'Anxiety'},
                      ),
                    ),
                    CategoryCard(
                      icon: '🌙',
                      title: 'Sleep',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {'id': 'sleep', 'title': 'Sleep'},
                      ),
                    ),
                    CategoryCard(
                      icon: '👥',
                      title: 'Relationships',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {
                          'id': 'relationships',
                          'title': 'Relationships',
                        },
                      ),
                    ),
                    CategoryCard(
                      icon: '🌿',
                      title: 'Self-compassion',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {
                          'id': 'self-compassion',
                          'title': 'Self-compassion',
                        },
                      ),
                    ),
                    CategoryCard(
                      icon: '💼',
                      title: 'Work & Life',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {'id': 'work-life', 'title': 'Work & Life'},
                      ),
                    ),
                    CategoryCard(
                      icon: '🕊',
                      title: 'Grief & Loss',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {'id': 'grief-loss', 'title': 'Grief & Loss'},
                      ),
                    ),
                    CategoryCard(
                      icon: '🧘',
                      title: 'Mindfulness',
                      onTap: () => context.push(
                        AppRouter.categoryDetail,
                        extra: {'id': 'mindfulness', 'title': 'Mindfulness'},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Saved Section
              _animatedWidget(
                reduceMotion: reduceMotion,
                animation: savedAnim,
                child: Text(
                  'Saved',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              _animatedWidget(
                reduceMotion: reduceMotion,
                animation: savedAnim,
                offset: Offset(0, 8),
                child: GestureDetector(
                  onTap: () => context.push(AppRouter.savedArticles),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.bookmark_outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your saved articles',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedWidget({
    required bool reduceMotion,
    required Animation<double> animation,
    required Widget child,
    Offset offset = Offset.zero,
    bool isScale = false,
  }) {
    if (reduceMotion) return child;

    return FadeTransition(
      opacity: animation,
      child: isScale
          ? ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            )
          : offset != Offset.zero
          ? SlideTransition(
              position: Tween<Offset>(
                begin: Offset(offset.dx, offset.dy / 100), // simplified
                end: Offset.zero,
              ).animate(animation),
              child: child,
            )
          : child,
    );
  }
}
