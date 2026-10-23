import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/theme/cozy_colors.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
// TODO: wire to backend when endpoint exists
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/local_db_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../community_theme.dart';
import '../widgets/visibility_sheet.dart';
import '../community_local_state.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/api/api_client.dart';
import '../../data/community_repository.dart';

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
  Uint8List? _image;
  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length >= 5 * 1024 * 1024) {
        AppSnackbar.show(
          context,
          AppSnackbar.error('Choose an image smaller than 5 MB.'),
        );
        return;
      }
      setState(() => _image = bytes);
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            'We could not open that image. Please try another photo.',
          ),
        );
      }
    }
  }

  final int _maxLength = 500;

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
    final length = _textController.text.trim().length;
    return length > 0 && length <= _maxLength && !_isPublishing;
  }

  void _handlePost() async {
    if (!_canPost) return;
    final owner = LocalDbService().activeUserId;
    if (!DemoMode.instance.enabled && _visibility == PostVisibility.followers) {
      AppSnackbar.show(
        context,
        AppSnackbar.info(
          'Followers-only posting is not available. Choose Public or Anonymous.',
        ),
      );
      return;
    }
    setState(() => _isPublishing = true);
    try {
      if (DemoMode.instance.enabled) {
        CommunityLocalState.instance.publish(
          content: _textController.text.trim(),
          topic: _selectedTopic == 'Topic (optional)' ? '' : _selectedTopic,
          visibility: _visibility.name,
        );
      } else {
        final response = await ApiClient().get('/config', withAuth: false);
        final document =
            response.data['consent']?['documents']?['ugc_guidelines'];
        if (document is! Map ||
            document['published'] != true ||
            '${document['content'] ?? ''}'.trim().isEmpty) {
          throw StateError('Guidelines are not available');
        }
        if (!mounted || owner != LocalDbService().activeUserId) return;
        final yes = await showWellnessSheet<bool>(
          context: context,
          builder: (context) => WellnessSheet(
            title: '${document['title']}',
            children: [
              Text('${document['content']}'),
              SizedBox(height: context.cozyColors.wellness.gap),
              WellnessAction(
                label: 'Agree and post',
                filled: true,
                onPressed: () => Navigator.pop(context, true),
              ),
              SizedBox(height: context.cozyColors.wellness.small),
              WellnessAction(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        );
        if (yes != true || !mounted || owner != LocalDbService().activeUserId) {
          return;
        }
        final payload = <String, dynamic>{
          'body': _textController.text.trim(),
          'is_anonymous': _visibility == PostVisibility.anonymous,
          'mood': _selectedTopic == 'Topic (optional)' ? null : _selectedTopic,
          'guidelines_version': document['version'],
          'guidelines_accepted': _image == null ? true : '1',
          if (_image != null)
            'image': MultipartFile.fromBytes(
              _image!,
              filename: 'community.jpg',
            ),
        };
        if (_image != null) {
          payload['is_anonymous'] = _visibility == PostVisibility.anonymous
              ? '1'
              : '0';
        }
        final saved = await ApiClient().post(
          '/community/posts',
          data: _image == null ? payload : FormData.fromMap(payload),
        );
        if (!mounted || owner != LocalDbService().activeUserId) return;
        CommunityLocalState.instance.ingestPost(
          CommunityRepository.post(saved.data['data'] as Map),
        );
        if (!mounted) return;
        AppSnackbar.show(
          context,
          AppSnackbar.info(
            saved.data['data']['status'] == 'pending'
                ? 'Your post was saved for review.'
                : 'Your post was published.',
          ),
        );
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            'Could not publish. Community or its approved guidelines may be unavailable. Your draft is still here.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  String get _authorName {
    final name = LocalDbService.instance.getUserProfile()?.name.trim() ?? '';
    return name.isEmpty ? 'you' : name;
  }

  String get _authorInitial => _authorName.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final isOverLimit = textLength >= _maxLength;
    final isWarning = textLength >= _maxLength - 200;

    return Scaffold(
      backgroundColor: context.communityBackground,
      appBar: AppBar(
        title: const Text('Create Post'),
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
        child: ListView(
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
                        _visibility == PostVisibility.anonymous
                            ? '?'
                            : _authorInitial,
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
                                : '@$_authorName',
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
                              Flexible(
                                child: Text(
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

            // Text area shares the scroll view with its accessories, including above the keyboard.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _textController,
                minLines: 5,
                maxLines: null,
                maxLength: _maxLength,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                ),
                style: context.communityBody1.copyWith(height: 1.5),
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
                        Expanded(
                          child: Text(
                            _selectedTopic,
                            style: context.communityBody1,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _isPublishing ? null : _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_image == null ? 'Add image' : 'Change image'),
                  ),
                  if (_image != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _image!,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      'Image posts are reviewed before they appear in the community.',
                    ),
                    TextButton(
                      onPressed: _isPublishing
                          ? null
                          : () => setState(() => _image = null),
                      child: const Text('Remove image'),
                    ),
                  ],
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
