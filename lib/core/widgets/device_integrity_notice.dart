import 'package:flutter/material.dart';
import '../services/device_integrity_service.dart';

class DeviceIntegrityNotice extends StatefulWidget {
  const DeviceIntegrityNotice({super.key, required this.child, this.service});
  final Widget child;
  final DeviceIntegrityService? service;
  @override
  State<DeviceIntegrityNotice> createState() => _DeviceIntegrityNoticeState();
}

class _DeviceIntegrityNoticeState extends State<DeviceIntegrityNotice> {
  late final _service = widget.service ?? DeviceIntegrityService.instance;
  bool _dismissed = false;
  @override
  void initState() {
    super.initState();
    _service.check();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _service,
    builder: (context, _) => Stack(
      children: [
        widget.child,
        if (_service.warning && !_dismissed)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: MaterialBanner(
                content: const Text(
                  'This device may be rooted or jailbroken. Your information may be less protected. You can continue.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _dismissed = true),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
