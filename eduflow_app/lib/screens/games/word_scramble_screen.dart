import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});
  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  final List<Map<String, String>> _words = [
    {'word': 'CHAT', 'hint': 'قطة - Cat'},
    {'word': 'CHIEN', 'hint': 'كلب - Dog'},
    {'word': 'MAISON', 'hint': 'منزل - House'},
    {'word': 'ECOLE', 'hint': 'مدرسة - School'},
    {'word': 'LIVRE', 'hint': 'كتاب - Book'},
    {'word': 'SOLEIL', 'hint': 'شمس - Sun'},
    {'word': 'ARBRE', 'hint': 'شجرة - Tree'},
    {'word': 'EAU', 'hint': 'ماء - Water'},
    {'word': 'POMME', 'hint': 'تفاحة - Apple'},
    {'word': 'FLEUR', 'hint': 'زهرة - Flower'},
  ];
  int _current = 0;
  int _score = 0;
  String _scrambled = '';
  final _ctrl = TextEditingController();
  bool _correct = false;
  bool _wrong = false;

  @override
  void initState() { super.initState(); _words.shuffle(); _scramble(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _scramble() {
    final word = _words[_current]['word']!;
    final chars = word.split('')..shuffle();
    setState(() { _scrambled = chars.join(); _correct = false; _wrong = false; _ctrl.clear(); });
  }

  void _check() {
    if (_ctrl.text.toUpperCase().trim() == _words[_current]['word']) {
      setState(() { _correct = true; _score += 10; });
      Future.delayed(const Duration(milliseconds: 800), _next);
    } else {
      setState(() => _wrong = true);
      Future.delayed(const Duration(milliseconds: 500), () { if (mounted) setState(() => _wrong = false); });
    }
  }

  void _next() {
    if (_current < _words.length - 1) { setState(() => _current++); _scramble(); }
    else showGameResult(context, _score, _words.length * 10, 'Word Scramble');
  }

  @override
  Widget build(BuildContext context) {
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final progress = (_current + 1) / _words.length;

    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Word Scramble 🔤', style: TextStyle(fontFamily: 'Cairo')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('⭐ $_score', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))],
      ),
      body: SafeArea(
        child: Column(children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_current + 1} / ${_words.length}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo', fontSize: 13)),
                Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(
                value: progress, backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 6,
              )),
            ]),
          ),
          const SizedBox(height: 8),
          // Main content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.bgColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const SizedBox(height: 8),
                  // Hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                    child: Text('💡 ${_words[_current]['hint']}', style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF059669))),
                  ),
                  const SizedBox(height: 24),
                  // Scrambled word
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _scrambled.split('').map((c) => Container(
                      width: 44, height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text(c, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Input
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _correct ? const Color(0xFF059669) : _wrong ? AppTheme.error : borderC, width: 2),
                      color: _correct ? const Color(0xFF059669).withOpacity(0.05) : _wrong ? AppTheme.error.withOpacity(0.05) : AppTheme.inputFillColor(context),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6, color: textD),
                      decoration: InputDecoration(
                        hintText: '_ _ _ _ _',
                        hintStyle: TextStyle(color: textM, fontSize: 20, letterSpacing: 6),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_correct)
                    const Text('Correct! 🎉', style: TextStyle(color: Color(0xFF059669), fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))
                  else if (_wrong)
                    const Text('Try again!', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: _next,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                      child: const Text('Skip', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: ElevatedButton(
                      onPressed: _check,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: const Text('Check', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}