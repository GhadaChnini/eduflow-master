import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

class LockOverlay extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback? onDismiss; // X button to go back without unlocking
  final bool isCurrentlyLocked; // true = app is locked, false = setting lock
  final String lang;

  const LockOverlay({
    super.key,
    required this.onUnlocked,
    this.onDismiss,
    required this.isCurrentlyLocked,
    required this.lang,
  });

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> {
  String _enteredPin = '';
  String _errorMsg = '';

  String _t(String ar, String fr, String en) {
    if (widget.lang == 'fr') return fr;
    if (widget.lang == 'en') return en;
    return ar;
  }

  void _onKey(String key) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += key;
      _errorMsg = '';
    });
    if (_enteredPin.length == 4) _checkPin();
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('parental_pin') ?? '';
    if (_enteredPin == savedPin) {
      widget.onUnlocked();
    } else {
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _errorMsg = _t('رمز PIN غير صحيح', 'Code PIN incorrect', 'Wrong PIN');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCurrentlyLocked
        ? _t('التطبيق مقفل', 'Application verrouillée', 'App is locked')
        : _t('قفل التطبيق', 'Verrouiller l application', 'Lock the app');

    final subtitle = widget.isCurrentlyLocked
        ? _t('أدخل رمز PIN لإلغاء القفل', 'Entrez le PIN pour déverrouiller', 'Enter PIN to unlock')
        : _t('أدخل رمز PIN لتأكيد القفل', 'Entrez le PIN pour confirmer', 'Enter PIN to confirm lock');

    final unlockSuccess = widget.isCurrentlyLocked
        ? _t('تم إلغاء القفل', 'Déverrouillé', 'Unlocked')
        : _t('تم قفل التطبيق 🔒', 'Application verrouillée 🔒', 'App locked 🔒');

    return Container(
      color: Colors.black.withOpacity(0.93),
      child: SafeArea(
        child: Column(
          children: [
            // X button — when wrong PIN entered
            if (_errorMsg.isNotEmpty)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      if (!widget.isCurrentlyLocked && widget.onDismiss != null) {
                        // Not locked yet — cancel and go back
                        widget.onDismiss!();
                      } else {
                        // Already locked — just reset PIN entry, stay locked
                        setState(() {
                          _enteredPin = '';
                          _errorMsg = '';
                        });
                      }
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.close, color: Colors.white, size: 20)),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 52),

            const Spacer(),

            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.isCurrentlyLocked ? '🔒' : '🔓',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), fontFamily: 'Cairo')),
            const SizedBox(height: 36),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _enteredPin.length ? AppTheme.primary : Colors.white.withOpacity(0.3),
                ),
              )),
            ),

            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_errorMsg, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                widget.isCurrentlyLocked
                    ? _t('اضغط X للمحاولة مجدداً', 'Appuyez sur X pour réessayer', 'Tap X to try again')
                    : _t('اضغط X للإلغاء', 'Appuyez sur X pour annuler', 'Tap X to cancel'),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Cairo', fontSize: 12),
              ),
            ],

            const SizedBox(height: 36),

            _buildKeypad(),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) => GestureDetector(
            onTap: key == '⌫' ? _onDelete : key.isEmpty ? null : () => _onKey(key),
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
                    : key.isEmpty
                        ? null
                        : Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          )).toList(),
        ),
      )).toList(),
    );
  }
}