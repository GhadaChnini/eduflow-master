import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  int _myRank = 0;
  Map<String, dynamic>? _myProfile;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, name, avatar_url, points, grade_level')
          .eq('role', 'parent')
          .order('points', ascending: false)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(res);
      int myRank = 0;
      Map<String, dynamic>? myProfile;
      for (int i = 0; i < list.length; i++) {
        if (list[i]['id'] == user?.id) {
          myRank = i + 1;
          myProfile = list[i];
          break;
        }
      }
      if (mounted) setState(() {
        _students = list;
        _myRank = myRank;
        _myProfile = myProfile;
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
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // Header
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); else context.go('/home'); },
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
                ),
                const SizedBox(width: 12),
                const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              ]),
              if (_myProfile != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    CircleAvatar(radius: 22, backgroundColor: Colors.white.withOpacity(0.3),
                      backgroundImage: _myProfile!['avatar_url'] != null ? NetworkImage(_myProfile!['avatar_url']) : null,
                      child: _myProfile!['avatar_url'] == null ? Text((_myProfile!['name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)) : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_myProfile!['name'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      Text('Your rank', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('#$_myRank', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                      Text('${_myProfile!['points'] ?? 0} pts', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                    ]),
                  ]),
                ),
              ],
            ]),
          )),

          // Top 3
          if (!_loading && _students.length >= 3)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _podium(_students[1], 2, 100, card, textD, textM, user?.id),
                _podium(_students[0], 1, 130, card, textD, textM, user?.id),
                _podium(_students[2], 3, 80, card, textD, textM, user?.id),
              ]),
            )),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // List
          _loading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: Color(0xFFF59E0B)))))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                    final s = _students[i];
                    final isMe = s['id'] == user?.id;
                    final rank = i + 1;
                    if (rank <= 3) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFF59E0B).withOpacity(0.08) : card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isMe ? const Color(0xFFF59E0B).withOpacity(0.4) : borderC),
                      ),
                      child: Row(children: [
                        SizedBox(width: 32, child: Center(child: Text('$rank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textM, fontFamily: 'Cairo')))),
                        const SizedBox(width: 8),
                        CircleAvatar(radius: 18, backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: s['avatar_url'] != null ? NetworkImage(s['avatar_url']) : null,
                          child: s['avatar_url'] == null ? Text((s['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)) : null),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: textD))),
                        Text('${s['points'] ?? 0} pts', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: isMe ? const Color(0xFFF59E0B) : textM, fontSize: 13)),
                      ]),
                    );
                  }, childCount: _students.length)),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _podium(Map<String, dynamic> s, int rank, double height, Color card, Color textD, Color textM, String? myId) {
    final isMe = s['id'] == myId;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
    final color = rank == 1 ? const Color(0xFFF59E0B) : rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFCD7F32);
    return Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        CircleAvatar(radius: rank == 1 ? 28 : 22,
          backgroundColor: color.withOpacity(0.2),
          backgroundImage: s['avatar_url'] != null ? NetworkImage(s['avatar_url']) : null,
          child: s['avatar_url'] == null ? Text((s['name'] ?? '?')[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: rank == 1 ? 20 : 16)) : null),
        const SizedBox(height: 6),
        Text(s['name'] ?? '', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        Text('${s['points'] ?? 0} pts', style: TextStyle(fontSize: 10, color: textM, fontFamily: 'Cairo')),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(isMe ? 0.4 : 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(child: Text('#$rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'))),
        ),
      ]),
    );
  }
}