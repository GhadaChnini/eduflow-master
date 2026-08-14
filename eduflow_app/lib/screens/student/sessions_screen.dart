import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import 'quiz_screen.dart' as student_quiz;
import 'payment_screen.dart';

class StudentSessionsScreen extends ConsumerStatefulWidget {
  const StudentSessionsScreen({super.key});
  @override
  ConsumerState<StudentSessionsScreen> createState() => _StudentSessionsScreenState();
}

class _StudentSessionsScreenState extends ConsumerState<StudentSessionsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _sessions = [];
  Set<String> _enrolledIds = {};
  bool _loading = true;
  String _filter = 'upcoming';
  String _searchQuery = '';
  String _priceFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final sessions = await Supabase.instance.client
          .from('live_sessions')
          .select('*, profiles!teacher_id(name, avatar_url)')
          .order('scheduled_at');

      final enrollments = await Supabase.instance.client
          .from('session_enrollments')
          .select('session_id')
          .eq('student_id', user.id);

      if (mounted) setState(() {
        _sessions = List<Map<String, dynamic>>.from(sessions);
        _enrolledIds = Set<String>.from(
          (enrollments as List).map((e) => e['session_id'].toString())
        );
        _loading = false;
      });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _sessions.where((s) {
      final scheduled = DateTime.parse(s['scheduled_at']);
      final status = s['status'] as String? ?? '';
      final title = (s['title'] ?? '').toLowerCase();
      final isPaid = s['is_paid'] == true;

      // Status filter
      bool statusMatch = true;
      if (_filter == 'upcoming') statusMatch = status == 'scheduled' && scheduled.isAfter(now);
      else if (_filter == 'live') statusMatch = status == 'live';
      else if (_filter == 'enrolled') statusMatch = _enrolledIds.contains(s['id'].toString());
      else if (_filter == 'completed') statusMatch = status == 'completed';

      // Search filter
      final searchMatch = _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());

      // Price filter
      bool priceMatch = true;
      if (_priceFilter == 'free') priceMatch = !isPaid;
      else if (_priceFilter == 'paid') priceMatch = isPaid;

      return statusMatch && searchMatch && priceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) Navigator.pop(context);
                    else context.go('/home');
                  },
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                  Text('${_sessions.length} available', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                ]),
              ]),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterChip('upcoming', 'Upcoming'),
                  _filterChip('live', 'Live Now'),
                  _filterChip('enrolled', 'My Sessions'),
                  _filterChip('completed', 'Ended'),
                  _filterChip('all', 'All'),
                ]),
              ),
              const SizedBox(height: 12),
              // Search bar
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    hintText: 'Search sessions...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Cairo'),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Price filter
              Row(children: [
                ...['all', 'free', 'paid'].map((p) {
                  final isSelected = _priceFilter == p;
                  final label = p == 'all' ? 'All' : p == 'free' ? 'Free' : 'Paid';
                  return GestureDetector(
                    onTap: () => setState(() => _priceFilter = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo',
                        color: isSelected ? AppTheme.primary : Colors.white)),
                    ),
                  );
                }),
              ]),
            ]),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _loading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
              : _filtered.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                      const Text('📅', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('No sessions found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                    ]))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                        final s = _filtered[i];
                        return _SessionCard(
                          session: s,
                          isEnrolled: _enrolledIds.contains(s['id'].toString()),
                          lang: _lang,
                          onEnrolled: _load,
                        );
                      }, childCount: _filtered.length)),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _filterChip(String val, String label) => GestureDetector(
    onTap: () => setState(() => _filter = val),
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _filter == val ? Colors.white : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold,
        color: _filter == val ? AppTheme.primary : Colors.white)),
    ),
  );
}

// ─── Session Card ────────────────────────────────────────────────────────────

class _SessionCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  final bool isEnrolled;
  final String lang;
  final VoidCallback onEnrolled;
  const _SessionCard({required this.session, required this.isEnrolled, required this.lang, required this.onEnrolled});
  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _enrolling = false;

  Future<void> _enroll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _enrolling = true);
    try {
      await Supabase.instance.client.from('session_enrollments').insert({
        'session_id': widget.session['id'],
        'student_id': user.id,
      });
      widget.onEnrolled();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enrolled successfully!', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    }
    if (mounted) setState(() => _enrolling = false);
  }

  Future<void> _joinSession() async {
    final url = widget.session['meeting_url'] as String?;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No meeting link available', style: TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final s = widget.session;
    final teacher = s['profiles'] as Map?;
    final scheduled = DateTime.parse(s['scheduled_at']);
    final status = s['status'] as String? ?? 'scheduled';
    final isPaid = s['is_paid'] == true;
    final price = s['price'] ?? 0;
    final isLive = status == 'live';

    return GestureDetector(
      onTap: () {
        final sessionStatus = s['status'] as String? ?? '';
        if (sessionStatus == 'completed' || sessionStatus == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              sessionStatus == 'completed' ? 'This session has ended' : 'This session was cancelled',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: sessionStatus == 'completed' ? Colors.grey : AppTheme.error,
          ));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudentSessionDetailScreen(
            session: s,
            isEnrolled: widget.isEnrolled,
            onEnrolled: widget.onEnrolled,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLive ? const Color(0xFF059669).withOpacity(0.5) : borderC),
          boxShadow: isLive ? [BoxShadow(color: const Color(0xFF059669).withOpacity(0.1), blurRadius: 12)] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          if (isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const Text('LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(s['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? AppTheme.secondary.withOpacity(0.1) : const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isPaid ? '$price DT' : 'Free',
                    style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                      color: isPaid ? AppTheme.secondary : const Color(0xFF059669)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // Teacher
              Row(children: [
                CircleAvatar(radius: 12, backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: teacher?['avatar_url'] != null ? NetworkImage(teacher!['avatar_url']) : null,
                  child: teacher?['avatar_url'] == null ? Text((teacher?['name'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)) : null),
                const SizedBox(width: 6),
                Text(teacher?['name'] ?? '', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: textM),
                const SizedBox(width: 4),
                Text('${scheduled.day}/${scheduled.month}/${scheduled.year}', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 13, color: textM),
                const SizedBox(width: 4),
                Text('${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 13, color: textM),
                const SizedBox(width: 4),
                Text('${s['duration_minutes'] ?? 60} min', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
              ]),
              const SizedBox(height: 12),
              // Action button
              SizedBox(
                width: double.infinity,
                child: widget.isEnrolled
                    ? isLive
                        ? ElevatedButton.icon(
                            onPressed: _joinSession,
                            icon: const Icon(Icons.videocam, size: 18),
                            label: const Text('Join Session', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Center(child: Text('Enrolled', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13))),
                          )
                    : status == 'completed'
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                            child: Center(child: Text('Session Completed', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: textM))),
                          )
                        : isPaid
                            ? ElevatedButton(
                                onPressed: _enrolling ? null : () => _showPaymentSheet(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                ),
                                child: _enrolling
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('Pay $price DT & Enroll', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              )
                            : ElevatedButton(
                                onPressed: _enrolling ? null : _enroll,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                ),
                                child: _enrolling
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Enroll Free', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final s = widget.session;
    final price = s['price'] ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Text('💳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Pay to Enroll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
          const SizedBox(height: 8),
          Text('${s['title']}', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: AppTheme.textMediumColor(context))),
          const SizedBox(height: 4),
          Text('$price DT', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.secondary, fontFamily: 'Cairo')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.bgColor(context), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _payRow('Session', s['title'] ?? ''),
              const Divider(height: 16),
              _payRow('Duration', '${s['duration_minutes'] ?? 60} minutes'),
              const Divider(height: 16),
              _payRow('Total', '$price DT', bold: true),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _enroll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text('Confirm Payment & Enroll', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
          )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context))),
          ),
        ]),
      ),
    );
  }

  Widget _payRow(String label, String value, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context), fontSize: 13)),
      Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: bold ? AppTheme.secondary : AppTheme.textDarkColor(context), fontSize: bold ? 16 : 13)),
    ],
  );
}

// ─── Student Session Detail Screen ──────────────────────────────────────────

class StudentSessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  final bool isEnrolled;
  final VoidCallback onEnrolled;
  const StudentSessionDetailScreen({super.key, required this.session, required this.isEnrolled, required this.onEnrolled});

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
  late Map<String, dynamic> _session;
  late bool _isEnrolled;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _isEnrolled = widget.isEnrolled;
    _reload();
  }

  Future<void> _reload() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final res = await Supabase.instance.client
          .from('live_sessions')
          .select('*, profiles!teacher_id(name, avatar_url)')
          .eq('id', widget.session['id'])
          .single();
      bool enrolled = _isEnrolled;
      if (user != null) {
        final e = await Supabase.instance.client
            .from('session_enrollments')
            .select()
            .eq('session_id', widget.session['id'])
            .eq('student_id', user.id)
            .maybeSingle();
        enrolled = e != null;
      }
      if (mounted) setState(() {
        _session = Map<String, dynamic>.from(res);
        _isEnrolled = enrolled;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final teacher = _session['profiles'] as Map?;
    final scheduled = DateTime.parse(_session['scheduled_at']);
    final status = _session['status'] as String? ?? 'scheduled';
    final isPaid = _session['is_paid'] == true;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)))),
            const SizedBox(height: 20),
            if (status == 'live')
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(100)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const Text('LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                ]),
              ),
            Text(_session['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(
              isPaid ? '${_session['price']} DT' : 'Free',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPaid ? const Color(0xFFFBBF24) : const Color(0xFF6EE7B7), fontFamily: 'Cairo'),
            ),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Teacher info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
              child: Row(children: [
                CircleAvatar(radius: 22, backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: teacher?['avatar_url'] != null ? NetworkImage(teacher!['avatar_url']) : null,
                  child: teacher?['avatar_url'] == null ? Text((teacher?['name'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)) : null),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(teacher?['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                  Text('Teacher', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            // Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
              child: Column(children: [
                _detailRow(Icons.calendar_today_outlined, 'Date', '${scheduled.day}/${scheduled.month}/${scheduled.year}', textD, textM),
                const Divider(height: 20),
                _detailRow(Icons.access_time, 'Time', '${scheduled.hour.toString().padLeft(2,'0')}:${scheduled.minute.toString().padLeft(2,'0')}', textD, textM),
                const Divider(height: 20),
                _detailRow(Icons.timer_outlined, 'Duration', '${_session['duration_minutes'] ?? 60} minutes', textD, textM),
                const Divider(height: 20),
                _detailRow(Icons.people_outline, 'Enrolled', '${_session['total_enrolled'] ?? 0} students', textD, textM),
                if (_session['max_students'] != null) ...[
                  const Divider(height: 20),
                  _detailRow(Icons.group_outlined, 'Max Students', '${_session['max_students']}', textD, textM),
                ],
              ]),
            ),
            if (_session['description'] != null && (_session['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                  const SizedBox(height: 8),
                  Text(_session['description'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM, height: 1.6)),
                ]),
              ),
            ],
            // Quiz banner when live and enrolled
            if (status == 'live' && _isEnrolled) ...[
              const SizedBox(height: 8),
              LiveSessionQuizBanner(sessionId: _session['id']),
            ],
            const SizedBox(height: 100),
          ]),
        )),
      ]),
      bottomNavigationBar: _SessionDetailBottomBar(
        session: _session,
        isEnrolled: _isEnrolled,
        onEnrolled: widget.onEnrolled,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textD, Color textM) => Row(children: [
    Container(width: 36, height: 36,
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: AppTheme.primary)),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textD, fontFamily: 'Cairo')),
    ]),
  ]);
}

// ─── Session Detail Bottom Bar ───────────────────────────────────────────────

class _SessionDetailBottomBar extends StatefulWidget {
  final Map<String, dynamic> session;
  final bool isEnrolled;
  final VoidCallback onEnrolled;
  const _SessionDetailBottomBar({required this.session, required this.isEnrolled, required this.onEnrolled});
  @override
  State<_SessionDetailBottomBar> createState() => _SessionDetailBottomBarState();
}

class _SessionDetailBottomBarState extends State<_SessionDetailBottomBar> {
  bool _enrolling = false;

  Future<void> _enroll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _enrolling = true);
    try {
      await Supabase.instance.client.from('session_enrollments').insert({
        'session_id': widget.session['id'],
        'student_id': user.id,
      });
      widget.onEnrolled();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enrolled successfully!', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    }
    if (mounted) setState(() => _enrolling = false);
  }

  Future<void> _joinSession() async {
    final url = widget.session['meeting_url'] as String?;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final card = AppTheme.cardColor(context);
    final textM = AppTheme.textMediumColor(context);
    final s = widget.session;
    final status = s['status'] as String? ?? 'scheduled';
    final isPaid = s['is_paid'] == true;
    final price = s['price'] ?? 0;
    final isLive = status == 'live';
    final isEnded = status == 'completed';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: card,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: widget.isEnrolled
          ? isLive
              ? ElevatedButton.icon(
                  onPressed: _joinSession,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Join Session', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                  child: const Center(child: Text('You are enrolled', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15))),
                )
          : isEnded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                  child: Center(child: Text('Session Completed', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: textM))),
                )
              : isPaid
                  ? ElevatedButton(
                      onPressed: _enrolling ? null : () => _showPaymentSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: _enrolling
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Pay $price DT & Enroll', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                    )
                  : ElevatedButton(
                      onPressed: _enrolling ? null : _enroll,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: _enrolling
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enroll Free', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final s = widget.session;
    final price = s['price'] ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Text('💳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Pay to Enroll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
          const SizedBox(height: 4),
          Text('${s['title']}', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: AppTheme.textMediumColor(context))),
          const SizedBox(height: 8),
          Text('$price DT', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.secondary, fontFamily: 'Cairo')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.bgColor(context), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Session', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context), fontSize: 13)),
                Flexible(child: Text(s['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, color: AppTheme.textDarkColor(context), fontSize: 13))),
              ]),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Duration', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context), fontSize: 13)),
                Text('${s['duration_minutes'] ?? 60} min', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context), fontSize: 13)),
              ]),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$price DT', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 16)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async { Navigator.pop(ctx); await _enroll(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Confirm & Enroll', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)))),
        ]),
      ),
    );
  }
}

// ─── Live Session Quiz Banner ─────────────────────────────────────────────────

class LiveSessionQuizBanner extends StatefulWidget {
  final String sessionId;
  const LiveSessionQuizBanner({super.key, required this.sessionId});
  @override
  State<LiveSessionQuizBanner> createState() => _LiveSessionQuizBannerState();
}

class _LiveSessionQuizBannerState extends State<LiveSessionQuizBanner> {
  List<Map<String, dynamic>> _activeQuizzes = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }

  Future<void> _poll() async {
    try {
      final res = await Supabase.instance.client
          .from('quizzes')
          .select()
          .eq('session_id', widget.sessionId)
          .eq('is_active', true);
      if (mounted) setState(() => _activeQuizzes = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_activeQuizzes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _activeQuizzes.map((quiz) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => student_quiz.StudentQuizScreen(quizId: quiz['id'], sessionId: widget.sessionId),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🧠', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quiz Available!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
              Text(quiz['title_ar'] ?? quiz['title'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontFamily: 'Cairo')),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
              child: const Text('Start', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
            ),
          ]),
        ),
      )).toList(),
    );
  }
}