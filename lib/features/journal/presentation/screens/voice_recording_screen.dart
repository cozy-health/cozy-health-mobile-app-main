import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  bool isRecording = false;
  String recordingTime = "00:03:54"; // Example time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Voice Journal', style: AppTextStyles.heading2),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          children: [
            8.sh,

            // Recording time
            Text(
              recordingTime,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),

            10.sh,

            // Audio Waveform
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(40, (index) {
                  final height = (20 + (index % 5) * 8).toDouble();
                  final isActive = index % 3 != 0; // Simulate active waveform
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: 4,
                      height: isActive ? height : 8,
                      decoration: BoxDecoration(
                        color: isActive ? Theme.of(context).colorScheme.primary : AppColors.midGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            4.sh,

            // Subtitle
            Text(
              'Recording in progress...',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey),
            ),

            const Spacer(),

            // Record / Stop Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isRecording = !isRecording;
                });
                // In real app, start/stop audio recording here
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                      borderRadius: isRecording
                          ? BorderRadius.circular(4)
                          : BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

            8.sh,

            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecording)
                  TextButton.icon(
                    onPressed: () {
                      // Cancel recording
                      context.pop();
                    },
                    icon: Icon(Icons.close, color: Colors.red),
                    label: Text(
                      'Cancel',
                      style: AppTextStyles.body1.copyWith(color: Colors.red),
                    ),
                  ),
                if (!isRecording)
                  TextButton.icon(
                    onPressed: () {
                      // Save and go back
                      context.pop();
                    },
                    icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                    label: Text(
                      'Save Recording',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            6.sh,
          ],
        ),
      ),
    );
  }
}
