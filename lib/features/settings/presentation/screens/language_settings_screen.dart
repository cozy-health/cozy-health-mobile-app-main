import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';
  final Map<String, String> _languageMap = {
    'en': 'English',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'ja': '日本語 (Japanese)',
    'ko': '한국어 (Korean)',
  };

  @override
  void initState() {
    super.initState();
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _selectedLanguage = 'English';
    }
  }

  final List<String> _languages = ['English'];

  void _onLanguageSelected(String lang) {
    setState(() => _selectedLanguage = lang);
    final key = _languageMap.entries
        .firstWhere(
          (e) => e.value == lang,
          orElse: () => const MapEntry('en', 'English'),
        )
        .key;
    ProfileRepository().updateField('language', key);

    AppSnackbar.show(
      context,
      AppSnackbar.fromLegacy(
        content: Text('English is the currently supported interface language.'),
      ),
    );
  }

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
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Language',
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
              Material(
                color: Theme.of(context).colorScheme.surface,
                shape: AppSurface.shape(context, BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(_languages.length, (index) {
                    final lang = _languages[index];
                    final isSelected = lang == _selectedLanguage;
                    return InkWell(
                      onTap: () => _onLanguageSelected(lang),
                      child: Column(
                        children: [
                          Semantics(
                            selected: isSelected,
                            label: lang,
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lang,
                                      style: AppTextStyles.body1.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (index < _languages.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
