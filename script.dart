import 'dart:io';

void main() {
  final file = File('lib/features/assistant/presentation/screens/assistant_screen.dart');
  final lines = file.readAsLinesSync();
  
  List<int>? findClassRange(String className) {
    int start = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('class $className ') || lines[i].startsWith('class $className{') || lines[i].startsWith('class $className extends') || lines[i].startsWith('class $className implements')) {
        start = i;
        break;
      }
    }
    if (start == -1) return null;
    
    int braces = 0;
    int end = -1;
    bool foundOpen = false;
    for (int i = start; i < lines.length; i++) {
      if (lines[i].contains('{')) {
        braces += '{'.allMatches(lines[i]).length;
        foundOpen = true;
      }
      if (lines[i].contains('}')) {
        braces -= '}'.allMatches(lines[i]).length;
      }
      if (foundOpen && braces == 0) {
        end = i;
        break;
      }
    }
    return [start, end];
  }

  void extractTo(String targetFile, List<String> classes) {
    List<String> output = [
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/services.dart';",
      "import 'package:go_router/go_router.dart';",
      "import '../../../../core/routing/app_router.dart';",
      "import '../../../../core/theme/app_colors.dart';",
      "import '../../../../core/theme/app_text_styles.dart';",
      "import '../../models/chat.dart';",
      ""
    ];
    for (var c in classes) {
      final range = findClassRange(c);
      if (range != null) {
        final classLines = lines.sublist(range[0], range[1] + 1);
        output.addAll(classLines);
        output.add('');
      }
    }
    File('lib/features/assistant/presentation/widgets/$targetFile').writeAsStringSync(output.join('\n'));
  }

  extractTo('message_bubble.dart', ['_MessageBubble']);
  extractTo('typing_indicator.dart', ['_TypingIndicatorBubble', '_TypingIndicatorBubbleState']);
  extractTo('chat_app_bar.dart', ['_ChatTopBar']);
  extractTo('chat_input_bar.dart', ['_ChatInputBar']);
  extractTo('conversation_list_view.dart', [
    'ConversationHistoryScreen', '_ConversationHistoryScreenState', 
    'PastConversationScreen', '_HistorySection', '_ConversationCard', 
    '_ConversationEmptyState', '_DeleteConversationDialog'
  ]);
  extractTo('chat_settings_view.dart', [
    'ChatSettingsScreen', '_ChatSettingsScreenState', '_SettingsSection', 
    '_SettingRow', '_SettingSwitch'
  ]);
  extractTo('chat_shared_widgets.dart', [
    '_AssistantSubScaffold', '_MenuSheet', '_SheetTile', '_CozyCharacter', 
    '_CozyCharacterState', '_WarmPanel', '_PrimaryButton', '_SecondaryButton', 
    '_AnimatedIn', '_InlineSuggestions', '_PromptButton'
  ]);

  // Now, collect all lines to REMOVE from assistant_screen.dart
  final toRemove = <int>{};
  final allClasses = [
    'ConversationHistoryScreen', '_ConversationHistoryScreenState', 'PastConversationScreen',
    'ChatSettingsScreen', '_ChatSettingsScreenState', '_ChatTopBar', '_ChatInputBar',
    '_MessageBubble', '_TypingIndicatorBubble', '_TypingIndicatorBubbleState',
    '_InlineSuggestions', '_PromptButton', '_HistorySection', '_ConversationCard',
    '_ConversationEmptyState', '_AssistantSubScaffold', '_SettingsSection',
    '_SettingRow', '_SettingSwitch', '_MenuSheet', '_SheetTile', '_DeleteConversationDialog',
    '_CozyCharacter', '_CozyCharacterState', '_WarmPanel', '_PrimaryButton',
    '_SecondaryButton', '_AnimatedIn'
  ];

  for (var c in allClasses) {
    final range = findClassRange(c);
    if (range != null) {
      for (int i = range[0]; i <= range[1]; i++) {
        toRemove.add(i);
      }
    }
  }

  // Remove lines and save
  List<String> newLines = [];
  for (int i = 0; i < lines.length; i++) {
    if (!toRemove.contains(i)) {
      newLines.add(lines[i]);
    }
  }
  file.writeAsStringSync(newLines.join('\n'));
}
