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

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final Map<String, bool> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = AppInfoMockData.getHelpContent();

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          'Trợ giúp',
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
    String? currentQuestion;
    List<String> currentAnswers = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (currentQuestion != null && currentAnswers.isNotEmpty) {
          widgets.add(
            _buildExpandableSection(
              currentQuestion,
              currentAnswers,
              isDark,
            ),
          );
          currentQuestion = null;
          currentAnswers = [];
        }
        widgets.add(const SizedBox(height: _Sp.lg));
        continue;
      }

      if (line.startsWith('# ')) {
        if (currentQuestion != null && currentAnswers.isNotEmpty) {
          widgets.add(
            _buildExpandableSection(
              currentQuestion,
              currentAnswers,
              isDark,
            ),
          );
          currentQuestion = null;
          currentAnswers = [];
        }
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
        if (currentQuestion != null && currentAnswers.isNotEmpty) {
          widgets.add(
            _buildExpandableSection(
              currentQuestion,
              currentAnswers,
              isDark,
            ),
          );
          currentQuestion = null;
          currentAnswers = [];
        }
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
      } else if (line.startsWith('**Q:') && line.endsWith('**')) {
        if (currentQuestion != null && currentAnswers.isNotEmpty) {
          widgets.add(
            _buildExpandableSection(
              currentQuestion,
              currentAnswers,
              isDark,
            ),
          );
        }
        currentQuestion = line.substring(5, line.length - 2).trim();
        currentAnswers = [];
      } else if (line.startsWith('A: ')) {
        if (currentQuestion != null) {
          currentAnswers.add(line.substring(3).trim());
        }
      } else if (line.startsWith('### ')) {
        if (currentQuestion != null && currentAnswers.isNotEmpty) {
          widgets.add(
            _buildExpandableSection(
              currentQuestion,
              currentAnswers,
              isDark,
            ),
          );
          currentQuestion = null;
          currentAnswers = [];
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: _Sp.xl, bottom: _Sp.md),
            child: Text(
              line.substring(5),
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
      } else if (line.startsWith('**') && line.endsWith('**')) {
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
      } else if (line.startsWith('- ')) {
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
      } else if (line.isNotEmpty) {
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

    if (currentQuestion != null && currentAnswers.isNotEmpty) {
      widgets.add(
        _buildExpandableSection(
          currentQuestion,
          currentAnswers,
          isDark,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildExpandableSection(
    String question,
    List<String> answers,
    bool isDark,
  ) {
    final isExpanded = _expandedSections[question] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: _Sp.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(_Rad.md),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.getTextLight(isDark).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedSections[question] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(_Rad.md),
              child: Container(
                padding: const EdgeInsets.all(_Sp.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: _Sp.sm),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.getTextSecondary(isDark),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(
                _Sp.md,
                0,
                _Sp.md,
                _Sp.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: answers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _Sp.md),
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.getTextSecondary(isDark),
                        height: 1.6,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
