import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../student/games_screen.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<String> _emojis = ['🐱', '🐶', '🐸', '🦁', '🐻', '🦊', '🐼', '🐨'];
  late List<String> _cards;
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _firstIndex;
  bool _canFlip = true;
  int _moves = 0;
  int _matches = 0;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() { super.initState(); _start(); }

  void _start() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstIndex = null; _canFlip = true; _moves = 0; _matches = 0; _seconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
    setState(() {});
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _onTap(int i) {
    if (!_canFlip || _flipped[i] || _matched[i]) return;
    setState(() => _flipped[i] = true);
    if (_firstIndex == null) {
      _firstIndex = i;
    } else {
      _moves++;
      _canFlip = false;
      if (_cards[_firstIndex!] == _cards[i]) {
        setState(() { _matched[_firstIndex!] = true; _matched[i] = true; _matches++; });
        _firstIndex = null; _canFlip = true;
        if (_matches == _emojis.length) {
          _timer?.cancel();
          final score = max(0, 100 - _moves * 2 - _seconds ~/ 5);
          Future.delayed(const Duration(milliseconds: 500), () => showGameResult(context, score, 100, 'Memory Match'));
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() { _flipped[_firstIndex!] = false; _flipped[i] = false; _firstIndex = null; _canFlip = true; });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
        title: const Text('Memory Match 🧩', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Text('⏱ $_seconds s   👆 $_moves', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _start),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 16,
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => _onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _matched[i] ? const Color(0xFF059669).withOpacity(0.2) : _flipped[i] ? Colors.white : const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _matched[i] ? const Color(0xFF059669) : const Color(0xFF7C3AED), width: 2),
              ),
              child: Center(child: Text(_flipped[i] || _matched[i] ? _cards[i] : '?', style: const TextStyle(fontSize: 28))),
            ),
          ),
        ),
      ),
    );
  }
}