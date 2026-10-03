import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';
import '../../../../core/repositories/journal_repository.dart';
import '../../../../core/models/journal_entry.dart';
import '../../../../core/services/local_db_service.dart';

enum JournalViewState { populated, empty, loading }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.viewState = JournalViewState.populated});

  final JournalViewState viewState;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  final CrisisDetector _crisisDetector = const CrisisDetector();
  late final AnimationController _entranceController;

  String _filter = 'All';
  final Set<String> _activeTags = {};
  String _dateRange = 'All time';
  final JournalRepository _repo = JournalRepository();

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewState == JournalViewState.loading) {
      return const _JournalLoading();
    }

    return Scaffold(
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              elevation: 0,
              leading: BackButton(),
              title: Text(
                'Journal',
                style: AppTextStyles.heading2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<List<JournalEntry>>(
          stream: _repo.watchJournalEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _JournalLoading();
            }

            final allEntries = snapshot.data ?? [];
            final entries = _filteredEntries(allEntries);

            if (allEntries.isEmpty) {
              return _JournalEmptyState(
                onFree: () => _openEditor(type: 'free'),
                onGuided: () => _openPromptLibrary(),
                onVoice: () => _openVoiceRecording(),
              );
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  Future<void>.delayed(const Duration(milliseconds: 450)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  _AnimatedIn(
                    controller: _entranceController,
                    interval: const Interval(0, .3, curve: Curves.easeOutCubic),
                    child: _JournalHeader(
                      onSearch: () => _openSearch(allEntries),
                    ),
                  ),
                  SizedBox(height: 24),
                  _AnimatedIn(
                    controller: _entranceController,
                    interval: const Interval(
                      .12,
                      .5,
                      curve: Curves.easeOutCubic,
                    ),
                    yOffset: 16,
                    child: _NewEntryHero(onTap: _showEntryTypePicker),
                  ),
                  SizedBox(height: 24),
                  _AnimatedIn(
                    controller: _entranceController,
                    interval: const Interval(
                      .25,
                      .62,
                      curve: Curves.easeOutCubic,
                    ),
                    yOffset: 12,
                    child: _FilterChips(
                      selected: _filter,
                      activeTags: _activeTags,
                      onChanged: (value) {
                        if (value == 'Tags') {
                          _showFilterSheet();
                        } else {
                          setState(() => _filter = value);
                        }
                      },
                    ),
                  ),
                  if (_activeTags.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _activeTags
                          .map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              onDeleted: () =>
                                  setState(() => _activeTags.remove(tag)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  SizedBox(height: 32),
                  if (entries.isEmpty)
                    _NoMatches(filter: _filter)
                  else ...[
                    _EntrySection(
                      title: 'This week',
                      entries: entries.take(3).toList(),
                      controller: _entranceController,
                      start: .45,
                      onTap: _openEntryDetail,
                      onMore: _showEntryMenu,
                    ),
                    if (entries.length > 3) ...[
                      SizedBox(height: 32),
                      _EntrySection(
                        title: 'Earlier',
                        entries: entries.skip(3).toList(),
                        controller: _entranceController,
                        start: .65,
                        onTap: _openEntryDetail,
                        onMore: _showEntryMenu,
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<JournalEntry> _filteredEntries(List<JournalEntry> allEntries) {
    return allEntries.where((entry) {
      final typeMatches =
          _filter == 'All' ||
          (_filter == 'Free' && entry.type == 'free') ||
          (_filter == 'Guided' && entry.type == 'guided') ||
          (_filter == 'Voice' && entry.type == 'voice');
      final tagMatches =
          _activeTags.isEmpty || (entry.tags ?? []).any(_activeTags.contains);
      final dateMatches = switch (_dateRange) {
        'Last 7 days' => entry.createdAt.isAfter(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
        'Last 30 days' => entry.createdAt.isAfter(
          DateTime.now().subtract(const Duration(days: 30)),
        ),
        _ => true,
      };
      return typeMatches && tagMatches && dateMatches;
    }).toList();
  }

  Future<void> _saveEntry(JournalEntry entry) async {
    final signal = _crisisDetector.analyze(entry.body);
    final shouldShowCrisisSupport = _crisisDetector.canTrigger(
      'journal',
      signal,
    );
    final entryToSave = shouldShowCrisisSupport
        ? JournalEntry(
            id: entry.id,
            type: entry.type,
            title: entry.title,
            body: entry.body,
            voiceUrl: entry.voiceUrl,
            voiceDuration: entry.voiceDuration,
            transcription: entry.transcription,
            promptId: entry.promptId,
            promptText: entry.promptText,
            tags: entry.tags,
            linkedMoodEntryId: entry.linkedMoodEntryId,
            wordCount: entry.wordCount,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            isDraft: entry.isDraft,
            isCrisisFlagged: true,
          )
        : entry;

    try {
      await _repo.save(entryToSave);
    } catch (e) {
      // Ignored for now - LocalDbService handles offline queueing
    }

    if (!mounted) return;
    if (shouldShowCrisisSupport) {
      _crisisDetector.markTriggered('journal');
      await showCrisisSupportOverlay(context, signal: signal);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(entry.isDraft ? 'Draft saved.' : 'Entry saved.')),
    );
  }

  Future<void> _openEditor({
    required String type,
    JournalPrompt? prompt,
    JournalEntry? existing,
  }) async {
    final entry = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute(
        builder: (_) =>
            JournalEditorScreen(type: type, prompt: prompt, existing: existing),
      ),
    );
    if (entry != null) await _saveEntry(entry);
  }

  Future<void> _openPromptLibrary() async {
    final prompt = await Navigator.of(context).push<JournalPrompt>(
      MaterialPageRoute(builder: (_) => const GuidedPromptsScreen()),
    );
    if (prompt != null) {
      await _openEditor(type: 'guided', prompt: prompt);
    }
  }

  Future<void> _openVoiceRecording() async {
    final entry = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute(builder: (_) => const JournalVoiceRecordingScreen()),
    );
    if (entry != null) await _saveEntry(entry);
  }

  Future<void> _openSearch(List<JournalEntry> allEntries) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            JournalSearchScreen(entries: allEntries, onOpen: _openEntryDetail),
      ),
    );
  }

  Future<void> _openEntryDetail(JournalEntry entry) async {
    final result = await Navigator.of(context).push<_EntryAction>(
      MaterialPageRoute(builder: (_) => JournalEntryDetailScreen(entry: entry)),
    );

    if (result == null) return;
    if (result.action == 'edit') {
      await _openEditor(type: entry.type, existing: entry);
    }
    if (result.action == 'delete') {
      _deleteEntry(entry);
    }
  }

  void _showEntryTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
      builder: (context) => _EntryTypePicker(
        onFree: () {
          Navigator.pop(context);
          _openEditor(type: 'free');
        },
        onGuided: () {
          Navigator.pop(context);
          _openPromptLibrary();
        },
        onVoice: () {
          Navigator.pop(context);
          _openVoiceRecording();
        },
      ),
    );
  }

  void _showEntryMenu(JournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryMoreSheet(
        onEdit: () {
          Navigator.pop(context);
          _openEditor(type: entry.type, existing: entry);
        },
        onShare: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider sharing is opt-in only.')),
          );
        },
        onAddTag: () {
          Navigator.pop(context);
          _showAddTagSheet(entry);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(entry);
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedTags: _activeTags,
        dateRange: _dateRange,
        onApply: (tags, dateRange) {
          setState(() {
            _activeTags
              ..clear()
              ..addAll(tags);
            _dateRange = dateRange;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _activeTags.clear();
            _dateRange = 'All time';
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddTagSheet(JournalEntry entry) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTagSheet(
        controller: controller,
        onAdd: () async {
          final tag = controller.text.trim().replaceAll('#', '');
          if (tag.isEmpty) return;

          final updatedEntry = JournalEntry(
            id: entry.id,
            type: entry.type,
            title: entry.title,
            body: entry.body,
            voiceUrl: entry.voiceUrl,
            voiceDuration: entry.voiceDuration,
            transcription: entry.transcription,
            promptId: entry.promptId,
            promptText: entry.promptText,
            tags: [...?(entry.tags), tag],
            linkedMoodEntryId: entry.linkedMoodEntryId,
            wordCount: entry.wordCount,
            createdAt: entry.createdAt,
            updatedAt: DateTime.now(),
            isDraft: entry.isDraft,
          );

          try {
            await _repo.save(updatedEntry);
          } catch (_) {}

          HapticFeedback.selectionClick();
          if (mounted) Navigator.pop(context);
        },
      ),
    ).whenComplete(controller.dispose);
  }

  void _confirmDelete(JournalEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => _DeleteConfirmation(
        onDelete: () {
          Navigator.pop(context);
          _deleteEntry(entry);
        },
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    try {
      await _repo.deleteJournalEntry(entry.id);
    } catch (e) {}
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry deleted.')));
  }
}

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({
    super.key,
    required this.type,
    this.prompt,
    this.existing,
  });

  final String type;
  final JournalPrompt? prompt;
  final JournalEntry? existing;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  late final List<String> _tags;
  late final String _draftId;
  JournalEntry? _availableDraft;
  bool _showDraftPrompt = false;
  Timer? _autoSaveTimer;
  String _saveStatus = 'No draft yet';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftId =
        widget.existing?.id ??
        'journal_draft_${widget.type}_${widget.prompt?.id ?? 'free'}';
    _availableDraft = widget.existing == null
        ? LocalDbService.instance.getJournalDraft(_draftId)
        : null;
    _showDraftPrompt = _availableDraft != null;
    _controller = TextEditingController(text: widget.existing?.body ?? '');
    _tags = [...(widget.existing?.tags ?? const <String>[])];
    if (_availableDraft != null) _saveStatus = 'Draft available';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveDraftNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt =
        widget.prompt ??
        (widget.existing?.promptText == null
            ? null
            : JournalPrompt(
                id: widget.existing!.promptId ?? 'existing',
                category: widget.existing!.title ?? 'Journal entry',
                text: widget.existing!.promptText!,
              ));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _finish,
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: Text('Save')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                children: [
                  Text(_dateStamp(), style: _captionStyle()),
                  if (prompt != null) ...[
                    SizedBox(height: 18),
                    _PromptPinnedCard(prompt: prompt),
                  ],
                  if (_showDraftPrompt && _availableDraft != null) ...[
                    SizedBox(height: 18),
                    _DraftRestoreCard(
                      draft: _availableDraft!,
                      onResume: _resumeDraft,
                      onDiscard: () => _discardDraft(),
                    ),
                  ],
                  SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    minLines: 12,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSubtleDark
                            : AppColors.textSubtleLight,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _scheduleAutoSave(),
                  ),
                ],
              ),
            ),
            _EditorFooter(
              tags: _tags,
              wordCount: _wordCount,
              status: _saveStatus,
              onAddTag: _addTag,
            ),
          ],
        ),
      ),
    );
  }

  int get _wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  void _resumeDraft() {
    final draft = _availableDraft;
    if (draft == null) return;
    setState(() {
      _controller.text = draft.body;
      _tags
        ..clear()
        ..addAll(draft.tags ?? const <String>[]);
      _showDraftPrompt = false;
      _saveStatus = 'Draft restored';
    });
  }

  Future<void> _discardDraft() async {
    await LocalDbService.instance.deleteJournalDraft(_draftId);
    if (!mounted) return;
    setState(() {
      _availableDraft = null;
      _showDraftPrompt = false;
      _saveStatus = 'No draft yet';
    });
  }

  void _addTag() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTagSheet(
        controller: controller,
        onAdd: () {
          final tag = controller.text.trim().replaceAll('#', '');
          if (tag.isEmpty) return;
          setState(() => _tags.add(tag));
          HapticFeedback.selectionClick();
          Navigator.pop(context);
        },
      ),
    ).whenComplete(controller.dispose);
  }

  void _scheduleAutoSave() {
    setState(() => _saveStatus = 'Saving draft...');
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 500),
      () => _saveDraftNow(),
    );
  }

  Future<void> _saveDraftNow() async {
    _autoSaveTimer?.cancel();
    final body = _controller.text.trim();
    if (body.isEmpty && _tags.isEmpty) {
      await LocalDbService.instance.deleteJournalDraft(_draftId);
      if (mounted) setState(() => _saveStatus = 'No draft yet');
      return;
    }

    await LocalDbService.instance.saveJournalDraft(
      JournalEntry(
        id: _draftId,
        type: widget.type,
        title:
            widget.prompt?.category ??
            widget.existing?.title ??
            'Journal entry',
        body: body,
        tags: _tags,
        promptId: widget.prompt?.id ?? widget.existing?.promptId,
        promptText: widget.prompt?.text ?? widget.existing?.promptText,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isDraft: true,
        wordCount: _wordCount,
      ),
    );

    if (mounted) setState(() => _saveStatus = 'Draft saved ${_timeNow()}');
  }

  Future<void> _finish() async {
    final body = _controller.text.trim();
    if (body.isEmpty && widget.existing == null) {
      await LocalDbService.instance.deleteJournalDraft(_draftId);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    await LocalDbService.instance.deleteJournalDraft(_draftId);
    if (!mounted) return;

    Navigator.pop(
      context,
      JournalEntry(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        type: widget.type,
        title:
            widget.prompt?.category ??
            widget.existing?.title ??
            'Journal entry',
        body: body,
        tags: _tags,
        promptId: widget.prompt?.id ?? widget.existing?.promptId,
        promptText: widget.prompt?.text ?? widget.existing?.promptText,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isDraft: false,
        wordCount: _wordCount,
      ),
    );
  }
}

class GuidedPromptsScreen extends StatefulWidget {
  const GuidedPromptsScreen({super.key});

  @override
  State<GuidedPromptsScreen> createState() => _GuidedPromptsScreenState();
}

class _GuidedPromptsScreenState extends State<GuidedPromptsScreen> {
  String _category = 'All';

  final List<JournalPrompt> _prompts = const [
    JournalPrompt(
      id: 'gratitude-1',
      category: 'Gratitude',
      text: "What are three things you're grateful for today?",
    ),
    JournalPrompt(
      id: 'letgo-1',
      category: 'Letting go',
      text: "What's one thing you can let go of today?",
    ),
    JournalPrompt(
      id: 'reflection-1',
      category: 'Reflection',
      text: 'Describe a moment this week that felt peaceful.',
    ),
    JournalPrompt(
      id: 'anxiety-1',
      category: 'Anxiety',
      text: "What's been weighing on your mind?",
    ),
    JournalPrompt(
      id: 'growth-1',
      category: 'Growth',
      text: 'What did you learn about yourself recently?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final prompts = _category == 'All'
        ? _prompts
        : _prompts.where((prompt) => prompt.category == _category).toList();

    return _JournalSubScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          const _CenteredIntro(
            title: 'Need inspiration?',
            subtitle: 'Pick a prompt.\nOr write your own.',
          ),
          SizedBox(height: 28),
          _PromptCategories(
            selected: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          SizedBox(height: 26),
          for (final prompt in prompts) ...[
            _PromptCard(
              prompt: prompt,
              onUse: () => Navigator.pop(context, prompt),
            ),
            SizedBox(height: 12),
          ],
          _DashedAction(
            label: 'Write your own prompt',
            onTap: () => Navigator.pop(
              context,
              const JournalPrompt(
                id: 'custom',
                category: 'Custom',
                text: 'Your own prompt',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalVoiceRecordingScreen extends StatefulWidget {
  const JournalVoiceRecordingScreen({super.key});

  @override
  State<JournalVoiceRecordingScreen> createState() =>
      _JournalVoiceRecordingScreenState();
}

class _JournalVoiceRecordingScreenState
    extends State<JournalVoiceRecordingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _showTranscription = false;
  int _seconds = 0;
  Timer? _timer;
  final TextEditingController _transcriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: .98,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRecording) return _playbackView();

    return _JournalSubScaffold(
      action: TextButton(onPressed: _cancel, child: Text('Cancel')),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            ScaleTransition(
              scale: MediaQuery.of(context).disableAnimations
                  ? const AlwaysStoppedAnimation(1)
                  : _pulseController,
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.danger : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: AppColors.white,
                    size: 58,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              _formatDuration(_seconds),
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _isRecording ? 'Recording...' : 'Tap to start',
              style: _captionStyle(),
            ),
            SizedBox(height: 34),
            _Waveform(active: _isRecording),
            const Spacer(),
            _PrimaryButton(
              label: _isRecording ? 'Tap to stop' : 'Start recording',
              onPressed: _toggleRecording,
            ),
            SizedBox(height: 12),
            _SecondaryButton(label: 'Cancel', onPressed: _cancel),
          ],
        ),
      ),
    );
  }

  Widget _playbackView() {
    return _JournalSubScaffold(
      action: TextButton(onPressed: _rerecord, child: Text('Re-record')),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: 50),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.white,
                  size: 46,
                ),
              ),
            ),
          ),
          SizedBox(height: 26),
          Center(
            child: Text(
              _formatDuration(_seconds),
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 28),
          _Waveform(
            active: _isPlaying,
            caption: '0:14 / ${_formatDuration(_seconds)}',
          ),
          SizedBox(height: 18),
          _TagRow(tags: const [], onAddTag: () {}),
          SizedBox(height: 12),
          _WarmPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Transcribe (optional)',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                setState(() {
                  _showTranscription = true;
                  _transcriptionController.text =
                      "So today was really tough. I wanted to talk it through instead of holding it in.";
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transcription ready.')),
                );
              },
            ),
          ),
          if (_showTranscription) ...[
            SizedBox(height: 24),
            Text(
              'Transcription',
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _transcriptionController,
              minLines: 6,
              maxLines: 8,
              decoration: _inputDecoration(''),
            ),
            SizedBox(height: 8),
            Text('AI-generated. Edit as needed.', style: _captionStyle()),
          ],
          SizedBox(height: 28),
          _PrimaryButton(label: 'Save entry', onPressed: _saveVoice),
          SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Delete',
              style: AppTextStyles.body1.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    if (_isRecording) {
      HapticFeedback.lightImpact();
      _timer?.cancel();
      _pulseController.stop();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        if (_seconds == 0) _seconds = 42;
      });
    } else {
      HapticFeedback.mediumImpact();
      _pulseController.repeat(reverse: true);
      setState(() {
        _isRecording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    }
  }

  void _cancel() {
    if (_isRecording) {
      showDialog<void>(
        context: context,
        builder: (context) => _DiscardRecordingDialog(
          onDiscard: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _rerecord() {
    setState(() {
      _hasRecording = false;
      _showTranscription = false;
      _seconds = 0;
    });
  }

  void _saveVoice() {
    Navigator.pop(
      context,
      JournalEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'voice',
        title: 'Voice note',
        body: _transcriptionController.text.trim(),
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        wordCount: 0,
        voiceDuration: _seconds,
        transcription: _showTranscription
            ? _transcriptionController.text.trim()
            : null,
      ),
    );
  }
}

class JournalSearchScreen extends StatefulWidget {
  const JournalSearchScreen({
    super.key,
    required this.entries,
    required this.onOpen,
  });

  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry> onOpen;

  @override
  State<JournalSearchScreen> createState() => _JournalSearchScreenState();
}

class _JournalSearchScreenState extends State<JournalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? <JournalEntry>[]
        : widget.entries.where((entry) {
            final haystack =
                '${entry.body} ${entry.title} ${(entry.tags ?? []).join(' ')}'
                    .toLowerCase();
            return haystack.contains(_query.toLowerCase());
          }).toList();

    return _JournalSubScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: _inputDecoration(
              'Search journal...',
            ).copyWith(prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: 28),
          if (_query.isEmpty) ...[
            _SearchSection(
              title: 'Recent searches',
              chips: const ['work', 'anxiety', 'gratitude'],
              onTap: _setQuery,
            ),
            SizedBox(height: 28),
            _SearchSection(
              title: 'Popular tags',
              chips: const [
                '#work',
                '#family',
                '#sleep',
                '#health',
                '#mood',
                '#self',
              ],
              onTap: _setQuery,
            ),
          ] else if (results.isEmpty)
            Text(
              "No entries match '$_query'",
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            )
          else
            for (final entry in results) ...[
              _JournalEntryCard(
                entry: entry,
                onTap: () => widget.onOpen(entry),
                onMore: () {},
              ),
              SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  void _setQuery(String value) {
    final clean = value.replaceAll('#', '');
    _controller.text = clean;
    setState(() => _query = clean);
  }
}

class JournalEntryDetailScreen extends StatelessWidget {
  const JournalEntryDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return _JournalSubScaffold(
      action: IconButton(
        tooltip: 'More',
        onPressed: () => _showMenu(context),
        icon: Icon(Icons.more_horiz),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Text(_detailDate(entry.createdAt), style: _captionStyle()),
          SizedBox(height: 34),
          if (entry.body.isNotEmpty)
            Text(
              entry.body,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          else
            Text(
              '🎤 Voice note · ${_formatDuration(entry.voiceDuration ?? 0)}',
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          SizedBox(height: 28),
          _TagRow(tags: entry.tags ?? [], onAddTag: () {}),
          if (entry.type == 'voice') ...[
            SizedBox(height: 18),
            _WarmPanel(
              child: Row(
                children: [
                  Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 12),
                  Text(
                    'Voice note · ${_formatDuration(entry.voiceDuration ?? 0)}',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 32),
          Text(
            'Last edited ${_detailDate(entry.updatedAt)}',
            style: _captionStyle(),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EntryMoreSheet(
        onEdit: () {
          Navigator.pop(sheetContext);
          Navigator.pop(context, const _EntryAction('edit'));
        },
        onShare: () {
          Navigator.pop(sheetContext);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider sharing is opt-in only.')),
          );
        },
        onAddTag: () => Navigator.pop(sheetContext),
        onDelete: () {
          Navigator.pop(sheetContext);
          Navigator.pop(context, const _EntryAction('delete'));
        },
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Journal',
            style: AppTextStyles.heading1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Search journal',
          onPressed: onSearch,
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _NewEntryHero extends StatelessWidget {
  const _NewEntryHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "What's on your mind? Start a new journal entry.",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _WarmPanel(
          color: AppColors.primarySubtle,
          borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
          radius: 20,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  "What's on your mind?",
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('Start →', style: AppTextStyles.linkText),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.activeTags,
    required this.onChanged,
  });

  final String selected;
  final Set<String> activeTags;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;
    final chips = ['All', 'Free', 'Guided', 'Voice', 'Tags'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) {
          final isSelected =
              selected == chip || (chip == 'Tags' && activeTags.isNotEmpty);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(chip == 'Tags' ? 'Tags ▼' : chip),
              selected: isSelected,
              onSelected: (_) => onChanged(chip),
              selectedColor: AppColors.primarySubtle,
              backgroundColor: colorScheme.surface,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : dividerColor ?? AppColors.border,
              ),
              labelStyle: AppTextStyles.body2.copyWith(
                color: isSelected ? Theme.of(context).colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EntrySection extends StatelessWidget {
  const _EntrySection({
    required this.title,
    required this.entries,
    required this.controller,
    required this.start,
    required this.onTap,
    required this.onMore,
  });

  final String title;
  final List<JournalEntry> entries;
  final AnimationController controller;
  final double start;
  final ValueChanged<JournalEntry> onTap;
  final ValueChanged<JournalEntry> onMore;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12),
        for (var i = 0; i < entries.length; i++) ...[
          _AnimatedIn(
            controller: controller,
            interval: Interval(
              (start + i * .06).clamp(0, .95),
              1,
              curve: Curves.easeOutCubic,
            ),
            yOffset: 12,
            child: _JournalEntryCard(
              entry: entries[i],
              onTap: () => onTap(entries[i]),
              onMore: () => onMore(entries[i]),
            ),
          ),
          if (i != entries.length - 1) SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.onTap,
    required this.onMore,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${_shortDate(entry.createdAt)}. ${entry.cardTitle}.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _WarmPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _detailDate(entry.createdAt),
                      style: _captionStyle(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'More options',
                    onPressed: onMore,
                    icon: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                entry.cardTitle,
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.type == 'guided' && entry.body.isNotEmpty) ...[
                SizedBox(height: 6),
                Text(
                  '"${entry.body}"',
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                SizedBox(height: 14),
                _TagRow(tags: entry.tags!, onAddTag: () {}, compact: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftRestoreCard extends StatelessWidget {
  const _DraftRestoreCard({
    required this.draft,
    required this.onResume,
    required this.onDiscard,
  });

  final JournalEntry draft;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final time =
        '${draft.updatedAt.hour.toString().padLeft(2, '0')}:${draft.updatedAt.minute.toString().padLeft(2, '0')}';

    return _WarmPanel(
      color: AppColors.primarySoft,
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have a draft from $time.',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            draft.body.isEmpty ? 'Tags saved without body text.' : draft.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(label: 'Resume', onPressed: onResume),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(label: 'Discard', onPressed: onDiscard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState({
    required this.onFree,
    required this.onGuided,
    required this.onVoice,
  });

  final VoidCallback onFree;
  final VoidCallback onGuided;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        _JournalHeader(onSearch: () {}),
        SizedBox(height: 54),
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 30),
        const _CenteredIntro(
          title: 'A private space\nfor you.',
          subtitle:
              'Write freely, reflect, or just\nempty your mind.\nNo one else sees this.',
        ),
        SizedBox(height: 36),
        _PrimaryButton(label: '✎  Write an entry', onPressed: onFree),
        SizedBox(height: 12),
        _EntryActionButton(
          icon: '💡',
          title: 'Need inspiration?',
          subtitle: 'Try a guided prompt',
          onTap: onGuided,
        ),
        SizedBox(height: 12),
        _EntryActionButton(
          icon: '🎤',
          title: 'Record a voice note',
          subtitle: '',
          onTap: onVoice,
        ),
      ],
    );
  }
}

class _JournalLoading extends StatelessWidget {
  const _JournalLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: const [
            Row(
              children: [
                _SkeletonBox(width: 120, height: 32),
                Spacer(),
                _SkeletonCircle(size: 24),
              ],
            ),
            SizedBox(height: 24),
            _SkeletonBox(height: 88, radius: 20),
            SizedBox(height: 24),
            Row(
              children: [
                _SkeletonBox(width: 60, height: 36),
                SizedBox(width: 8),
                _SkeletonBox(width: 70, height: 36),
                SizedBox(width: 8),
                _SkeletonBox(width: 84, height: 36),
              ],
            ),
            SizedBox(height: 32),
            _SkeletonBox(width: 80, height: 20),
            SizedBox(height: 12),
            _SkeletonBox(height: 100, radius: 16),
            SizedBox(height: 12),
            _SkeletonBox(height: 100, radius: 16),
            SizedBox(height: 12),
            _SkeletonBox(height: 100, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _EntryTypePicker extends StatelessWidget {
  const _EntryTypePicker({
    required this.onFree,
    required this.onGuided,
    required this.onVoice,
  });

  final VoidCallback onFree;
  final VoidCallback onGuided;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What kind of entry?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 18),
          _EntryActionButton(
            icon: '✎',
            title: 'Free write',
            subtitle: 'Just start',
            onTap: onFree,
          ),
          SizedBox(height: 10),
          _EntryActionButton(
            icon: '💡',
            title: 'Guided prompt',
            subtitle: 'Need a nudge?',
            onTap: onGuided,
          ),
          SizedBox(height: 10),
          _EntryActionButton(
            icon: '🎤',
            title: 'Voice note',
            subtitle: 'Speak instead',
            onTap: onVoice,
          ),
          SizedBox(height: 14),
          _SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _EntryActionButton extends StatelessWidget {
  const _EntryActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _WarmPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCategories extends StatelessWidget {
  const _PromptCategories({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;
    const categories = [
      'All',
      'Gratitude',
      'Reflection',
      'Letting go',
      'Growth',
      'Anxiety',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: categories.map((category) {
        final active = selected == category;
        return ChoiceChip(
          label: Text(category),
          selected: active,
          onSelected: (_) => onChanged(category),
          selectedColor: AppColors.primarySubtle,
          backgroundColor: colorScheme.surface,
          side: BorderSide(
            color: active
                ? Theme.of(context).colorScheme.primary
                : dividerColor ?? AppColors.border,
          ),
        );
      }).toList(),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.onUse});

  final JournalPrompt prompt;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${prompt.text}"',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  prompt.category,
                  style: AppTextStyles.body2.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              TextButton(onPressed: onUse, child: Text('Use →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptPinnedCard extends StatelessWidget {
  const _PromptPinnedCard({required this.prompt});

  final JournalPrompt prompt;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      color: AppColors.primarySubtle,
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 ${prompt.category}',
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '"${prompt.text}"',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedTags,
    required this.dateRange,
    required this.onApply,
    required this.onClear,
  });

  final Set<String> selectedTags;
  final String dateRange;
  final void Function(Set<String>, String) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _tags = {...widget.selectedTags};
  late String _dateRange = widget.dateRange;

  @override
  Widget build(BuildContext context) {
    const tags = ['work', 'family', 'sleep', 'mood', 'health', 'self'];
    const ranges = ['Last 7 days', 'Last 30 days', 'All time'];
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Tags',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final selected = _tags.contains(tag);
              return FilterChip(
                label: Text('#$tag'),
                selected: selected,
                onSelected: (_) => setState(
                  () => selected ? _tags.remove(tag) : _tags.add(tag),
                ),
                selectedColor: AppColors.primarySubtle,
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Text(
            'Date range',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final range in ranges)
            InkWell(
              onTap: () => setState(() => _dateRange = range),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      _dateRange == range
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _dateRange == range
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.textMuted,
                    ),
                    SizedBox(width: 12),
                    Text(
                      range,
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 10),
          _PrimaryButton(
            label: 'Apply filters',
            onPressed: () => widget.onApply(_tags, _dateRange),
          ),
          SizedBox(height: 10),
          _SecondaryButton(label: 'Clear all', onPressed: widget.onClear),
        ],
      ),
    );
  }
}

class _EntryMoreSheet extends StatelessWidget {
  const _EntryMoreSheet({
    required this.onEdit,
    required this.onShare,
    required this.onAddTag,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onAddTag;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTile(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
          _SheetTile(
            icon: Icons.ios_share_outlined,
            label: 'Share with provider',
            onTap: onShare,
          ),
          _SheetTile(
            icon: Icons.sell_outlined,
            label: 'Add tag',
            onTap: onAddTag,
          ),
          _SheetTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            danger: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmation extends StatelessWidget {
  const _DeleteConfirmation({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: _WarmPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete this entry?',
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "This can't be undone.",
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Delete'),
              ),
            ),
            SizedBox(height: 10),
            _SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscardRecordingDialog extends StatelessWidget {
  const _DiscardRecordingDialog({required this.onDiscard});

  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Discard recording?'),
      content: Text('This recording has not been saved.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(onPressed: onDiscard, child: Text('Discard')),
      ],
    );
  }
}

class _AddTagSheet extends StatelessWidget {
  const _AddTagSheet({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add tag',
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: _inputDecoration('#tag'),
            ),
            SizedBox(height: 14),
            _PrimaryButton(label: 'Add tag', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.title,
    required this.chips,
    required this.onTap,
  });

  final String title;
  final List<String> chips;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map(
                (chip) =>
                    ActionChip(label: Text(chip), onPressed: () => onTap(chip)),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tags,
    required this.onAddTag,
    this.compact = false,
  });

  final List<String> tags;
  final VoidCallback onAddTag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '#$tag',
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
        if (!compact) ActionChip(label: Text('+ Add tag'), onPressed: onAddTag),
      ],
    );
  }
}

class _EditorFooter extends StatelessWidget {
  const _EditorFooter({
    required this.tags,
    required this.wordCount,
    required this.status,
    required this.onAddTag,
  });

  final List<String> tags;
  final int wordCount;
  final String status;
  final VoidCallback onAddTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WarmPanel(
            padding: const EdgeInsets.all(10),
            child: _TagRow(tags: tags, onAddTag: onAddTag),
          ),
          SizedBox(height: 8),
          _WarmPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text('$wordCount words', style: _captionStyle()),
                const Spacer(),
                Text(status, style: _captionStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.active, this.caption});

  final bool active;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(42, (index) {
      final height = active
          ? 10 + ((index * 11) % 48).toDouble()
          : 8 + ((index * 7) % 28).toDouble();
      return Container(
        width: 4,
        height: height,
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : AppColors.borderStrong,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    });

    return _WarmPanel(
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: bars,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: 8),
            Text(caption!, style: _captionStyle()),
          ],
        ],
      ),
    );
  }
}

class _JournalSubScaffold extends StatelessWidget {
  const _JournalSubScaffold({required this.child, this.action});

  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (action != null) action!,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dividerColor ?? AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.text),
      title: Text(
        label,
        style: AppTextStyles.body1.copyWith(
          color: danger ? AppColors.danger : AppColors.text,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _CenteredIntro extends StatelessWidget {
  const _CenteredIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      child: Text(
        filter == 'All' ? 'No entries yet.' : 'No entries match this filter.',
        style: AppTextStyles.body1.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class _DashedAction extends StatelessWidget {
  const _DashedAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderStrong,
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          '+ $label',
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WarmPanel extends StatelessWidget {
  const _WarmPanel({
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? dividerColor ?? AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({
    required this.controller,
    required this.child,
    required this.interval,
    this.yOffset = 8,
  });

  final AnimationController controller;
  final Widget child;
  final Interval interval;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final animation = CurvedAnimation(parent: controller, curve: interval);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, yOffset / 100),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.radius = 12});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: .55),
        shape: BoxShape.circle,
      ),
    );
  }
}

extension on JournalEntry {
  String get cardTitle {
    return switch (type) {
      'voice' => '🎤 Voice note',
      'guided' => '✎ Guided · $title',
      'free' => body.isEmpty ? 'Tap to write' : body,
      _ => title ?? body,
    };
  }
}

class JournalPrompt {
  const JournalPrompt({
    required this.id,
    required this.category,
    required this.text,
  });

  final String id;
  final String category;
  final String text;
}

class _EntryAction {
  const _EntryAction(this.action);

  final String action;
}

TextStyle _captionStyle() => AppTextStyles.body2.copyWith(
  color: AppColors.textMuted,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textSubtle),
    filled: true,
    fillColor: AppColors.surfaceElevated,
    contentPadding: const EdgeInsets.all(16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
    ),
  );
}

String _dateStamp() => 'Sep 28, 2026 · 9:42 AM';

String _timeNow() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _detailDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour:$minute $suffix';
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}
