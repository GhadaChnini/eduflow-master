import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../widgets/common/main_scaffold.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _getSlides(String lang) => [
    {
      'emoji': '🌟',
      'titleKey': 'slide1_title',
      'subtitleKey': 'slide1_sub',
      'darkSlide': false,
    },
    {
      'emoji': '🏆',
      'titleKey': 'slide2_title',
      'subtitleKey': 'slide2_sub',
      'darkSlide': true,
      'color': Color(0xFF7C3AED),
    },
    {
      'emoji': '🤖',
      'titleKey': 'slide3_title',
      'subtitleKey': 'slide3_sub',
      'darkSlide': true,
      'color': Color(0xFFF59E0B),
    },
    {
      'emoji': '🎮',
      'titleKey': 'slide4_title',
      'subtitleKey': 'slide4_sub',
      'darkSlide': true,
      'color': Color(0xFFEC4899),
    },
    {
      'emoji': '🦸',
      'titleKey': 'slide5_title',
      'subtitleKey': 'slide5_sub',
      'darkSlide': true,
      'color': Color(0xFF7C3AED),
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final slides = _getSlides(lang);
    final slide = slides[_currentPage];
    final hasColor = slide.containsKey('color');
    final isDarkSlide = slide['darkSlide'] as bool;
    final appIsDark = AppTheme.isDark(context);

    // Background color logic
    Color bg;
    if (hasColor) {
      bg = slide['color'] as Color;
    } else {
      bg = AppTheme.bgColor(context);
    }

    final textColor = isDarkSlide ? Colors.white : AppTheme.textDarkColor(context);
    final subtitleColor = isDarkSlide ? Colors.white70 : AppTheme.textMediumColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // PageView slides
          PageView.builder(
            controller: _pageController,
            reverse: true,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final s = slides[index];
              final hasC = s.containsKey('color');
              final isDark = s['darkSlide'] as bool;
              final slideBg = hasC ? s['color'] as Color : AppTheme.bgColor(context);
              final tc = isDark ? Colors.white : AppTheme.textDarkColor(context);
              final sc = isDark ? Colors.white70 : AppTheme.textMediumColor(context);

              return Container(
                color: slideBg,
                child: Column(
                  children: [
                    const SizedBox(height: 140),
                    Text(s['emoji'] as String, style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(Tr.t(s['titleKey'] as String, lang),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: tc),
                        textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(Tr.t(s['subtitleKey'] as String, lang),
                        style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: sc),
                        textAlign: TextAlign.center),
                    ),
                  ],
                ),
              );
            },
          ),

          // Top nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('🌟', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('EduFlow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkSlide ? Colors.white : AppTheme.primary)),
                          Text('Kids Learning ✨', style: TextStyle(fontSize: 9, color: isDarkSlide ? Colors.white70 : AppTheme.secondary)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkSlide ? Colors.white.withOpacity(0.2) : AppTheme.primaryLight.withOpacity(appIsDark ? 0.2 : 1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isDarkSlide ? Colors.white30 : AppTheme.borderColor(context), width: 2),
                      ),
                      child: Text(Tr.t('login_nav', lang),
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                          color: isDarkSlide ? Colors.white : AppTheme.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dots
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? (isDarkSlide ? Colors.white : AppTheme.primary)
                      : (isDarkSlide ? Colors.white.withOpacity(0.3) : AppTheme.primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24, right: 24,
            child: Consumer(
              builder: (context, ref, _) {
                final dark = ref.watch(isDarkModeProvider);
                final btnColor = isDarkSlide ? (dark ? Colors.black87 : Colors.white) : AppTheme.primary;
                final btnTextColor = isDarkSlide ? (dark ? Colors.white : AppTheme.primary) : Colors.white;
                final outlineColor = isDarkSlide ? (dark ? Colors.black87 : Colors.white) : const Color(0xFF6366F1);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkSlide ? Colors.white.withOpacity(0.2) : AppTheme.primaryLight.withOpacity(dark ? 0.2 : 1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isDarkSlide ? Colors.white30 : AppTheme.borderColor(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇹🇳', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(Tr.t('tunisian_curriculum', lang),
                            style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                              color: isDarkSlide ? Colors.white : AppTheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/auth/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: Text(Tr.t('start_free', lang),
                          style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                            color: btnTextColor)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/auth/teacher-login'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          side: BorderSide(color: outlineColor, width: 2),
                        ),
                        child: Text(Tr.t('teach_on', lang),
                          style: TextStyle(fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                            color: outlineColor)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}