import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _selectedTheme = 'System';
  Color _selectedAccent = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      setState(() {
        final theme = profile.theme;
        final safeTheme = theme.isEmpty ? 'system' : theme;

        // Theme: Capitalize first letter
        _selectedTheme =
            safeTheme[0].toUpperCase() + safeTheme.substring(1);

        // Accent Color
        if (profile.accentColor != 'lavender' &&
            int.tryParse(profile.accentColor) != null) {
          _selectedAccent = Color(int.parse(profile.accentColor));
        }
      });
    }
  }

  void _updateTheme(String theme) {
    setState(() => _selectedTheme = theme);
    ProfileRepository().updateField('theme', theme.toLowerCase());
  }

  void _updateAccent(Color color) {
    setState(() => _selectedAccent = color);
    ProfileRepository().updateField('accentColor', color.value.toString());
  }

  final List<String> _themes = ['Light', 'Dark', 'System'];
  final List<Color> _accents = [
    AppColors.primary,
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF97316), // Orange
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Appearance',
          style: AppTextStyles.heading2.copyWith(color: colorScheme.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              // Live Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dividerColor ?? AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedAccent.withValues(alpha: 0.2),
                          ),
                          child: Icon(Icons.check, color: _selectedAccent),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 8,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Button',
                            style: AppTextStyles.body2.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              Text(
                'Theme',
                style: AppTextStyles.body1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dividerColor ?? AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: List.generate(_themes.length, (index) {
                    final theme = _themes[index];
                    final isSelected = theme == _selectedTheme;
                    return InkWell(
                      onTap: () => _updateTheme(theme),
                      child: Column(
                        children: [
                          Semantics(
                            selected: isSelected,
                            label: '$theme theme',
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      theme,
                                      style: AppTextStyles.body1.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check, color: _selectedAccent),
                                ],
                              ),
                            ),
                          ),
                          if (index < _themes.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: (dividerColor ?? AppColors.border)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 32),

              Text(
                'Accent Color',
                style: AppTextStyles.body1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _accents.map((color) {
                  final isSelected = color == _selectedAccent;
                  return Semantics(
                    selected: isSelected,
                    button: true,
                    label: 'Accent color swatch',
                    child: GestureDetector(
                      onTap: () => _updateAccent(color),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme.onSurface,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: AppColors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
