import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _lang = 'ar';
  bool _loading = true;
  int _totalStudents = 0;
  int _totalUnits = 0;
  int _publishedUnits = 0;
  double _avgRating = 0;
  int _totalEnrollments = 0;
  int _totalSessions = 0;
  List<Map<String, dynamic>> _topUnits = [];
  int _totalRevenue = 0;

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
      // Units
      final units = await Supabase.instance.client
          .from('behavioral_units')
          .select(
              'id, title_ar, title, total_enrolled, avg_rating, is_free, price, status')
          .eq('teacher_id', user.id);

      final unitsList = List<Map<String, dynamic>>.from(units);
      final published =
          unitsList.where((u) => u['status'] == 'published').toList();
      final unitIds =
          unitsList.map((u) => u['id'].toString()).toList();

      // Enrollments — using unit IDs directly
      int uniqueStudents = 0;
      int totalEnrollments = 0;

      if (unitIds.isNotEmpty) {
        final enrollments = await Supabase.instance.client
            .from('unit_enrollments')
            .select('student_id')
            .inFilter('unit_id', unitIds);

        final enrollmentsList =
            List<Map<String, dynamic>>.from(enrollments);

        totalEnrollments = enrollmentsList.length;
        uniqueStudents =
            enrollmentsList.map((e) => e['student_id']).toSet().length;
      }

      // Sessions
      final sessions = await Supabase.instance.client
          .from('live_sessions')
          .select('id, total_enrolled, price, is_paid')
          .eq('teacher_id', user.id);

      final sessionsList =
          List<Map<String, dynamic>>.from(sessions);

      final totalSessions = sessionsList.length;

      // Revenue calculation — units + sessions
      int revenue = 0;

      for (final u in unitsList) {
        if (!(u['is_free'] ?? true)) {
          revenue += (((u['total_enrolled'] ?? 0) as num) *
                  ((u['price'] ?? 0) as num))
              .toInt();
        }
      }

      for (final s in sessionsList) {
        if (s['is_paid'] == true) {
          revenue += (((s['total_enrolled'] ?? 0) as num) *
                  ((s['price'] ?? 0) as num))
              .toInt();
        }
      }

      // Top units by enrollment
      unitsList.sort(
          (a, b) => (b['total_enrolled'] ?? 0)
              .compareTo(a['total_enrolled'] ?? 0));

      // Avg rating
      final ratings = unitsList
          .where((u) => (u['avg_rating'] ?? 0) > 0)
          .map((u) => (u['avg_rating'] as num).toDouble())
          .toList();

      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      if (mounted) {
        setState(() {
          _totalStudents = uniqueStudents;
          _totalUnits = unitsList.length;
          _publishedUnits = published.length;
          _avgRating = avgRating;
          _totalEnrollments = totalEnrollments;
          _totalSessions = totalSessions;
          _topUnits = unitsList.take(5).toList();
          _totalRevenue = revenue;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
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
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 16, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF9D5CF6)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
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
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              )
            else ...[
              // Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _statCard(
                            '👥',
                            'Students',
                            '$_totalStudents',
                            const Color(0xFF059669),
                            card,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            '📚',
                            'Units',
                            '$_totalUnits',
                            AppTheme.primary,
                            card,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            '🌟',
                            'Published',
                            '$_publishedUnits',
                            const Color(0xFFF59E0B),
                            card,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            '⭐',
                            'Avg Rating',
                            _avgRating.toStringAsFixed(1),
                            const Color(0xFFEF4444),
                            card,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            '📋',
                            'Enrollments',
                            '$_totalEnrollments',
                            const Color(0xFF8B5CF6),
                            card,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            '📅',
                            'Sessions',
                            '$_totalSessions',
                            const Color(0xFF059669),
                            card,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                context.go('/teacher/earnings'),
                            child: _statCard(
                              '💰',
                              'Total Revenue',
                              '$_totalRevenue DT',
                              const Color(0xFF059669),
                              card,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            '📅',
                            'Sessions',
                            '$_totalSessions',
                            const Color(0xFF2563EB),
                            card,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Top Units
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Units',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: textD,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._topUnits
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final u = entry.value;
                        final enrolled =
                            u['total_enrolled'] ?? 0;

                        final maxEnrolled =
                            _topUnits.isEmpty
                                ? 1
                                : (_topUnits.first[
                                        'total_enrolled'] ??
                                    1);

                        final ratio = maxEnrolled == 0
                            ? 0.0
                            : enrolled / maxEnrolled;

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 10),
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: borderC,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              AppTheme.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      u['title_ar'] ??
                                          u['title'] ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontFamily: 'Cairo',
                                        color: textD,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$enrolled enrolled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textM,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(100),
                                child:
                                    LinearProgressIndicator(
                                  value: ratio.toDouble(),
                                  backgroundColor: AppTheme
                                      .primary
                                      .withOpacity(0.1),
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                    AppTheme.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '★ ${(u['avg_rating'] ?? 0.0).toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textM,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    u['is_free'] == true
                                        ? 'Free'
                                        : '${u['price']} DT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textM,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: u['status'] ==
                                              'published'
                                          ? const Color(0xFF059669)
                                              .withOpacity(0.1)
                                          : Colors.grey
                                              .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              100),
                                    ),
                                    child: Text(
                                      u['status'] ?? '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'Cairo',
                                        fontWeight:
                                            FontWeight.bold,
                                        color: u['status'] ==
                                                'published'
                                            ? const Color(
                                                0xFF059669)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String icon,
    String label,
    String value,
    Color color,
    Color card,
  ) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
}