import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class CatchAnswerScreen extends StatefulWidget {
  const CatchAnswerScreen({super.key});
  @override
  State<CatchAnswerScreen> createState() => _CatchAnswerScreenState();
}

class _CatchAnswerScreenState extends State<CatchAnswerScreen> {
  final _rng = Random();
  int _a = 0, _b = 0, _correct = 0;
  List<Map<String, dynamic>> _falling = [];
  Timer? _timer;
  int _score = 0;
  int _lives = 3;
  int _question = 0;
  int _total = 8;
  double _screenWidth = 300;

  @override
  void initState() { super.initState(); _nextQuestion(); }

  void _nextQuestion() {
    if (_question >= _total || _lives <= 0) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 300), () => showGameResult(context, _score, _total * 10, 'Catch Answer'));
      return;
    }
    _a = _rng.nextInt(10) + 1; _b = _rng.nextInt(10) + 1; _correct = _a + _b;
    final wrongs = <int>{};
    while (wrongs.length < 3) { wrongs.add(_correct + _rng.nextInt(10) - 5); wrongs.remove(_correct); }
    final answers = [_correct, ...wrongs.take(3)]..shuffle();
    setState(() {
      _falling = answers.asMap().entries.map((e) => {'value': e.value, 'x': _rng.nextDouble(), 'y': 0.0, 'speed': 0.003 + _rng.nextDouble() * 0.002}).toList();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        for (final f in _falling) { f['y'] = (f['y'] as double) + (f['speed'] as double); }
        _falling.removeWhere((f) {
          if ((f['y'] as double) > 1.0) { if (f['value'] == _correct) { _lives--; } return true; }
          return false;
        });
        if (_falling.isEmpty) { _question++; _nextQuestion(); }
      });
    });
  }

  void _tap(Map<String, dynamic> item) {
    if (item['value'] == _correct) {
      setState(() { _score += 10; _falling.clear(); });
      _timer?.cancel(); _question++;
      Future.delayed(const Duration(milliseconds: 300), _nextQuestion);
    } else {
      setState(() { _lives--; _falling.remove(item); });
      if (_lives <= 0) { _timer?.cancel(); showGameResult(context, _score, _total * 10, 'Catch Answer'); }
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height - 120;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
        title: const Text('Catch Answer 🎯', style: TextStyle(fontFamily: 'Cairo')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('❤️×$_lives  ⭐$_score', style: const TextStyle(fontFamily: 'Cairo'))))],
      ),
      body: Stack(children: [
        Center(child: Text('$_a + $_b = ?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'))),
        ..._falling.map((f) => Positioned(
          left: (f['x'] as double) * (_screenWidth - 70),
          top: (f['y'] as double) * screenHeight,
          child: GestureDetector(
            onTap: () => _tap(f),
            child: Container(width: 70, height: 44, decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(22)),
              child: Center(child: Text('${f['value']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
          ),
        )),
      ]),
    );
  }
}