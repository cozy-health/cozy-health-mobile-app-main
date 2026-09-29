import 'dart:io';

void main() {
  final dir1 = Directory('lib/features/assistant/presentation/widgets');
  final file2 = File('lib/features/assistant/presentation/screens/assistant_screen.dart');
  
  final toReplace = {
    '_ChatTopBar': 'ChatTopBar',
    '_ChatInputBar': 'ChatInputBar',
    '_MessageBubble': 'MessageBubble',
    '_TypingIndicatorBubble': 'TypingIndicatorBubble',
    '_InlineSuggestions': 'InlineSuggestions',
    '_PromptButton': 'PromptButton',
    '_HistorySection': 'HistorySection',
    '_ConversationCard': 'ConversationCard',
    '_ConversationEmptyState': 'ConversationEmptyState',
    '_AssistantSubScaffold': 'AssistantSubScaffold',
    '_SettingsSection': 'SettingsSection',
    '_SettingRow': 'SettingRow',
    '_SettingSwitch': 'SettingSwitch',
    '_MenuSheet': 'MenuSheet',
    '_SheetTile': 'SheetTile',
    '_DeleteConversationDialog': 'DeleteConversationDialog',
    '_CozyCharacter': 'CozyCharacter',
    '_WarmPanel': 'WarmPanel',
    '_PrimaryButton': 'PrimaryButton',
    '_SecondaryButton': 'SecondaryButton',
    '_AnimatedIn': 'AnimatedIn',
    '_timestampStyle': 'timestampStyle',
    '_formatTime': 'formatTime'
  };

  void processFile(File f) {
    if (!f.existsSync()) return;
    String content = f.readAsStringSync();
    
    // Add import to chat_shared_widgets.dart if missing in other widget files
    if (f.path.contains('widgets') && !f.path.contains('chat_shared_widgets.dart')) {
       if (!content.contains("import 'chat_shared_widgets.dart';")) {
           content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'chat_shared_widgets.dart';");
       }
    }

    toReplace.forEach((key, value) {
      // replace with word boundaries to avoid replacing e.g. _MessageBubbleState partially if we only replace _MessageBubble
      // actually dart string replaceAll is fine because we are replacing the exact string
      content = content.replaceAll(key, value);
    });
    f.writeAsStringSync(content);
  }

  for (final f in dir1.listSync()) {
    if (f is File && f.path.endsWith('.dart')) {
      processFile(f);
    }
  }
  processFile(file2);
}
