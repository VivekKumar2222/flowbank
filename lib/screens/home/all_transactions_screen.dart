import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PlaidTransaction {
  final String name;
  final double amount;
  final String date;
  final String category;
  final String accountName;
  final bool isDebit;

  PlaidTransaction({
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountName,
    required this.isDebit,
  });

  factory PlaidTransaction.fromMap(Map<String, dynamic> map) {
    final double rawAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    return PlaidTransaction(
      name: map['name'] ?? map['merchant_name'] ?? 'Unknown',
      amount: rawAmount.abs(),
      date: map['date']?.toString() ?? '',
      category: _parseCategory(map['category']),
      accountName: map['account_name'] ?? map['accountName'] ?? 'My Account',
      isDebit: rawAmount > 0,
    );
  }

  static String _parseCategory(dynamic cat) {
    if (cat == null) return 'Uncategorized';
    if (cat is String) return cat;
    if (cat is List && cat.isNotEmpty) return cat.last.toString();
    return 'Uncategorized';
  }
}

class AllTransactionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawTransactions;
  final String userName;

  const AllTransactionsScreen({
    super.key,
    required this.rawTransactions,
    required this.userName,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  static const _blue = Color(0xFF1E88E5);
  static const _textDark = Color(0xFF1A1F36);
  static const _textMid = Color(0xFF475467);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey = Color(0xFFF5F7FA);
  static const _border = Color(0xFFE2E8F0);

  late List<PlaidTransaction> _allTx;
  List<PlaidTransaction> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _allTx = widget.rawTransactions.map((m) => PlaidTransaction.fromMap(m)).toList();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<PlaidTransaction> result = List.from(_allTx);

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedFilter == 'Debit') result = result.where((t) => t.isDebit).toList();
    if (_selectedFilter == 'Credit') result = result.where((t) => !t.isDebit).toList();

    switch (_selectedSort) {
      case 'Newest': result.sort((a, b) => b.date.compareTo(a.date)); break;
      case 'Oldest': result.sort((a, b) => a.date.compareTo(b.date)); break;
      case 'Highest': result.sort((a, b) => b.amount.compareTo(a.amount)); break;
      case 'Lowest': result.sort((a, b) => a.amount.compareTo(b.amount)); break;
    }

    setState(() => _filtered = result);
  }

  double get _totalDebit => _filtered.where((t) => t.isDebit).fold(0, (s, t) => s + t.amount);
  double get _totalCredit => _filtered.where((t) => !t.isDebit).fold(0, (s, t) => s + t.amount);

  Map<String, List<PlaidTransaction>> get _grouped {
    final Map<String, List<PlaidTransaction>> map = {};
    for (final tx in _filtered) {
      map.putIfAbsent(_groupLabel(tx.date), () => []).add(tx);
    }
    return map;
  }

  String _groupLabel(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today';
      final y = now.subtract(const Duration(days: 1));
      if (dt.year == y.year && dt.month == y.month && dt.day == y.day) return 'Yesterday';
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) { return raw; }
  }

  String _shortDate(String raw) {
    try { return DateFormat('MMM d').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }

  Future<void> _exportXlsx() async {
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Transactions'];
      final headers = ['Date', 'Name', 'Category', 'Account', 'Type', 'Amount'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      for (int i = 0; i < _filtered.length; i++) {
        final tx = _filtered[i];
        final r = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue(tx.date);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue(tx.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue(tx.category);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue(tx.accountName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = TextCellValue(tx.isDebit ? 'Debit' : 'Credit');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r)).value = DoubleCellValue(tx.amount);
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      final bytes = excel.encode();
      if (bytes != null) { await file.writeAsBytes(bytes); await OpenFile.open(file.path); }
    } catch (e) { _snack('Export failed: $e'); }
    finally { setState(() => _isExporting = false); }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Transaction History', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('${widget.userName}  ·  ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
        ]),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2), 1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.8), 3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: ['Date', 'Name', 'Category', 'Type', 'Amount'].map((h) =>
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)))).toList(),
              ),
              ..._filtered.asMap().entries.map((e) {
                final tx = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : PdfColors.grey50),
                  children: [tx.date, tx.name, tx.category, tx.isDebit ? 'Debit' : 'Credit', '\$${tx.amount.toStringAsFixed(2)}'].map((v) =>
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: pw.Text(v, style: const pw.TextStyle(fontSize: 8)))).toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Total: ${_filtered.length} transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text('Spent: \$${_totalDebit.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Received: \$${_totalCredit.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
        ],
      ));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) { _snack('Export failed: $e'); }
    finally { setState(() => _isExporting = false); }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Export Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 4),
          Text('${_filtered.length} transactions will be exported', style: const TextStyle(fontSize: 13, color: _textLight)),
          const SizedBox(height: 18),
          _exportOption(icon: Icons.table_chart_rounded, color: const Color(0xFF1D6F42),
            label: 'Export as Excel (.xlsx)', sub: 'Open in Excel, Google Sheets, Numbers',
            onTap: () { Navigator.pop(context); _exportXlsx(); }),
          const SizedBox(height: 10),
          _exportOption(icon: Icons.picture_as_pdf_rounded, color: const Color(0xFFE53935),
            label: 'Export as PDF', sub: 'Formatted table, ready to print or share',
            onTap: () { Navigator.pop(context); _exportPdf(); }),
        ]),
      ),
    );
  }

  Widget _exportOption({required IconData icon, required Color color, required String label, required String sub, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.06), 
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(color: color.withOpacity(0.2))),

        child: Row(children: [
          Container(width: 42, height: 42, 
          decoration: BoxDecoration(color: color, 
          borderRadius: BorderRadius.circular(12)), 
          child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            Text(sub, style: const TextStyle(fontSize: 12, color: _textLight)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
        ]),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sort by', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 14),
          ...['Newest', 'Oldest', 'Highest', 'Lowest'].map((opt) {
            final sel = _selectedSort == opt;
            return GestureDetector(
              onTap: () { setState(() => _selectedSort = opt); _applyFilters(); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: sel ? _blue.withOpacity(0.07) : _bgGrey, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _blue : Colors.transparent)),
                child: Row(children: [
                  Expanded(child: Text(opt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sel ? _blue : _textDark))),
                  if (sel) const Icon(Icons.check_rounded, color: _blue, size: 18),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38, height: 38,
            decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textDark),
          ),
        ),
        title: const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
        actions: [
          _isExporting
              ? const Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
              : GestureDetector(
                  onTap: _showExportSheet,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.download_rounded, size: 15, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  ),
                ),
        ],
      ),
      body: Column(children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _stat('Transactions', '${_filtered.length}', _textMid),
            Container(width: 1, height: 28, color: _border),
            _stat('Spent', '\$${_totalDebit.toStringAsFixed(0)}', Colors.red.shade600),
            Container(width: 1, height: 28, color: _border),
            _stat('Received', '\$${_totalCredit.toStringAsFixed(0)}', _blue),
          ]),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search transactions…',
              hintStyle: const TextStyle(color: _textLight, fontSize: 14),
              filled: true, fillColor: _bgGrey,
              prefixIcon: const Icon(Icons.search_rounded, color: _textLight, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(onTap: () { _searchCtrl.clear(); _applyFilters(); }, child: const Icon(Icons.close_rounded, color: _textLight, size: 18))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),

        // Filter + Sort chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            ...([('All', Icons.list_rounded), ('Debit', Icons.arrow_upward_rounded), ('Credit', Icons.arrow_downward_rounded)].map((f) {
              final active = _selectedFilter == f.$1;
              return GestureDetector(
                onTap: () { setState(() => _selectedFilter = f.$1); _applyFilters(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: active ? _blue : _bgGrey, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? _blue : _border)),
                  child: Row(children: [
                    Icon(f.$2, size: 13, color: active ? Colors.white : _textMid),
                    const SizedBox(width: 4),
                    Text(f.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _textMid)),
                  ]),
                ),
              );
            })),
            const Spacer(),
            GestureDetector(
              onTap: _showSortSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
                child: Row(children: [
                  const Icon(Icons.sort_rounded, size: 14, color: _textMid),
                  const SizedBox(width: 4),
                  Text(_selectedSort, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMid)),
                ]),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F2F5)),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 64, height: 64, decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.receipt_long_rounded, color: _textLight, size: 30)),
                  const SizedBox(height: 16),
                  const Text('No transactions found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 6),
                  const Text('Try adjusting your filters', style: TextStyle(fontSize: 13, color: _textLight)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final key = keys[i];
                    final txs = grouped[key]!;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textLight, letterSpacing: 0.5)),
                      ),
                      ...txs.map((tx) => _TxTile(tx: tx, shortDate: _shortDate(tx.date))),
                      const SizedBox(height: 8),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: _textLight)),
  ]));
}

class _TxTile extends StatelessWidget {
  final PlaidTransaction tx;
  final String shortDate;
  const _TxTile({required this.tx, required this.shortDate});

  Color get _accent => tx.isDebit ? const Color(0xFFE53935) : const Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tx.isDebit ? const Color(0xFFFFF5F5) : const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tx.isDebit ? const Color(0xFFFFD2D2) : const Color(0xFFD7E8FF), width: 1.2),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
          alignment: Alignment.center,
          child: Text(tx.name.length >= 2 ? tx.name.substring(0, 2).toUpperCase() : tx.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _accent)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _accent)),
          const SizedBox(height: 3),
          Text(tx.category, style: TextStyle(fontSize: 12, color: _accent.withOpacity(0.7), fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${tx.isDebit ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _accent)),
          const SizedBox(height: 4),
          tx.category == 'Uncategorized'
              ? const Text(
                  'Categorize +',
                  style: TextStyle(fontSize: 12, fontFamily: 'Manrope', fontWeight: FontWeight.w600, color: Color(0xFF667085)),
                )
              : Text(
                  'Categorized',
                  style: TextStyle(fontSize: 12, fontFamily: 'Manrope', fontWeight: FontWeight.w500, color: _accent),
                ),
          const SizedBox(height: 4),
          Text(shortDate, style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3))),
        ]),
      ]),
    );
  }
}