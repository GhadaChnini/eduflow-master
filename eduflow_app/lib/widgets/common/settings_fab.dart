import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

import '../../widgets/common/main_scaffold.dart';

class SettingsFab extends ConsumerStatefulWidget {
  const SettingsFab({super.key});

  @override
  ConsumerState<SettingsFab> createState() => _SettingsFabState();
}

class _SettingsFabState extends ConsumerState<SettingsFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  Future<void> _logout() async {
    _close();
    final lang = ref.read(languageProvider);
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
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentLang = ref.watch(languageProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: _isOpen ? _buildOptions(isDark, currentLang) : const SizedBox.shrink(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isOpen ? '✕' : '⚙️',
                  key: ValueKey(_isOpen),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(bool isDark, String currentLang) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile
          _circleBtn('👤', false, () async {
            _close();
            final supabase = Supabase.instance.client;
            final user = supabase.auth.currentUser;
            if (user == null) return;
            final profile = await supabase.from('profiles').select('role').eq('id', user.id).single();
            if (!mounted) return;
            final role = profile['role'] ?? 'parent';
            if (role == 'teacher') {
              context.go('/teacher/profile');
            } else {
              context.go('/profile');
            }
          }),
          const SizedBox(height: 6),

          // Contact Support
          _circleBtn('🎧', false, () {
            _close();
            context.go('/messages');
          }),
          const SizedBox(height: 6),

          // Dark/Light mode toggle
          _circleBtn(isDark ? '🌙' : '☀️', isDark, () {
            ref.read(isDarkModeProvider.notifier).toggle(!isDark);
          }),
          const SizedBox(height: 6),

          // Languages
          _circleBtn('🇹🇳', currentLang == 'ar', () {
            ref.read(languageProvider.notifier).setLanguage('ar');
            _close();
          }),
          const SizedBox(height: 6),
          _circleBtn('🇫🇷', currentLang == 'fr', () {
            ref.read(languageProvider.notifier).setLanguage('fr');
            _close();
          }),
          const SizedBox(height: 6),
          _circleBtn('🇬🇧', currentLang == 'en', () {
            ref.read(languageProvider.notifier).setLanguage('en');
            _close();
          }),
          const SizedBox(height: 6),

          // Logout
          _circleBtn('🚪', false, _logout),
        ],
      ),
    );
  }

  Widget _circleBtn(String icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.inputFillColor(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
      ),
    );
  }
}