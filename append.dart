import 'dart:io';

void main() {
  final file = File('lib/features/assistant/presentation/widgets/chat_shared_widgets.dart');
  file.writeAsStringSync('''

TextStyle timestampStyle() => AppTextStyles.body2.copyWith(
  color: AppColors.textSubtle,
  fontSize: 11,
  fontWeight: FontWeight.w500,
);

String formatTime(DateTime date) {
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '\$hour:\$minute \$suffix';
}
''', mode: FileMode.append);
}
