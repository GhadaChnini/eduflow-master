import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../widgets/common/main_scaffold.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../widgets/common/settings_fab.dart';

class StudentSettingsScreen extends ConsumerWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Text(Tr.t('settings', lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile
                  _sectionTitle(Tr.t('account', lang), textM),
                  const SizedBox(height: 8),
                  _tile(context, card, borderC, textD, textM, '👤', Tr.t('my_profile', lang), () => context.go('/profile')),
                  const SizedBox(height: 8),
                  _tile(context, card, borderC, textD, textM, '👨‍👩‍👧', Tr.t('parental_controls', lang), () => context.go('/parental-controls')),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  // Support
                  _sectionTitle(Tr.t('help', lang), textM),
                  const SizedBox(height: 8),
                  _tile(context, card, borderC, textD, textM, '🎧', Tr.t('contact_support', lang), () => context.go('/messages')),
                  const SizedBox(height: 24),

                  // Appearance
                  _sectionTitle(Tr.t('appearance', lang), textM),
                  const SizedBox(height: 8),
                  // Dark mode toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                    child: Row(children: [
                      Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(Tr.t('dark_mode', lang), style: TextStyle(fontSize: 15, fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.w500))),
                      Switch(
                        value: isDark,
                        onChanged: (v) => ref.read(isDarkModeProvider.notifier).toggle(v),
                        activeColor: AppTheme.primary,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Language
                  _sectionTitle(Tr.t('language', lang), textM),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                    child: Column(children: [
                      _langTile('🇹🇳', 'العربية', 'ar', lang, ref, borderC, textD, textM, isFirst: true),
                      Divider(height: 1, color: borderC),
                      _langTile('🇫🇷', 'Français', 'fr', lang, ref, borderC, textD, textM),
                      Divider(height: 1, color: borderC),
                      _langTile('🇬🇧', 'English', 'en', lang, ref, borderC, textD, textM, isLast: true),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  GestureDetector(
                    onTap: () => _logout(context, ref, lang),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🚪', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(Tr.t('logout', lang), style: const TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.error)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color textM) =>
    Text(title, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM, fontWeight: FontWeight.w600));

  Widget _tile(BuildContext context, Color card, Color border, Color textD, Color textM, String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios, size: 14, color: textM),
        ]),
      ),
    );
  }

  Widget _langTile(String flag, String label, String code, String currentLang, WidgetRef ref, Color border, Color textD, Color textM, {bool isFirst = false, bool isLast = false}) {
    final isSelected = currentLang == code;
    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(14) : Radius.zero,
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.w500))),
          if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
        ]),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref, String lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Tr.t('logout', lang), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context)), textAlign: TextAlign.center),
        content: Text(Tr.t('logout_confirm', lang), style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(Tr.t('cancel', lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(Tr.t('logout', lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/');
    }
  }
}