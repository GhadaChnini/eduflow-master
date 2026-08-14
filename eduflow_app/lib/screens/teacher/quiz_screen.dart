import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class TeacherQuizScreen extends ConsumerStatefulWidget {
  const TeacherQuizScreen({super.key});
  @override
  ConsumerState<TeacherQuizScreen> createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends ConsumerState<TeacherQuizScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('quizzes')
          .select('*, behavioral_units!unit_id(title_ar, title)')
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _quizzes = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _toggleActive(String id, bool current) async {
    await Supabase.instance.client.from('quizzes').update({'is_active': !current}).eq('id', id);
    _load();
  }

  Future<void> _delete(String id) async {
    if (!(await _confirm('Delete this quiz?'))) return;
    await Supabase.instance.client.from('quizzes').delete().eq('id', id);
    _load();
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(msg, style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
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
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateQuizScreen())).then((_) => _load()),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quizzes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                Text('${_quizzes.length} created', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
              ]),
            ]),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _loading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary))))
              : _quizzes.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                      const Text('🧠', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('No quizzes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                      const SizedBox(height: 8),
                      Text('Tap + to create your first quiz', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
                    ]))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                        final q = _quizzes[i];
                        final unit = q['behavioral_units'] as Map?;
                        final isActive = q['is_active'] == true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? AppTheme.primary.withOpacity(0.4) : borderC)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: isActive ? AppTheme.primary : Colors.grey)),
                              ),
                              const Spacer(),
                              Text('⏱ ${(q['time_limit_seconds'] ?? 300) ~/ 60} min', style: TextStyle(fontSize: 12, color: textM, fontFamily: 'Cairo')),
                            ]),
                            const SizedBox(height: 10),
                            Text(q['title_ar'] ?? q['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                            if (unit != null) ...[
                              const SizedBox(height: 4),
                              Text('📚 ${unit['title_ar'] ?? unit['title'] ?? ''}', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM)),
                            ],
                            const SizedBox(height: 12),
                            Row(children: [
                              _btn(isActive ? 'Deactivate' : 'Activate', isActive ? Colors.grey : AppTheme.primary, () => _toggleActive(q['id'], isActive)),
                              const SizedBox(width: 8),
                              _btn('Questions', AppTheme.secondary, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizQuestionsScreen(quizId: q['id'], quizTitle: q['title_ar'] ?? q['title'] ?? ''))).then((_) => _load())),
                              const SizedBox(width: 8),
                              _btn('Delete', AppTheme.error, () => _delete(q['id'])),
                            ]),
                          ]),
                        );
                      }, childCount: _quizzes.length)),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: color)),
    ),
  );
}

// ─── Create Quiz Screen ──────────────────────────────────────────────────────

class CreateQuizScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  const CreateQuizScreen({super.key, this.sessionId});
  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _timeLimitCtrl = TextEditingController(text: '5');
  String? _selectedUnitId;
  List<Map<String, dynamic>> _units = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadUnits(); }
  @override
  void dispose() { _titleCtrl.dispose(); _timeLimitCtrl.dispose(); super.dispose(); }

  Future<void> _loadUnits() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final res = await Supabase.instance.client.from('behavioral_units').select('id, title_ar, title').eq('teacher_id', user.id);
    if (mounted) setState(() => _units = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser!;
    try {
      final res = await Supabase.instance.client.from('quizzes').insert({
        'teacher_id': user.id,
        'title': _titleCtrl.text.trim(),
        'title_ar': _titleCtrl.text.trim(),
        'time_limit_seconds': (int.tryParse(_timeLimitCtrl.text) ?? 5) * 60,
        if (_selectedUnitId != null) 'unit_id': _selectedUnitId,
        if (widget.sessionId != null) 'session_id': widget.sessionId,
        'is_active': false,
      }).select().single();
      if (mounted) {
        // Navigate to questions screen directly
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => QuizQuestionsScreen(
            quizId: res['id'],
            quizTitle: _titleCtrl.text.trim(),
          ),
        ));
      }
    } catch (e) { debugPrint('Create quiz error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Create Quiz', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quiz Title', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, style: TextStyle(fontFamily: 'Cairo', color: textD),
            decoration: InputDecoration(hintText: 'e.g. Unit 1 Quiz', hintStyle: TextStyle(fontFamily: 'Cairo', color: textM), filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          const SizedBox(height: 16),
          Text('Time Limit (minutes)', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
          const SizedBox(height: 8),
          TextField(controller: _timeLimitCtrl, keyboardType: TextInputType.number, style: TextStyle(fontFamily: 'Cairo', color: textD),
            decoration: InputDecoration(hintText: '5', hintStyle: TextStyle(fontFamily: 'Cairo', color: textM), filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          const SizedBox(height: 16),
          Text('Linked Unit (optional)', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderC)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _selectedUnitId, hint: Text('Select unit', style: TextStyle(fontFamily: 'Cairo', color: textM)),
              isExpanded: true, dropdownColor: card,
              items: [
                DropdownMenuItem<String>(value: null, child: Text('None', style: TextStyle(fontFamily: 'Cairo', color: textD))),
                ..._units.map((u) => DropdownMenuItem<String>(value: u['id'], child: Text(u['title_ar'] ?? u['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', color: textD)))),
              ],
              onChanged: (v) => setState(() => _selectedUnitId = v),
            )),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : _create,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Quiz', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }
}

// ─── Quiz Questions Screen ───────────────────────────────────────────────────

class QuizQuestionsScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String quizTitle;
  const QuizQuestionsScreen({super.key, required this.quizId, required this.quizTitle});
  @override
  ConsumerState<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends ConsumerState<QuizQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('quiz_questions')
          .select()
          .eq('quiz_id', widget.quizId)
          .order('order_num');
      if (mounted) setState(() { _questions = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('quiz_questions').delete().eq('id', id);
    _load();
  }

  void _addQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddQuestionSheet(quizId: widget.quizId, orderNum: _questions.length, onAdded: () { Navigator.pop(ctx); _load(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(onPressed: _addQuestion, backgroundColor: AppTheme.primary, child: const Icon(Icons.add, color: Colors.white)),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text(widget.quizTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${_questions.length} Q', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _questions.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🧠', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('No questions yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                  const SizedBox(height: 8),
                  Text('Tap + to add questions', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (ctx, i) {
                    final q = _questions[i];
                    final options = (q['options'] as List?) ?? [];
                    final correct = q['correct_answer'] as int? ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(q['question_text'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD))),
                          GestureDetector(onTap: () => _delete(q['id']), child: Icon(Icons.delete_outline, color: AppTheme.error, size: 20)),
                        ]),
                        const SizedBox(height: 10),
                        ...options.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(e.key == correct ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 16, color: e.key == correct ? const Color(0xFF059669) : textM),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value.toString(), style: TextStyle(fontSize: 13, fontFamily: 'Cairo',
                              color: e.key == correct ? const Color(0xFF059669) : textD,
                              fontWeight: e.key == correct ? FontWeight.bold : FontWeight.normal))),
                          ]),
                        )),
                        const SizedBox(height: 4),
                        Text('${q['points'] ?? 10} points', style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ─── Add Question Sheet ──────────────────────────────────────────────────────

class _AddQuestionSheet extends StatefulWidget {
  final String quizId;
  final int orderNum;
  final VoidCallback onAdded;
  const _AddQuestionSheet({required this.quizId, required this.orderNum, required this.onAdded});
  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _questionCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');
  final List<TextEditingController> _optionCtrls = List.generate(4, (_) => TextEditingController());
  int _correctAnswer = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _questionCtrl.dispose(); _pointsCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_questionCtrl.text.trim().isEmpty) return;
    final options = _optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (options.length < 2) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 2 options'))); return; }
    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.from('quiz_questions').insert({
        'quiz_id': widget.quizId,
        'question_text': _questionCtrl.text.trim(),
        'question_text_ar': _questionCtrl.text.trim(),
        'options': options,
        'correct_answer': _correctAnswer,
        'points': int.tryParse(_pointsCtrl.text) ?? 10,
        'order_num': widget.orderNum,
      });
      widget.onAdded();
    } catch (e) { debugPrint('Add question error: $e'); }
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
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        Text('Add Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
        const SizedBox(height: 16),
        TextField(controller: _questionCtrl, maxLines: 2, style: TextStyle(fontFamily: 'Cairo', color: textD),
          decoration: InputDecoration(hintText: 'Question text...', hintStyle: TextStyle(fontFamily: 'Cairo', color: textM), filled: true, fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            contentPadding: const EdgeInsets.all(14))),
        const SizedBox(height: 16),
        Text('Options (tap to mark correct)', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
        const SizedBox(height: 8),
        ...List.generate(4, (i) => GestureDetector(
          onTap: () => setState(() => _correctAnswer = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _correctAnswer == i ? const Color(0xFF059669).withOpacity(0.08) : inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _correctAnswer == i ? const Color(0xFF059669) : borderC, width: _correctAnswer == i ? 2 : 1),
            ),
            child: Row(children: [
              Padding(padding: const EdgeInsets.all(12), child: Icon(_correctAnswer == i ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _correctAnswer == i ? const Color(0xFF059669) : textM, size: 20)),
              Expanded(child: TextField(controller: _optionCtrls[i], style: TextStyle(fontFamily: 'Cairo', color: textD),
                decoration: InputDecoration(hintText: 'Option ${i + 1}', hintStyle: TextStyle(fontFamily: 'Cairo', color: textM), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)))),
            ]),
          ),
        )),
        const SizedBox(height: 8),
        Row(children: [
          Text('Points: ', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
          SizedBox(width: 80, child: TextField(controller: _pointsCtrl, keyboardType: TextInputType.number, style: TextStyle(fontFamily: 'Cairo', color: textD, fontWeight: FontWeight.bold),
            decoration: InputDecoration(filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          child: _submitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Add Question', style: TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        )),
      ])),
    );
  }
}

// ─── Quiz Leaderboard Screen ─────────────────────────────────────────────────

class QuizLeaderboardScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  const QuizLeaderboardScreen({super.key, required this.quizId, required this.quizTitle});
  @override
  State<QuizLeaderboardScreen> createState() => _QuizLeaderboardScreenState();
}

class _QuizLeaderboardScreenState extends State<QuizLeaderboardScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('quiz_attempts')
          .select('*, profiles!student_id(name, avatar_url)')
          .eq('quiz_id', widget.quizId)
          .order('score', ascending: false);
      if (mounted) setState(() { _results = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text(widget.quizTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _results.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🏆', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('No submissions yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                  const SizedBox(height: 8),
                  Text('Results will appear here when students submit', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final r = _results[i];
                    final profile = r['profiles'] as Map?;
                    final score = r['score'] as int? ?? 0;
                    final total = r['total_points'] as int? ?? 0;
                    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';
                    final isTop = i < 3;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isTop ? const Color(0xFFF59E0B).withOpacity(i == 0 ? 0.12 : i == 1 ? 0.07 : 0.04) : card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isTop ? const Color(0xFFF59E0B).withOpacity(0.3) : borderC),
                      ),
                      child: Row(children: [
                        SizedBox(width: 36, child: Center(child: Text(medal, style: const TextStyle(fontSize: 22)))),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url']) : null,
                          child: profile?['avatar_url'] == null ? Text(
                            (profile?['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(profile?['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                          Text('Submitted ${_timeAgo(r['completed_at'] ?? '')}', style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo')),
                          Text('/ $total pts', style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }

  String _timeAgo(String createdAt) {
    if (createdAt.isEmpty) return '';
    final diff = DateTime.now().difference(DateTime.parse(createdAt));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}