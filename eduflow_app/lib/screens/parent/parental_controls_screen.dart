import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class ParentalControlsScreen extends ConsumerStatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  ConsumerState<ParentalControlsScreen> createState() => _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends ConsumerState<ParentalControlsScreen> {
  String _lang = 'ar';
  bool _isPinSet = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isPinSet = (prefs.getString('parental_pin') ?? '').isNotEmpty;
        _loading = false;
      });
    }
  }

  Future<void> _setPin() async {
    final pin = await _showPinDialog(Tr.t('set_pin', _lang));
    if (pin != null && pin.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parental_pin', pin);
      setState(() => _isPinSet = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.t('pin_set_success', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  Future<void> _changePin() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('parental_pin') ?? '';
    final entered = await _showPinDialog(Tr.t('enter_current_pin', _lang));
    if (entered != currentPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.t('wrong_pin', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error),
        );
      }
      return;
    }
    final newPin = await _showPinDialog(Tr.t('enter_new_pin', _lang));
    if (newPin != null && newPin.length == 4) {
      await prefs.setString('parental_pin', newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.t('pin_changed', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('parental_pin') ?? '';
    final entered = await _showPinDialog(Tr.t('enter_current_pin', _lang));
    if (entered != currentPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.t('wrong_pin', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error),
        );
      }
      return;
    }
    await prefs.remove('parental_pin');
    setState(() => _isPinSet = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.t('pin_removed', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success),
      );
    }
  }

  Future<String?> _showPinDialog(String title) async {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context)), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < pin.length ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
                  ),
                )),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  ['1','2','3'],
                  ['4','5','6'],
                  ['7','8','9'],
                  ['','0','⌫'],
                ].map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((k) => GestureDetector(
                      onTap: () {
                        if (k == '⌫') {
                          if (pin.isNotEmpty) setDialogState(() => pin = pin.substring(0, pin.length - 1));
                        } else if (k.isNotEmpty && pin.length < 4) {
                          setDialogState(() => pin += k);
                          if (pin.length == 4) Navigator.pop(ctx, pin);
                        }
                      },
                      child: Container(
                        width: 52, height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: k.isEmpty ? Colors.transparent : AppTheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: k == '⌫'
                              ? Icon(Icons.backspace_outlined, color: AppTheme.primary, size: 18)
                              : k.isEmpty ? null
                              : Text(k, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context))),
                        ),
                      ),
                    )).toList(),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Tr.t('cancel', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => context.go('/settings'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(Tr.t('parental_controls', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            const Text('🔒', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(Tr.t('parental_info', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: AppTheme.primary))),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        // PIN section
                        Text(Tr.t('pin_protection', _lang), style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                          child: Column(children: [
                            // Status
                            ListTile(
                              leading: Icon(_isPinSet ? Icons.lock : Icons.lock_open, color: _isPinSet ? AppTheme.success : AppTheme.error),
                              title: Text(
                                _isPinSet ? Tr.t('pin_set', _lang) : Tr.t('no_pin', _lang),
                                style: TextStyle(fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Divider(height: 1, color: borderC),
                            // Set / Change PIN
                            ListTile(
                              leading: const Text('🔑', style: TextStyle(fontSize: 22)),
                              title: Text(
                                _isPinSet ? Tr.t('change_pin', _lang) : Tr.t('set_pin', _lang),
                                style: TextStyle(fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.w500),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: textM),
                              onTap: _isPinSet ? _changePin : _setPin,
                            ),
                            if (_isPinSet) ...[
                              Divider(height: 1, color: borderC),
                              // Remove PIN
                              ListTile(
                                leading: const Text('🗑️', style: TextStyle(fontSize: 22)),
                                title: Text(Tr.t('remove_pin', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.error),
                                onTap: _removePin,
                              ),
                            ],
                          ]),
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
}