import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('unit_enrollments')
          .select('*, behavioral_units!unit_id(id, title_ar, title, avg_rating, teacher_id, profiles!teacher_id(name))')
          .eq('student_id', user.id)
          .order('enrolled_at', ascending: false);
      if (mounted) setState(() {
        _enrollments = List<Map<String, dynamic>>.from(res);
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

    final completed = _enrollments.where((e) => (e['progress'] ?? 0) >= 100).length;
    final inProgress = _enrollments.where((e) => (e['progress'] ?? 0) > 0 && (e['progress'] ?? 0) < 100).length;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                  const Text('My Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                  Text('${_enrollments.length} units enrolled', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                ]),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                _summaryChip('📚', '${_enrollments.length}', 'Enrolled'),
                const SizedBox(width: 10),
                _summaryChip('🔄', '$inProgress', 'In Progress'),
                const SizedBox(width: 10),
                _summaryChip('🏁', '$completed', 'Completed'),
              ]),
            ]),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _loading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
              : _enrollments.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                      const Text('📚', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('No units enrolled yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                      const SizedBox(height: 8),
                      Text('Browse units to get started', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/browse'),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        child: const Text('Browse Units', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    ]))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                        final e = _enrollments[i];
                        final unit = e['behavioral_units'] as Map?;
                        final teacher = unit?['profiles'] as Map?;
                        final progress = (e['progress'] ?? 0) as int;
                        final isCompleted = progress >= 100;
                        return GestureDetector(
                          onTap: () => context.push('/unit/${unit?['id']}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isCompleted ? const Color(0xFF059669).withOpacity(0.3) : borderC),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(unit?['title_ar'] ?? unit?['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                  const SizedBox(height: 2),
                                  Text(teacher?['name'] ?? '', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? const Color(0xFF059669).withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Completed' : '$progress%',
                                    style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                                      color: isCompleted ? const Color(0xFF059669) : AppTheme.primary),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation(isCompleted ? const Color(0xFF059669) : AppTheme.primary),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isCompleted ? 'All files completed' : progress == 0 ? 'Not started yet' : '$progress% of files completed',
                                style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textM),
                              ),
                            ]),
                          ),
                        );
                      }, childCount: _enrollments.length)),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _summaryChip(String emoji, String count, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
      ]),
    ),
  );
}