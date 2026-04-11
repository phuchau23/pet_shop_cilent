import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import 'privacy_policy_page.dart';
import 'security_info_page.dart';
import 'about_app_page.dart';
import 'terms_of_service_page.dart';
import 'help_page.dart';

// Spacing constants
class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

// Border radius constants
class _Rad {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _Sp.md,
                _Sp.lg,
                _Sp.md,
                _Sp.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Appearance Section
                  _SettingsSection(
                    title: 'Giao diện',
                    children: [
                      _SettingsToggleItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Chế độ tối',
                        subtitle: 'Bật chế độ tối để bảo vệ mắt',
                        value: themeMode == ThemeModeOption.dark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).setTheme(
                            value ? ThemeModeOption.dark : ThemeModeOption.light,
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsSelectionItem(
                        icon: Icons.language_outlined,
                        title: 'Ngôn ngữ',
                        subtitle: _getLanguageName(locale),
                        onTap: () => _showLanguageDialog(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: _Sp.lg),
                  // Account Section
                  _SettingsSection(
                    title: 'Tài khoản',
                    children: [
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Quyền riêng tư',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsItem(
                        icon: Icons.security_outlined,
                        title: 'Bảo mật',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SecurityInfoPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: _Sp.lg),
                  // About Section
                  _SettingsSection(
                    title: 'Thông tin',
                    children: [
                      _SettingsItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Về ứng dụng',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutAppPage(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsItem(
                        icon: Icons.description_outlined,
                        title: 'Điều khoản sử dụng',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TermsOfServicePage(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Trợ giúp',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HelpPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return 'Tiếng Việt';
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSelectionSheet(
        currentLocale: currentLocale,
        onLocaleSelected: (locale) {
          ref.read(localeProvider.notifier).setLocale(locale);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _Sp.xs, bottom: _Sp.sm + _Sp.xs),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(isDark).withOpacity(0.7),
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(_Rad.lg),
            border: Border.all(
              color: AppColors.getTextLight(isDark).withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Rad.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _Sp.md,
            vertical: _Sp.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: _Sp.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getTextLight(isDark).withOpacity(0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _Sp.md,
        vertical: _Sp.md,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: _Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: _Sp.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(isDark),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsSelectionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsSelectionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Rad.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _Sp.md,
            vertical: _Sp.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: _Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimary(isDark),
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: _Sp.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getTextSecondary(isDark),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getTextLight(isDark).withOpacity(0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: _Sp.md + 22 + _Sp.md, // icon width + icon size + gap
      endIndent: _Sp.md,
      color: AppColors.getTextLight(isDark).withOpacity(0.08),
    );
  }
}

class _LanguageSelectionSheet extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleSelected;

  const _LanguageSelectionSheet({
    required this.currentLocale,
    required this.onLocaleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(_Rad.xl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: _Sp.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getTextLight(isDark).withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _Sp.md,
                _Sp.lg,
                _Sp.md,
                _Sp.md,
              ),
              child: Row(
                children: [
                  const Text(
                    'Chọn ngôn ngữ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.getTextSecondary(isDark),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(_Sp.md, 0, _Sp.md, _Sp.xl),
                children: [
                  _LanguageOption(
                    locale: const Locale('vi', 'VN'),
                    name: 'Tiếng Việt',
                    isSelected: currentLocale.languageCode == 'vi',
                    onTap: () => onLocaleSelected(const Locale('vi', 'VN')),
                  ),
                  const SizedBox(height: _Sp.md),
                  _LanguageOption(
                    locale: const Locale('en', 'US'),
                    name: 'English',
                    isSelected: currentLocale.languageCode == 'en',
                    onTap: () => onLocaleSelected(const Locale('en', 'US')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final Locale locale;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Rad.lg),
        child: Container(
          padding: const EdgeInsets.all(_Sp.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.getBackground(isDark),
            borderRadius: BorderRadius.circular(_Rad.lg),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.getTextLight(isDark).withOpacity(0.12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                    height: 1.3,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
