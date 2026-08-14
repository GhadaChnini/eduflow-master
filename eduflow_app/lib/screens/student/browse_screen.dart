import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _lang = 'ar';
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;
  int? _selectedGrade;
  String? _selectedSubject;
  String _priceFilter = 'all'; // all, free, paid
  String _sortBy = 'newest'; // newest, rating, enrolled
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    try {
      final gradesRes = await supabase.from('grades').select().order('level', ascending: true);
      final subjectsRes = await supabase.from('subjects').select();
      var query = supabase.from('behavioral_units').select('''
        *,
        profiles(name),
        grades(name_ar, name_fr, name_en),
        subjects(name_ar, name_fr, name_en, icon)
      ''').eq('status', 'published');

      if (_selectedGrade != null) query = query.eq('grade_id', _selectedGrade!);
      if (_selectedSubject != null) query = query.eq('subject_id', _selectedSubject!);
      if (_priceFilter == 'free') query = query.eq('is_free', true);
      if (_priceFilter == 'paid') query = query.eq('is_free', false);

      final sortCol = _sortBy == 'rating' ? 'avg_rating' : _sortBy == 'enrolled' ? 'total_enrolled' : 'created_at';
      final unitsRes = await query.order(sortCol, ascending: false);

      if (mounted) {
        setState(() {
          _grades = List<Map<String, dynamic>>.from(gradesRes);
          _subjects = List<Map<String, dynamic>>.from(subjectsRes);
          _units = List<Map<String, dynamic>>.from(unitsRes);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUnits {
    if (_searchQuery.isEmpty) return _units;
    return _units.where((u) {
      final title = (u['title_ar'] ?? u['title'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
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
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('←', style: TextStyle(color: Colors.white, fontSize: 18))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(Tr.t('browse_title', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: Tr.t('search_unit', _lang),
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Cairo'),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Filter bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  // Active filters summary
                  Expanded(child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      if (_selectedGrade != null)
                        _activeChip('Grade: ${_grades.firstWhere((g) => g['id'] == _selectedGrade, orElse: () => {})['name_ar'] ?? ''}', () { setState(() => _selectedGrade = null); _loadData(); }),
                      if (_selectedSubject != null)
                        _activeChip('Subject: ${_subjects.firstWhere((s) => s['id'] == _selectedSubject, orElse: () => {})['name_ar'] ?? ''}', () { setState(() => _selectedSubject = null); _loadData(); }),
                      if (_priceFilter != 'all')
                        _activeChip(_priceFilter == 'free' ? 'Free' : 'Paid', () { setState(() => _priceFilter = 'all'); _loadData(); }),
                      if (_sortBy != 'newest')
                        _activeChip(_sortBy == 'rating' ? 'Top Rated' : 'Popular', () { setState(() => _sortBy = 'newest'); _loadData(); }),
                    ]),
                  )),
                  const SizedBox(width: 8),
                  // Filter button
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, card, textD, textM, borderC),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (_selectedGrade != null || _selectedSubject != null || _priceFilter != 'all' || _sortBy != 'newest')
                            ? AppTheme.primary : card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.tune_rounded, size: 16,
                          color: (_selectedGrade != null || _selectedSubject != null || _priceFilter != 'all' || _sortBy != 'newest')
                              ? Colors.white : AppTheme.primary),
                        const SizedBox(width: 6),
                        Text('Filters', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                          color: (_selectedGrade != null || _selectedSubject != null || _priceFilter != 'all' || _sortBy != 'newest')
                              ? Colors.white : AppTheme.primary)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Units list
            _loading
                ? const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )),
                  )
                : _filteredUnits.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const Text('📭', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(Tr.t('no_units', _lang), style: TextStyle(fontFamily: 'Cairo', color: textM, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _buildUnitCard(_filteredUnits[i], card, textD, textM),
                            childCount: _filteredUnits.length,
                          ),
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit, Color card, Color textD, Color textM) {
    final subject = unit['subjects'] as Map?;
    final grade = unit['grades'] as Map?;
    final teacher = unit['profiles'] as Map?;
    final icon = subject?['icon'] ?? '📚';
    final subjectName = _lang == 'ar' 
        ? (subject?['name_ar'] ?? '') 
        : _lang == 'fr' 
            ? (subject?['name_fr'] ?? subject?['name_ar'] ?? '')
            : (subject?['name_en'] ?? subject?['name_fr'] ?? subject?['name_ar'] ?? '');
    final gradeName = _lang == 'ar'
        ? (grade?['name_ar'] ?? '')
        : _lang == 'fr'
            ? (grade?['name_fr'] ?? grade?['name_ar'] ?? '')
            : (grade?['name_en'] ?? grade?['name_fr'] ?? grade?['name_ar'] ?? '');
    final isFree = unit['is_free'] ?? true;
    final price = unit['price'] ?? 0;
    final rating = unit['avg_rating'] ?? 0.0;
    final enrolled = unit['total_enrolled'] ?? 0;

    return GestureDetector(
      onTap: () => context.go('/unit/${unit['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_lang == 'ar' ? (unit['title_ar'] ?? '') : _lang == 'fr' ? (unit['title'] ?? unit['title_ar'] ?? '') : (unit['title_en'] ?? unit['title'] ?? unit['title_ar'] ?? ''), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(subjectName, style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      Text(gradeName, style: TextStyle(fontSize: 11, color: textM, fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('⭐ ${rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: textM)),
                      const SizedBox(width: 8),
                      Text('👥 $enrolled', style: TextStyle(fontSize: 11, color: textM)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFree ? const Color(0xFF059669).withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isFree ? Tr.t('free', _lang) : '$price ${Tr.t("currency", _lang)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: isFree ? const Color(0xFF059669) : AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: textM),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: AppTheme.primary, fontWeight: FontWeight.bold)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 12, color: AppTheme.primary)),
    ]),
  );

  void _showFilterSheet(BuildContext context, Color card, Color textD, Color textM, Color borderC) {
    // Local temp state
    int? tempGrade = _selectedGrade;
    String? tempSubject = _selectedSubject;
    String tempPrice = _priceFilter;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(color: card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            // Handle
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                TextButton(onPressed: () {
                  setSheetState(() { tempGrade = null; tempSubject = null; tempPrice = 'all'; tempSort = 'newest'; });
                }, child: const Text('Reset', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary))),
              ]),
            ),
            const Divider(),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Grade
              Text('Grade', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _filterOption('All Grades', tempGrade == null, () => setSheetState(() => tempGrade = null), card, textM, borderC),
                ..._grades.map((g) => _filterOption(
                  g['name_ar'] ?? '',
                  tempGrade == g['id'],
                  () => setSheetState(() => tempGrade = g['id']),
                  card, textM, borderC,
                )),
              ]),
              const SizedBox(height: 24),
              // Subject
              Text('Subject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _filterOption('All Subjects', tempSubject == null, () => setSheetState(() => tempSubject = null), card, textM, borderC),
                ..._subjects.map((s) => _filterOption(
                  '${s['icon'] ?? '📖'} ${s['name_ar'] ?? ''}',
                  tempSubject == s['id'],
                  () => setSheetState(() => tempSubject = s['id']),
                  card, textM, borderC,
                )),
              ]),
              const SizedBox(height: 24),
              // Price
              Text('Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                _filterOption('All', tempPrice == 'all', () => setSheetState(() => tempPrice = 'all'), card, textM, borderC),
                _filterOption('Free', tempPrice == 'free', () => setSheetState(() => tempPrice = 'free'), card, textM, borderC),
                _filterOption('Paid', tempPrice == 'paid', () => setSheetState(() => tempPrice = 'paid'), card, textM, borderC),
              ]),
              const SizedBox(height: 24),
              // Sort
              Text('Sort By', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                _filterOption('Newest', tempSort == 'newest', () => setSheetState(() => tempSort = 'newest'), card, textM, borderC),
                _filterOption('Top Rated', tempSort == 'rating', () => setSheetState(() => tempSort = 'rating'), card, textM, borderC),
                _filterOption('Most Popular', tempSort == 'enrolled', () => setSheetState(() => tempSort = 'enrolled'), card, textM, borderC),
              ]),
            ]))),
            // Apply button
            Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), child: SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() { _selectedGrade = tempGrade; _selectedSubject = tempSubject; _priceFilter = tempPrice; _sortBy = tempSort; });
                Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
              child: const Text('Apply Filters', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
            ))),
          ]),
        ),
      ),
    );
  }

  Widget _filterOption(String label, bool selected, VoidCallback onTap, Color card, Color textM, Color borderC) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : card,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: selected ? AppTheme.primary : borderC),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: selected ? Colors.white : textM)),
    ),
  );
}