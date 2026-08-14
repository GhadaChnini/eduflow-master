import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:file_selector/file_selector.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class CreateUnitScreen extends ConsumerStatefulWidget {
  const CreateUnitScreen({super.key});

  @override
  ConsumerState<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends ConsumerState<CreateUnitScreen> {
  String _lang = 'ar';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];
  int? _selectedGradeId;
  int? _selectedSubjectId;
  bool _isFree = true;
  bool _loading = false;
  bool _loadingData = true;
  List<Map<String, String>> _uploadedFiles = [];
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final supabase = Supabase.instance.client;
    final gradesRes = await supabase.from('grades').select().order('level');
    final subjectsRes = await supabase.from('subjects').select();
    if (mounted) {
      setState(() {
        _grades = List<Map<String, dynamic>>.from(gradesRes);
        _subjects = List<Map<String, dynamic>>.from(subjectsRes);
        _loadingData = false;
      });
    }
  }

  Future<String> _translate(String text, String to) async {
    if (text.isEmpty) return '';
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final sb = StringBuffer();
        for (final item in data[0]) {
          if (item[0] != null) sb.write(item[0]);
        }
        return sb.toString();
      }
      return text;
    } catch (e) {
      return text;
    }
  }

  Future<void> _pickAndUploadFile() async {
    final picker = ImagePicker();
    XFile? picked;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 24)),
              title: const Text('Image', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500)),
              onTap: () async {
                picked = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🎥', style: TextStyle(fontSize: 24)),
              title: const Text('Video', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500)),
              onTap: () async {
                picked = await picker.pickVideo(source: ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('📄', style: TextStyle(fontSize: 24)),
              title: const Text('PDF', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500)),
              onTap: () async {
                const typeGroup = XTypeGroup(
                  label: 'PDF',
                  extensions: ['pdf'],
                );
                final file = await openFile(acceptedTypeGroups: [typeGroup]);
                if (file != null) picked = file;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null) return;
    setState(() => _uploadingFile = true);
    final supabase = Supabase.instance.client;
    final selectedFiles = [picked!];
    for (final file in selectedFiles) {
      Uint8List bytes;
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'file';
      // Compress video before upload
      if (['mp4', 'mov', 'avi'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compressing video...', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              duration: Duration(minutes: 2),
            ),
          );
        }
        final MediaInfo? info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (info?.file == null) continue;
        bytes = await info!.file!.readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }
      if (bytes.isEmpty) continue;
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = 'units/$fileName';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading ${file.name}...', style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppTheme.primary,
              duration: const Duration(minutes: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        await supabase.storage.from('unit_content').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final url = supabase.storage.from('unit_content').getPublicUrl(path);
        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'file';
        String contentType;
        if (['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext)) {
          contentType = 'video';
        } else if (ext == 'pdf') {
          contentType = 'pdf';
        } else if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
          contentType = 'image';
        } else {
          contentType = 'mixed';
        }
        debugPrint('Uploaded: $url');
        setState(() => _uploadedFiles.add({'name': file.name, 'url': url, 'type': contentType}));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${file.name}: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
    if (mounted) setState(() => _uploadingFile = false);
  }

  String _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return '📄';
      case 'doc': case 'docx': return '📝';
      case 'mp4': case 'mov': case 'avi': return '🎥';
      case 'png': case 'jpg': case 'jpeg': return '🖼️';
      default: return '📎';
    }
  }

  Future<void> _createUnit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.t('enter_title_first', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_selectedGradeId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.t('select_grade_subject', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (!_isFree && (double.tryParse(_priceController.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.t('enter_valid_price', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _loading = true);

    // Show translating indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(Tr.t('translating', _lang), style: const TextStyle(fontFamily: 'Cairo')),
          ]),
          duration: const Duration(seconds: 10),
          backgroundColor: AppTheme.primary,
        ),
      );
    }

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    try {
      // Auto-translate in background
      final titleAr = await _translate(title, 'ar');
      final titleFr = await _translate(title, 'fr');
      final titleEn = await _translate(title, 'en');
      final descAr = await _translate(desc, 'ar');
      final descFr = await _translate(desc, 'fr');
      final descEn = await _translate(desc, 'en');

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);

      debugPrint('Uploaded files count: ${_uploadedFiles.length}');
      debugPrint('Content URL: ${_uploadedFiles.isNotEmpty ? _uploadedFiles.first['url'] : 'null'}');
      await supabase.from('behavioral_units').insert({
        'teacher_id': user!.id,
        'title_ar': titleAr,
        'title': titleFr,
        'title_en': titleEn,
        'description_ar': descAr,
        'description': descFr,
        'description_en': descEn,
        'grade_id': _selectedGradeId,
        'subject_id': _selectedSubjectId,
        'is_free': _isFree,
        'price': price,
        'status': 'draft',
        'total_enrolled': 0,
        'avg_rating': 0.0,
        'content_url': _uploadedFiles.isNotEmpty ? _uploadedFiles.first['url'] : null,
        'content_type': _uploadedFiles.isNotEmpty ? _uploadedFiles.first['type'] : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.t('unit_created', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success),
        );
        context.go('/teacher/units');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);
    final isRtl = _lang == 'ar';

    return Scaffold(
      backgroundColor: bg,
            body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => context.go('/teacher/units'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(Tr.t('create_unit', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unit Title
                        Text(Tr.t('unit_title', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _titleController,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(fontFamily: 'Cairo', color: textD, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: Tr.t('enter_unit_title', _lang),
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                            filled: true, fillColor: inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Unit Description
                        Text(Tr.t('unit_description', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _descController,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          maxLines: 5,
                          style: TextStyle(fontFamily: 'Cairo', color: textD),
                          decoration: InputDecoration(
                            hintText: Tr.t('enter_unit_desc', _lang),
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                            filled: true, fillColor: inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Grade
                        Text(Tr.t('grade_optional', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedGradeId,
                              hint: Text(Tr.t('select_grade', _lang), style: TextStyle(fontFamily: 'Cairo', color: textM)),
                              isExpanded: true, dropdownColor: card,
                              items: _grades.map((g) {
                                final name = _lang == 'ar' ? g['name_ar'] : _lang == 'fr' ? g['name_fr'] : (g['name_en'] ?? g['name_fr']);
                                return DropdownMenuItem<int>(value: g['id'], child: Text(name ?? '', style: TextStyle(fontFamily: 'Cairo', color: textD)));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedGradeId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subject
                        Text(Tr.t('subject', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedSubjectId,
                              hint: Text(Tr.t('select_subject', _lang), style: TextStyle(fontFamily: 'Cairo', color: textM)),
                              isExpanded: true, dropdownColor: card,
                              items: _subjects.map((s) {
                                final name = _lang == 'ar' ? s['name_ar'] : _lang == 'fr' ? s['name_fr'] : (s['name_en'] ?? s['name_fr']);
                                return DropdownMenuItem<int>(value: s['id'], child: Text('${s['icon'] ?? ''} $name', style: TextStyle(fontFamily: 'Cairo', color: textD)));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedSubjectId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price
                        Text(Tr.t('price', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isFree = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isFree ? AppTheme.primary.withOpacity(0.1) : inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _isFree ? AppTheme.primary : borderC, width: _isFree ? 2 : 1),
                                ),
                                child: Center(child: Text(Tr.t('free', _lang), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _isFree ? AppTheme.primary : textM))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isFree = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isFree ? AppTheme.primary.withOpacity(0.1) : inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: !_isFree ? AppTheme.primary : borderC, width: !_isFree ? 2 : 1),
                                ),
                                child: Center(child: Text(Tr.t('paid', _lang), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: !_isFree ? AppTheme.primary : textM))),
                              ),
                            ),
                          ),
                        ]),
                        if (!_isFree) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontFamily: 'Cairo', color: textD),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                              suffixText: Tr.t('currency', _lang),
                              suffixStyle: TextStyle(fontFamily: 'Cairo', color: textM),
                              filled: true, fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],


                        const SizedBox(height: 24),

                        // File upload section
                        Text(Tr.t('unit_files', _lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _uploadingFile ? null : _pickAndUploadFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderC, style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: [
                                _uploadingFile
                                    ? const CircularProgressIndicator(color: AppTheme.primary)
                                    : const Text('📎', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text(
                                  _uploadingFile ? Tr.t('uploading', _lang) : Tr.t('upload_files_hint', _lang),
                                  style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_uploadedFiles.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ..._uploadedFiles.map((f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                            child: Row(children: [
                              Text(_fileIcon(f['type'] ?? ''), style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(f['name'] ?? '', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textD), overflow: TextOverflow.ellipsis)),
                              GestureDetector(
                                onTap: () => setState(() => _uploadedFiles.remove(f)),
                                child: const Icon(Icons.close, size: 18, color: AppTheme.error),
                              ),
                            ]),
                          )),
                        ],

                        const SizedBox(height: 32),

                        // Create button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _createUnit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(Tr.t('create_unit', _lang), style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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