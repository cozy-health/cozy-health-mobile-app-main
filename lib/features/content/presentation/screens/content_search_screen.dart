import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/article_card_compact.dart';

class ContentSearchScreen extends StatefulWidget {
  const ContentSearchScreen({super.key});

  @override
  State<ContentSearchScreen> createState() => _ContentSearchScreenState();
}

class _ContentSearchScreenState extends State<ContentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search library...',
                          hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTextStyles.body1,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: _query.isEmpty ? _buildSuggestions() : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent searches', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('anxiety'),
              _buildChip('sleep'),
              _buildChip('breathe'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Popular', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('self'),
              _buildChip('rest'),
              _buildChip('work'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: AppTextStyles.body1.copyWith(color: AppColors.text)),
      ),
    );
  }

  Widget _buildResults() {
    final queryLower = _query.toLowerCase();
    
    // Very basic mock search
    final allArticles = [
      {'title': 'What Anxiety Actually Is', 'meta': 'Anxiety · 5 min read'},
      {'title': 'The 5-4-3-2-1 Grounding Technique', 'meta': 'Anxiety · 4 min read'},
      {'title': 'Why Sleep Affects Mood', 'meta': 'Sleep · 4 min read'},
      {'title': 'It\'s Okay to Rest', 'meta': 'Self-compassion · 3 min read'},
    ];
    
    final results = allArticles.where((a) => 
      a['title']!.toLowerCase().contains(queryLower) || 
      a['meta']!.toLowerCase().contains(queryLower)
    ).toList();
    
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No articles match "$_query"',
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = results[index];
        return ArticleCardCompact(
          title: article['title']!,
          metadata: article['meta']!,
          onTap: () {
            context.push(AppRouter.articleDetail, extra: {
              'title': article['title'],
            });
          },
        );
      },
    );
  }
}
