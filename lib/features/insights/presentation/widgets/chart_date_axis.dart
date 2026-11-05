import 'package:flutter/material.dart';

/// A bounded set of evenly spaced ticks; the data table retains every date.
class ChartDateAxis extends StatelessWidget {
  const ChartDateAxis({super.key, required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = MediaQuery.textScalerOf(context).scale(48);
        final count = (constraints.maxWidth / labelWidth).floor().clamp(
          1,
          days.length,
        );
        return Row(
          children: [
            for (var tick = 0; tick < count; tick++)
              Expanded(
                child: Text(
                  days[count == 1
                      ? 0
                      : (tick * (days.length - 1) / (count - 1)).round()],
                  textAlign: count == 1 || tick == 0
                      ? TextAlign.left
                      : tick == count - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
