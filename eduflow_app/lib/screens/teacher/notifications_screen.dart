import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../widgets/common/main_scaffold.dart';
import '../shared/notification_detail_screen.dart';

class TeacherNotificationsScreen extends ConsumerStatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  ConsumerState<TeacherNotificationsScreen> createState() => _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState extends ConsumerState<TeacherNotificationsScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) _notifications[index]['is_read'] = true;
    });
  }

  Future<void> _markAllAsRead() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
    setState(() { for (final n in _notifications) n['is_read'] = true; });
    ref.invalidate(unreadNotifProvider);
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: bg,
            body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadNotifications,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        Expanded(child: Text(Tr.t('notifications_label', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'))),
                        if (unreadCount > 0)
                          GestureDetector(
                            onTap: _markAllAsRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                              child: Text(Tr.t('mark_all_read', _lang), style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                        child: Text('🔔 $unreadCount ${Tr.t("unread", _lang)}', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _loading
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
                : _notifications.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              const Text('🔔', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: 16),
                              Text(Tr.t('no_notifications', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                              const SizedBox(height: 8),
                              Text(Tr.t('no_notifications_desc', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final n = _notifications[i];
                              final isRead = n['is_read'] == true;
                              final type = n['type'] ?? 'info';
                              final emoji = type == 'enrollment' ? '📚' : type == 'achievement' ? '🏆' : type == 'announcement' ? '📢' : '🔔';
                              return GestureDetector(
                                onTap: () async {
                                  await _markAsRead(n['id'].toString());
                                  if (mounted) {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (ctx) => NotificationDetailScreen(
                                        notification: n,
                                        lang: _lang,
                                      ),
                                    ));
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isRead ? card : AppTheme.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.2)),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(color: isRead ? AppTheme.primary.withOpacity(0.08) : AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(n['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                            const SizedBox(height: 4),
                                            Text(n['body'] ?? '', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        children: [
                                          Text(_timeAgo(n['created_at'] ?? ''), style: TextStyle(fontSize: 11, color: textM)),
                                          if (!isRead) ...[const SizedBox(height: 6), Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _notifications.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}