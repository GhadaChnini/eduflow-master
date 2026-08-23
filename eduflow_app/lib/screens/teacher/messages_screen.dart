import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _lang = 'ar';
  String _role = 'parent';
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadMessages();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final profile = await ref.read(authServiceProvider).getCurrentProfile();
    if (mounted) setState(() => _role = profile?['role'] ?? 'parent');
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('support_messages')
          .select()
          .eq('sender_id', user.id)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
        _scrollToBottom();
        _subscribeToMessages(user.id);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToMessages(String userId) {
    final supabase = Supabase.instance.client;
    _channel?.unsubscribe();
    _channel = supabase
        .channel('messages_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() => _messages.add(Map<String, dynamic>.from(payload.newRecord)));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    final text = _messageController.text.trim();
    _messageController.clear();
    try {
      await supabase.from('support_messages').insert({
        'sender_id': user.id,
        'content': text,
        'is_from_admin': false,
        'is_read': false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  String _timeFormat(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go(_role == 'teacher' ? '/teacher' : '/home'),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('🎧', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Tr.t('support_team', _lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                      Text(Tr.t('support_online', _lang), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text(Tr.t('no_messages', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                            const SizedBox(height: 8),
                            Text(Tr.t('send_first_message', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isFromAdmin = msg['is_from_admin'] == true;
                          final isMe = !isFromAdmin;
                          final time = _timeFormat(msg['created_at'] ?? '');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Center(child: Text('🎧', style: TextStyle(fontSize: 16))),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? AppTheme.primary : card,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                                            bottomRight: Radius.circular(isMe ? 4 : 16),
                                          ),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                                        ),
                                        child: Text(msg['content'] ?? '', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: isMe ? Colors.white : textD)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(time, style: TextStyle(fontSize: 10, color: textM)),
                                    ],
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 8),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: card,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: Tr.t('type_message', _lang),
                      hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: borderC)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: borderC)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                      filled: true,
                      fillColor: AppTheme.inputFillColor(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(14)),
                    child: _sending
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}