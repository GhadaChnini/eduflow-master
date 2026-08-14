import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import 'payment_screen.dart';
import '../../services/language_service.dart';
import 'content_preview_screen.dart';

class UnitDetailScreen extends ConsumerStatefulWidget {
  final String unitId;
  const UnitDetailScreen({super.key, required this.unitId});

  @override
  ConsumerState<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends ConsumerState<UnitDetailScreen> {
  String _lang = 'ar';
  Map<String, dynamic>? _unit;
  bool _loading = true;
  bool _isEnrolled = false;
  bool _enrolling = false;
  VideoPlayerController? _videoController;
  int? _userRating;
  String _userComment = '';
  bool _submittingReview = false;
  bool _hasReviewed = false;

  String _fileType(String url) {
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) return 'video';
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp')) return 'image';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'doc';
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return 'ppt';
    return 'other';
  }

  Future<void> _initVideo(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    if (mounted) setState(() {});
  }


  Future<void> _downloadFile(String url) async {
    try {
      // Extract original filename from URL
      // URL format: .../units/1234567890_123_originalname.pdf
      final uri = Uri.parse(url);
      final rawFileName = uri.pathSegments.last;
      final decoded = Uri.decodeComponent(rawFileName);
      // Remove timestamp prefix (everything before second underscore)
      final underscoreIdx = decoded.indexOf('_');
      final secondUnderscoreIdx = underscoreIdx >= 0 ? decoded.indexOf('_', underscoreIdx + 1) : -1;
      final originalName = secondUnderscoreIdx >= 0
          ? decoded.substring(secondUnderscoreIdx + 1)
          : decoded;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$originalName';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Tr.t('downloading', _lang), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final dio = Dio();
      await dio.download(url, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$originalName ${Tr.t("download_complete", _lang)}', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await OpenFilex.open(savePath);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Fallback to browser
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  List<String> _parseContentUrls(String contentUrl) {
    try {
      final decoded = jsonDecode(contentUrl);
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
    return [contentUrl]; // single URL fallback
  }

  String _fileEmoji(String url) {
    final type = _fileType(url);
    switch (type) {
      case 'image': return '🖼️';
      case 'video': return '🎥';
      case 'pdf': return '📄';
      default: return '📎';
    }
  }

  Widget _buildContentPreview(String url, Color textD, Color textM, Color card, Color borderC) {
    final type = _fileType(url);
    debugPrint('Content URL: $url');
    debugPrint('Detected type: $type');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each type handles its own preview + lock logic internally
        _buildPreviewContent(url, type, textD, textM, card),
        const SizedBox(height: 12),
        // Download button — enrolled only
        if (_isEnrolled)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _downloadFile(url),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(Tr.t('download_file', _lang), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewContent(String url, String type, Color textD, Color textM, Color card) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black87,
              builder: (ctx) => Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: _isEnrolled
                          ? Image.network(url, fit: BoxFit.contain)
                          : Stack(
                              children: [
                                Image.network(url, fit: BoxFit.contain),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                        stops: const [0.3, 1.0],
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('🔒', style: TextStyle(fontSize: 36)),
                                        SizedBox(height: 8),
                                        Text('Enroll to view full image', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                        SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    top: 40, right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(url, fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null ? child :
                      Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))),
                  ),
                  if (!_isEnrolled)
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                        child: const Center(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔒', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text('Tap to preview', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )),
                      ),
                    ),
                  if (_isEnrolled)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tap to expand', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo')),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case 'video':
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  // Lock overlay after 1 min for non-enrolled
                  if (!_isEnrolled && _videoController!.value.position.inSeconds >= 60)
                    Container(
                      color: Colors.black.withOpacity(0.85),
                      child: const Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔒', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 8),
                          Text('Enroll to continue', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        ],
                      )),
                    ),
                  // Controls
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black38,
                      child: Row(children: [
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white, size: 24,
                          ),
                          onPressed: () {
                            if (!_isEnrolled && _videoController!.value.position.inSeconds >= 60) return;
                            setState(() {
                              _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                            });
                          },
                        ),
                        Expanded(
                          child: VideoProgressIndicator(_videoController!,
                            allowScrubbing: _isEnrolled,
                            colors: VideoProgressColors(
                              playedColor: AppTheme.primary,
                              bufferedColor: Colors.white30,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_videoController!.value.position.inMinutes}:${(_videoController!.value.position.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        if (!_isEnrolled)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text('1:00 max', style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Cairo')),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          height: 200,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        );

      case 'pdf':
        return _DocumentPreview(url: url, isEnrolled: _isEnrolled, type: 'pdf');

      case 'doc':
        return _DocumentPreview(url: url, isEnrolled: _isEnrolled, type: 'doc');

      case 'ppt':
        return _DocumentPreview(url: url, isEnrolled: _isEnrolled, type: 'ppt');

      default:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Text('📎', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Tr.t('view_file', _lang), style: TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                Text(Tr.t('tap_to_open', _lang), style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
              ]),
            ),
          ]),
        );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final supabase = Supabase.instance.client;
    try {
      print('Loading unit: \${widget.unitId}');
      final unitRes = await supabase.from('behavioral_units').select('''
        *,
        profiles(name),
        grades(name_ar, name_fr, name_en),
        subjects(name_ar, name_fr, name_en, icon, color)
      ''').eq('id', widget.unitId).single();

      final user = supabase.auth.currentUser;
      bool enrolled = false;
      if (user != null) {
        final enrollment = await supabase
            .from('unit_enrollments')
            .select('id')
            .eq('unit_id', widget.unitId)
            .eq('student_id', user.id)
            .maybeSingle();
        enrolled = enrollment != null;
      }

      print('Unit loaded: \$unitRes');
      if (mounted) {
        setState(() {
          _unit = Map<String, dynamic>.from(unitRes);
          _isEnrolled = enrolled;
          _loading = false;
        });
        if (enrolled) _loadReview();
        _loadReviews();
        // Init video preview if content is a video
        final contentUrl = unitRes['content_url'] as String?;
        if (contentUrl != null && _fileType(contentUrl) == 'video') {
          _initVideo(contentUrl);
        }
      }
    } catch (e) {
      print('Unit load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enroll() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _enrolling = true);
    try {
      await supabase.from('unit_enrollments').insert({
        'unit_id': widget.unitId,
        'student_id': user.id,
        'progress': 0,
      });
      await supabase.rpc('increment_enrollment', params: {'unit_id': widget.unitId});
      setState(() => _isEnrolled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Tr.t('enrolled_success', _lang), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Enroll error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _enrolling = false);
  }

  List<Map<String, dynamic>> _reviews = [];

  Future<void> _loadReviews() async {
    try {
      final res = await Supabase.instance.client
          .from('unit_reviews')
          .select('*, profiles!student_id(name, avatar_url)')
          .eq('unit_id', widget.unitId)
          .order('created_at', ascending: false);
      if (mounted) setState(() => _reviews = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  Future<void> _loadReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('unit_reviews')
          .select()
          .eq('unit_id', widget.unitId)
          .eq('student_id', user.id)
          .maybeSingle();
      if (mounted && res != null) {
        setState(() {
          _userRating = res['rating'];
          _userComment = res['comment'] ?? '';
          _hasReviewed = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitReview() async {
    if (_userRating == null) return;
    setState(() => _submittingReview = true);
    final user = Supabase.instance.client.auth.currentUser!;
    try {
      await Supabase.instance.client.from('unit_reviews').upsert({
        'unit_id': widget.unitId,
        'student_id': user.id,
        'rating': _userRating,
        'comment': _userComment,
      }, onConflict: 'unit_id,student_id');

      // Notify teacher
      if (_unit != null) {
        final teacherId = _unit!['teacher_id'];
        if (teacherId != null && teacherId != user.id) {
          final profile = await Supabase.instance.client.from('profiles').select('name').eq('id', user.id).single();
          await Supabase.instance.client.from('notifications').insert({
            'user_id': teacherId,
            'sender_id': user.id,
            'title': 'New review on your unit',
            'title_ar': 'تقييم جديد على وحدتك',
            'message': '${profile['name']} rated your unit ${_getTitle()} with $_userRating stars',
            'message_ar': '${profile['name']} قيّم وحدتك ${_getTitle()} بـ $_userRating نجوم',
            'type': 'review',
          });
        }
      }

      if (mounted) {
        setState(() { _hasReviewed = true; _submittingReview = false; });
        _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.t('review_submitted', _lang), style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  String _getTitle() {
    if (_unit == null) return '';
    if (_lang == 'ar') return _unit!['title_ar'] ?? _unit!['title'] ?? '';
    if (_lang == 'fr') return _unit!['title'] ?? _unit!['title_ar'] ?? '';
    return _unit!['title_en'] ?? _unit!['title'] ?? _unit!['title_ar'] ?? '';
  }

  String _getDescription() {
    if (_unit == null) return '';
    if (_lang == 'ar') return _unit!['description_ar'] ?? _unit!['description'] ?? '';
    if (_lang == 'fr') return _unit!['description'] ?? _unit!['description_ar'] ?? '';
    return _unit!['description_en'] ?? _unit!['description'] ?? _unit!['description_ar'] ?? '';
  }

  String _getSubjectName() {
    final subject = _unit?['subjects'] as Map?;
    if (subject == null) return '';
    if (_lang == 'ar') return subject['name_ar'] ?? '';
    if (_lang == 'fr') return subject['name_fr'] ?? subject['name_ar'] ?? '';
    return subject['name_en'] ?? subject['name_fr'] ?? subject['name_ar'] ?? '';
  }

  String _getGradeName() {
    final grade = _unit?['grades'] as Map?;
    if (grade == null) return '';
    if (_lang == 'ar') return grade['name_ar'] ?? '';
    if (_lang == 'fr') return grade['name_fr'] ?? grade['name_ar'] ?? '';
    return grade['name_en'] ?? grade['name_fr'] ?? grade['name_ar'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_unit == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Unit not found', style: TextStyle(color: textM, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/browse'),
                child: const Text('Back to Browse'),
              ),
            ],
          ),
        ),
      );
    }

    final subject = _unit!['subjects'] as Map?;
    final icon = subject?['icon'] ?? '📚';
    final isFree = _unit!['is_free'] ?? true;
    final price = _unit!['price'] ?? 0;
    final rating = (_unit!['avg_rating'] ?? 0.0).toDouble();
    final enrolledCount = _unit!['total_enrolled'] ?? 0;
    final teacher = _unit!['profiles'] as Map?;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
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
                  GestureDetector(
                    onTap: () => context.go('/browse'),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 16),
                  Text(_getTitle(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('📚 ${_getSubjectName()}'),
                      const SizedBox(width: 8),
                      _chip('🎓 ${_getGradeName()}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip('⭐ ${rating.toStringAsFixed(1)}'),
                      const SizedBox(width: 8),
                      _chip('👥 $enrolledCount'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFree ? const Color(0xFF059669) : AppTheme.secondary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isFree ? Tr.t('free', _lang) : '$price ${Tr.t("currency", _lang)}',
                          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Tr.t('about_unit', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Text(_getDescription(),
                      style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM, height: 1.8),
                      textAlign: _lang == 'ar' ? TextAlign.right : TextAlign.left),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (teacher != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                        child: Center(
                          child: Text(
                            (teacher['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Tr.t('teacher', _lang), style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                          Text(teacher['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Content section
          if (_unit!['content_url'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Tr.t('unit_content', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                    const SizedBox(height: 12),
                    ..._parseContentUrls(_unit!['content_url'] as String).asMap().entries.map((entry) {
                      final i = entry.key;
                      final url = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < _parseContentUrls(_unit!['content_url'] as String).length - 1 ? 12 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => ContentPreviewScreen(
                                      url: url,
                                      isEnrolled: _isEnrolled,
                                      unitId: widget.unitId,
                                    ),
                                  ));
                                },
                                icon: Text(_fileEmoji(url), style: const TextStyle(fontSize: 16)),
                                label: Text(
                                  _isEnrolled ? Tr.t('view_content', _lang) : Tr.t('preview_content', _lang),
                                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  side: const BorderSide(color: AppTheme.primary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                ),
                              ),
                            ),
                            if (_isEnrolled) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _downloadFile(url),
                                  icon: const Icon(Icons.download_rounded, size: 20),
                                  label: Text(Tr.t('download_file', _lang), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Review section — enrolled only
          if (_isEnrolled)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Tr.t('your_review', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stars
                          Row(
                            children: List.generate(5, (i) => GestureDetector(
                              onTap: () => setState(() => _userRating = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  i < (_userRating ?? 0) ? Icons.star : Icons.star_border,
                                  color: const Color(0xFFF59E0B),
                                  size: 32,
                                ),
                              ),
                            )),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: TextEditingController(text: _userComment),
                            maxLines: 3,
                            onChanged: (v) => _userComment = v,
                            style: TextStyle(fontFamily: 'Cairo', color: textD),
                            decoration: InputDecoration(
                              hintText: Tr.t('write_review', _lang),
                              hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                              filled: true,
                              fillColor: AppTheme.inputFillColor(context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submittingReview || _userRating == null ? null : _submitReview,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: _submittingReview
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _hasReviewed ? Tr.t('update_review', _lang) : Tr.t('submit_review', _lang),
                                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // All reviews
          if (_reviews.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(Tr.t('all_reviews', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                    const SizedBox(height: 12),
                    ..._reviews.map((review) {
                      final author = review['profiles'] as Map?;
                      final rating = review['rating'] as int? ?? 0;
                      final comment = review['comment'] as String? ?? '';
                      final diff = DateTime.now().difference(DateTime.parse(review['created_at']));
                      final timeAgo = diff.inDays > 0 ? '${diff.inDays}d ago' : diff.inHours > 0 ? '${diff.inHours}h ago' : '${diff.inMinutes}m ago';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
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
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(author?['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: textD)),
                                Text(timeAgo, style: TextStyle(fontSize: 11, color: textM)),
                              ])),
                              Row(children: List.generate(5, (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFF59E0B), size: 14,
                              ))),
                            ]),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comment, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM, height: 1.5)),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _isEnrolled
          ? Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: card,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Center(
                child: Text(
                  Tr.t('already_enrolled', _lang),
                  style: const TextStyle(color: Color(0xFF059669), fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: card,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: ElevatedButton(
                onPressed: _enrolling ? null : () {
                  if (!isFree) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        itemTitle: _getTitle(),
                        amount: price is num ? (price as num).toInt() : int.tryParse(price.toString()) ?? 0,
                        onSuccess: _enroll,
                      ),
                    ));
                  } else {
                    _enroll();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: _enrolling
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isFree ? Tr.t('enroll_free', _lang) : '${Tr.t('enroll_paid', _lang)} $price ${Tr.t("currency", _lang)}',
                        style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
              ),
            ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cairo')),
    );
  }
}

class _DocumentPreview extends StatefulWidget {
  final String url;
  final bool isEnrolled;
  final String type; // 'pdf' or 'doc'
  const _DocumentPreview({required this.url, required this.isEnrolled, required this.type});

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  String? _localPath; // for PDF only
  bool _loading = true;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'pdf') {
      _downloadPdf();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = widget.url.split('/').last.split('?').first;
      final path = '${dir.path}/$fileName';
      final file = File(path);
      if (!await file.exists()) {
        final dio = Dio();
        await dio.download(widget.url, path);
      }
      if (mounted) setState(() { _localPath = path; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFullPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (ctx, _) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(children: [
                  Text(widget.type == 'pdf' ? '📄' : '📝', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(widget.type == 'pdf' ? 'PDF' : 'Document',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),

                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]),
              ),
              Expanded(
                child: Stack(
                  children: [
                    widget.type == 'pdf' && _localPath != null
                        ? PDFView(
                            filePath: _localPath!,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: true,
                            pageFling: true,
                            pageSnap: true,
                            defaultPage: 0,
                            fitPolicy: FitPolicy.WIDTH,
                            onRender: (pages) => setState(() => _totalPages = pages ?? 0),
                            onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
                          )
                        : WebViewWidget(
                            controller: WebViewController()
                              ..setJavaScriptMode(JavaScriptMode.unrestricted)
                              ..loadRequest(Uri.parse(
                                'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.url)}&embedded=true',
                              )),
                          ),
                    // Lock overlay for non-enrolled after 3 pages
                    if (!widget.isEnrolled && widget.type == 'pdf' && _currentPage >= 3)
                      Container(
                        color: Colors.white.withOpacity(0.97),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔒', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              const Text('Enroll to read the full document',
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text('You\'ve seen the first 3 pages',
                                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    // Bottom fade for non-enrolled (when on page 2-3)
                    if (!widget.isEnrolled && widget.type == 'pdf' && _currentPage == 2)
                      Positioned(
                        bottom: 0, left: 0, right: 0, height: 150,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.white.withOpacity(0.95)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.type == 'pdf' ? '📄' : widget.type == 'ppt' ? '📊' : '📝';

    return GestureDetector(
      onTap: _openFullPreview,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: _loading
            ? const Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  SizedBox(height: 8),
                  Text('Loading preview...', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12)),
                ],
              ))
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // PDF thumbnail or doc icon
                    widget.type == 'pdf' && _localPath != null
                        ? PDFView(
                            filePath: _localPath!,
                            enableSwipe: false,
                            swipeHorizontal: false,
                            autoSpacing: false,
                            pageFling: false,
                            pageSnap: false,
                            defaultPage: 0,
                            fitPolicy: FitPolicy.WIDTH,
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                Text(
                                  widget.type == 'doc' ? 'Document' : 'Presentation',
                                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                                ),
                              ],
                            )),
                          ),
                    // Tap overlay
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              widget.isEnrolled ? 'Tap to read' : 'Tap to preview',
                              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
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