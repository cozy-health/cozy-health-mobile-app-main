import '../../../../core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});
  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  final _generation = TokenStorage.generation;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
  }

  Future<void> _offer() async {
    await showWellnessDialog<void>(
      context: context,
      dismissible: false,
      builder: (context) => WellnessSheet(
        title: 'You are ready to begin',
        busy: true,
        children: [
          const Icon(Icons.check_circle_outline),
          const Text('Your account has been created.'),
          WellnessAction(
            label: 'Continue',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (!mounted || _generation != TokenStorage.generation) return;
    final personalized = await PersonalizationService()
        .hasCompletedPersonalization();
    if (mounted && _generation == TokenStorage.generation) {
      context.go(personalized ? AppRouter.home : AppRouter.personalization);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
