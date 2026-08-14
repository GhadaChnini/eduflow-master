import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class MathChallengeScreen extends ConsumerStatefulWidget {
  const MathChallengeScreen({super.key});
  @override
  ConsumerState<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends ConsumerState<MathChallengeScreen> {
  final _rng = Random();
  int _a = 0, _b = 0, _answer = 0;
  String _operator = '+';
  List<int> _options = [];
  int _score = 0;
  int _question = 0;
  int _total = 10;
  int _secondsLeft = 10;
  Timer? _timer;
  int _gradeLevel = 1;

  @override
  void initState() { super.initState(); _loadGrade(); }

  Future<void> _loadGrade() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { _nextQuestion(); return; }
    try {
      final res = await Supabase.instance.client.from('profiles').select('grade_level').eq('id', user.id).single();
      _gradeLevel = res['grade_level'] ?? 1;
    } catch (_) {}
    _nextQuestion();
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_question >= _total) { showGameResult(context, _score, _total * 10, 'Math Challenge'); return; }
    int maxNum = _gradeLevel <= 2 ? 20 : _gradeLevel <= 4 ? 100 : 200;
    List<String> ops = _gradeLevel <= 2 ? ['+', '-'] : _gradeLevel <= 4 ? ['+', '-', '×'] : ['+', '-', '×', '÷'];
    _operator = ops[_rng.nextInt(ops.length)];
    switch (_operator) {
      case '+': _a = _rng.nextInt(maxNum); _b = _rng.nextInt(maxNum); _answer = _a + _b; break;
      case '-': _a = _rng.nextInt(maxNum); _b = _rng.nextInt(_a + 1); _answer = _a - _b; break;
      case '×': _a = _rng.nextInt(12) + 1; _b = _rng.nextInt(12) + 1; _answer = _a * _b; break;
      case '÷': _b = _rng.nextInt(11) + 1; _answer = _rng.nextInt(11) + 1; _a = _b * _answer; break;
    }
    final Set<int> opts = {_answer};
    while (opts.length < 4) { opts.add(_answer + _rng.nextInt(21) - 10); }
    _options = opts.toList()..shuffle();
    _secondsLeft = 10;
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) { t.cancel(); _question++; _nextQuestion(); }
      else setState(() => _secondsLeft--);
    });
  }

  void _pick(int opt) {
    _timer?.cancel();
    if (opt == _answer) setState(() => _score += _secondsLeft + 1);
    _question++;
    Future.delayed(const Duration(milliseconds: 300), _nextQuestion);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final card = AppTheme.cardColor(context);
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
        title: const Text('Math Challenge 🔢', style: TextStyle(fontFamily: 'Cairo')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${_question + 1}/$_total  ⭐$_score', style: const TextStyle(fontFamily: 'Cairo'))))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          LinearProgressIndicator(value: _secondsLeft / 10, color: _secondsLeft <= 3 ? AppTheme.error : const Color(0xFF2563EB), backgroundColor: AppTheme.borderColor(context), minHeight: 8),
          const SizedBox(height: 8),
          Text('$_secondsLeft seconds', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: AppTheme.textMediumColor(context))),
          const SizedBox(height: 32),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
            child: Text('$_a $_operator $_b = ?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF2563EB))),
          ),
          const SizedBox(height: 24),
          GridView.count(shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5,
            children: _options.map((opt) => ElevatedButton(
              onPressed: () => _pick(opt),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('$opt', style: const TextStyle(fontSize: 22, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            )).toList()),
        ]),
      ),
    );
  }
}