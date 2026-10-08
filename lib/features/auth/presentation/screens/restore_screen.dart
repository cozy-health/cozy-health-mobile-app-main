import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/restore_service.dart';
import '../../../../core/widgets/app_button.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key, this.controller});
  final RestoreController? controller;
  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  RestoreController? _controller;
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final settings = await LocalDbService().settingsBox();
    if (!mounted) return;
    final userId = settings.get('device_user_id')?.toString();
    if (widget.controller == null && userId == null) {
      context.go(AppRouter.login);
      return;
    }
    _controller = widget.controller ?? RestoreController(userId: userId!);
    _controller!.addListener(_update);
    setState(() {});
    unawaited(_controller!.run());
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _cancel() async {
    await _controller?.cancel();
    if (mounted) context.go(AppRouter.login);
  }

  Future<void> _continue({bool partial = false}) async {
    await _controller!.finish(acceptPartial: partial);
    if (mounted) context.go(AppRouter.home);
  }

  @override
  void dispose() {
    _controller?.removeListener(_update);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome back'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.cloud_download_outlined, size: 80),
              const SizedBox(height: 24),
              Text(
                'Restoring your data... ${controller?.restored ?? 0} items',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(value: controller?.progress ?? 0),
              const SizedBox(height: 16),
              if (controller == null || controller.busy)
                Text(controller?.current ?? 'Getting ready'),
              if (controller != null && !controller.busy) ...[
                if (controller.failed.isNotEmpty) ...[
                  Text(
                    "Some items couldn't be restored. Restored ${controller.restored} items. Tap to retry the rest.",
                  ),
                  const SizedBox(height: 12),
                  Text(controller.failed.join(', ')),
                  AppButton(
                    text: 'Retry',
                    onPressed: () => controller.run(retryOnly: true),
                  ),
                ],
                if (controller.unavailable.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Saved articles and standalone emergency contacts are not available to download yet. Contacts included in your safety plan are restored with it.',
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: controller.failed.isEmpty
                      ? 'Continue to Home'
                      : 'Continue with restored data',
                  onPressed: () =>
                      _continue(partial: controller.failed.isNotEmpty),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(onPressed: _cancel, child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
