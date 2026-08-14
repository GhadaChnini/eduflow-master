import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../services/notification_sender.dart';

class TeacherUnitsScreen extends ConsumerStatefulWidget {
  const TeacherUnitsScreen({super.key});

  @override
  ConsumerState<TeacherUnitsScreen> createState() => _TeacherUnitsScreenState();
}

class _TeacherUnitsScreenState extends ConsumerState<TeacherUnitsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, published, draft
  String _priceFilter = 'all'; // all, free, paid
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _filtered {
    return _units.where((u) {
      final title = (_getTitle(u)).toLowerCase();
      final status = u['status'] as String? ?? '';
      final isFree = u['is_free'] == true;
      final searchMatch = _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());
      final statusMatch = _statusFilter == 'all' || status == _statusFilter;
      final priceMatch = _priceFilter == 'all' || (_priceFilter == 'free' ? isFree : !isFree);
      return searchMatch && statusMatch && priceMatch;
    }).toList();
  }

  Future<void> _loadUnits() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('behavioral_units')
          .select('*, subjects(name_ar, name_fr, name_en, icon), grades(name_ar, name_fr, name_en)')
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _units = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUnit(String unitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Tr.t('delete_unit', _lang), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context)), textAlign: TextAlign.center),
        content: Text(Tr.t('delete_unit_confirm', _lang), style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Tr.t('cancel', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(Tr.t('delete', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      // Notify enrolled students before deleting
      final user = Supabase.instance.client.auth.currentUser;
      try {
        final enrollments = await Supabase.instance.client
            .from('unit_enrollments').select('student_id').eq('unit_id', unitId);
        final studentIds = (enrollments as List).map((e) => e['student_id'].toString())
            .where((sid) => sid != (user?.id ?? '')).toList();
        if (studentIds.isNotEmpty) {
          await Supabase.instance.client.from('notifications').insert(
            studentIds.map((sid) => {
              'user_id': sid,
              'sender_id': user?.id,
              'title': 'Unit removed',
              'title_ar': 'تم حذف الوحدة',
              'message': 'A unit you were enrolled in has been removed by the teacher.',
              'message_ar': 'تم حذف وحدة كنت مسجلاً فيها من قبل المعلم.',
              'type': 'announcement',
            }).toList(),
          );
        }
      } catch (e) { debugPrint('Notify delete error: $e'); }
      await Supabase.instance.client.from('behavioral_units').delete().eq('id', unitId);
      _loadUnits();
    }
  }

  Future<void> _toggleStatus(String unitId, String currentStatus) async {
    final newStatus = currentStatus == 'published' ? 'draft' : 'published';
    await Supabase.instance.client.from('behavioral_units').update({'status': newStatus}).eq('id', unitId);

    if (newStatus == 'published') {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;

        final unitRes = await Supabase.instance.client
            .from('behavioral_units')
            .select('title_ar, title')
            .eq('id', unitId)
            .single();
        final title = unitRes['title_ar'] ?? unitRes['title'] ?? '';

        // Get ALL students enrolled in ANY of this teacher's units
        final teacherUnits = await Supabase.instance.client
            .from('behavioral_units')
            .select('id')
            .eq('teacher_id', user.id);
        final unitIds = (teacherUnits as List).map((u) => u['id'].toString()).toList();

        if (unitIds.isEmpty) return;

        final enrollments = await Supabase.instance.client
            .from('unit_enrollments')
            .select('student_id')
            .inFilter('unit_id', unitIds);
        final studentIds = (enrollments as List)
            .map((e) => e['student_id'].toString())
            .toSet()
            .toList();

        debugPrint('📚 Publishing unit, notifying ${studentIds.length} students');
        if (studentIds.isNotEmpty) {
          await NotificationSender.sendToUsers(
            userIds: studentIds,
            title: '📚 New Content Available',
            body: '"$title" has just been published. Check it out!',
          );
        }
      } catch (e) { debugPrint('Push publish error: $e'); }
    }
    _loadUnits();
  }

  String _getTitle(Map<String, dynamic> unit) {
    if (_lang == 'ar') return unit['title_ar'] ?? unit['title'] ?? '';
    if (_lang == 'fr') return unit['title'] ?? unit['title_ar'] ?? '';
    return unit['title_en'] ?? unit['title'] ?? unit['title_ar'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_unit',
        onPressed: () => context.go('/teacher/units/create'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadUnits,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/teacher'),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Tr.t('my_units', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                          Text('${_units.length} ${Tr.t("units", _lang)}', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Search + filters
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor(context))),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(fontFamily: 'Cairo', color: textD),
                    decoration: InputDecoration(
                      hintText: 'Search units...',
                      hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                  // Status filter
                  ...['all', 'published', 'draft'].map((s) {
                    final isSelected = _statusFilter == s;
                    final label = s == 'all' ? 'All' : s == 'published' ? 'Published' : 'Draft';
                    return GestureDetector(
                      onTap: () => setState(() => _statusFilter = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderColor(context)),
                        ),
                        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: isSelected ? Colors.white : textM)),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  // Price filter
                  ...['all', 'free', 'paid'].map((p) {
                    final isSelected = _priceFilter == p;
                    final label = p == 'all' ? 'All' : p == 'free' ? 'Free' : 'Paid';
                    return GestureDetector(
                      onTap: () => setState(() => _priceFilter = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF059669) : AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isSelected ? const Color(0xFF059669) : AppTheme.borderColor(context)),
                        ),
                        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: isSelected ? Colors.white : textM)),
                      ),
                    );
                  }),
                  ]),
                ),
                const SizedBox(height: 8),
              ]),
            )),
            _loading
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
                : _filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const Text('📝', style: TextStyle(fontSize: 56)),
                                const SizedBox(height: 16),
                                Text(Tr.t('no_units_yet', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                const SizedBox(height: 8),
                                Text(Tr.t('create_first_unit', _lang), style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/teacher/units/create'),
                                  icon: const Icon(Icons.add),
                                  label: Text(Tr.t('create_unit', _lang), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final unit = _filtered[i];
                              final subject = unit['subjects'] as Map?;
                              final grade = unit['grades'] as Map?;
                              final icon = subject?['icon'] ?? '📚';
                              final status = unit['status'] ?? 'draft';
                              final enrolled = unit['total_enrolled'] ?? 0;
                              final isFree = unit['is_free'] ?? true;
                              final price = unit['price'] ?? 0;

                              final statusColor = status == 'published' ? const Color(0xFF059669) : const Color(0xFFF59E0B);
                              final statusLabel = status == 'published' ? Tr.t('published', _lang) : Tr.t('draft', _lang);

                              final gradeName = _lang == 'ar' ? (grade?['name_ar'] ?? '') : _lang == 'fr' ? (grade?['name_fr'] ?? '') : (grade?['name_en'] ?? grade?['name_fr'] ?? '');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_getTitle(unit), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Text(gradeName, style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                                          child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                      children: [
                                        Text('👥 $enrolled', style: TextStyle(fontSize: 12, color: textM)),
                                        const SizedBox(width: 12),
                                        Text(isFree ? Tr.t('free', _lang) : '$price ${Tr.t("currency", _lang)}',
                                          style: TextStyle(fontSize: 12, color: isFree ? const Color(0xFF059669) : AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 12),
                                        // Toggle status
                                        GestureDetector(
                                          onTap: () => _toggleStatus(unit['id'].toString(), status),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: status == 'published' ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF059669).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status == 'published' ? Tr.t('unpublish', _lang) : Tr.t('publish', _lang),
                                              style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                                                color: status == 'published' ? const Color(0xFFF59E0B) : const Color(0xFF059669)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Edit
                                        GestureDetector(
                                          onTap: () => context.go('/teacher/units/${unit['id']}'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text(Tr.t('edit_unit', _lang), style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Delete
                                        GestureDetector(
                                          onTap: () => _deleteUnit(unit['id'].toString()),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text(Tr.t('delete', _lang), style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.error)),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}