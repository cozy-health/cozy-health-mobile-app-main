import 'package:flutter/material.dart';

/// Explicit, consent-filtered record presentation. Timestamps and internal IDs
/// never become display fields, including in previews and shared history.
class SharedRecordCard extends StatefulWidget {
  const SharedRecordCard({
    super.key,
    required this.record,
    this.preview = false,
  });

  final Map<String, dynamic> record;
  final bool preview;

  @override
  State<SharedRecordCard> createState() => _SharedRecordCardState();
}

class _SharedRecordCardState extends State<SharedRecordCard> {
  bool _expanded = false;

  String _humanize(Object? value) {
    final text =
        value?.toString().trim().replaceAll(RegExp(r'[_-]+'), ' ') ?? '';
    return text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final data = Map<String, dynamic>.from(record['data'] as Map? ?? {});
    final owner = Map<String, dynamic>.from(record['owner'] as Map? ?? {});
    final ownerName = owner['name']?.toString().trim() ?? '';
    final unavailable = record['unavailable'] == true;
    final type = record['type']?.toString() ?? '';
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (label, icon, accent) = switch (type) {
      'moods' => (
        'Mood check-in',
        Icons.favorite_border_rounded,
        const Color(0xFF00BC4C),
      ),
      'journals' => (
        'Journal summary',
        Icons.auto_stories_outlined,
        const Color(0xFF0460D8),
      ),
      'quizzes' => (
        'Assessment result',
        Icons.fact_check_outlined,
        const Color(0xFFF25C05),
      ),
      'notes' => ('Care note', Icons.notes_outlined, const Color(0xFFF2CB05)),
      _ => ('Shared record', Icons.description_outlined, colors.primary),
    };
    var title = label;
    String? body;
    final highlights = <String>[];
    if (unavailable) {
      title = 'Record unavailable';
      body = 'Access has changed or this record was removed.';
    } else {
      switch (type) {
        case 'moods':
          final mood = _humanize(data['mood']);
          title = mood.isEmpty
              ? 'A moment to check in'
              : 'Feeling ${mood.toLowerCase()}';
          if (data['intensity'] != null) {
            highlights.add('Intensity ${data['intensity']}');
          }
          body = data['note']?.toString();
        case 'journals':
          title = data['title']?.toString().trim() ?? '';
          if (title.isEmpty) title = 'Untitled journal';
          highlights.add(
            data['type'] == 'voice' ? 'Voice journal' : 'Written journal',
          );
          if (data['word_count'] != null) {
            highlights.add(
              '${data['word_count']} ${data['word_count'] == 1 ? 'word' : 'words'}',
            );
          }
          body = 'A journal summary shared with your provider.';
        case 'quizzes':
          title = data['quiz_title']?.toString().trim() ?? '';
          if (title.isEmpty) {
            title =
                data['quiz_slug']
                    ?.toString()
                    .replaceAll('-', ' ')
                    .toUpperCase() ??
                'Assessment';
          }
          if (data['score'] != null) {
            highlights.add(
              'Score ${data['score']}${data['maximum_score'] == null ? '' : ' / ${data['maximum_score']}'}',
            );
          }
          body = _humanize(data['interpretation']);
        case 'notes':
          title = 'A note for your care';
          body = data['body']?.toString();
      }
    }
    final content = body?.trim() ?? '';
    final longContent =
        content.length > 180 || '\n'.allMatches(content).length > 3;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  unavailable ? Icons.lock_outline : icon,
                  color: unavailable ? colors.onSurfaceVariant : accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.preview ? 'Preview' : 'Shared',
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: highlights
                  .map(
                    (value) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        value,
                        style: text.labelMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              maxLines: _expanded || !longContent ? null : 4,
              overflow: _expanded || !longContent
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (longContent)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(
                  owner['initials']?.toString() ??
                      (ownerName.isEmpty
                          ? 'P'
                          : ownerName.characters.first.toUpperCase()),
                  style: text.labelMedium,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName.isEmpty
                          ? 'Shared by patient'
                          : '${widget.preview ? 'Sharing as' : 'Shared by'} $ownerName',
                      style: text.labelLarge?.copyWith(color: colors.onSurface),
                    ),
                    Text(
                      'Cozy Health',
                      style: text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
