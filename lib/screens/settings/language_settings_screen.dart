import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/language_provider.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final currentCode = langProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('selectLanguage')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _LanguageTile(
                  title: 'English',
                  subtitle: 'English',
                  isSelected: currentCode == 'en',
                  onTap: () {
                    if (currentCode != 'en') {
                      langProvider.toggleLanguage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.translate('languageChanged')),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                ),
                Container(height: 1, color: AppTheme.dividerColor),
                _LanguageTile(
                  title: 'ਪੰਜਾਬੀ',
                  subtitle: 'Punjabi',
                  isSelected: currentCode == 'pa',
                  onTap: () {
                    if (currentCode != 'pa') {
                      langProvider.toggleLanguage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.translate('languageChanged')),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
          : const Icon(Icons.circle_outlined, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
