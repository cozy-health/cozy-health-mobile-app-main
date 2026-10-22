import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/cozy_colors.dart';
import '../utils/motion.dart';
import 'app_pressable.dart';
import '../theme/app_text_styles.dart';
import '../../gen/assets.gen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final GlobalKey? assistantTourKey;
  final bool showAssistant;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.assistantTourKey,
    this.showAssistant = true,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  final _selectedKey = GlobalKey();
  @override
  void didUpdateWidget(covariant CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) _revealSelection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revealSelection();
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedKey.currentContext;
      if (!mounted || selectedContext == null) return;
      Scrollable.ensureVisible(
        selectedContext,
        alignment: .5,
        duration: motionDuration(context, const Duration(milliseconds: 200)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Container(
      decoration: BoxDecoration(
        color: navTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: (dividerColor ?? AppColors.border).withValues(alpha: .4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height:
              72 +
              (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(
                    0,
                    double.infinity,
                  ) *
                  2,
          child: LayoutBuilder(
            builder: (context, box) {
              final labels = [
                'Home',
                'Activity',
                if (widget.showAssistant) 'Provider',
                'Community',
                'Settings',
              ];
              final widths = <double>[];
              for (final label in labels) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: label,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                widths.add((painter.width + 24).clamp(64, double.infinity));
                painter.dispose();
              }
              final total = widths.fold<double>(0, (a, b) => a + b);
              final extra = total < box.maxWidth
                  ? (box.maxWidth - total) / widths.length
                  : 0.0;
              final indices = [0, 1, if (widget.showAssistant) 2, 3, 4];
              final assets = [
                Assets.svg.home,
                Assets.svg.activity,
                if (widget.showAssistant) Assets.svg.community,
                Assets.svg.community,
                Assets.svg.settings,
              ];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      SizedBox(
                        width: widths[i] + extra,
                        key: indices[i] == widget.currentIndex
                            ? _selectedKey
                            : null,
                        child: _buildNavItem(
                          context,
                          indices[i],
                          labels[i],
                          assets[i],
                          icon: indices[i] == 2
                              ? Icons.medical_services_outlined
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    String assetPath, {
    IconData? icon,
  }) {
    final isSelected = widget.currentIndex == index;
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final scheme = Theme.of(context).colorScheme;
    final selectedColor = context.cozyColors.recording.controlColor(
      navTheme.selectedItemColor ?? scheme.primary,
      navTheme.backgroundColor ?? scheme.surface,
      scheme.onSurface,
    );
    final unselectedColor =
        navTheme.unselectedItemColor ?? Theme.of(context).colorScheme.onSurface;

    return AppPressable(
      key: index == 2 ? widget.assistantTourKey : null,
      selected: isSelected,
      label: label,
      onPressed: () => widget.onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: motionDuration(
                context,
                const Duration(milliseconds: 200),
              ),
              width: 42,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withValues(alpha: .12) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 24,
                        color: isSelected ? selectedColor : unselectedColor,
                      )
                    : SvgPicture.asset(
                        assetPath,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          isSelected ? selectedColor : unselectedColor,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
