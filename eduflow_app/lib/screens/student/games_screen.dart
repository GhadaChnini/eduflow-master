import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../games/memory_game_screen.dart';
import '../games/word_scramble_screen.dart';
import '../games/math_challenge_screen.dart';
import '../games/catch_answer_screen.dart';
import '../games/picture_match_screen.dart';
import '../games/spin_wheel_screen.dart';
import '../games/webview_game_screen.dart';

// ─── Add Points Helper ────────────────────────────────────────────────────────
Future<void> awardPoints(int points) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    await Supabase.instance.client.rpc('add_points', params: {'user_id': user.id, 'points_to_add': points});
  } catch (e) { debugPrint('Award points error: $e'); }
}

// ─── Game Result Dialog ───────────────────────────────────────────────────────
Future<void> showGameResult(BuildContext context, int score, int maxScore, String gameName) async {
  await awardPoints(score);
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(score >= maxScore * 0.8 ? '🎉' : score >= maxScore * 0.5 ? '👍' : '💪', style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(gameName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
        const SizedBox(height: 8),
        Text('Score: $score / $maxScore', style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', color: AppTheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('+$score points earned!', style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF059669))),
      ]),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
          child: const Text('Done', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontWeight: FontWeight.bold))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          child: const Text('Play Again', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

// ─── Games Launcher ───────────────────────────────────────────────────────────
class StudentGamesScreen extends ConsumerWidget {
  const StudentGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    final games = [
      {'emoji': '🧩', 'title': 'Memory Match', 'desc': 'Flip cards to find pairs', 'color': const Color(0xFF7C3AED), 'screen': const MemoryGameScreen()},
      {'emoji': '🔤', 'title': 'Word Scramble', 'desc': 'Unscramble the letters', 'color': const Color(0xFF059669), 'screen': const WordScrambleScreen()},
      {'emoji': '🔢', 'title': 'Math Challenge', 'desc': 'Solve math problems fast', 'color': const Color(0xFF2563EB), 'screen': const MathChallengeScreen()},
      {'emoji': '🎯', 'title': 'Catch Answer', 'desc': 'Catch the correct answer', 'color': const Color(0xFFDC2626), 'screen': const CatchAnswerScreen()},
      {'emoji': '🖼️', 'title': 'Picture Match', 'desc': 'Match image to word', 'color': const Color(0xFFD97706), 'screen': const PictureMatchScreen()},
      {'emoji': '🎡', 'title': 'Spin Wheel', 'desc': 'Spin and answer', 'color': const Color(0xFFDB2777), 'screen': const SpinWheelScreen()},
      {'emoji': '🌐', 'title': 'Web Learning', 'desc': 'Educational web games', 'color': const Color(0xFF0891B2), 'screen': const WebViewGameScreen(url: 'https://www.mathsisfun.com/games/', title: 'Web Learning')},
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); else context.go('/home'); },
              child: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Games', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              Text('Play & earn points', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
            ]),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.05, crossAxisSpacing: 12, mainAxisSpacing: 12),
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final g = games[i];
              final color = g['color'] as Color;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => g['screen'] as Widget)),
                child: Container(
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderC)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 60, height: 60, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                      child: Center(child: Text(g['emoji'] as String, style: const TextStyle(fontSize: 28)))),
                    const SizedBox(height: 10),
                    Text(g['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                    const SizedBox(height: 2),
                    Text(g['desc'] as String, style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                  ]),
                ),
              );
            }, childCount: games.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }
} 