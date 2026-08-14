import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});
  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  double _unitEarnings = 0;
  double _sessionEarnings = 0;
  List<Map<String, dynamic>> _statements = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // Paid units
      final units = await Supabase.instance.client
          .from('behavioral_units')
          .select('id, title_ar, title, title_en, total_enrolled, price, is_free, created_at')
          .eq('teacher_id', user.id)
          .eq('is_free', false);
      final unitList = List<Map<String, dynamic>>.from(units);

      // Paid sessions
      final sessions = await Supabase.instance.client
          .from('live_sessions')
          .select('id, title, total_enrolled, price, is_paid, scheduled_at')
          .eq('teacher_id', user.id)
          .eq('is_paid', true);
      final sessionList = List<Map<String, dynamic>>.from(sessions);

      // Calculate earnings (teacher gets X - 5%)
      double uEarnings = 0;
      for (final u in unitList) {
        final gross = ((u['total_enrolled'] ?? 0) as num) * ((u['price'] ?? 0) as num);
        uEarnings += gross * 0.95;
      }
      double sEarnings = 0;
      for (final s in sessionList) {
        final gross = ((s['total_enrolled'] ?? 0) as num) * ((s['price'] ?? 0) as num);
        sEarnings += gross * 0.95;
      }

      // Build statement list
      final List<Map<String, dynamic>> statements = [];
      for (final u in unitList) {
        final enrolled = (u['total_enrolled'] ?? 0) as int;
        if (enrolled == 0) continue;
        final price = (u['price'] ?? 0) as num;
        final gross = enrolled * price;
        final eduflow = gross * 0.1; // 10% from student side
        final fee = gross * 0.05;    // 5% from teacher side
        final net = gross * 0.95;
        statements.add({
          'type': 'unit',
          'title': u['title_ar'] ?? u['title'] ?? '',           // for UI (Arabic)
          'title_pdf': u['title_en'] ?? u['title'] ?? u['title_ar'] ?? '', // for PDF (English)
          'enrolled': enrolled,
          'price': price,
          'gross': gross,
          'eduflow_fee': eduflow,
          'teacher_fee': fee,
          'net': net,
          'date': u['created_at'],
          'icon': '📚',
        });
      }
      for (final s in sessionList) {
        final enrolled = (s['total_enrolled'] ?? 0) as int;
        if (enrolled == 0) continue;
        final price = (s['price'] ?? 0) as num;
        final gross = enrolled * price;
        final eduflow = gross * 0.1;
        final fee = gross * 0.05;
        final net = gross * 0.95;
        statements.add({
          'type': 'session',
          'title': s['title'] ?? '',
          'title_pdf': s['title'] ?? '',
          'enrolled': enrolled,
          'price': price,
          'gross': gross,
          'eduflow_fee': eduflow,
          'teacher_fee': fee,
          'net': net,
          'date': s['scheduled_at'],
          'icon': '📅',
        });
      }

      // Sort by date descending
      statements.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

      if (mounted) setState(() {
        _unitEarnings = uEarnings;
        _sessionEarnings = sEarnings;
        _statements = statements;
        _loading = false;
      });
    } catch (e) { debugPrint('Earnings error: $e'); if (mounted) setState(() => _loading = false); }
  }

  Future<void> _downloadStatement() async {
    try {
      // Load Cairo font for Arabic support
      final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
      final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
      final pdf = pw.Document();
      final total = _unitEarnings + _sessionEarnings;
      final now = DateTime.now();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('059669'), borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('EduFlow', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Earnings Statement', style: pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                pw.Text('Generated: ${now.day}/${now.month}/${now.year}', style: pw.TextStyle(fontSize: 11, color: PdfColors.white)),
              ]),
            ),
            pw.SizedBox(height: 24),
            // Summary
            pw.Row(children: [
              pw.Expanded(child: _pdfCard('Total Net Earnings', '${total.toStringAsFixed(2)} DT', PdfColor.fromHex('059669'))),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _pdfCard('Units', '${_unitEarnings.toStringAsFixed(2)} DT', PdfColor.fromHex('2563EB'))),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _pdfCard('Sessions', '${_sessionEarnings.toStringAsFixed(2)} DT', PdfColor.fromHex('7C3AED'))),
            ]),
            pw.SizedBox(height: 24),
            // Table header
            pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Table header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
                  children: [
                    _pdfCell('Title', bold: true),
                    _pdfCell('Enrolled', bold: true),
                    _pdfCell('Price', bold: true),
                    _pdfCell('You Receive', bold: true),
                  ],
                ),
                // Data rows
                ..._statements.map((s) => pw.TableRow(children: [
                  _pdfCell((s['title_pdf'] ?? s['title'] ?? '').toString()),
                  _pdfCell('${s['enrolled']}'),
                  _pdfCell('${s['price']} DT'),
                  _pdfCell('${(s['net'] as double).toStringAsFixed(2)} DT', color: PdfColor.fromHex('059669')),
                ])),
                // Total row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
                  children: [
                    _pdfCell('TOTAL', bold: true),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell('${total.toStringAsFixed(2)} DT', bold: true, color: PdfColor.fromHex('059669')),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Text('EduFlow - Behavioral Learning Platform', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ));

      final bytes = await pdf.save();
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'EduFlow_Statement_${now.day}_${now.month}_${now.year}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('PDF error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating PDF: $e', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  pw.Widget _pdfCard(String label, String value, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
      pw.SizedBox(height: 4),
      pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    ]),
  );

  pw.Widget _pdfCell(String text, {bool bold = false, PdfColor? color}) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    )),
  );

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final total = _unitEarnings + _sessionEarnings;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // Header
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(bottom: false, child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); else context.go('/teacher'); },
                    child: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
                  ),
                  const SizedBox(width: 12),
                  const Text('Earnings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/teacher/bank'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                      child: const Row(children: [
                        Icon(Icons.account_balance, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Bank', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              // Total
              Text('Total Net Earnings', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
              const SizedBox(height: 4),
              Text('${total.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              // Summary chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _chip('📚 Units', '${_unitEarnings.toStringAsFixed(2)} DT'),
                  const SizedBox(width: 10),
                  _chip('📅 Sessions', '${_sessionEarnings.toStringAsFixed(2)} DT'),
                ]),
              ),
              const SizedBox(height: 16),
              // Tabs
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [Tab(text: 'Statement'), Tab(text: 'Summary')],
              ),
            ])),
          )),
          // Tab content
          SliverFillRemaining(
            child: TabBarView(controller: _tabCtrl, children: [
              // Statement tab
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                  : _statements.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('💰', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No earnings yet', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                          const SizedBox(height: 6),
                          Text('Create paid units or sessions', style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _statements.length,
                          itemBuilder: (ctx, i) {
                            final s = _statements[i];
                            final date = s['date'] != null ? DateTime.tryParse(s['date']) : null;
                            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                              child: Column(children: [
                                // Header
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(children: [
                                    Container(width: 42, height: 42,
                                      decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Center(child: Text(s['icon'], style: const TextStyle(fontSize: 20)))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(s['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                                      Text('${s['enrolled']} enrollments  •  $dateStr', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textM)),
                                    ])),
                                    Text('+${(s['net'] as double).toStringAsFixed(2)} DT',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF059669), fontFamily: 'Cairo')),
                                  ]),
                                ),
                                // Breakdown
                                Container(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                                  decoration: BoxDecoration(color: AppTheme.bgColor(context), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                                  child: Column(children: [
                                    _statRow('Price per enrollment', '${s['price']} DT', textM, textD),
                                    _statRow('Enrollments', '${s['enrolled']}', textM, textD),
                                    _statRow('Gross', '${(s['gross'] as double).toStringAsFixed(2)} DT', textM, textD),
                                    const Divider(height: 12),
                                    _statRow('You receive', '${(s['net'] as double).toStringAsFixed(2)} DT', textD, const Color(0xFF059669), bold: true),
                                  ]),
                                ),
                              ]),
                            );
                          },
                        ),
              // Summary tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 8),
                  _summaryCard('📚 Units Revenue', _unitEarnings, _statements.where((s) => s['type'] == 'unit').length, card, textD, textM, borderC),
                  const SizedBox(height: 12),
                  _summaryCard('📅 Sessions Revenue', _sessionEarnings, _statements.where((s) => s['type'] == 'session').length, card, textD, textM, borderC),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _downloadStatement,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC),
                      ),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.download, color: Color(0xFF059669)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Download Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
                          Text('Export your earnings as a text report', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textM)),
                        ])),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF059669)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
      ]),
    ),
  );

  Widget _statRow(String label, String value, Color labelColor, Color valueColor, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: labelColor)),
      Text(value, style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: valueColor, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]),
  );

  Widget _summaryCard(String title, double amount, int count, Color card, Color textD, Color textM, Color borderC) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
        const SizedBox(height: 4),
        Text('$count paid items', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textM)),
      ])),
      Text('${amount.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669), fontFamily: 'Cairo')),
    ]),
  );
}