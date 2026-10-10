import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class DataTableView extends StatelessWidget {
  final String title;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const DataTableView({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                dataTextStyle: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
