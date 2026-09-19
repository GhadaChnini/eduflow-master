import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;
  final String lang;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.lang,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  Map<String, dynamic>? _sender;

  @override
  void initState() {
    super.initState();
    _loadSender();
  }

  Future<void> _loadSender() async {
    final senderId = widget.notification['sender_id'];
    if (senderId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('name, avatar_url, role')
          .eq('id', senderId)
          .single();
      if (mounted) setState(() => _sender = Map<String, dynamic>.from(res));
    } catch (_) {}
  }

  String _timeAgo(String createdAt) {
    final diff = DateTime.now().difference(DateTime.parse(createdAt));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _typeIcon(String? type) {
    switch (type) {
      case 'enrollment': return '🎓';
      case 'announcement': return '📢';
      case 'forum': return '💬';
      default: return '🔔';
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'enrollment': return const Color(0xFF059669);
      case 'announcement': return const Color(0xFF7C3AED);
      case 'forum': return const Color(0xFF2563EB);
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final type = widget.notification['type'] as String?;
    final color = _typeColor(type);

    final title = widget.lang == 'ar'
        ? (widget.notification['title_ar'] ?? widget.notification['title'] ?? '')
        : (widget.notification['title'] ?? '');
    final message = widget.lang == 'ar'
        ? (widget.notification['message_ar'] ?? widget.notification['message'] ?? '')
        : (widget.notification['message'] ?? '');

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Center(child: Text(_typeIcon(type), style: const TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(widget.notification['created_at'] ?? DateTime.now().toIso8601String()),
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender card
                  if (_sender != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withOpacity(0.1),
                          backgroundImage: _sender!['avatar_url'] != null
                              ? NetworkImage(_sender!['avatar_url'])
                              : null,
                          child: _sender!['avatar_url'] == null
                              ? Text(
                                  (_sender!['name'] ?? '?')[0].toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_sender!['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                            Text(
                              _sender!['role'] == 'teacher' ? '👩‍🏫 Teacher' : '🎓 Student',
                              style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM),
                            ),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Message card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderC),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            (type ?? 'notification').toUpperCase(),
                            style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message.isEmpty ? title : message,
                          style: TextStyle(fontSize: 15, fontFamily: 'Cairo', color: textD, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}