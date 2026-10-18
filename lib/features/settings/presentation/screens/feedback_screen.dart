import 'package:flutter/material.dart';
import 'report_problem_screen.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportProblemScreen(feedback: true);
}
