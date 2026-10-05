import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';

import '../../data/chat_repository.dart';
import '../../models/chat.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_settings_view.dart';
import '../widgets/chat_shared_widgets.dart';
import '../widgets/conversation_list_view.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final CrisisDetector _crisisDetector = const CrisisDetector();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _entranceController;

  final ChatRepository _repo = ChatRepository();
  StreamSubscription<List<ChatMessage>>? _messageSub;
  StreamSubscription<List<Conversation>>? _historySub;
  List<Conversation> _history = [];

  late Conversation _activeConversation;
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _showNudge = false;
  String _streamingText = '';
  Timer? _streamTimer;
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    _startNewConversation();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).disableAnimations) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
      _controller.addListener(() => setState(() {}));
    });
    _startNudgeTimer();
  }

  void _startNewConversation() {
    _activeConversation = Conversation(
      id: 'active-${DateTime.now().microsecondsSinceEpoch}',
      title: 'New conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );
    _listenToMessages();
    _historySub?.cancel();
    _historySub = _repo
        .watchConversations()
        .map(
          (convs) => convs
              .map(
                (c) => Conversation(
                  id: c.id,
                  title: c.title ?? 'New conversation',
                  createdAt: c.createdAt,
                  updatedAt: c.updatedAt,
                  messages: [],
                ),
              )
              .toList(),
        )
        .listen((convs) {
          if (mounted) setState(() => _history = convs);
        });
  }

  void _listenToMessages() {
    _messageSub?.cancel();
    _messageSub = _repo
        .watchMessages(_activeConversation.id)
        .map(
          (msgs) => msgs
              .map(
                (m) => ChatMessage(
                  id: m.id,
                  role: m.role == 'assistant'
                      ? ChatRole.assistant
                      : ChatRole.user,
                  text: m.content,
                  createdAt: m.createdAt,
                ),
              )
              .toList(),
        )
        .listen((msgs) {
          if (!mounted) return;
          setState(() {
            _activeConversation.messages.clear();
            _activeConversation.messages.addAll(msgs);
          });
          _scrollToBottom();
        });
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _messageSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _entranceController.dispose();
    _streamTimer?.cancel();
    _nudgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _activeConversation.messages.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ChatTopBar(onMenu: _showMainMenu),
            Expanded(
              child: hasMessages ? _activeConversationView() : _chatHomeView(),
            ),
            if (hasMessages && _showNudge && _controller.text.trim().isEmpty)
              InlineSuggestions(onPick: _setPrompt),
            ChatInputBar(
              controller: _controller,
              sending: _isTyping || _isStreaming,
              onMic: () =>
                  Navigator.of(context).pushNamed(AppRouter.voiceRecording),
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatHomeView() {
    const prompts = [
      "I'm feeling anxious",
      'I need to vent',
      'Help me reflect',
      'I just want to talk',
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        48,
        24,
        AppScaffoldPadding.tabScrollBottom(context).bottom,
      ),
      children: [
        AnimatedIn(
          controller: _entranceController,
          interval: const Interval(0, .45, curve: Curves.easeOutCubic),
          child: const CozyCharacter(size: 120),
        ),
        const SizedBox(height: 32),
        AnimatedIn(
          controller: _entranceController,
          interval: const Interval(.2, .62, curve: Curves.easeOutCubic),
          yOffset: 12,
          child: Text(
            'Hi Sarah.',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedIn(
          controller: _entranceController,
          interval: const Interval(.32, .72, curve: Curves.easeOutCubic),
          child: Text(
            "I'm here to listen.\nWhat's on your mind?",
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 48),
        for (var i = 0; i < prompts.length; i++) ...[
          AnimatedIn(
            controller: _entranceController,
            interval: Interval(.48 + (i * .08), 1, curve: Curves.easeOutCubic),
            yOffset: 12,
            child: PromptButton(
              text: prompts[i],
              onTap: () => _setPrompt(prompts[i]),
            ),
          ),
          if (i != prompts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _activeConversationView() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        AppScaffoldPadding.tabScrollBottom(context).bottom,
      ),
      itemCount:
          _activeConversation.messages.length +
          (_isTyping || _isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _activeConversation.messages.length) {
          if (_isStreaming) {
            return MessageBubble(
              message: ChatMessage(
                id: 'streaming',
                role: ChatRole.assistant,
                text: '$_streamingText▍',
                createdAt: DateTime.now(),
              ),
              onLongPress: null,
            );
          }
          return const TypingIndicatorBubble();
        }

        final message = _activeConversation.messages[index];
        return Padding(
          padding: EdgeInsets.only(bottom: _messageBottomSpacing(index)),
          child: MessageBubble(
            message: message,
            onLongPress: () => _showMessageActions(message),
            onRetry: message.status == MessageStatus.failed
                ? () => _retryMessage(message)
                : null,
          ),
        );
      },
    );
  }

  double _messageBottomSpacing(int index) {
    if (index >= _activeConversation.messages.length - 1) return 12;
    final current = _activeConversation.messages[index];
    final next = _activeConversation.messages[index + 1];
    return current.role == next.role ? 8 : 16;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping || _isStreaming) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    _showNudge = false;
    _nudgeTimer?.cancel();

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    final signal = _crisisDetector.analyze(text);
    final shouldShowCrisis = _crisisDetector.canTrigger('chat', signal);

    if (_activeConversation.messages.isEmpty) {
      _activeConversation.title = _titleFrom(text);
      _repo.saveConversation(_activeConversation.toChatConversation());
    }

    _repo.saveMessage(userMessage.toCoreMessage(_activeConversation.id));

    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isStreaming = true;
        _streamingText = '';
      });
      _streamAssistantReply(
        _replyFor(text, shouldShowCrisis),
        signal,
        shouldShowCrisis,
      );
    });
  }

  void _streamAssistantReply(
    String reply,
    CrisisSignal signal,
    bool shouldShowCrisis,
  ) {
    final words = reply.split(' ');
    var index = 0;
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index >= words.length) {
        timer.cancel();
        final assistantMessage = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: ChatRole.assistant,
          text: reply,
          createdAt: DateTime.now(),
        );
        _repo.saveMessage(
          assistantMessage.toCoreMessage(_activeConversation.id),
        );

        setState(() {
          _isStreaming = false;
          _streamingText = '';
        });
        _scrollToBottom();
        _startNudgeTimer();

        if (shouldShowCrisis) {
          _crisisDetector.markTriggered('chat');
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) showCrisisSupportOverlay(context, signal: signal);
          });
        }
        return;
      }
      setState(() {
        _streamingText = [
          if (_streamingText.isNotEmpty) _streamingText,
          words[index],
        ].join(_streamingText.isEmpty ? '' : ' ');
      });
      index++;
      _scrollToBottom();
    });
  }

  String _replyFor(String text, bool crisis) {
    final lower = text.toLowerCase();
    if (crisis) {
      return "That sounds really hard. I'm here with you. You do not have to handle this alone.";
    }
    if (lower.contains('anxious') || lower.contains('work')) {
      return "That sounds heavy. What's coming up at work that's weighing on you?";
    }
    if (lower.contains('vent')) {
      return "You can put it here. I'll listen first, and we can sort through it slowly after.";
    }
    if (lower.contains('reflect')) {
      return "Let's start with what feels most present right now. What keeps coming back to your mind?";
    }
    if (lower.contains('thank')) {
      return "I'm glad I could be here.";
    }
    return "Thank you for sharing that. What's the part of it that feels heaviest right now?";
  }

  void _retryMessage(ChatMessage message) {
    setState(() => message.status = MessageStatus.sent);
    _repo.updateMessageStatus(message.id, MessageStatus.sent.name);
    // Ideally, we would also trigger a resend to the AI backend here
  }

  void _setPrompt(String prompt) {
    setState(() {
      _controller.text = prompt;
      _controller.selection = TextSelection.collapsed(offset: prompt.length);
      _showNudge = false;
    });
  }

  void _startNudgeTimer() {
    _nudgeTimer?.cancel();
    if (_activeConversation.messages.isEmpty) return;
    _nudgeTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _controller.text.trim().isEmpty) {
        setState(() => _showNudge = true);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showMainMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuSheet(
        children: [
          SheetTile(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: () {
              Navigator.pop(context);
              _openHistory();
            },
          ),
          SheetTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openHistory() async {
    final conversation = await Navigator.of(context).push<Conversation>(
      MaterialPageRoute(
        builder: (_) => ConversationHistoryScreen(
          conversations: [
            _activeConversation,
            ..._history,
          ].where((conversation) => conversation.messages.isNotEmpty).toList(),
        ),
      ),
    );
    if (conversation != null) {
      setState(() {
        _activeConversation = conversation.copy();
      });
      _listenToMessages();
    }
  }

  void _showMessageActions(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuSheet(
        children: [
          SheetTile(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.text));
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
          if (message.role == ChatRole.assistant ||
              message.status == MessageStatus.failed)
            SheetTile(
              icon: Icons.refresh_rounded,
              label: 'Retry',
              onTap: () {
                Navigator.pop(context);
                _retryAssistantResponse(message);
              },
            ),
          SheetTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            danger: true,
            onTap: () {
              Navigator.pop(context);
              setState(() => _activeConversation.messages.remove(message));
            },
          ),
        ],
      ),
    );
  }

  void _retryAssistantResponse(ChatMessage message) {
    final index = _activeConversation.messages.indexOf(message);
    final previousUser = _activeConversation.messages
        .take(index < 0 ? _activeConversation.messages.length : index)
        .toList()
        .reversed
        .where((item) => item.role == ChatRole.user)
        .firstOrNull;
    if (previousUser == null) return;
    setState(() {
      _activeConversation.messages.removeWhere((item) => item.id == message.id);
      _isTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _streamAssistantReply(
        _replyFor(previousUser.text, false),
        CrisisSignal.none,
        false,
      );
    });
  }

  String _titleFrom(String text) {
    final clean = text.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (clean.isEmpty) return 'New conversation';
    final words = clean.split(RegExp(r'\s+')).take(5).join(' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
