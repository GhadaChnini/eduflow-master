import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('announcements')
          .select()
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _createAnnouncement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateAnnouncementSheet(
        lang: _lang,
        onCreated: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('announcements').delete().eq('id', id);
    _load();
  }

  String _timeAgo(String createdAt) {
    final diff = DateTime.now().difference(DateTime.parse(createdAt));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: bg,
        floatingActionButton: FloatingActionButton(
          onPressed: _createAnnouncement,
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
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 16,
                    24,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF9D5CF6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Tr.t('announcements', _lang),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                '${_announcements.length} ${Tr.t("total", _lang)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              _loading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                  : _announcements.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                children: [
                                  const Text(
                                    '📢',
                                    style: TextStyle(fontSize: 56),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    Tr.t('no_announcements', _lang),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      color: textD,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Tr.t(
                                      'create_announcement_hint',
                                      _lang,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Cairo',
                                      color: textM,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final a = _announcements[i];
                                final title = _lang == 'ar'
                                    ? (a['title_ar'] ?? a['title'])
                                    : a['title'];
                                final content = _lang == 'ar'
                                    ? (a['content_ar'] ?? a['content'])
                                    : a['content'];
                                final targetGrade = a['target_grade'];

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderC),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '📢',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title ?? '',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                    color: textD,
                                                  ),
                                                ),
                                                Text(
                                                  _timeAgo(a['created_at']),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textM,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _delete(a['id']),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: AppTheme.error,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        content ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Cairo',
                                          color: textM,
                                          height: 1.5,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (targetGrade != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            '🎓 Grade $targetGrade',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Cairo',
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                              childCount: _announcements.length,
                            ),
                          ),
                        ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateAnnouncementSheet extends StatefulWidget {
  final String lang;
  final VoidCallback onCreated;

  const _CreateAnnouncementSheet({
    required this.lang,
    required this.onCreated,
  });

  @override
  State<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState
    extends State<_CreateAnnouncementSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _submitting = false;
  List<Map<String, dynamic>> _grades = [];
  int? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    final res = await Supabase.instance.client
        .from('grades')
        .select()
        .order('level');
    if (mounted) {
      setState(() => _grades = List<Map<String, dynamic>>.from(res));
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      await Supabase.instance.client.from('announcements').insert({
        'teacher_id': user!.id,
        'title': _titleController.text.trim(),
        'title_ar': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'content_ar': _contentController.text.trim(),
        if (_selectedGrade != null) 'target_grade': _selectedGrade,
      });

      // Notify all students enrolled in any of this teacher's units
      final enrollments = await Supabase.instance.client
          .from('unit_enrollments')
          .select(
            'student_id, behavioral_units!unit_id(teacher_id)',
          )
          .eq('behavioral_units.teacher_id', user.id);

      final studentIds = (enrollments as List)
          .map((e) => e['student_id'].toString())
          .toSet()
          .toList();

      if (studentIds.isNotEmpty) {
        final notifications = studentIds
            .map(
              (id) => {
                'user_id': id,
                'sender_id': user.id,
                'title': _titleController.text.trim(),
                'title_ar': _titleController.text.trim(),
                'message': _contentController.text.trim(),
                'message_ar': _contentController.text.trim(),
                'type': 'announcement',
              },
            )
            .toList();

        await Supabase.instance.client
            .from('notifications')
            .insert(notifications);
      }

      widget.onCreated();
    } catch (e) {
      debugPrint('Announcement error: $e');
    }

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Tr.t('new_announcement', widget.lang),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: textD,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: textD,
            ),
            decoration: InputDecoration(
              hintText: Tr.t(
                'announcement_title',
                widget.lang,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: textM,
              ),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: textD,
            ),
            decoration: InputDecoration(
              hintText: Tr.t(
                'announcement_content',
                widget.lang,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: textM,
              ),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderC),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedGrade,
                hint: Text(
                  Tr.t(
                    'target_grade_optional',
                    widget.lang,
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: textM,
                  ),
                ),
                isExpanded: true,
                dropdownColor: bg,
                items: [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      Tr.t('all_grades', widget.lang),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: textD,
                      ),
                    ),
                  ),
                  ..._grades.map((g) {
                    final name = widget.lang == 'ar'
                        ? g['name_ar']
                        : widget.lang == 'fr'
                            ? g['name_fr']
                            : (g['name_en'] ?? g['name_fr']);

                    return DropdownMenuItem<int>(
                      value: g['id'],
                      child: Text(
                        name ?? '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: textD,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (v) =>
                    setState(() => _selectedGrade = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      Tr.t(
                        'send_announcement',
                        widget.lang,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}