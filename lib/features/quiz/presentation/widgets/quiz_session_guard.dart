import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/storage/token_storage.dart';

/// Results and invitations remain bound to the account that opened the screen.
mixin QuizSessionGuard<T extends StatefulWidget> on State<T> {
  final String? quizOwner = LocalDbService().activeUserId;
  bool _ended = false;
  StreamSubscription<void>? _clearing;
  StreamSubscription<dynamic>? _accounts;
  bool get isQuizSessionActive =>
      !_ended && quizOwner == LocalDbService().activeUserId;
  void onQuizSessionEnded() {}
  void _end() {
    if (!mounted || _ended) return;
    setState(() {
      _ended = true;
      onQuizSessionEnded();
    });
  }

  @override
  void initState() {
    super.initState();
    _clearing = TokenStorage.sessionClearing.listen((_) => _end());
    _accounts = LocalDbService().watchQuizAttempts().listen((_) {
      if (quizOwner != LocalDbService().activeUserId) _end();
    });
  }

  @override
  void dispose() {
    _clearing?.cancel();
    _accounts?.cancel();
    super.dispose();
  }
}
