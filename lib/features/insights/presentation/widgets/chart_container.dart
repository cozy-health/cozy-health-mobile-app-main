import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'data_table_view.dart';

class ChartContainer extends StatelessWidget {
  final Widget chart;
  final double height;
  final String? title;
  final Widget? legend;
  final String accessibleLabel;
  final List<DataRow> tableRows;
  final List<DataColumn> tableColumns;

  const ChartContainer({
    super.key,
    required this.chart,
    this.height = 240,
    this.title,
    this.legend,
    required this.accessibleLabel,
    required this.tableRows,
    required this.tableColumns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: accessibleLabel,
            child: Container(
              padding: const EdgeInsets.all(16),
              height: height,
              child: chart,
            ),
          ),
          if (legend != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: legend!,
            ),
          const Divider(height: 1),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DataTableView(
                      title: title ?? 'Data table',
                      columns: tableColumns,
                      rows: tableRows,
                    ),
                  ),
                );
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Read as table',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
