import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../widgets/journal_share_flow.dart';
import '../../../../core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/mood_artwork.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/security_gate.dart';

import 'package:uuid/uuid.dart';
import '../../../../core/audio/voice_audio.dart';
import '../../../../core/audio/voice_player.dart';
import '../../../../core/audio/voice_recorder_popup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';
import '../../../../core/repositories/journal_repository.dart';
import '../../../../core/models/journal_entry.dart';
import '../../../../core/models/sync_item.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/services/local_db_service.dart';

enum JournalViewState { populated, empty, loading }

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    this.viewState = JournalViewState.populated,
    this.openCompose = false,
    this.recordVoiceOnOpen = false,
    this.initialPrompt,
  });

  final JournalViewState viewState;
  final bool openCompose;
  final bool recordVoiceOnOpen;
  final JournalPrompt? initialPrompt;

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
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
      if (widget.recordVoiceOnOpen) unawaited(_openVoiceRecording());
      if (widget.openCompose) {
        unawaited(
          _openEditor(
            type: widget.initialPrompt == null ? 'free' : 'guided',
            prompt: widget.initialPrompt,
          ),
        );
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
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter journal entries',
            icon: const Icon(Icons.tune),
            initialValue: _filter,
            itemBuilder: (_) => [
              for (final type in ['All', 'Free', 'Guided', 'Voice'])
                CheckedPopupMenuItem(
                  value: type,
                  checked: _filter == type,
                  child: Text(type),
                ),
              const PopupMenuItem(
                value: 'Tags',
                child: Text('Tags and date range'),
              ),
            ],
            onSelected: (value) {
              if (value == 'Tags') {
                _showFilterSheet();
              } else {
                setState(() => _filter = value);
              }
            },
          ),
          IconButton(
            tooltip: 'New journal entry',
            onPressed: _showEntryTypePicker,
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<JournalEntry>>(
          stream: _repo.watchJournalEntries(),
          initialData: LocalDbService().getAllJournalEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _JournalLoading();
            }

            final allEntries = snapshot.data ?? const [];
            final entries = _filteredEntries(allEntries);

            if (allEntries.isEmpty) {
              final theme = Theme.of(context);
              final dark = theme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _JournalHeader(onSearch: () => _openSearch(allEntries)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColoredBox(
                          color: dark
                              ? AppColors.surfaceSubtleDark
                              : AppColors.surfaceSubtle,
                          child: EmptyState(
                            onOfflineRetry: () => _repo.fetchJournalEntries(),
                            icon: Icons.menu_book_rounded,
                            title: 'A private space for your thoughts.',
                            primaryCtaLabel: 'Write your first entry',
                            onPrimaryCta: () => _openEditor(type: 'free'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  Future<void>.delayed(const Duration(milliseconds: 450)),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _AnimatedIn(
                    controller: _entranceController,
                    interval: const Interval(0, .3, curve: Curves.easeOutCubic),
                    child: _JournalHeader(
                      onSearch: () => _openSearch(allEntries),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activeTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                      onDelete: _deleteEntry,
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
                        onDelete: _deleteEntry,
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

  Future<bool> _saveEntry(JournalEntry entry) async {
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
            localVoicePath: entry.localVoicePath,
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
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save your entry. Your words are still here.",
          ),
        );
      }
      return false;
    }

    if (!mounted) return true;
    if (shouldShowCrisisSupport) {
      _crisisDetector.markTriggered('journal');
      await showCrisisSupportOverlay(context, signal: signal);
      return true;
    }

    AppSnackbar.show(
      context,
      AppSnackbar.saved(type: 'journal_entry', id: entry.id),
    );
    return true;
  }

  Future<void> _openEditor({
    required String type,
    JournalPrompt? prompt,
    JournalEntry? existing,
  }) async {
    final entry = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute(
        builder: (_) => SecurityGate(
          journal: true,
          child: JournalEditorScreen(
            onSave: _saveEntry,
            type: type,
            prompt: prompt,
            existing: existing,
          ),
        ),
      ),
    );
    if (entry != null) await _saveEntry(entry);
  }

  Future<void> _openPromptLibrary() async {
    final prompt = await Navigator.of(context).push<JournalPrompt>(
      MaterialPageRoute(
        builder: (_) =>
            const SecurityGate(journal: true, child: GuidedPromptsScreen()),
      ),
    );
    if (prompt != null) {
      await _openEditor(type: 'guided', prompt: prompt);
    }
  }

  Future<void> _openVoiceRecording() async {
    final id = const Uuid().v4();
    final owner = LocalDbService().activeUserId;
    await showVoiceRecorder(
      context,
      journal: true,
      onConfirm: (audio) async {
        if (owner != LocalDbService().activeUserId) {
          throw StateError('Account changed');
        }
        final path = await VoiceAudio.save(audio, id);
        final now = DateTime.now();
        final saved = await _saveEntry(
          JournalEntry(
            id: id,
            type: 'voice',
            title: 'Voice note',
            body: '',
            voiceUrl: path,
            localVoicePath: path,
            voiceDuration: audio.duration,
            tags: [],
            wordCount: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (!saved) throw StateError('Could not save journal');
      },
    );
  }

  Future<void> _openSearch(List<JournalEntry> allEntries) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SecurityGate(
          journal: true,
          child: JournalSearchScreen(
            entries: allEntries,
            onOpen: _openEntryDetail,
          ),
        ),
      ),
    );
  }

  Future<void> _openEntryDetail(JournalEntry entry) async {
    final result = await Navigator.of(context).push<_EntryAction>(
      MaterialPageRoute(
        builder: (_) => SecurityGate(
          journal: true,
          child: JournalEntryDetailScreen(entry: entry),
        ),
      ),
    );

    if (result == null) return;
    if (result.action == 'edit') {
      await _openEditor(type: entry.type, existing: entry);
    }
    if (result.action == 'tag') {
      _showAddTagSheet(entry);
    }
    if (result.action == 'delete') {
      _deleteEntry(entry);
    }
  }

  void _showEntryTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
      builder: (context) => SingleChildScrollView(
        child: _EntryTypePicker(
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
      ),
    );
  }

  void _showEntryMenu(JournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (context) => _EntryMoreSheet(
        onEdit: () {
          Navigator.pop(context);
          _openEditor(type: entry.type, existing: entry);
        },
        onShare: () {
          Navigator.pop(context);
          showJournalShareFlow(this.context, entry);
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
      shape: const RoundedRectangleBorder(),
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
    showWellnessDialog<void>(
      context: context,
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
            localVoicePath: entry.localVoicePath,
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
            isCrisisFlagged: entry.isCrisisFlagged,
          );

          try {
            await _repo.save(updatedEntry);
          } catch (_) {
            if (context.mounted) {
              AppSnackbar.show(
                context,
                AppSnackbar.error('Could not save tag. Try again.'),
              );
            }
            return;
          }

          HapticFeedback.selectionClick();
          if (context.mounted) Navigator.pop(context);
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
    } catch (e) {
      debugPrint('Journal entry deletion failed: details withheld.');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text('Unable to delete entry. Try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    AppSnackbar.show(
      context,
      SnackBar(
        content: const Text('Entry deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await _repo.saveJournalEntry(entry);
            } catch (_) {
              if (mounted) {
                AppSnackbar.show(
                  context,
                  AppSnackbar.error('Unable to restore entry. Try again.'),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({
    super.key,
    required this.type,
    this.prompt,
    this.existing,
    this.onSave,
  });

  final String type;
  final JournalPrompt? prompt;
  final JournalEntry? existing;
  final Future<bool> Function(JournalEntry)? onSave;

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
  bool _saving = false;
  final _owner = LocalDbService.instance.activeUserId;
  final _sessionGeneration = TokenStorage.generation;
  StreamSubscription<void>? _sessionClearing, _sessionChanges, _accountChanges;
  bool _sessionEnded = false;
  bool get _active =>
      !_sessionEnded &&
      _owner == LocalDbService.instance.activeUserId &&
      _sessionGeneration == TokenStorage.generation;

  void _endSession() {
    if (!mounted || _sessionEnded) return;
    _autoSaveTimer?.cancel();
    _controller.clear();
    _tags.clear();
    setState(() {
      _sessionEnded = true;
      _availableDraft = null;
    });
  }

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
    _sessionClearing = TokenStorage.sessionClearing.listen(
      (_) => _endSession(),
    );
    _sessionChanges = TokenStorage.sessionChanges.listen((_) => _endSession());
    _accountChanges = LocalDbService.instance.accountChanges.listen((_) {
      if (_owner != LocalDbService.instance.activeUserId) _endSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    unawaited(_sessionClearing?.cancel());
    unawaited(_sessionChanges?.cancel());
    unawaited(_accountChanges?.cancel());
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
  Widget build(BuildContext context) => _active
      ? _buildProtected(context)
      : const Scaffold(
          body: Center(
            child: Text(
              'Your session changed. Reopen the journal to continue.',
            ),
          ),
        );

  Widget _buildProtected(BuildContext context) {
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
                    onPressed: _saving ? null : _finish,
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: _saving
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Loading...'),
                            ],
                          )
                        : const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                children: [
                  Text(_dateStamp(), style: _captionStyle(context)),
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
                      fontFamily: 'Outfit',
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
        ..addAll(draft.tags ?? <String>[]);
      _showDraftPrompt = false;
      _saveStatus = 'Draft restored';
    });
  }

  Future<void> _discardDraft() async {
    if (!_active) return;
    await LocalDbService.instance.deleteJournalDraft(_draftId);
    if (!mounted) return;
    setState(() {
      _availableDraft = null;
      _showDraftPrompt = false;
      _saveStatus = 'No draft yet';
    });
  }

  void _addTag() {
    if (!_active) return;
    final controller = TextEditingController();
    showWellnessDialog<void>(
      context: context,
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
    if (!_active) return;
    setState(() => _saveStatus = 'Saving draft...');
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 500),
      () => _saveDraftNow(),
    );
  }

  Future<void> _saveDraftNow() async {
    if (!_active) return;
    _autoSaveTimer?.cancel();
    final body = _controller.text.trim();
    if (body.isEmpty && _tags.isEmpty) {
      await LocalDbService.instance.deleteJournalDraft(_draftId);
      if (mounted) setState(() => _saveStatus = 'No draft yet');
      return;
    }

    try {
      await LocalDbService.instance.saveJournalDraft(
        JournalEntry(
          id: _draftId,
          type: widget.type,
          title:
              widget.prompt?.category ??
              widget.existing?.title ??
              'Journal entry',
          body: body,
          voiceUrl: widget.existing?.voiceUrl,
          localVoicePath: widget.existing?.localVoicePath,
          voiceDuration: widget.existing?.voiceDuration,
          transcription: widget.existing?.transcription,
          tags: _tags,
          promptId: widget.prompt?.id ?? widget.existing?.promptId,
          promptText: widget.prompt?.text ?? widget.existing?.promptText,
          createdAt: widget.existing?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          isDraft: true,
          wordCount: _wordCount,
        ),
      );

      if (mounted && _active)
        setState(() => _saveStatus = 'Draft saved ${_timeNow()}');
    } catch (_) {
      if (mounted && _active)
        setState(
          () => _saveStatus =
              'Draft could not save. Keep this page open and retry.',
        );
    }
  }

  Future<void> _finish() async {
    if (_saving || !_active) return;
    setState(() => _saving = true);
    _autoSaveTimer?.cancel();
    try {
      await _finishEntry();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save your entry. Please try again.",
            onRetry: _finish,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finishEntry() async {
    if (!_active) return;
    final body = _controller.text.trim();
    if (body.isEmpty && widget.existing == null) {
      await LocalDbService.instance.deleteJournalDraft(_draftId);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final entry = JournalEntry(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: widget.type,
      title:
          widget.prompt?.category ?? widget.existing?.title ?? 'Journal entry',
      body: body,
      voiceUrl: widget.existing?.voiceUrl,
      localVoicePath: widget.existing?.localVoicePath,
      voiceDuration: widget.existing?.voiceDuration,
      transcription: widget.existing?.transcription,
      tags: _tags,
      promptId: widget.prompt?.id ?? widget.existing?.promptId,
      promptText: widget.prompt?.text ?? widget.existing?.promptText,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isDraft: false,
      wordCount: _wordCount,
    );
    if (widget.onSave != null && !await widget.onSave!(entry)) return;
    if (!_active) return;
    await LocalDbService.instance.deleteJournalDraft(_draftId);
    if (mounted && _active)
      Navigator.pop(context, widget.onSave == null ? entry : null);
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

// Compatibility entry point for existing routes; the recorder itself stays compact.
class JournalVoiceRecordingScreen extends StatelessWidget {
  const JournalVoiceRecordingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const JournalScreen(recordVoiceOnOpen: true);
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
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: _inputDecoration(
              context,
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
            EmptyState(
              icon: Icons.search,
              title: "No entries match '$_query'.",
              primaryCtaLabel: 'Clear search',
              onPrimaryCta: () => _setQuery(''),
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
  Widget build(BuildContext context) => StreamBuilder<JournalEntry?>(
    stream: JournalRepository().watchEntryById(entry.id),
    initialData: entry,
    builder: (context, snapshot) =>
        _buildProtected(context, snapshot.data ?? entry),
  );

  Widget _buildProtected(BuildContext context, JournalEntry entry) {
    final linked = MoodRepository().currentEntries().where(
      (mood) => mood.id == entry.linkedMoodEntryId,
    );
    final mood = linked.isEmpty ? null : linked.first;
    return _JournalSubScaffold(
      action: IconButton(
        tooltip: 'More',
        onPressed: () => _showMenu(context),
        icon: const Icon(Icons.more_horiz),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Text(_detailDate(entry.createdAt), style: _captionStyle(context)),
          if (mood != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (MoodArtwork.assetFor(mood.mood) != null) ...[
                  MoodArtwork(mood: mood.mood, size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    '${mood.displayFeeling} | Intensity ${mood.intensity}/10',
                    style: _captionStyle(context),
                  ),
                ),
              ],
            ),
          ],
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
          _TagRow(tags: entry.tags ?? [], onAddTag: () {}, compact: true),
          if (entry.type == 'voice') ...[
            SizedBox(height: 18),
            if (entry.voiceUrl?.isNotEmpty == true ||
                entry.localVoicePath?.isNotEmpty == true)
              VoicePlayer(
                journal: true,
                source: entry.voiceUrl ?? '',
                localPath: entry.localVoicePath,
                duration: entry.voiceDuration ?? 0,
              )
            else
              const Text('Audio is unavailable for this older entry.'),
            if (entry.voiceUrl?.isNotEmpty == true ||
                entry.localVoicePath?.isNotEmpty == true)
              StreamBuilder<List<SyncItem>>(
                stream: LocalDbService().watchPendingItems(),
                initialData: LocalDbService().pendingItems,
                builder: (context, snapshot) {
                  final pending =
                      snapshot.data?.any(
                        (item) =>
                            item.type == 'journal_entry' &&
                            item.recordId == entry.id,
                      ) ??
                      false;
                  final uploaded =
                      entry.voiceUrl?.startsWith('/audio-attachments/') == true;
                  return Text(
                    uploaded && !pending
                        ? 'Synced privately to your account'
                        : 'Saved on device - Waiting to sync',
                    style: _captionStyle(context),
                  );
                },
              ),
            if (entry.transcription?.isNotEmpty == true)
              Text(entry.transcription!),
          ],
          SizedBox(height: 32),
          Text(
            'Last edited ${_detailDate(entry.updatedAt)}',
            style: _captionStyle(context),
          ),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                onPressed: () =>
                    Navigator.pop(context, const _EntryAction('edit')),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: () =>
                    Navigator.pop(context, const _EntryAction('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (sheetContext) => _EntryMoreSheet(
        onEdit: () {
          Navigator.pop(sheetContext);
          Navigator.pop(context, const _EntryAction('edit'));
        },
        onShare: () {
          Navigator.pop(sheetContext);
          showJournalShareFlow(context, entry);
        },
        onAddTag: () {
          Navigator.pop(sheetContext);
          Navigator.pop(context, const _EntryAction('tag'));
        },
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
            'Your Journal',
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

class _EntrySection extends StatelessWidget {
  const _EntrySection({
    required this.title,
    required this.entries,
    required this.controller,
    required this.start,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
  });
  final String title;
  final List<JournalEntry> entries;
  final AnimationController controller;
  final double start;
  final ValueChanged<JournalEntry> onTap;
  final ValueChanged<JournalEntry> onMore;
  final ValueChanged<JournalEntry> onDelete;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: AppSurface.border(context),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceSubtleDark
                : AppColors.surfaceSubtle,
          ),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _AnimatedIn(
                  controller: controller,
                  interval: Interval(
                    (start + i * .06).clamp(0, .95),
                    1,
                    curve: Curves.easeOutCubic,
                  ),
                  yOffset: 12,
                  child: Dismissible(
                    key: ValueKey(entries[i].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => onDelete(entries[i]),
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    child: _JournalEntryCard(
                      entry: entries[i],
                      onTap: () => onTap(entries[i]),
                      onMore: () => onMore(entries[i]),
                    ),
                  ),
                ),
                if (i != entries.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${_shortDate(entry.createdAt)}. ${entry.cardTitle}.',
    child: Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceSubtleDark
          : AppColors.surfaceSubtle,
      shape: AppSurface.shape(context, BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 69),
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_shortDate(entry.createdAt)} · ${entry.body}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'More options',
                onPressed: onMore,
                icon: Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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

class _JournalLoading extends StatelessWidget {
  const _JournalLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Row(
              children: [
                _SkeletonBox(width: 120, height: 32),
                const Spacer(),
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
  final VoidCallback onFree, onGuided, onVoice;
  @override
  Widget build(BuildContext context) => WellnessSheet(
    title: 'Start a journal entry',
    children: [
      const Text('Choose how you want to capture your thoughts.'),
      WellnessSheetOption(
        label: 'Write freely',
        subtitle: 'Start a blank entry and write your thoughts.',
        icon: Icons.edit_outlined,
        onPressed: onFree,
      ),
      WellnessSheetOption(
        label: 'Write with a prompt',
        subtitle: 'Choose a question to help you get started.',
        icon: Icons.quiz_outlined,
        onPressed: onGuided,
      ),
      WellnessSheetOption(
        label: 'Record a voice note',
        subtitle: 'Record your thoughts using your microphone.',
        icon: Icons.mic_none_outlined,
        onPressed: onVoice,
      ),
    ],
  );
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
                : dividerColor ?? Theme.of(context).colorScheme.outlineVariant,
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
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
  final VoidCallback onEdit, onShare, onAddTag, onDelete;
  @override
  Widget build(BuildContext context) => WellnessSheet(
    title: 'Entry actions',
    children: [
      WellnessSheetOption(
        label: 'Edit entry',
        subtitle: 'Change this entry.',
        icon: Icons.edit_outlined,
        onPressed: onEdit,
      ),
      WellnessSheetOption(
        label: 'Add a tag',
        subtitle: 'Add a label to help find this entry later.',
        icon: Icons.sell_outlined,
        onPressed: onAddTag,
      ),
      WellnessSheetOption(
        label: 'Share with provider',
        subtitle: 'Send a reviewed copy to a provider you choose.',
        icon: Icons.ios_share_outlined,
        onPressed: onShare,
      ),
      WellnessSheetOption(
        label: 'Delete entry',
        subtitle: 'Remove this entry from your journal.',
        icon: Icons.delete_outline,
        destructive: true,
        onPressed: onDelete,
      ),
    ],
  );
}

class _DeleteConfirmation extends StatelessWidget {
  const _DeleteConfirmation({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
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

class _AddTagSheet extends StatelessWidget {
  const _AddTagSheet({required this.controller, required this.onAdd});
  final TextEditingController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => WellnessSheet(
    title: 'Add a tag',
    children: [
      const Text('Add a label to help find this entry later.'),
      TextField(
        key: const ValueKey('journal-tag-input'),
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Tag name',
          hintText: 'e.g. Reflection',
        ),
      ),
      WellnessAction(
        label: 'Save tag',
        icon: Icons.sell_outlined,
        onPressed: onAdd,
      ),
    ],
  );
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
              border: AppSurface.border(context),
              color: AppSurface.tint(context, AppColors.primarySubtle),
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
                Text('$wordCount words', style: _captionStyle(context)),
                Spacer(),
                Text(status, style: _captionStyle(context)),
              ],
            ),
          ),
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Material(
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
            shape: AppSurface.shape(context, BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(20 + AppSurface.side(context).width),
              child: child,
            ),
          ),
        ),
      ),
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
            color: Theme.of(context).colorScheme.outline,
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
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color != null && color!.a < 1
            ? AppSurface.tint(context, color!)
            : color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(
          AppSurface.side(context, color: borderColor),
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
    return SkeletonLoader(width: width, height: height, radius: radius);
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(width: size, height: size, radius: size / 2);
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

TextStyle _captionStyle(BuildContext context) => AppTextStyles.body2.copyWith(
  color: Theme.of(context).colorScheme.onSurfaceVariant,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

InputDecoration _inputDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body1.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainer,
    contentPadding: EdgeInsets.all(16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
