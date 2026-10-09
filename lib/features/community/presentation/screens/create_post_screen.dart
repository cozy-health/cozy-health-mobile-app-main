// TODO: wire to backend when endpoint exists
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../community_theme.dart';
import '../widgets/visibility_sheet.dart';
import '../community_local_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  PostVisibility _visibility = PostVisibility.public;
  String _selectedTopic = 'Topic (optional)';
  bool _isPublishing = false;

  final int _maxLength = 2000;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canPost {
    final length = _textController.text.length;
    return length > 0 && length <= _maxLength && !_isPublishing;
  }

  void _handlePost() async {
    setState(() {
      _isPublishing = true;
    });

    // Mock network request
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check for mock keywords
    if (_textController.text.toLowerCase().contains('harm')) {
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text(
            'Your post is being reviewed. It may take a moment to appear.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      CommunityLocalState.instance.publish(
        content: _textController.text.trim(),
        topic: _selectedTopic == 'Topic (optional)' ? '' : _selectedTopic,
        visibility: _visibility.name,
      );
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text('Post added.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final isOverLimit = textLength >= _maxLength;
    final isWarning = textLength >= _maxLength - 200;

    return Scaffold(
      backgroundColor: context.communityBackground,
      appBar: AppBar(
        backgroundColor: context.communityBackground,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: context.communityBody1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        leadingWidth: 80,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _canPost ? _handlePost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                disabledBackgroundColor: context.communityBorder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Post',
                      style: context.communityBody2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Author Row
            GestureDetector(
              onTap: () {
                VisibilitySheet.show(
                  context,
                  currentVisibility: _visibility,
                  onSelect: (v) {
                    setState(() {
                      _visibility = v;
                    });
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _visibility == PostVisibility.anonymous
                            ? context.communityBorder
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _visibility == PostVisibility.anonymous ? '?' : 'S',
                        style: context.communityBody1.copyWith(
                          color: _visibility == PostVisibility.anonymous
                              ? context.communityMuted
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _visibility == PostVisibility.anonymous
                                ? 'Anonymous'
                                : '@sarahchen',
                            style: context.communityBody1.copyWith(
                              color: context.communityText,
                              fontWeight: FontWeight.w500,
                              fontStyle: _visibility == PostVisibility.anonymous
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _visibility == PostVisibility.public
                                    ? 'Posting publicly'
                                    : _visibility == PostVisibility.followers
                                    ? 'Followers only'
                                    : 'Posting anonymously',
                                style: context.communityBody2.copyWith(
                                  color: context.communityMuted,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: context.communityMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Text Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: context.communityBody1.copyWith(
                      color: context.communityMuted,
                    ),
                    border: InputBorder.none,
                  ),
                  style: context.communityBody1.copyWith(height: 1.5),
                ),
              ),
            ),

            // Bottom Accessories
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Topic Selector
                  GestureDetector(
                    onTap: () async {
                      final topic = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) =>
                              _PostCategoryScreen(selected: _selectedTopic),
                        ),
                      );
                      if (mounted && topic != null) {
                        setState(() => _selectedTopic = topic);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTopic, style: context.communityBody1),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Attach Image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 12),
                          Text('Add image', style: context.communityBody1),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Guidelines Reminder
                  GestureDetector(
                    onTap: () => context.push(AppRouter.communityGuidelines),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Community guidelines\nBe kind. Be honest. Be safe.',
                              style: context.communityBody2.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Character Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$textLength / $_maxLength',
                        style: context.communityBody2.copyWith(
                          color: isOverLimit
                              ? AppColors.danger
                              : isWarning
                              ? AppColors.warning
                              : context.communityMuted,
                          fontWeight: isWarning
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCategoryScreen extends StatelessWidget {
  const _PostCategoryScreen({required this.selected});
  final String selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a category')),
    body: SafeArea(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 110,
          mainAxisSpacing: 12,
          crossAxisSpacing: 20,
        ),
        itemCount: CommunityLocalState.topics.length,
        itemBuilder: (context, index) {
          final topic = CommunityLocalState.topics[index];
          final active = topic == selected;
          return Material(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.communityBorder,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(topic),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(topic, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
