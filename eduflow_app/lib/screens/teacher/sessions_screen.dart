import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../services/notification_sender.dart';
import 'quiz_screen.dart';

class TeacherSessionsScreen extends ConsumerStatefulWidget {
  const TeacherSessionsScreen({super.key});
  @override
  ConsumerState<TeacherSessionsScreen> createState() => _TeacherSessionsScreenState();
}

class _TeacherSessionsScreenState extends ConsumerState<TeacherSessionsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      var query = Supabase.instance.client
          .from('live_sessions')
          .select('*, behavioral_units!unit_id(title_ar, title)')
          .eq('teacher_id', user.id)
          .order('scheduled_at');
      final res = await query;
      if (mounted) setState(() { _sessions = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _delete(String id) async {
    final user = Supabase.instance.client.auth.currentUser;
    final session = _sessions.firstWhere((s) => s['id'] == id, orElse: () => {});
    // Notify enrolled students before deleting
    try {
      final enrollments = await Supabase.instance.client
          .from('session_enrollments').select('student_id').eq('session_id', id);
      final studentIds = (enrollments as List).map((e) => e['student_id'].toString())
          .where((sid) => sid != (user?.id ?? '')).toList();
      if (studentIds.isNotEmpty) {
        final sessionTitle = session['title']?.toString() ?? '';
        await Supabase.instance.client.from('notifications').insert(
          studentIds.map((sid) => {
            'user_id': sid,
            'sender_id': user?.id,
            'title': 'Session cancelled',
            'title_ar': 'تم إلغاء الجلسة',
            'message': 'The session "$sessionTitle" has been cancelled.',
            'message_ar': 'تم إلغاء الجلسة "$sessionTitle".',
            'type': 'announcement',
          }).toList(),
        );
        await NotificationSender.sendToUsers(
          userIds: studentIds,
          title: '❌ Session Cancelled',
          body: 'The session "$sessionTitle" has been cancelled.',
        );
      }
    } catch (e) { debugPrint('Notify cancel error: $e'); }
    await Supabase.instance.client.from('live_sessions').delete().eq('id', id);
    _load();
  }

  Future<void> _editSession(Map<String, dynamic> session) async {
    final titleCtrl = TextEditingController(text: session['title'] ?? '');
    final urlCtrl = TextEditingController(text: session['meeting_url'] ?? '');
    final durationCtrl = TextEditingController(text: (session['duration_minutes'] ?? 60).toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text('Edit Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
            const SizedBox(height: 16),
            _buildEditField(titleCtrl, 'Session Title', context),
            const SizedBox(height: 12),
            _buildEditField(urlCtrl, 'Meeting Link', context),
            const SizedBox(height: 12),
            _buildEditField(durationCtrl, 'Duration (minutes)', context, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.from('live_sessions').update({
                  'title': titleCtrl.text.trim(),
                  'title_ar': titleCtrl.text.trim(),
                  'meeting_url': urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                  'duration_minutes': int.tryParse(durationCtrl.text) ?? 60,
                }).eq('id', session['id']);
                // Notify enrolled students
                final user = Supabase.instance.client.auth.currentUser;
                final enrollments = await Supabase.instance.client
                    .from('session_enrollments').select('student_id').eq('session_id', session['id']);
                final studentIds = (enrollments as List).map((e) => e['student_id'].toString())
                    .where((sid) => sid != (user?.id ?? '')).toList();
                if (studentIds.isNotEmpty) {
                  final t = titleCtrl.text;
                  await Supabase.instance.client.from('notifications').insert(
                    studentIds.map((sid) => {
                      'user_id': sid,
                      'sender_id': user?.id,
                      'title': 'Session details updated',
                      'title_ar': 'تم تحديث تفاصيل الجلسة',
                      'message': 'Session "$t" details have been updated.',
                      'message_ar': 'تم تحديث تفاصيل الجلسة "$t".',
                      'type': 'announcement',
                    }).toList(),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
              child: const Text('Save Changes', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String hint, BuildContext ctx, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(ctx)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(ctx)),
        filled: true, fillColor: AppTheme.inputFillColor(ctx),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(ctx))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(ctx))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    debugPrint('Updating session $id to status: $status');
    try {
      final res = await Supabase.instance.client
          .from('live_sessions')
          .update({'status': status})
          .eq('id', id)
          .select()
          .single();
      debugPrint('Update result: $res');
    } catch (e) {
      debugPrint('Update error: $e');
    }
    // Notify enrolled students when going live
    if (status == 'live') {
      final user = Supabase.instance.client.auth.currentUser;
      final session = _sessions.firstWhere((s) => s['id'] == id, orElse: () => {});
      final enrollments = await Supabase.instance.client
          .from('session_enrollments')
          .select('student_id')
          .eq('session_id', id);
      final studentIds = (enrollments as List).map((e) => e['student_id'].toString()).toList();
      if (studentIds.isNotEmpty) {
        final sessionTitle = session['title']?.toString() ?? '';
        // In-app notification
        await Supabase.instance.client.from('notifications').insert(
          studentIds.map((sid) => {
            'user_id': sid,
            'sender_id': user?.id,
            'title': 'Session is now LIVE',
            'title_ar': 'الجلسة الآن مباشرة',
            'message': 'The session "$sessionTitle" has started!',
            'message_ar': 'بدأت الجلسة "$sessionTitle"!',
            'type': 'announcement',
          }).toList(),
        );
        // Push notification
        await NotificationSender.sendToUsers(
          userIds: studentIds,
          title: '🔴 Session is LIVE!',
          body: '"$sessionTitle" has started. Join now!',
        );
      }
    }
    _load();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _sessions;
    return _sessions.where((s) => s['status'] == _filter).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'live': return const Color(0xFF059669);
      case 'scheduled': return AppTheme.primary;
      case 'completed': return Colors.grey;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.primary;
    }
  }

  String _statusAr(String s) {
    switch (s) {
      case 'live': return 'مباشر';
      case 'scheduled': return 'مجدول';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return s;
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateSessionScreen())).then((_) => _load()),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        } else {
                          context.go('/teacher');
                        }
                      },
                      child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sessions', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                      Text('${_sessions.length} total', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: ['all', 'scheduled', 'live', 'completed', 'cancelled'].map((f) => GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _filter == f ? Colors.white : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(f == 'all' ? 'All' : _statusAr(f),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold,
                            color: _filter == f ? AppTheme.primary : Colors.white)),
                      ),
                    )).toList()),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _loading
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
                : _filtered.isEmpty
                    ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                        const Text('📅', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text('No sessions yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 8),
                        Text('Tap + to create a session', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
                      ]))))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                          final s = _filtered[i];
                          final unit = s['behavioral_units'] as Map?;
                          final scheduled = DateTime.parse(s['scheduled_at']);
                          final status = s['status'] as String;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderC)),
                            color: card,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => SessionDetailScreen(session: s),
                              )).then((_) => _load()),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        if (status == 'live') Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                                        Text(status == 'live' ? 'LIVE' : _statusAr(status),
                                          style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _statusColor(status))),
                                      ]),
                                    ),
                                    const Spacer(),
                                    Text('${scheduled.day}/${scheduled.month}/${scheduled.year}', style: TextStyle(fontSize: 12, color: textM)),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(s['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                  if (unit != null) ...[
                                    const SizedBox(height: 4),
                                    Text('📚 ${unit['title_ar'] ?? unit['title'] ?? ''}', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
                                  ],
                                  const SizedBox(height: 4),
                                  Text('⏰ ${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')} • ${s['duration_minutes'] ?? 60} min',
                                    style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
                                  const SizedBox(height: 4),
                                  Text(
                                    s['is_paid'] != true ? 'Free' : '${s['price'] ?? 0} DT',
                                    style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                                      color: s['is_paid'] != true ? const Color(0xFF059669) : AppTheme.secondary),
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: [
                                      if (status == 'scheduled') ...[
                                        _actionBtn('Go Live', const Color(0xFF059669), () => _updateStatus(s['id'], 'live')),
                                        const SizedBox(width: 8),
                                        _actionBtn('Edit', AppTheme.primary, () => _editSession(s)),
                                        const SizedBox(width: 8),
                                      ],
                                      if (status == 'live') ...[
                                        _actionBtn('End', const Color(0xFFF59E0B), () => _updateStatus(s['id'], 'completed')),
                                        const SizedBox(width: 8),
                                      ],
                                      _actionBtn('Cancel', AppTheme.error, () => _delete(s['id'])),
                                    ]),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }, childCount: _filtered.length)),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: color.withOpacity(0.1),
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: color)),
  );
}

// ─── Create Session Screen ───────────────────────────────────────────────────

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});
  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  String _lang = 'ar';
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  String? _selectedUnitId;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  List<Map<String, dynamic>> _units = [];
  bool _loading = false;
  bool _isFree = true;
  int _price = 0;

  @override
  void initState() { super.initState(); _loadUnits(); }

  @override
  void dispose() { _titleCtrl.dispose(); _urlCtrl.dispose(); _durationCtrl.dispose(); super.dispose(); }

  Future<void> _loadUnits() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final res = await Supabase.instance.client.from('behavioral_units').select('id, title_ar, title').eq('teacher_id', user.id);
    if (mounted) setState(() => _units = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _scheduledAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt));
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser!;
    try {
      await Supabase.instance.client.from('live_sessions').insert({
        'teacher_id': user.id,
        'title': _titleCtrl.text.trim(),
        'title_ar': _titleCtrl.text.trim(),
        'meeting_url': _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        'duration_minutes': int.tryParse(_durationCtrl.text) ?? 60,
        'scheduled_at': _scheduledAt.toIso8601String(),
        if (_selectedUnitId != null) 'unit_id': _selectedUnitId,
        'status': 'scheduled',
        'is_paid': !_isFree,
        'price': _isFree ? 0 : _price,
      });
      // Notify enrolled students
      final user2 = Supabase.instance.client.auth.currentUser!;
      final profile = await Supabase.instance.client.from('profiles').select('name').eq('id', user2.id).single();
      // Get unique students from teacher's units and sessions
      final teacherUnits = await Supabase.instance.client
          .from('behavioral_units').select('id').eq('teacher_id', user2.id);
      final unitIds = (teacherUnits as List).map((u) => u['id'].toString()).toList();

      final teacherSessions = await Supabase.instance.client
          .from('live_sessions').select('id').eq('teacher_id', user2.id);
      final sessionIds = (teacherSessions as List).map((s) => s['id'].toString()).toList();

      final Set<String> studentIdSet = {};
      if (unitIds.isNotEmpty) {
        final unitEnrollments = await Supabase.instance.client
            .from('unit_enrollments').select('student_id').inFilter('unit_id', unitIds);
        studentIdSet.addAll((unitEnrollments as List).map((e) => e['student_id'].toString()));
      }
      if (sessionIds.isNotEmpty) {
        final sessionEnrollments = await Supabase.instance.client
            .from('session_enrollments').select('student_id').inFilter('session_id', sessionIds);
        studentIdSet.addAll((sessionEnrollments as List).map((e) => e['student_id'].toString()));
      }
      final studentIds = studentIdSet.where((id) => id != user2.id).toList();
      if (studentIds.isNotEmpty) {
        await Supabase.instance.client.from('notifications').insert(
          studentIds.map((id) => {
            'user_id': id,
            'sender_id': user2.id,
            'title': 'New session scheduled',
            'title_ar': 'جلسة جديدة مجدولة',
            'message': '${profile['name']} scheduled a new session: ${_titleCtrl.text.trim()}',
            'message_ar': '${profile['name']} جدول جلسة جديدة: ${_titleCtrl.text.trim()}',
            'type': 'announcement',
          }).toList(),
        );
        await NotificationSender.sendToUsers(
          userIds: studentIds,
          title: '📅 New Session',
          body: '${profile['name']} scheduled: ${_titleCtrl.text.trim()}',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) { debugPrint('Create session error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

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
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)))),
            const SizedBox(width: 12),
            const Text('Create Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _fieldLabel('Session Title', textM),
            _textField(_titleCtrl, 'e.g. Math Review Session', textD, textM, borderC, inputFill),
            const SizedBox(height: 16),
            _fieldLabel('Linked Unit (optional)', textM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _selectedUnitId,
                hint: Text('Select unit', style: TextStyle(fontFamily: 'Cairo', color: textM)),
                isExpanded: true,
                dropdownColor: card,
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('None', style: TextStyle(fontFamily: 'Cairo', color: textD))),
                  ..._units.map((u) => DropdownMenuItem<String>(value: u['id'], child: Text(u['title_ar'] ?? u['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', color: textD)))),
                ],
                onChanged: (v) => setState(() => _selectedUnitId = v),
              )),
            ),
            const SizedBox(height: 16),
            _fieldLabel('Meeting Link (Zoom, Google Meet...)', textM),
            _textField(_urlCtrl, 'https://meet.google.com/...', textD, textM, borderC, inputFill, keyboard: TextInputType.url),
            const SizedBox(height: 16),
            _fieldLabel('Duration (minutes)', textM),
            _textField(_durationCtrl, '60', textD, textM, borderC, inputFill, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _fieldLabel('Scheduled Date & Time', textM),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text('${_scheduledAt.day}/${_scheduledAt.month}/${_scheduledAt.year} at ${_scheduledAt.hour.toString().padLeft(2, '0')}:${_scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontFamily: 'Cairo', color: textD)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _fieldLabel('Pricing', textM),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isFree = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isFree ? AppTheme.primary : inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isFree ? AppTheme.primary : borderC),
                    ),
                    child: Center(child: Text('Free', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _isFree ? Colors.white : textM))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isFree = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isFree ? AppTheme.primary : inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: !_isFree ? AppTheme.primary : borderC),
                    ),
                    child: Center(child: Text('Paid', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: !_isFree ? Colors.white : textM))),
                  ),
                ),
              ),
            ]),
            if (!_isFree) ...[
              const SizedBox(height: 12),
              _fieldLabel('Price (DT)', textM),
              TextField(
                onChanged: (v) => _price = int.tryParse(v) ?? 0,
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'Cairo', color: textD),
                decoration: InputDecoration(
                  hintText: '0', hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                  filled: true, fillColor: inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixText: 'DT',
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _create,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Session', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 100),
          ]),
        )),
      ]),
    );
  }

  Widget _fieldLabel(String label, Color color) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: color)));

  Widget _textField(TextEditingController ctrl, String hint, Color textD, Color textM, Color borderC, Color inputFill, {TextInputType? keyboard}) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    style: TextStyle(fontFamily: 'Cairo', color: textD),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
      filled: true, fillColor: inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Session Detail Screen ───────────────────────────────────────────────────

class SessionDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  const SessionDetailScreen({super.key, required this.session});
  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _enrolled = [];
  List<String> _present = [];
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final enrollments = await Supabase.instance.client
          .from('session_enrollments')
          .select('*, profiles!student_id(id, name, avatar_url)')
          .eq('session_id', widget.session['id']);
      final quizzes = await Supabase.instance.client
          .from('quizzes')
          .select()
          .eq('session_id', widget.session['id']);
      if (mounted) setState(() {
        _enrolled = List<Map<String, dynamic>>.from(enrollments);
        // Load already-saved presence
        _present = _enrolled
            .where((e) => e['is_present'] == true)
            .map((e) => (e['profiles'] as Map?)?['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        _quizzes = List<Map<String, dynamic>>.from(quizzes);
        _loading = false;
      });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _togglePresence(String studentId) async {
    final isPresent = _present.contains(studentId);
    setState(() {
      if (isPresent) {
        _present.remove(studentId);
      } else {
        _present.add(studentId);
      }
    });
    // Save to DB
    await Supabase.instance.client
        .from('session_enrollments')
        .update({'is_present': !isPresent})
        .eq('session_id', widget.session['id'])
        .eq('student_id', studentId);
  }

  void _createQuizForSession() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateQuizScreen(sessionId: widget.session['id']),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final scheduled = DateTime.parse(widget.session['scheduled_at']);
    final status = widget.session['status'] as String;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.session['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                Text('${scheduled.day}/${scheduled.month}/${scheduled.year} • ${scheduled.hour.toString().padLeft(2,'0')}:${scheduled.minute.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _chip('👥 ${_enrolled.length} registered'),
              const SizedBox(width: 8),
              _chip('📋 ${_present.length} present'),
              const SizedBox(width: 8),
              _chip('${widget.session['is_paid'] != true ? 'Free' : '${widget.session['price']} DT'}'),
            ]),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        if (_loading)
          const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primary))))
        else ...[
          // Attendance
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Attendance (${_present.length}/${_enrolled.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                if (status == 'live')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Tap to mark present', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Color(0xFF059669))),
                  ),
              ]),
              const SizedBox(height: 12),
              if (_enrolled.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                  child: Center(child: Text('No students registered yet', style: TextStyle(fontFamily: 'Cairo', color: textM))),
                )
              else
                ..._enrolled.map((e) {
                  final profile = e['profiles'] as Map?;
                  final studentId = profile?['id']?.toString() ?? '';
                  final isPresent = _present.contains(studentId);
                  final sessionStatus = widget.session['status'] as String;
                  final isEnded = sessionStatus == 'completed';
                  return GestureDetector(
                    onTap: sessionStatus == 'live' ? () => _togglePresence(studentId) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? const Color(0xFF059669).withOpacity(0.08)
                            : isEnded ? AppTheme.error.withOpacity(0.05) : card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPresent
                            ? const Color(0xFF059669).withOpacity(0.4)
                            : isEnded ? AppTheme.error.withOpacity(0.3) : borderC),
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url']) : null,
                          child: profile?['avatar_url'] == null ? Text((profile?['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)) : null),
                        const SizedBox(width: 10),
                        Expanded(child: Text(profile?['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, color: textD))),
                        if (isEnded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPresent ? const Color(0xFF059669).withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                                color: isPresent ? const Color(0xFF059669) : AppTheme.error),
                            ),
                          )
                        else
                          Icon(isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isPresent ? const Color(0xFF059669) : textM, size: 20),
                      ]),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Quizzes section
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Quizzes (${_quizzes.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                GestureDetector(
                  onTap: _createQuizForSession,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(100)),
                    child: const Text('+ Add Quiz', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_quizzes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                  child: Center(child: Text('No quizzes yet. Add one!', style: TextStyle(fontFamily: 'Cairo', color: textM))),
                )
              else
                ..._quizzes.map((q) {
                  final isActive = q['is_active'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary.withOpacity(0.05) : card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? AppTheme.primary.withOpacity(0.4) : borderC),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 6, 8),
                        child: Row(children: [
                          const Text('🧠', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(q['title_ar'] ?? q['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD, fontSize: 14)),
                            Row(children: [
                              Text('⏱ ${(q['time_limit_seconds'] ?? 300) ~/ 60} min', style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                                  child: const Text('LIVE', style: TextStyle(fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                ),
                              ],
                            ]),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: isActive ? AppTheme.primary : textM)),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isActive,
                                activeColor: AppTheme.primary,
                                onChanged: (val) async {
                                  await Supabase.instance.client.from('quizzes').update({'is_active': val}).eq('id', q['id']);
                                  // Push when activating quiz
                                  if (val == true) {
                                    final enrollments = await Supabase.instance.client
                                        .from('session_enrollments')
                                        .select('student_id')
                                        .eq('session_id', widget.session['id']);
                                    final studentIds = (enrollments as List).map((e) => e['student_id'].toString()).toList();
                                    if (studentIds.isNotEmpty) {
                                      await NotificationSender.sendToUsers(
                                        userIds: studentIds,
                                        title: '🧠 Quiz is LIVE!',
                                        body: 'A quiz is now available in your session. Answer now!',
                                      );
                                    }
                                  }
                                  _load();
                                },
                              ),
                            ),
                          ]),
                        ]),
                      ),
                      // Divider
                      Divider(height: 1, color: borderC),
                      // Buttons row
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => QuizQuestionsScreen(quizId: q['id'], quizTitle: q['title_ar'] ?? q['title'] ?? ''),
                              )),
                              icon: const Icon(Icons.quiz_outlined, size: 16, color: AppTheme.primary),
                              label: const Text('Questions', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.primary.withOpacity(0.07),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => QuizLeaderboardScreen(quizId: q['id'], quizTitle: q['title_ar'] ?? q['title'] ?? ''),
                              )),
                              icon: const Icon(Icons.leaderboard_outlined, size: 16, color: Color(0xFFF59E0B)),
                              label: const Text('Leaderboard', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B).withOpacity(0.07),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  );
                }),
              const SizedBox(height: 32),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo')),
  );
}