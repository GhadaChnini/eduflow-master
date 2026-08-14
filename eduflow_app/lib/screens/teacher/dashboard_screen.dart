import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../widgets/common/main_scaffold.dart';
import '../../services/auth_service.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  String _lang = 'ar';
  Map<String, dynamic>? _profile;
  bool _loading = true;
  int _totalUnits = 0;
  int _totalEnrolled = 0;
  List<Map<String, dynamic>> _recentUnits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await ref.read(authServiceProvider).getCurrentProfile();
      
      final units = await supabase
          .from('behavioral_units')
          .select('*, subjects(name_ar, name_fr, name_en, icon)')
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false);

      final unitsList = List<Map<String, dynamic>>.from(units);
      int totalEnrolled = 0;
      for (final unit in unitsList) {
        totalEnrolled += (unit['total_enrolled'] as int? ?? 0);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _totalUnits = unitsList.length;
          _totalEnrolled = totalEnrolled;
          _recentUnits = unitsList.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Tr.t('logout_confirm_title', _lang),
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context)),
          textAlign: TextAlign.center),
        content: Text(Tr.t('logout_confirm_msg', _lang),
          style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)),
          textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Tr.t('cancel', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.go('/');
            },
            child: Text(Tr.t('logout', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final name = _profile?['name'] ?? 'أستاذ';

    return Scaffold(
      backgroundColor: bg,
            body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Header
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
                              GestureDetector(
                                onTap: () => context.go('/teacher/profile'),
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
                                    Text('👋 ${Tr.t("hello", _lang)}', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/teacher/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
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
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _statChip('📚', '$_totalUnits', Tr.t('my_units', _lang)),
                              const SizedBox(width: 10),
                              _statChip('👥', '$_totalEnrolled', Tr.t('enrolled_units', _lang)),
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
                          Text(Tr.t('quick_actions', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _actionBtn(context, '➕', Tr.t('create_unit', _lang), '/teacher/units/create', card, textD),
                              _actionBtn(context, '📢', 'Notices', '/teacher/announcements', card, textD),
                              _actionBtn(context, '📅', 'Sessions', '/teacher/sessions', card, textD),
                              _actionBtn(context, '📊', 'Analytics', '/teacher/analytics', card, textD),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Recent units
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Tr.t('recent_units', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                          GestureDetector(
                            onTap: () => context.go('/teacher/units'),
                            child: Text(Tr.t('view_all', _lang), style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  _recentUnits.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap: () => context.go('/teacher/units/create'),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: Column(
                                  children: [
                                    const Text('📝', style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
                                    Text(Tr.t('no_units_yet', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                    const SizedBox(height: 8),
                                    Text(Tr.t('create_first_unit', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(100)),
                                      child: Text(Tr.t('create_unit', _lang), style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _buildUnitCard(_recentUnits[i], card, textD, textM),
                              childCount: _recentUnits.length,
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('$value $label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String emoji, String label, String route, Color card, Color textD) {
    final btnWidth = (MediaQuery.of(context).size.width - 48 - 36) / 4;
    return SizedBox(
      width: btnWidth,
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: textD), textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit, Color card, Color textD, Color textM) {
    final subject = unit['subjects'] as Map?;
    final icon = subject?['icon'] ?? '📚';
    final title = _lang == 'ar' ? (unit['title_ar'] ?? '') : _lang == 'fr' ? (unit['title'] ?? '') : (unit['title_en'] ?? unit['title'] ?? '');
    final enrolled = unit['total_enrolled'] ?? 0;
    final status = unit['status'] ?? 'draft';

    final statusColor = status == 'published' ? const Color(0xFF059669) : status == 'draft' ? const Color(0xFFF59E0B) : AppTheme.error;
    final statusLabel = status == 'published' ? Tr.t('published', _lang) : status == 'draft' ? Tr.t('draft', _lang) : Tr.t('archived', _lang);

    return GestureDetector(
      onTap: () => context.go('/teacher/units'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                        child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ),
                      const SizedBox(width: 8),
                      Text('👥 $enrolled', style: TextStyle(fontSize: 11, color: textM)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textM),
          ],
        ),
      ),
    );
  }
}