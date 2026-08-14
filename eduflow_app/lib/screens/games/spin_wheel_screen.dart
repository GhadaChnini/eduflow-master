import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});
  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _questions = [
    {'q': 'What is 5 × 4?', 'a': '20', 'opts': ['20', '15', '25', '18']},
    {'q': 'Capital of Tunisia?', 'a': 'Tunis', 'opts': ['Tunis', 'Sfax', 'Sousse', 'Bizerte']},
    {'q': 'How many days in a week?', 'a': '7', 'opts': ['7', '5', '6', '8']},
    {'q': 'What color is the sky?', 'a': 'Blue', 'opts': ['Blue', 'Red', 'Green', 'Yellow']},
    {'q': 'What is 12 + 8?', 'a': '20', 'opts': ['20', '18', '22', '24']},
    {'q': 'How many months in a year?', 'a': '12', 'opts': ['12', '10', '11', '13']},
  ];

  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _spinning = false;
  Map<String, dynamic>? _currentQ;
  int _score = 0;
  int _round = 0;
  int _total = 5;
  int? _selected;
  bool _answered = false;
  final _rng = Random();

  final List<Color> _wheelColors = [
    const Color(0xFFDB2777), const Color(0xFFF59E0B), const Color(0xFF059669),
    const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFDC2626),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _spin() {
    if (_spinning || _round >= _total) return;
    setState(() { _spinning = true; _currentQ = null; _answered = false; _selected = null; });
    _ctrl.forward(from: 0).then((_) {
      if (mounted) setState(() { _spinning = false; _currentQ = _questions[_rng.nextInt(_questions.length)]; });
    });
  }

  void _answer(String opt) {
    if (_answered) return;
    setState(() { _answered = true; _selected = (_currentQ!['opts'] as List).indexOf(opt); });
    if (opt == _currentQ!['a']) setState(() => _score += 10);
    _round++;
    if (_round >= _total) {
      Future.delayed(const Duration(milliseconds: 1000), () => showGameResult(context, _score, _total * 10, 'Spin Wheel'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDB2777),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Spin Wheel 🎡', style: TextStyle(fontFamily: 'Cairo')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16),
          child: Center(child: Text('${_round + 1}/$_total  ⭐$_score', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))],
      ),
      body: Column(children: [
        // Wheel section
        Container(
          color: const Color(0xFFDB2777),
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: Column(children: [
              const SizedBox(height: 16),
              // Pointer
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 36),
              // Wheel
              AnimatedBuilder(
                animation: _anim,
                builder: (ctx, _) => Transform.rotate(
                  angle: _anim.value * 8 * pi,
                  child: SizedBox(
                    width: 180, height: 180,
                    child: CustomPaint(painter: _WheelPainter(_wheelColors)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_spinning && _currentQ == null && _round < _total)
                ElevatedButton(
                  onPressed: _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDB2777),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('SPIN!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                )
              else if (_spinning)
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ]),
          ),
        ),
        // Question section
        Expanded(
          child: _currentQ == null
              ? Center(child: Text(_round >= _total ? 'Game Over!' : 'Spin to get a question!',
                  style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: AppTheme.textMediumColor(context))))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                      child: Text(_currentQ!['q'], style: TextStyle(fontSize: 17, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    // Options
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: (_currentQ!['opts'] as List<String>).asMap().entries.map((e) {
                        final isCorrect = e.value == _currentQ!['a'];
                        Color color = const Color(0xFFDB2777);
                        if (_answered && _selected == e.key) color = isCorrect ? const Color(0xFF059669) : AppTheme.error;
                        else if (_answered && isCorrect) color = const Color(0xFF059669);
                        return ElevatedButton(
                          onPressed: _answered ? null : () => _answer(e.value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            disabledBackgroundColor: color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(e.value, style: const TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    if (_answered && _round < _total) ...[
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: ElevatedButton(
                        onPressed: _spin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB2777),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text('Spin Again!', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                      )),
                    ],
                  ]),
                ),
        ),
      ]),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Color> colors;
  _WheelPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final segmentAngle = (2 * pi) / colors.length;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle - pi / 2, segmentAngle, true, paint);
    }

    // Center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, 20, paint);
    paint.color = const Color(0xFFDB2777);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, 20, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}