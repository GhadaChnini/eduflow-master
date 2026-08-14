import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});
  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _lang = 'ar';
  bool _loading = true;
  int _totalEnrollments = 0;
  int _completedUnits = 0;
  int _totalPoints = 0;
  int _quizzesDone = 0;
  bool _perfectScore = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles').select('points').eq('id', user.id).single();
      final enrollments = await Supabase.instance.client
          .from('unit_enrollments').select('progress').eq('student_id', user.id);
      final quizzes = await Supabase.instance.client
          .from('quiz_attempts').select('score, total_points').eq('student_id', user.id);
      final enrollList = List<Map<String, dynamic>>.from(enrollments);
      final quizList = List<Map<String, dynamic>>.from(quizzes);
      final hasPerfect = quizList.any((q) => q['score'] != null && q['total_points'] != null && q['score'] >= q['total_points']);
      if (mounted) setState(() {
        _totalPoints = profile['points'] ?? 0;
        _totalEnrollments = enrollList.length;
        _completedUnits = enrollList.where((e) => (e['progress'] ?? 0) >= 100).length;
        _quizzesDone = quizList.length;
        _perfectScore = hasPerfect;
        _loading = false;
      });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    final achievements = [
      _Achievement('🎓', 'First Step', 'Enroll in your first unit', _totalEnrollments >= 1, 1, _totalEnrollments, 1),
      _Achievement('📚', 'Bookworm', 'Enroll in 5 units', _totalEnrollments >= 5, 5, _totalEnrollments, 5),
      _Achievement('🏆', 'Scholar', 'Enroll in 10 units', _totalEnrollments >= 10, 10, _totalEnrollments, 10),
      _Achievement('🏁', 'Finisher', 'Complete your first unit', _completedUnits >= 1, 1, _completedUnits, 1),
      _Achievement('💯', 'Overachiever', 'Complete 5 units', _completedUnits >= 5, 5, _completedUnits, 5),
      _Achievement('🧠', 'Quiz Taker', 'Complete your first quiz', _quizzesDone >= 1, 1, _quizzesDone, 1),
      _Achievement('⭐', 'Quiz Master', 'Complete 5 quizzes', _quizzesDone >= 5, 5, _quizzesDone, 5),
      _Achievement('💎', 'Perfect', 'Get a perfect score on a quiz', _perfectScore, 1, _perfectScore ? 1 : 0, 1),
      _Achievement('🔥', 'Point Collector', 'Earn 100 points', _totalPoints >= 100, 100, _totalPoints, 100),
      _Achievement('🚀', 'High Scorer', 'Earn 500 points', _totalPoints >= 500, 500, _totalPoints, 500),
      _Achievement('👑', 'Champion', 'Earn 1000 points', _totalPoints >= 1000, 1000, _totalPoints, 1000),
    ];

    final earned = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); else context.go('/home'); },
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Achievements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                  Text('$earned / ${achievements.length} earned', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                ]),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: achievements.isEmpty ? 0 : earned / achievements.length,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
            ]),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _loading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: Color(0xFFF59E0B)))))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final a = achievements[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: a.unlocked ? const Color(0xFFF59E0B).withOpacity(0.1) : card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: a.unlocked ? const Color(0xFFF59E0B).withOpacity(0.5) : borderC),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(a.emoji, style: TextStyle(fontSize: 28, color: a.unlocked ? null : const Color(0xFFAAAAAA))),
                            const Spacer(),
                            if (a.unlocked) const Icon(Icons.check_circle, color: Color(0xFFF59E0B), size: 18)
                            else const Icon(Icons.lock, color: Color(0xFFAAAAAA), size: 16),
                          ]),
                          const SizedBox(height: 6),
                          Text(a.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: a.unlocked ? textD : textM)),
                          Text(a.description, style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: textM), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          if (!a.unlocked) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: (a.current / a.target).clamp(0.0, 1.0),
                                backgroundColor: borderC,
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('${a.current.clamp(0, a.target)} / ${a.target}', style: TextStyle(fontSize: 9, fontFamily: 'Cairo', color: textM)),
                          ],
                        ]),
                      );
                    }, childCount: achievements.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }
}

class _Achievement {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final int target;
  final int current;
  final int maxDisplay;
  const _Achievement(this.emoji, this.title, this.description, this.unlocked, this.target, this.current, this.maxDisplay);
}