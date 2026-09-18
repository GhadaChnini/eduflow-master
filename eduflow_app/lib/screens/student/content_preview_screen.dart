import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';

class ContentPreviewScreen extends StatefulWidget {
  final String url;
  final bool isEnrolled;
  final String? unitId;

  const ContentPreviewScreen({
    super.key,
    required this.url,
    required this.isEnrolled,
    this.unitId,
  });

  @override
  State<ContentPreviewScreen> createState() => _ContentPreviewScreenState();
}

class _ContentPreviewScreenState extends State<ContentPreviewScreen> {
  VideoPlayerController? _videoController;
  String? _localPdfPath;
  bool _loading = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _locked = false;
  bool _completed = false;

  String get _type {
    final lower = widget.url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) return 'video';
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp')) return 'image';
    return 'other';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final t = _type;
    if (t == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController!.initialize();
      _videoController!.addListener(_onVideoProgress);
      await _videoController!.play();
      if (mounted) setState(() => _loading = false);
    } else if (t == 'pdf') {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await Dio().download(widget.url, file.path);
        if (mounted) setState(() { _localPdfPath = file.path; _loading = false; });
      } catch (e) {
        if (mounted) setState(() => _loading = false);
      }
    } else if (t == 'image') {
      setState(() => _loading = false);
      // Image is instant — mark complete
      if (widget.isEnrolled) _markComplete();
    } else {
      setState(() => _loading = false);
    }
  }

  void _onVideoProgress() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position.inSeconds;
    final dur = _videoController!.value.duration.inSeconds;
    if (dur == 0) return;

    // Lock at 60s for non-enrolled
    if (!widget.isEnrolled && pos >= 60) {
      _videoController!.pause();
      _videoController!.seekTo(const Duration(seconds: 60));
      if (mounted) setState(() => _locked = true);
      return;
    }

    // Update progress continuously
    if (widget.isEnrolled && widget.unitId != null) {
      final progress = ((pos / dur) * 100).round().clamp(0, 100);
      if (progress > 0 && progress % 5 == 0) { // update every 5%
        _updateVideoProgress(progress);
      }
      // Mark complete at 90%
      if (pos / dur >= 0.9 && !_completed) _markComplete();
    }
  }

  Future<void> _updateVideoProgress(int progress) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || widget.unitId == null) return;
    try {
      await Supabase.instance.client
          .from('unit_enrollments')
          .update({'progress': progress})
          .eq('unit_id', widget.unitId!)
          .eq('student_id', user.id);
      debugPrint('🎬 Video progress: $progress%');
    } catch (e) { debugPrint('Video progress error: $e'); }
  }

  Future<void> _updatePdfProgress(int currentPage, int totalPages) async {
    if (widget.unitId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // Progress = pages read / total pages
      final progress = (((currentPage + 1) / totalPages) * 100).round().clamp(0, 100);
      await Supabase.instance.client
          .from('unit_enrollments')
          .update({'progress': progress})
          .eq('unit_id', widget.unitId!)
          .eq('student_id', user.id);
      debugPrint('📄 PDF progress: ${currentPage + 1}/$totalPages = $progress%');
      // Mark complete and award points on last page
      if (currentPage == totalPages - 1) _markComplete();
    } catch (e) { debugPrint('PDF progress error: $e'); }
  }

  Future<void> _markComplete() async {
    if (_completed || widget.unitId == null) return;
    setState(() => _completed = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      debugPrint('🎯 Marking complete: ${widget.url}');
      debugPrint('🎯 unitId: ${widget.unitId}');
      // Record file completion
      await Supabase.instance.client.from('unit_file_progress').upsert({
        'student_id': user.id,
        'unit_id': widget.unitId,
        'file_url': widget.url,
      }, onConflict: 'student_id,unit_id,file_url');
      debugPrint('✅ File progress saved');

      // Recalculate unit progress
      await _updateUnitProgress(user.id);

      // Award points
      await Supabase.instance.client.rpc('add_points', params: {'user_id': user.id, 'points_to_add': 5});
      debugPrint('✅ Points awarded');
    } catch (e) { debugPrint('❌ Mark complete error: $e'); }
  }

  Future<void> _updateUnitProgress(String userId) async {
    if (widget.unitId == null) return;
    try {
      final unit = await Supabase.instance.client
          .from('behavioral_units')
          .select('content_url')
          .eq('id', widget.unitId!)
          .single();
      final contentUrl = unit['content_url'] as String?;
      if (contentUrl == null) return;

      // Parse file list
      List<String> files = [];
      try {
        if (contentUrl.trim().startsWith('[')) {
          final decoded = jsonDecode(contentUrl) as List;
          files = decoded.map((e) => e.toString()).toList();
        } else {
          files = [contentUrl];
        }
      } catch (_) { files = [contentUrl]; }

      if (files.isEmpty) return;

      // Get completed files
      final completed = await Supabase.instance.client
          .from('unit_file_progress')
          .select('file_url')
          .eq('student_id', userId)
          .eq('unit_id', widget.unitId!);

      final completedCount = (completed as List).length;
      final progress = ((completedCount / files.length) * 100).round().clamp(0, 100);

      await Supabase.instance.client
          .from('unit_enrollments')
          .update({'progress': progress})
          .eq('unit_id', widget.unitId!)
          .eq('student_id', userId);

      debugPrint('Progress updated: $completedCount/${files.length} = $progress%');
    } catch (e) { debugPrint('Update progress error: $e'); }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_type.toUpperCase(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white)),
        actions: [
          if (widget.isEnrolled && !_completed)
            TextButton(
              onPressed: _markComplete,
              child: const Text('Mark Done', style: TextStyle(color: Color(0xFF059669), fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          if (_completed)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: Text('✓ Done', style: TextStyle(color: Color(0xFF059669), fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    switch (_type) {
      case 'pdf':
        return _localPdfPath == null
            ? const Center(child: Text('Failed to load PDF', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')))
            : Stack(children: [
                PDFView(
                  filePath: _localPdfPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  onRender: (pages) {
                    setState(() => _totalPages = pages ?? 0);
                    if (pages == 1 && widget.isEnrolled) _markComplete();
                  },
                  onPageChanged: (page, total) {
                    setState(() { _currentPage = page ?? 0; _totalPages = total ?? 0; });
                    if (!widget.isEnrolled && (page ?? 0) >= 3) {
                      setState(() => _locked = true);
                    }
                    if (widget.isEnrolled && total != null && total > 0) {
                      _updatePdfProgress(page ?? 0, total);
                    }
                  },
                ),
                if (_locked) _buildLockOverlay('Preview limited to first 3 pages'),
                Positioned(
                  bottom: 16, left: 0, right: 0,
                  child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                    child: Text('${_currentPage + 1} / $_totalPages', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo')),
                  )),
                ),
              ]);

      case 'video':
        if (_videoController == null) return const SizedBox.shrink();
        return Stack(children: [
          Center(child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )),
          Positioned(bottom: 0, left: 0, right: 0,
            child: VideoProgressIndicator(_videoController!, allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: AppTheme.primary))),
          Center(child: GestureDetector(
            onTap: () {
              if (_videoController!.value.isPlaying) _videoController!.pause();
              else _videoController!.play();
              setState(() {});
            },
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
            ),
          )),
          if (_locked) _buildLockOverlay('Preview limited to 1 minute'),
        ]);

      case 'image':
        return InteractiveViewer(
          child: Center(child: Image.network(widget.url, fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) => progress == null ? child
                : const Center(child: CircularProgressIndicator(color: AppTheme.primary)))),
        );

      default:
        return Center(child: Text('Cannot preview this file type', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')));
    }
  }

  Widget _buildLockOverlay(String message) => Positioned.fill(
    child: Container(
      color: Colors.black87,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          child: const Text('Enroll to unlock', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ]),
    ),
  );
}