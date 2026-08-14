import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/common/main_scaffold.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String _lang = 'ar';
  int _rank = 0;
  DateTime? _lastSpin;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);
    final profile = await authService.getCurrentProfile();
    // Fetch rank
    int rank = 0;
    if (profile != null) {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id, points')
            .eq('role', 'parent')
            .order('points', ascending: false);
        final list = List<Map<String, dynamic>>.from(res);
        rank = list.indexWhere((p) => p['id'] == profile['id']) + 1;
      } catch (_) {}
    }
    // Check last spin from shared prefs via profile metadata or local storage
    if (mounted) setState(() { _profile = profile; _rank = rank; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final name = _profile?['name'] ?? Tr.t('default_student', _lang);
    final points = _profile?['points'] ?? 0;
    final gradeLevel = _profile?['grade_level'];

    final gradeNames = {1: 'السنة 1', 2: 'السنة 2', 3: 'السنة 3', 4: 'السنة 4', 5: 'السنة 5', 6: 'السنة 6'};

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadProfile,
              child: CustomScrollView(
                slivers: [
                  // Top section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    image: _profile?['avatar_url'] != null
                                        ? DecorationImage(image: NetworkImage(_profile!['avatar_url']), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: _profile?['avatar_url'] == null
                                      ? Center(child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '؟',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                        ))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(Tr.t('hello', _lang), style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                              // Notification
                              GestureDetector(
                                onTap: () => context.go('/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(child: Text('🔔', style: TextStyle(fontSize: 20))),
                                    ),
                                    Consumer(
                                      builder: (ctx, ref, _) {
                                        final count = ref.watch(unreadNotifProvider).value ?? 0;
                                        if (count == 0) return const SizedBox.shrink();
                                        return Positioned(
                                          top: -4, right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                            child: Text(
                                              count > 99 ? '99+' : '$count',
                                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Stats row
                          Row(
                            children: [
                              _statChip('⭐', '$points', Tr.t('points', _lang)),
                              const SizedBox(width: 10),
                              if (gradeLevel != null)
                                _statChip('🎓', gradeNames[gradeLevel] ?? 'السنة $gradeLevel', ''),
                              const SizedBox(width: 10),
                              _statChip('🏆', _rank > 0 ? '#$_rank' : '#—', Tr.t('rank', _lang)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Quick actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Tr.t('what_to_do', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _quickAction(context, '🏆', Tr.t('rank', _lang), '/leaderboard', card, textD),
                              const SizedBox(width: 12),
                              _quickAction(context, '🎯', 'Badges', '/achievements', card, textD),
                              const SizedBox(width: 12),
                              _quickAction(context, '📅', Tr.t('sessions', _lang), '/sessions', card, textD),
                              const SizedBox(width: 12),
                              _quickAction(context, '📊', Tr.t('progress', _lang), '/progress', card, textD),
                              const SizedBox(width: 12),
                              _quickAction(context, '🎮', Tr.t('nav_games', _lang), '/games', card, textD),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Lucky Wheel daily card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _LuckyWheelCard(onPointsEarned: _loadProfile),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Continue learning section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Tr.t('continue_learning', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                          GestureDetector(
                            onTap: () => context.go('/browse'),
                            child: Text(Tr.t('view_all', _lang), style: TextStyle(fontSize: 13, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Empty state
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => context.go('/browse'),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              const Text('🚀', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(Tr.t('start_journey', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                              const SizedBox(height: 8),
                              Text(Tr.t('browse_units_desc', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(100)),
                                child: Text(Tr.t('browse_units', _lang), style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _statChip(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? value : '$value $label',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, String emoji, String label, String route, Color card, Color textD) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: textD),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lucky Wheel Card ─────────────────────────────────────────────────────────
class _LuckyWheelCard extends StatefulWidget {
  final VoidCallback onPointsEarned;
  const _LuckyWheelCard({required this.onPointsEarned});
  @override
  State<_LuckyWheelCard> createState() => _LuckyWheelCardState();
}

class _LuckyWheelCardState extends State<_LuckyWheelCard> {
  bool _spunToday = false;
  DateTime? _lastSpinDate;

  @override
  void initState() { super.initState(); _checkLastSpin(); }

  Future<void> _checkLastSpin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('last_spin_date')
          .eq('id', user.id)
          .single();
      final lastSpin = res['last_spin_date'];
      if (lastSpin != null) {
        final date = DateTime.tryParse(lastSpin);
        if (date != null) {
          final now = DateTime.now();
          final spunToday = date.year == now.year && date.month == now.month && date.day == now.day;
          if (mounted) setState(() { _lastSpinDate = date; _spunToday = spunToday; });
        }
      }
    } catch (_) {}
  }

  void _openWheel() {
    if (_spunToday) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already spun today! Come back tomorrow 🌙', style: TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LuckyWheelScreen(onSpinComplete: () {
        setState(() => _spunToday = true);
        widget.onPointsEarned();
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openWheel,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _spunToday
                ? [const Color(0xFF6B7280), const Color(0xFF9CA3AF)]
                : [const Color(0xFFF59E0B), const Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Text(_spunToday ? '🌙' : '🎰', style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lucky Wheel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            Text(
              _spunToday ? 'Come back tomorrow!' : 'Spin for free points!',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), fontFamily: 'Cairo'),
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(100)),
            child: Text(_spunToday ? 'Done ✓' : 'Spin!',
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

// ─── Lucky Wheel Screen ───────────────────────────────────────────────────────
class LuckyWheelScreen extends StatefulWidget {
  final VoidCallback onSpinComplete;
  const LuckyWheelScreen({super.key, required this.onSpinComplete});
  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _spinning = false;
  bool _done = false;
  double _totalRotation = 0;

  final List<Map<String, dynamic>> _segments = [
    {'label': '+5 pts', 'points': 5, 'color': const Color(0xFF7C3AED)},
    {'label': 'Try Again', 'points': 0, 'color': const Color(0xFF374151)},
    {'label': '+10 pts', 'points': 10, 'color': const Color(0xFF059669)},
    {'label': '+5 pts', 'points': 5, 'color': const Color(0xFF2563EB)},
    {'label': '+15 pts', 'points': 15, 'color': const Color(0xFFDB2777)},
    {'label': 'Try Again', 'points': 0, 'color': const Color(0xFF374151)},
    {'label': '+10 pts', 'points': 10, 'color': const Color(0xFFF59E0B)},
    {'label': '+5 pts', 'points': 5, 'color': const Color(0xFFDC2626)},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _spin() async {
    if (_spinning || _done) return;
    setState(() => _spinning = true);
    final rng = Random();
    final landIndex = rng.nextInt(_segments.length);
    final segmentAngle = (2 * pi) / _segments.length;
    final extraRotations = 5 + rng.nextInt(3);
    _totalRotation = extraRotations * 2 * pi + (landIndex * segmentAngle);

    _ctrl.duration = const Duration(seconds: 4);
    _ctrl.reset();
    await _ctrl.forward();

    final prize = _segments[landIndex]['points'] as int;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'last_spin_date': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      if (prize > 0) {
        await Supabase.instance.client.rpc('add_points', params: {'user_id': user.id, 'points_to_add': prize});
      }
    }

    if (mounted) setState(() { _spinning = false; _done = true; });
    widget.onSpinComplete();
    _showResult(prize, _segments[landIndex]['label'] as String);
  }

  void _showResult(int points, String label) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(points > 0 ? '🎉' : '😅', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFFF59E0B))),
          const SizedBox(height: 8),
          Text(
            points > 0 ? '+$points points added!' : 'Better luck tomorrow!',
            style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ]),
        actions: [
          Center(child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Awesome!', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wheelSize = size.width * 0.82;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B2A),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                ),
              ),
              const Expanded(child: Center(
                child: Text('Lucky Wheel 🎰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              )),
              const SizedBox(width: 38),
            ]),
          ),
          const SizedBox(height: 8),
          Text(
            _done ? '🌙 Come back tomorrow!' : '1 free spin per day',
            style: const TextStyle(color: Colors.white38, fontFamily: 'Cairo', fontSize: 12),
          ),
          const Spacer(),
          // Wheel + pointer
          Stack(alignment: Alignment.topCenter, children: [
            // Glow effect
            Container(
              width: wheelSize + 20,
              height: wheelSize + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.25), blurRadius: 40, spreadRadius: 10)],
              ),
            ),
            // Wheel
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (ctx, _) => Transform.rotate(
                  angle: _anim.value * _totalRotation,
                  child: SizedBox(
                    width: wheelSize,
                    height: wheelSize,
                    child: CustomPaint(painter: _LuckyWheelPainter(_segments)),
                  ),
                ),
              ),
            ),
            // Pointer
            Positioned(
              top: 0,
              child: Container(
                width: 28, height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: const Center(child: Icon(Icons.arrow_downward, color: Colors.white, size: 18)),
              ),
            ),
            // Center pin
            Positioned(
              top: 24 + wheelSize / 2 - 18,
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Center(child: Text('⭐', style: TextStyle(fontSize: 18))),
              ),
            ),
          ]),
          const Spacer(),
          // Spin button
          if (!_done)
            GestureDetector(
              onTap: _spinning ? null : _spin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 180, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(child: _spinning
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('SPIN!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white, letterSpacing: 2)),
              )),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(100)),
              child: const Text('✓ Already spun today', style: TextStyle(color: Colors.white38, fontFamily: 'Cairo', fontSize: 14)),
            ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _LuckyWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  _LuckyWheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < segments.length; i++) {
      // Draw segment
      paint.color = segments[i]['color'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle - pi / 2,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle - pi / 2,
        segmentAngle,
        true,
        paint,
      );
      paint.style = PaintingStyle.fill;

      // Draw text
      final angle = i * segmentAngle - pi / 2 + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(angle);
      final textY = center.dy + textRadius * sin(angle);

      textPainter.text = TextSpan(
        text: segments[i]['label'] as String,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(angle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    // Center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, 24, paint);
    paint.color = const Color(0xFF1E1B4B);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(center, 24, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}