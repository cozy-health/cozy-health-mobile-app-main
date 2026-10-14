# Overlay call-site inventory

Generated 2026-10-10. Every direct showDialog/showModalBottomSheet/showMenu/showGeneralDialog/showBottomSheet call in lib is listed with opening arguments. Indirect/custom overlays and snackbar sites are listed separately below or in full-app-notices.md. Absence of animationStyle in this excerpt alone is a review cue, not proof of a motion defect.

## lib/core/security_gate.dart:244

```dart
  return await showDialog<bool>(
        context: context,
        animationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (_) => _PinDialog(setup: setup),
      ) ??
      false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.setup});
  final bool setup;
```

## lib/core/widgets/consent_gate.dart:75

```dart
    await showDialog<void>(
      context: context,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => AlertDialog(
        title: Text(doc.title),
        content: SingleChildScrollView(
          child: Text(
            doc.reviewable
                ? doc.content!
                : 'This document is still a draft. We will notify you when the approved text is published.',
          ),
```

## lib/core/widgets/sync_queue_badge.dart:18

```dart
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
              ? AnimationStyle.noAnimation
              : null,
          isScrollControlled: true,
          builder: (_) => const _QueueSheet(),
        ),
      );
    },
  );
}

```

## lib/features/assistant/presentation/screens/assistant_screen.dart:446

```dart
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
```

## lib/features/assistant/presentation/screens/assistant_screen.dart:494

```dart
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
              AppSnackbar.show(
                context,
```

## lib/features/assistant/presentation/widgets/chat_settings_view.dart:104

```dart
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuSheet(
        children: ['Warm', 'Neutral', 'Direct']
            .map(
              (tone) => SheetTile(
                icon: tone == _tone
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                label: tone,
                onTap: () {
                  setState(() => _tone = tone);
```

## lib/features/assistant/presentation/widgets/conversation_list_view.dart:94

```dart
    showDialog<void>(
      context: context,
      builder: (context) => DeleteConversationDialog(
        onDelete: () async {
          Navigator.pop(context);
          final index = _conversations.indexWhere(
            (item) => item.id == conversation.id,
          );
          if (index == -1) return;

          final repo = ChatRepository();
          await repo.deleteConversation(conversation.id);

```

## lib/features/auth/presentation/widgets/sign_up_form.dart:98

```dart
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Terms and Conditions', style: AppTextStyles.heading2),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.grey),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
```

## lib/features/community/presentation/screens/community_hub_screen.dart:76

```dart
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
```

## lib/features/community/presentation/screens/direct_messages_screen.dart:48

```dart
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
```

## lib/features/community/presentation/screens/user_profile_screen.dart:39

```dart
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
```

## lib/features/community/presentation/widgets/post_actions.dart:9

```dart
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy post'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Clipboard.setData(
                  ClipboardData(text: post['content'] as String? ?? ''),
```

## lib/features/community/presentation/widgets/report_sheet.dart:11

```dart
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ReportSheet(onSubmit: onSubmit),
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
```

## lib/features/community/presentation/widgets/visibility_sheet.dart:20

```dart
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VisibilitySheet(
        currentVisibility: currentVisibility,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:493

```dart
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:597

```dart
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:782

```dart
    () => showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:1156

```dart
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:1206

```dart
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Start over?',
            style: CrisisText.h2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This will clear your current safety plan draft.',
            style: CrisisText.bodyMuted.copyWith(
```

## lib/features/crisis/presentation/screens/crisis_screens.dart:2065

```dart
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
```

## lib/features/crisis/presentation/widgets/crisis_fab.dart:59

```dart
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        void open(String route) {
          Navigator.of(sheetContext).pop();
          router.push(route);
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
```

## lib/features/home/presentation/screens/main_screen.dart:105

```dart
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
```

## lib/features/home/presentation/widgets/feature_tour.dart:48

```dart
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Want a quick look around?'),
          content: const Text(
            'A short tour can help you find your way. You can skip it anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            FilledButton(
```

Additional framework/custom overlay reference: [lib/features/home/presentation/widgets/feature_tour.dart:231](../../lib/features/home/presentation/widgets/feature_tour.dart) - `_tour?.removeOverlayEntry();`

Additional framework/custom overlay reference: [lib/features/journal/presentation/screens/journal_screen.dart:77](../../lib/features/journal/presentation/screens/journal_screen.dart) - `PopupMenuButton<String>(`

## lib/features/journal/presentation/screens/journal_screen.dart:372

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:397

```dart
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
          AppSnackbar.show(
            context,
            AppSnackbar.fromLegacy(
```

## lib/features/journal/presentation/screens/journal_screen.dart:427

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:455

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:495

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:747

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:1233

```dart
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
```

## lib/features/journal/presentation/screens/journal_screen.dart:1420

```dart
        onPressed: () => _showMenu(context),
        icon: const Icon(Icons.more_horiz),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Text(_detailDate(entry.createdAt), style: _captionStyle(context)),
          if (mood != null) ...[
            const SizedBox(height: 12),
            Text(
              '${mood.emoji} ${mood.mood} | Intensity ${mood.intensity}/10',
              style: _captionStyle(context),
            ),
```

## lib/features/journal/presentation/screens/journal_screen.dart:1501

```dart
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
          AppSnackbar.show(
            context,
```

## lib/features/journal/presentation/screens/journal_screen.dart:1502

```dart
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
          AppSnackbar.show(
            context,
            AppSnackbar.fromLegacy(
```

## lib/features/mood_check_in/presentation/screens/mood_feeling_screen.dart:310

```dart
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Discard this entry?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
```

## lib/features/notifications/presentation/screens/notifications_screen.dart:213

```dart
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
```

## lib/features/notifications/presentation/widgets/notification_denied_sheet.dart:10

```dart
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationDeniedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
```

## lib/features/notifications/presentation/widgets/notification_permission_sheet.dart:10

```dart
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationPermissionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
```

## lib/features/quiz/presentation/widgets/clinical_disclaimer_sheet.dart:11

```dart
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ClinicalDisclaimerSheet(),
    );
    if (accepted == true) await settings.put(acknowledgementKey, true);
    return accepted;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
```

## lib/features/quiz/presentation/widgets/provider_share_confirm_dialog.dart:15

```dart
  }) => showDialog<bool>(
    context: context,
    builder: (_) => ProviderShareConfirmDialog(providerName: providerName),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Share assessment results?'),
    content: SingleChildScrollView(
      child: Text(
        'Allow $providerName to see your assessment totals, severity labels and completion dates? This includes past and future results. Individual answers are not shared. You can turn sharing off in Settings.',
      ),
    ),
    actions: [
```

## lib/features/quiz/presentation/widgets/quiz_back_confirm_dialog.dart:10

```dart
    return showDialog<bool>(
      context: context,
      builder: (context) => const QuizBackConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Leave the quiz?', style: AppTextStyles.heading2),
      content: Text(
```

## lib/features/quiz/presentation/widgets/quiz_retake_confirm_dialog.dart:9

```dart
    return showDialog<String>(
      context: context,
      builder: (context) => const QuizRetakeConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Retake quiz?', style: AppTextStyles.heading2),
      content: Text(
```

## lib/features/quiz/presentation/widgets/quiz_support_sheet.dart:7

```dart
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const QuizSupportSheet(),
  );
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
```

Additional framework/custom overlay reference: [lib/features/settings/presentation/screens/about_screen.dart:190](../../lib/features/settings/presentation/screens/about_screen.dart) - `showLicensePage(`

## lib/features/settings/presentation/screens/about_screen.dart:248

```dart
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
```

## lib/features/settings/presentation/screens/active_sessions_screen.dart:79

```dart
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out all devices?'),
        content: const Text(
          'This includes this device. You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
```

## lib/features/settings/presentation/screens/blocked_users_screen.dart:39

```dart
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Unblock @$username?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
```

## lib/features/settings/presentation/screens/cancel_subscription_screen.dart:68

```dart
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Subscription?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
```

## lib/features/settings/presentation/screens/connected_apps_screen.dart:35

```dart
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Disconnect $app?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
```

Additional framework/custom overlay reference: [lib/features/settings/presentation/screens/legal_hub_screen.dart:115](../../lib/features/settings/presentation/screens/legal_hub_screen.dart) - `showLicensePage(`

## lib/features/settings/presentation/screens/provider_screen.dart:303

```dart
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke provider access?'),
        content: const Text(
          'Your provider will lose access to your shared data and cannot add notes. You can reconnect later; all sharing choices will start off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
```

## lib/features/settings/presentation/screens/settings_screen.dart:340

```dart
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          backgroundColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Log out?',
                            style: AppTextStyles.heading2.copyWith(
                              color: colorScheme.onSurface,
                            ),
```

## lib/features/settings/presentation/screens/two_factor_auth_screen.dart:436

```dart
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Disable 2FA?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
```
