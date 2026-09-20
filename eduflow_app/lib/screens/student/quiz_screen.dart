import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';

class StudentQuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String sessionId;
  const StudentQuizScreen({super.key, required this.quizId, required this.sessionId});
  @override
  ConsumerState<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends ConsumerState<StudentQuizScreen> {
  String _lang = 'ar';
  Map<String, dynamic>? _quiz;
  List<Map<String, dynamic>> _questions = [];
  Map<int, int> _answers = {}; // questionIndex -> selectedOption
  bool _loading = true;
  bool _submitted = false;
  bool _alreadyAttempted = false;
  bool _submitting = false;
  int _currentIndex = 0;
  int _secondsLeft = 300;
  Timer? _timer;
  int _startTime = 0;
  int? _finalScore;
  int? _totalPoints;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // Check if already attempted
      final attempts = await Supabase.instance.client
          .from('quiz_attempts')
          .select()
          .eq('quiz_id', widget.quizId)
          .eq('student_id', user.id)
          .limit(1);
      final attempt = (attempts as List).isNotEmpty ? attempts.first : null;
      if (attempt != null && mounted) {
        // Already done — show result directly
        final questions = await Supabase.instance.client
            .from('quiz_questions').select().eq('quiz_id', widget.quizId).order('order_num');
        setState(() {
          _questions = List<Map<String, dynamic>>.from(questions);
          _submitted = true;
          _alreadyAttempted = true;
          _finalScore = attempt['score'] as int? ?? 0;
          _totalPoints = attempt['total_points'] as int? ?? 0;
          final savedAnswers = (attempt['answers'] as List?) ?? [];
          for (int i = 0; i < savedAnswers.length; i++) {
            _answers[i] = savedAnswers[i] as int? ?? -1;
          }
          _loading = false;
        });
        return;
      }
      final quiz = await Supabase.instance.client
          .from('quizzes').select().eq('id', widget.quizId).single();
      final questions = await Supabase.instance.client
          .from('quiz_questions').select().eq('quiz_id', widget.quizId).order('order_num');
      if (mounted) {
        setState(() {
          _quiz = Map<String, dynamic>.from(quiz);
          _questions = List<Map<String, dynamic>>.from(questions);
          _secondsLeft = quiz['time_limit_seconds'] ?? 300;
          _loading = false;
        });
        _startTimer();
        _startTime = DateTime.now().millisecondsSinceEpoch;
      }
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _submit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitted || _submitting) return;
    _timer?.cancel();
    setState(() => _submitting = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final timeTaken = (DateTime.now().millisecondsSinceEpoch - _startTime) / 1000;
    final totalTime = (_quiz?['time_limit_seconds'] ?? 300).toDouble();

    int correctCount = 0;
    int basePoints = 0;
    final List<int> answersList = [];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _answers[i];
      final opts = (q['options'] as List?) ?? [];
      final correctIdx = (q['correct_answer'] as int?) ?? 0;
      answersList.add(selected ?? -1);
      if (selected != null && correctIdx < opts.length && selected == correctIdx) {
        correctCount++;
        basePoints += (q['points'] as int? ?? 10);
      }
    }

    // Time bonus: faster = more points (up to 10% extra)
    double timeBonus = 0;
    if (correctCount > 0 && timeTaken < totalTime) {
      timeBonus = ((totalTime - timeTaken) / totalTime) * basePoints * 0.1;
    }

    final finalScore = (basePoints + timeBonus).round();
    final totalPossible = _questions.fold<int>(0, (sum, q) => sum + (q['points'] as int? ?? 10));
    final maxTotal = (totalPossible * 1.1).round();

    try {
      await Supabase.instance.client.from('quiz_attempts').insert({
        'quiz_id': widget.quizId,
        'student_id': user.id,
        'score': finalScore,
        'total_points': maxTotal,
        'answers': answersList,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) { debugPrint('Submit quiz error: $e'); }

    if (mounted) setState(() {
      _submitted = true;
      _submitting = false;
      _finalScore = finalScore;
      _totalPoints = maxTotal;
    });
  }

  String get _timerDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 60) return const Color(0xFF059669);
    if (_secondsLeft > 30) return const Color(0xFFF59E0B);
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    if (_loading) return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)));

    if (_submitted) return _buildResultScreen(context, card, textD, textM, borderC);

    final q = _questions[_currentIndex];
    final options = (q['options'] as List?) ?? [];
    if (options.isEmpty) {
      return Scaffold(backgroundColor: bg, body: Center(child: Text('No options for this question', style: TextStyle(fontFamily: 'Cairo', color: textD))));
    }
    final selected = _answers[_currentIndex];
    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(_quiz?['title_ar'] ?? _quiz?['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: _timerColor, borderRadius: BorderRadius.circular(100)),
                child: Text(_timerDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('${_currentIndex + 1}/${_questions.length}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo', fontSize: 13)),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              )),
            ]),
          ]),
        ),
        // Question
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text(q['question_text'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD, height: 1.5)),
            const SizedBox(height: 8),
            Text('${q['points'] ?? 10} points', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
            const SizedBox(height: 24),
            ...options.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value.toString();
              final isSelected = selected == i;
              return GestureDetector(
                onTap: () => setState(() => _answers[_currentIndex] = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.08) : card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppTheme.primary : borderC, width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(
                        i < 4 ? ['A', 'B', 'C', 'D'][i] : '${i + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.primary, fontSize: 14),
                      )),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(opt, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: textD))),
                    if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                  ]),
                ),
              );
            }),
          ]),
        )),
        // Navigation
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(color: card, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
          child: Row(children: [
            if (_currentIndex > 0)
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _currentIndex--),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                child: const Text('Previous', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              )),
            if (_currentIndex > 0) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _currentIndex < _questions.length - 1
                  ? () => setState(() => _currentIndex++)
                  : _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                backgroundColor: _currentIndex == _questions.length - 1 ? const Color(0xFF059669) : AppTheme.primary,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentIndex < _questions.length - 1 ? 'Next' : 'Submit', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultScreen(BuildContext context, Color card, Color textD, Color textM, Color borderC) {
    final score = _finalScore ?? 0;
    final total = _totalPoints ?? 1;
    final percent = (score / total * 100).round();
    final correct = _answers.entries.where((e) {
      final q = _questions[e.key];
      return e.value >= 0 && e.value == (q['correct_answer'] as int? ?? 0);
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(children: [
            Text(percent >= 80 ? '🎉' : percent >= 50 ? '👍' : '💪', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(_alreadyAttempted ? 'Already Submitted' : (percent >= 80 ? 'Excellent!' : percent >= 50 ? 'Good job!' : 'Keep practicing!'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text('$score / $total points', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontFamily: 'Cairo')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
              child: Text('$percent%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            ),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 8),
            Row(children: [
              _resultCard('Correct', '$correct/${_questions.length}', const Color(0xFF059669), card),
              const SizedBox(width: 12),
              _resultCard('Wrong', '${_questions.length - correct}/${_questions.length}', AppTheme.error, card),
            ]),
            const SizedBox(height: 20),
            Text('Question Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final selected = _answers[i];
              final correct2 = (q['correct_answer'] as int?) ?? 0;
              final options = (q['options'] as List?) ?? [];
              final isCorrect = selected != null && selected >= 0 && selected == correct2;
              final selectedText = (selected != null && selected >= 0 && selected < options.length) 
                  ? options[selected].toString() : 'No answer';
              final correctText = (correct2 >= 0 && correct2 < options.length) 
                  ? options[correct2].toString() : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isCorrect ? const Color(0xFF059669).withOpacity(0.4) : AppTheme.error.withOpacity(0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? const Color(0xFF059669) : AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q['question_text'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD, fontSize: 13))),
                  ]),
                  const SizedBox(height: 8),
                  if (selected != null && !isCorrect)
                    Text('Your answer: $selectedText', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: AppTheme.error)),
                  Text('Correct: $correctText', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF059669))),
                ]),
              );
            }),
            const SizedBox(height: 80),
          ]),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.close, color: Colors.white),
        label: const Text('Close', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _resultCard(String label, String value, Color color, Color card) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7), fontFamily: 'Cairo')),
      ]),
    ),
  );
}