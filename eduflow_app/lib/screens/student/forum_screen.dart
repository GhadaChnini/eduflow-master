import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('forum_posts')
          .select('*, profiles!author_id(name, avatar_url), grades(name_ar, name_fr, name_en), subjects(name_ar, name_fr, name_en, icon)')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _posts = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPost(Map<String, dynamic> post) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => ForumPostScreen(post: post, lang: _lang),
    )).then((_) => _loadPosts());
  }

  void _createPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(lang: _lang, onCreated: () { Navigator.pop(ctx); _loadPosts(); }),
    );
  }

  String _timeAgo(String createdAt) {
    final diff = DateTime.now().difference(DateTime.parse(createdAt));
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
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
        onPressed: _createPost,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadPosts,
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
                    Row(children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            GoRouter.of(context).go('/home');
                          }
                        },
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Tr.t('forum', _lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                        Text('${_posts.length} ${Tr.t("posts", _lang)}', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                      ]),
                    ]),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _loading
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
                : _posts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(children: [
                              const Text('💬', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: 16),
                              Text(Tr.t('no_posts_yet', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                              const SizedBox(height: 8),
                              Text(Tr.t('be_first_post', _lang), style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                            ]),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final post = _posts[i];
                              final author = post['profiles'] as Map?;
                              final subject = post['subjects'] as Map?;
                              final grade = post['grades'] as Map?;
                              final subjectName = _lang == 'ar' ? (subject?['name_ar'] ?? '') : (_lang == 'fr' ? (subject?['name_fr'] ?? '') : (subject?['name_en'] ?? ''));
                              final gradeName = _lang == 'ar' ? (grade?['name_ar'] ?? '') : (_lang == 'fr' ? (grade?['name_fr'] ?? '') : (grade?['name_en'] ?? ''));

                              return GestureDetector(
                                onTap: () => _openPost(post),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderC),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                                          backgroundImage: author?['avatar_url'] != null ? NetworkImage(author!['avatar_url']) : null,
                                          child: author?['avatar_url'] == null
                                              ? Text((author?['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14))
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(author?['name'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                                            Text(_timeAgo(post['created_at']), style: TextStyle(fontSize: 11, color: textM)),
                                          ]),
                                        ),
                                        if (subject != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                                            child: Text('${subject['icon'] ?? ''} $subjectName', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: AppTheme.primary)),
                                          ),
                                      ]),
                                      const SizedBox(height: 10),
                                      Text(post['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                      const SizedBox(height: 4),
                                      Text(post['content'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 10),
                                      Row(children: [
                                        Icon(Icons.thumb_up_outlined, size: 14, color: textM),
                                        const SizedBox(width: 4),
                                        Text('${post['likes'] ?? 0}', style: TextStyle(fontSize: 12, color: textM)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.chat_bubble_outline, size: 14, color: textM),
                                        const SizedBox(width: 4),
                                        Text('${post['replies_count'] ?? 0}', style: TextStyle(fontSize: 12, color: textM)),
                                        if (gradeName != null) ...[
                                          const Spacer(),
                                          Text(gradeName, style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _posts.length,
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

class ForumPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String lang;
  const ForumPostScreen({super.key, required this.post, required this.lang});

  @override
  State<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends State<ForumPostScreen> {
  List<Map<String, dynamic>> _replies = [];
  bool _loading = true;
  final _replyController = TextEditingController();
  bool _submitting = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
    _checkIsLiked();
  }

  Future<void> _checkIsLiked() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('forum_likes')
          .select()
          .eq('post_id', widget.post['id'])
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted) setState(() => _isLiked = res != null);
    } catch (_) {}
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    try {
      final res = await Supabase.instance.client
          .from('forum_replies')
          .select('*, profiles!author_id(name, avatar_url)')
          .eq('post_id', widget.post['id'])
          .order('created_at');
      if (mounted) setState(() { _replies = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('forum_replies').insert({
        'post_id': widget.post['id'],
        'author_id': user!.id,
        'content': _replyController.text.trim(),
      });
      await Supabase.instance.client.from('forum_posts')
          .update({'replies_count': (widget.post['replies_count'] ?? 0) + 1})
          .eq('id', widget.post['id']);

      // Notify post author if different user
      final postAuthorId = widget.post['author_id'];
      if (postAuthorId != user.id) {
        final profile = await Supabase.instance.client.from('profiles').select('name').eq('id', user.id).single();
        await Supabase.instance.client.from('notifications').insert({
          'user_id': postAuthorId,
          'sender_id': user.id,
          'title': 'New reply on your post 💬',
          'title_ar': 'رد جديد على منشورك 💬',
          'message': '${profile['name']} replied: ${_replyController.text.trim()}',
          'message_ar': '${profile['name']} ردّ: ${_replyController.text.trim()}',
          'type': 'forum',
        });
      }

      _replyController.clear();
      _loadReplies();
    } catch (e) {
      debugPrint('Reply error: $e');
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _editPost() async {
    final titleCtrl = TextEditingController(text: widget.post['title'] ?? '');
    final contentCtrl = TextEditingController(text: widget.post['content'] ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context)),
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true, fillColor: AppTheme.inputFillColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context)),
                decoration: InputDecoration(
                  hintText: 'Content',
                  filled: true, fillColor: AppTheme.inputFillColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.from('forum_posts').update({
                      'title': titleCtrl.text.trim(),
                      'content': contentCtrl.text.trim(),
                    }).eq('id', widget.post['id']);
                    widget.post['title'] = titleCtrl.text.trim();
                    widget.post['content'] = contentCtrl.text.trim();
                    // Notify all who interacted (replied or liked)
                    final replies = await Supabase.instance.client
                        .from('forum_replies').select('author_id').eq('post_id', widget.post['id']);
                    final likes = await Supabase.instance.client
                        .from('forum_likes').select('user_id').eq('post_id', widget.post['id']);
                    final interactedIds = {
                      ...(replies as List).map((r) => r['author_id'].toString()),
                      ...(likes as List).map((l) => l['user_id'].toString()),
                    }.where((id) => id != widget.post['author_id']).toList();
                    if (interactedIds.isNotEmpty) {
                      await Supabase.instance.client.from('notifications').insert(
                        interactedIds.map((id) => {
                          'user_id': id,
                          'sender_id': widget.post['author_id'],
                          'title': 'Post edited ✏️',
                          'title_ar': 'تم تعديل المنشور ✏️',
                          'message': 'A post you interacted with was edited: ${titleCtrl.text.trim()}',
                          'message_ar': 'تم تعديل منشور تفاعلت معه: ${titleCtrl.text.trim()}',
                          'type': 'forum',
                        }).toList(),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  child: const Text('Save', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post?', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('This will delete the post and all replies.', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    // Notify all repliers before deleting
    final replies = await Supabase.instance.client
        .from('forum_replies').select('author_id').eq('post_id', widget.post['id']);
    final likes = await Supabase.instance.client
        .from('forum_likes').select('user_id').eq('post_id', widget.post['id']);
    final interactedIds = {
      ...(replies as List).map((r) => r['author_id'].toString()),
      ...(likes as List).map((l) => l['user_id'].toString()),
    }.where((id) => id != widget.post['author_id']).toList();
    if (interactedIds.isNotEmpty) {
      await Supabase.instance.client.from('notifications').insert(
        interactedIds.map((id) => {
          'user_id': id,
          'sender_id': widget.post['author_id'],
          'title': 'Post deleted 🗑️',
          'title_ar': 'تم حذف المنشور 🗑️',
          'message': 'A post you interacted with was deleted: ${widget.post['title']}',
          'message_ar': 'تم حذف منشور تفاعلت معه: ${widget.post['title']}',
          'type': 'forum',
        }).toList(),
      );
    }
    await Supabase.instance.client.from('forum_posts').delete().eq('id', widget.post['id']);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _likePost() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Check if already liked
    Map? existing;
    try {
      existing = await Supabase.instance.client
          .from('forum_likes')
          .select()
          .eq('post_id', widget.post['id'])
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (_) {
      existing = null;
    }

    if (existing != null) {
      // Unlike
      await Supabase.instance.client.from('forum_likes')
          .delete().eq('post_id', widget.post['id']).eq('user_id', user.id);
      await Supabase.instance.client.from('forum_posts')
          .update({'likes': (widget.post['likes'] ?? 1) - 1}).eq('id', widget.post['id']);
      setState(() { widget.post['likes'] = (widget.post['likes'] ?? 1) - 1; _isLiked = false; });
      return;
    }

    // Like
    await Supabase.instance.client.from('forum_likes').insert({
      'post_id': widget.post['id'],
      'user_id': user.id,
    });
    await Supabase.instance.client.from('forum_posts')
        .update({'likes': (widget.post['likes'] ?? 0) + 1}).eq('id', widget.post['id']);
    setState(() { widget.post['likes'] = (widget.post['likes'] ?? 0) + 1; _isLiked = true; });

    // Notify post author
    final postAuthorId = widget.post['author_id'];
    if (postAuthorId != user.id) {
      final profile = await Supabase.instance.client.from('profiles').select('name').eq('id', user.id).single();
      await Supabase.instance.client.from('notifications').insert({
        'user_id': postAuthorId,
        'sender_id': user.id,
        'title': 'Someone liked your post 👍',
        'title_ar': 'شخص ما أعجبه منشورك 👍',
        'message': '${profile['name']} liked your post: ${widget.post['title']}',
        'message_ar': '${profile['name']} أعجبه منشورك: ${widget.post['title']}',
        'type': 'forum',
      });
    }
  }

  String _timeAgo(String createdAt) {
    final diff = DateTime.now().difference(DateTime.parse(createdAt));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final author = widget.post['profiles'] as Map?;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text(Tr.t('forum', widget.lang), style: const TextStyle(fontFamily: 'Cairo')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Post
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: author?['avatar_url'] != null ? NetworkImage(author!['avatar_url']) : null,
                          child: author?['avatar_url'] == null
                              ? Text((author?['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(author?['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                          Text(_timeAgo(widget.post['created_at']), style: TextStyle(fontSize: 11, color: textM)),
                        ]),
                      ]),
                      const SizedBox(height: 12),
                      Text(widget.post['title'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                      const SizedBox(height: 8),
                      Text(widget.post['content'] ?? '', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM, height: 1.6)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _likePost,
                            child: Row(children: [
                              Icon(
                                _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 18,
                                color: _isLiked ? AppTheme.primary : AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('${widget.post['likes'] ?? 0}',
                                style: TextStyle(
                                  color: _isLiked ? AppTheme.primary : AppTheme.primary,
                                  fontFamily: 'Cairo',
                                  fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                                )),
                            ]),
                          ),
                          const Spacer(),
                          // Edit/Delete — only for post author
                          if (Supabase.instance.client.auth.currentUser?.id == widget.post['author_id'])
                            Row(children: [
                              GestureDetector(
                                onTap: _editPost,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('✏️', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _deletePost,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('🗑️', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                            ]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('${_replies.length} ${Tr.t("replies", widget.lang)}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                else
                  ..._replies.map((reply) {
                    final replyAuthor = reply['profiles'] as Map?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.secondary.withOpacity(0.1),
                              backgroundImage: replyAuthor?['avatar_url'] != null ? NetworkImage(replyAuthor!['avatar_url']) : null,
                              child: replyAuthor?['avatar_url'] == null
                                  ? Text((replyAuthor?['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 13))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(replyAuthor?['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: textD)),
                            const Spacer(),
                            Text(_timeAgo(reply['created_at']), style: TextStyle(fontSize: 10, color: textM)),
                          ]),
                          const SizedBox(height: 8),
                          Text(reply['content'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM, height: 1.5)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          // Reply input
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: card,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  style: TextStyle(fontFamily: 'Cairo', color: textD),
                  decoration: InputDecoration(
                    hintText: Tr.t('write_reply', widget.lang),
                    hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                    filled: true,
                    fillColor: AppTheme.inputFillColor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitting ? null : _submitReply,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: _submitting
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final String lang;
  final VoidCallback onCreated;
  const _CreatePostSheet({required this.lang, required this.onCreated});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('forum_posts').insert({
        'author_id': user!.id,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
      });
      widget.onCreated();
    } catch (e) {
      debugPrint('Create post error: $e');
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
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(Tr.t('new_post', widget.lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: TextStyle(fontFamily: 'Cairo', color: textD),
            decoration: InputDecoration(
              hintText: Tr.t('post_title', widget.lang),
              hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
              filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(fontFamily: 'Cairo', color: textD),
            decoration: InputDecoration(
              hintText: Tr.t('post_content', widget.lang),
              hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
              filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
              child: _submitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(Tr.t('post', widget.lang), style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}