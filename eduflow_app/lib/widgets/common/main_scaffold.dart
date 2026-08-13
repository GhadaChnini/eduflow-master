import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isLockedProvider = StateProvider<bool>((ref) => false);
final lockedLocationProvider = StateProvider<String>((ref) => '');

final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) { _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? false;
  }
  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }
}

// Unread notifications count
final unreadNotifProvider = StreamProvider<int>((ref) async* {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) { yield 0; return; }

  while (true) {
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);
      yield (res as List).length;
    } catch (_) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isLocked = ref.watch(isLockedProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final unreadCount = ref.watch(unreadNotifProvider).value ?? 0;

    final tabs = [
      {'icon': '🏠', 'route': '/home', 'label': Tr.t('nav_home', lang)},
      {'icon': '📚', 'route': '/browse', 'label': Tr.t('nav_units', lang)},
      {'icon': '💬', 'route': '/forum', 'label': Tr.t('forum', lang)},
      {'icon': '👤', 'route': '/profile', 'label': Tr.t('nav_profile', lang)},
      {'icon': '⚙️', 'route': '/settings', 'label': Tr.t('settings', lang)},
    ];

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (isLocked) return true; // block back
        return false; // allow normal back
      },
      child: PopScope(
        canPop: !isLocked,
        child: Scaffold(
        backgroundColor: AppTheme.bgColor(context),
        floatingActionButton: LockFab(isLocked: isLocked),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Stack(
          children: [
            child,
          ],
        ),
        bottomNavigationBar: isLocked ? null : Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          color: Colors.transparent,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.isDark(context) ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.map((tab) {
                final isActive = location == tab['route'];
                return GestureDetector(
                  onTap: () => context.go(tab['route'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tab['icon'] as String,
                            style: TextStyle(fontSize: isActive ? 22 : 20)),
                        if (isActive)
                          Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class LockFab extends ConsumerStatefulWidget {
  final bool isLocked;
  const LockFab({super.key, required this.isLocked});

  @override
  ConsumerState<LockFab> createState() => _LockFabState();
}

class _LockFabState extends ConsumerState<LockFab> {
  String _t(String ar, String fr, String en) {
    final l = ref.read(languageProvider);
    if (l == 'fr') return fr;
    if (l == 'en') return en;
    return ar;
  }

  void _onFabTap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('parental_pin') ?? '';
    if (!mounted) return;
    if (savedPin.isEmpty) {
      context.go('/parental-controls');
      return;
    }
    _showPinDialog(savedPin);
  }

  void _showPinDialog(String savedPin) {
    String pin = '';
    String error = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void onKey(String key) {
            if (pin.length >= 4) return;
            setDialogState(() { pin += key; error = ''; });
            if (pin.length == 4) {
              Future.microtask(() {
                if (pin == savedPin) {
                  Navigator.of(ctx).pop();
                  if (widget.isLocked) {
                    ref.read(isLockedProvider.notifier).state = false;
                    ref.read(lockedLocationProvider.notifier).state = '';
                  } else {
                    final location = GoRouterState.of(context).matchedLocation;
                    ref.read(lockedLocationProvider.notifier).state = location;
                    ref.read(isLockedProvider.notifier).state = true;
                  }
                } else {
                  setDialogState(() { pin = ''; error = _t('رمز PIN غير صحيح', 'Code PIN incorrect', 'Wrong PIN'); });
                }
              });
            }
          }

          void onDelete() {
            if (error.isNotEmpty) {
              setDialogState(() => error = '');
              return;
            }
            if (pin.isEmpty) return;
            setDialogState(() => pin = pin.substring(0, pin.length - 1));
          }

          final title = widget.isLocked
              ? _t('أدخل PIN لإلغاء القفل', 'Entrez PIN pour déverrouiller', 'Enter PIN to unlock')
              : _t('أدخل PIN لقفل التطبيق', 'Entrez PIN pour verrouiller', 'Enter PIN to lock');

          return WillPopScope(
            onWillPop: () async => true,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: Column(
                    children: [
                      // X button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.close, color: Colors.white, size: 20)),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(widget.isLocked ? '🔐' : '🔒', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < pin.length ? AppTheme.primary : Colors.white.withOpacity(0.3),
                          ),
                        )),
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(error, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 13)),
                      ],
                      const SizedBox(height: 32),
                      // Keypad
                      ...[['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']].map((row) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: row.map((key) => GestureDetector(
                              onTap: key == '⌫' ? onDelete : key.isEmpty ? null : () => onKey(key),
                              child: Container(
                                width: 70, height: 70,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: key.isEmpty ? Colors.transparent : Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: key == '⌫'
                                      ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
                                      : key.isEmpty ? null
                                      : Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onFabTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: widget.isLocked ? AppTheme.error : AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(widget.isLocked ? '🔐' : '🔒', style: const TextStyle(fontSize: 20))),
      ),
    );
  }
}