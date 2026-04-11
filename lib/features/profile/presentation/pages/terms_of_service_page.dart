import 'package:flutter/material.dart';
import '../../data/mock_data/app_info_mock_data.dart';
import '../../../../core/theme/app_colors.dart';

// Spacing constants
class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// Border radius constants
class _Rad {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = AppInfoMockData.getTermsOfService();

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          'Điều khoản sử dụng',
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
              padding: const EdgeInsets.symmetric(horizontal: _Sp.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: _Sp.lg),
                  _buildContent(content, isDark),
                  const SizedBox(height: _Sp.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String content, bool isDark) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: _Sp.lg));
        continue;
      }

      if (line.startsWith('# ')) {
        // Main title - Hero style
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: _Sp.xl),
            child: Text(
              line.substring(2),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(isDark),
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // Section title - Clean with accent line
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: _Sp.xxl, bottom: _Sp.lg),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: _Sp.md),
                Expanded(
                  child: Text(
                    line.substring(3),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(isDark),
                      letterSpacing: -0.4,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        // Subsection title
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: _Sp.xl, bottom: _Sp.md),
            child: Text(
              line.substring(4),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
                letterSpacing: -0.2,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        // Bullet point - Clean list style
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: _Sp.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: _Sp.md),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextSecondary(isDark),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('**') && line.endsWith('**')) {
        // Bold text - Label style
        final text = line.substring(2, line.length - 2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: _Sp.sm),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
                height: 1.6,
              ),
            ),
          ),
        );
      } else {
        // Regular paragraph - Clean text, no container
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: _Sp.lg),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextSecondary(isDark),
                height: 1.7,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
