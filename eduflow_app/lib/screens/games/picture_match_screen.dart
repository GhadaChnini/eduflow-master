import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class PictureMatchScreen extends StatefulWidget {
  const PictureMatchScreen({super.key});
  @override
  State<PictureMatchScreen> createState() => _PictureMatchScreenState();
}

class _PictureMatchScreenState extends State<PictureMatchScreen> {
  final List<Map<String, String>> _items = [
    {'emoji': '🐱', 'ar': 'قطة', 'fr': 'Chat'}, {'emoji': '🐶', 'ar': 'كلب', 'fr': 'Chien'},
    {'emoji': '🌳', 'ar': 'شجرة', 'fr': 'Arbre'}, {'emoji': '☀️', 'ar': 'شمس', 'fr': 'Soleil'},
    {'emoji': '📚', 'ar': 'كتاب', 'fr': 'Livre'}, {'emoji': '🏠', 'ar': 'منزل', 'fr': 'Maison'},
    {'emoji': '🍎', 'ar': 'تفاحة', 'fr': 'Pomme'}, {'emoji': '🌸', 'ar': 'زهرة', 'fr': 'Fleur'},
    {'emoji': '🐟', 'ar': 'سمكة', 'fr': 'Poisson'}, {'emoji': '⭐', 'ar': 'نجمة', 'fr': 'Étoile'},
  ];
  int _current = 0; int _score = 0; List<String> _options = []; bool _answered = false; int? _selected;
  final _rng = Random();

  @override
  void initState() { super.initState(); _items.shuffle(); _generateOptions(); }

  void _generateOptions() {
    final correct = _items[_current]['ar']!;
    final Set<String> opts = {correct};
    while (opts.length < 4) { opts.add(_items[_rng.nextInt(_items.length)]['ar']!); }
    _options = opts.toList()..shuffle();
    setState(() { _answered = false; _selected = null; });
  }

  void _select(int i) {
    if (_answered) return;
    setState(() { _selected = i; _answered = true; });
    if (_options[i] == _items[_current]['ar']) _score += 10;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_current < _items.length - 1) { setState(() => _current++); _generateOptions(); }
      else showGameResult(context, _score, _items.length * 10, 'Picture Match');
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = AppTheme.cardColor(context);
    final textM = AppTheme.textMediumColor(context);
    final item = _items[_current];
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white,
        title: const Text('Picture Match 🖼️', style: TextStyle(fontFamily: 'Cairo')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${_current + 1}/${_items.length}  ⭐$_score', style: const TextStyle(fontFamily: 'Cairo'))))],
      ),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)), child: Column(children: [
          Text(item['emoji']!, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          Text(item['fr']!, style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: textM)),
        ])),
        const SizedBox(height: 24),
        GridView.count(shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5,
          children: _options.asMap().entries.map((e) {
            final isCorrect = e.value == item['ar'];
            Color color = const Color(0xFFD97706);
            if (_answered && _selected == e.key) color = isCorrect ? const Color(0xFF059669) : AppTheme.error;
            else if (_answered && isCorrect) color = const Color(0xFF059669);
            return ElevatedButton(
              onPressed: () => _select(e.key),
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(e.value, style: const TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            );
          }).toList()),
      ])),
    );
  }
}