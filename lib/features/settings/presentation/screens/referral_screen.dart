import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/wellness_panel.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key, this.share});
  final Future<void> Function(ShareParams)? share;
  static const invitationUrl = ApiConstants.environment == 'production'
      ? 'https://cozyhealth.org'
      : 'https://dev.cozyhealth.org';
  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _sharing = false;
  String? _error;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(
        const ClipboardData(text: ReferralScreen.invitationUrl),
      );
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(content: const Text('Link copied')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy the link. Please retry.');
      }
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      final box = context.findRenderObject() as RenderBox?;
      final params = ShareParams(
        text:
            'Take a moment for your wellbeing with Cozy Health. Explore it here: ${ReferralScreen.invitationUrl}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      if (widget.share != null) {
        await widget.share!(params);
      } else {
        await SharePlus.instance.share(params);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Sharing is unavailable. Copy the link and send it to your friend.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite a friend'),
        leading: AppPressable(
          label: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRouter.settings),
          child: SizedBox(
            width: w.touch,
            height: w.touch,
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(w.page),
          children: [
            const Text(
              'If Cozy Health has helped you, share it with someone who might need it.',
            ),
            SizedBox(height: w.gap),
            const WellnessPanel(
              child: SelectableText(ReferralScreen.invitationUrl),
            ),
            SizedBox(height: w.gap),
            WellnessAction(
              key: const ValueKey('invite-share'),
              label: _sharing ? 'Opening sharing…' : 'Share link',
              icon: Icons.share_outlined,
              filled: true,
              onPressed: _sharing ? null : _share,
            ),
            SizedBox(height: w.contentGap),
            WellnessAction(
              key: const ValueKey('invite-copy'),
              label: 'Copy link',
              icon: Icons.copy_outlined,
              onPressed: _copy,
            ),
            if (_error != null) ...[
              SizedBox(height: w.contentGap),
              Semantics(liveRegion: true, child: Text(_error!)),
            ],
          ],
        ),
      ),
    );
  }
}
