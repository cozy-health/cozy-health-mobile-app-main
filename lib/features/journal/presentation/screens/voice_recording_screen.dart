import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/audio/audio_recorder_service.dart';
import '../../../../core/permissions/permission_service.dart';
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
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  String? _recordingPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

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
              onTap: () async {
                if (isRecording) {
                  final path = await _audioRecorder.stop();
                  if (!context.mounted) return;
                  if (path == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Couldn't save recording. Try again?"),
                      ),
                    );
                  }
                  setState(() {
                    isRecording = false;
                    _recordingPath = path;
                  });
                  return;
                }
                final result = await PermissionService.requestMicrophone();
                if (!context.mounted) return;
                if (result == MicPermissionResult.granted) {
                  try {
                    await _audioRecorder.start();
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Couldn't save recording. Try again?"),
                      ),
                    );
                    return;
                  }
                  setState(() => isRecording = true);
                } else if (result == MicPermissionResult.permanentlyDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Microphone access is needed to record.'),
                      action: SnackBarAction(
                        label: 'Open Settings',
                        onPressed: PermissionService.openAppSettings,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Microphone access is needed to record.'),
                    ),
                  );
                }
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
                      if (_recordingPath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Couldn't save recording. Try again?"),
                          ),
                        );
                        return;
                      }
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
