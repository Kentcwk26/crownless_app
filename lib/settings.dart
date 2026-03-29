import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const SettingsPage({super.key, this.toggleTheme, this.isDarkMode = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Locale _selectedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale = context.locale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: SafeArea(
        child: Column(
          spacing: 8.0,
          children: [
            SwitchListTile(
              title: Text('theme'.tr()),
              value: widget.isDarkMode,
              onChanged: (_) => widget.toggleTheme?.call(),
              secondary: const Icon(Icons.brightness_6),
            ),
            ListTile(
              title: Text('language'.tr()),
              subtitle: Text(_getLanguageName(_selectedLocale)),
              leading: const Icon(Icons.language),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(context),
            ),
            Spacer(),
            Text('${"appVersion".tr()} v1.0.0').tr()
          ],
        ),
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    const languageNames = {
      'en': 'English',
      'zh': 'Chinese (中文)',
      'ms': 'Malay (Bahasa Melayu)',
    };
    return languageNames[locale.languageCode] ?? locale.languageCode;
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, const Locale('en'), 'English'),
              _buildLanguageOption(context, const Locale('zh'), 'Mandarin (中文)'),
              _buildLanguageOption(context, const Locale('ms'), 'Malay (Bahasa Melayu)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, Locale locale, String name) {
    final isSelected = _selectedLocale.languageCode == locale.languageCode;
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        context.setLocale(locale);
        setState(() {
          _selectedLocale = locale;
        });
        Navigator.pop(context);
      },
    );
  }
}