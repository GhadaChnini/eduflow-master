import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState
    extends ConsumerState<TeacherStudentsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String _search = '';

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
      // Get all students enrolled in teacher's units
      final res = await Supabase.instance.client
          .from('unit_enrollments')
          .select(
            'student_id, progress, enrolled_at, behavioral_units!unit_id(title_ar, title, teacher_id), profiles!student_id(id, name, email, avatar_url, points)',
          )
          .eq('behavioral_units.teacher_id', user.id);

      // Group by student
      final Map<String, Map<String, dynamic>> studentMap = {};

      for (final row in (res as List)) {
        final profile = row['profiles'] as Map?;
        if (profile == null) continue;

        final id = profile['id'].toString();

        if (!studentMap.containsKey(id)) {
          studentMap[id] = {
            ...Map<String, dynamic>.from(profile),
            'units': [],
            'total_progress': 0,
          };
        }

        final unit = row['behavioral_units'] as Map?;
        if (unit != null) {
          (studentMap[id]!['units'] as List).add({
            'title': unit['title_ar'] ?? unit['title'],
            'progress': row['progress'] ?? 0,
            'enrolled_at': row['enrolled_at'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _students = studentMap.values.toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Students error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _students
      .where(
        (s) =>
            (s['name'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
            (s['email'] ?? '').toLowerCase().contains(_search.toLowerCase()),
      )
      .toList();

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
                        // ONLY CHANGE: back button
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
                            const Text(
                              'My Students',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              '${_students.length} enrolled',
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
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search students...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontFamily: 'Cairo',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
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
                : _filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const Text(
                                  '👥',
                                  style: TextStyle(fontSize: 56),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No students yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    color: textD,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Students will appear when they enroll',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final s = _filtered[i];
                              final units = s['units'] as List;
                              final avgProgress = units.isEmpty
                                  ? 0
                                  : (units
                                              .map((u) => u['progress'] as int)
                                              .reduce((a, b) => a + b) /
                                          units.length)
                                      .round();

                              return GestureDetector(
                                onTap: () => _showStudentDetail(
                                  context,
                                  s,
                                  card,
                                  textD,
                                  textM,
                                  borderC,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderC),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.primary
                                            .withOpacity(0.1),
                                        backgroundImage:
                                            s['avatar_url'] != null
                                                ? NetworkImage(
                                                    s['avatar_url'],
                                                  )
                                                : null,
                                        child: s['avatar_url'] == null
                                            ? Text(
                                                (s['name'] ?? '?')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                  fontSize: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['name'] ?? '',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                                color: textD,
                                              ),
                                            ),
                                            Text(
                                              s['email'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'Cairo',
                                                color: textM,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  '${units.length} units',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textM,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '⭐ ${s['points'] ?? 0} pts',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textM,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$avgProgress%',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          Text(
                                            'avg progress',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textM,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetail(
    BuildContext context,
    Map<String, dynamic> s,
    Color card,
    Color textD,
    Color textM,
    Color borderC,
  ) {
    final units = s['units'] as List;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scroll,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: s['avatar_url'] != null
                        ? NetworkImage(s['avatar_url'])
                        : null,
                    child: s['avatar_url'] == null
                        ? Text(
                            (s['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: textD,
                        ),
                      ),
                      Text(
                        s['email'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Cairo',
                          color: textM,
                        ),
                      ),
                      Text(
                        '⭐ ${s['points'] ?? 0} points',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Enrolled Units (${units.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: textD,
                ),
              ),
              const SizedBox(height: 12),
              ...units.map(
                (u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderC),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '📚',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          u['title'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cairo',
                            color: textD,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${u['progress']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}