import 'package:flutter/material.dart';
import 'post_detail_screen.dart';

/// Reuses the same thread, composer and reply handling as the post detail.
class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key, required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) =>
      PostDetailScreen(post: post, commentsOnly: true);
}
