// File: lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/sl_financial_data.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _isLoading = false;
  String _status = '';

  // FD Rates controllers
  final Map<String, Map<String, TextEditingController>> _fdControllers = {};

  // Tax controllers
  final _taxFreeAllowanceController = TextEditingController();
  final List<Map<String, dynamic>> _taxBrackets = [];

  @override
  void initState() {
    super.initState();
    _initFDControllers();
    _initTaxBrackets();
    _loadCurrentRates();
  }

  void _initFDControllers() {
    for (var bank in SLFinancialData.fdRates.keys) {
      _fdControllers[bank] = {};
      for (var period in ['3 Months', '6 Months', '1 Year', '2 Years', '3 Years', '5 Years']) {
        double rate = SLFinancialData.fdRates[bank]?[period] ?? 0.10;
        _fdControllers[bank]![period] = TextEditingController(text: '${(rate * 100).toStringAsFixed(2)}');
      }
    }
  }

  void _initTaxBrackets() {
    _taxFreeAllowanceController.text = '1800000';
    _taxBrackets.addAll([
      {'min': '0', 'max': '1000000', 'rate': '6', 'label': 'First Rs. 1,000,000'},
      {'min': '1000000', 'max': '1500000', 'rate': '18', 'label': 'Next Rs. 500,000'},
      {'min': '1500000', 'max': '2000000', 'rate': '24', 'label': 'Next Rs. 500,000'},
      {'min': '2000000', 'max': '2500000', 'rate': '30', 'label': 'Next Rs. 500,000'},
      {'min': '2500000', 'max': '', 'rate': '36', 'label': 'Balance above Rs. 2,500,000'},
    ]);
  }

  Future<void> _loadCurrentRates() async {
    setState(() { _isLoading = true; _status = 'Loading current rates...'; });
    try {
      final rates = await _firestore.getRates();
      if (rates != null) {
        // Update FD controllers
        if (rates['fd_rates'] != null) {
          final fdRates = rates['fd_rates'] as Map<String, dynamic>;
          for (var bank in fdRates.keys) {
            if (_fdControllers.containsKey(bank)) {
              final periods = fdRates[bank] as Map<String, dynamic>;
              for (var period in periods.keys) {
                if (_fdControllers[bank]!.containsKey(period)) {
                  _fdControllers[bank]![period]!.text = '${(double.parse(periods[period].toString()) * 100).toStringAsFixed(2)}';
                }
              }
            }
          }
        }
        _status = 'Current rates loaded';
      } else {
        _status = 'No saved rates found. Using defaults.';
      }
    } catch (e) {
      _status = 'Error loading rates: $e';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAndPublish() async {
    setState(() { _isLoading = true; _status = 'Saving...'; });

    try {
      // Save FD rates
      Map<String, Map<String, double>> fdRates = {};
      for (var bank in _fdControllers.keys) {
        fdRates[bank] = {};
        for (var period in _fdControllers[bank]!.keys) {
          double rate = (double.tryParse(_fdControllers[bank]![period]!.text) ?? 10) / 100;
          fdRates[bank]![period] = rate;
        }
      }
      await _firestore.saveFDRates(fdRates);

      // Save tax brackets
      List<Map<String, dynamic>> brackets = _taxBrackets.map((b) => {
        'min': double.tryParse(b['min']) ?? 0,
        'max': b['max'].toString().isEmpty ? 999999999 : (double.tryParse(b['max']) ?? 0),
        'rate': (double.tryParse(b['rate']) ?? 0) / 100,
        'label': b['label'],
      }).toList();
      await _firestore.saveTaxBrackets(brackets, double.tryParse(_taxFreeAllowanceController.text) ?? 1800000);

      // Publish
      await _firestore.publishRates();
      setState(() => _status = '✅ Rates published successfully!');
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    for (var bank in _fdControllers.keys) {
      for (var period in _fdControllers[bank]!.keys) {
        _fdControllers[bank]![period]!.dispose();
      }
    }
    _taxFreeAllowanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (_status.isNotEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(_status, style: const TextStyle(color: Color(0xFF66FCF1), fontSize: 12)),
            )),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('FD Rates (%)'),
                  _buildFDTable(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Tax Brackets'),
                  _buildTaxTable(),
                  const SizedBox(height: 32),
                  _buildPublishButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFDTable() {
    final periods = ['3 Months', '6 Months', '1 Year', '2 Years', '3 Years', '5 Years'];
    final banks = _fdControllers.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A2E)),
        dataRowColor: WidgetStateProperty.all(const Color(0xFF0B0C10)),
        border: TableBorder.all(color: Colors.white.withOpacity(0.1), width: 1),
        columns: [
          const DataColumn(label: Text('Bank', style: TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold))),
          ...periods.map((p) => DataColumn(label: Text(p, style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold)))),
        ],
        rows: banks.map((bank) => DataRow(cells: [
          DataCell(Text(bank, style: const TextStyle(color: Colors.white, fontSize: 12))),
          ...periods.map((period) => DataCell(
            SizedBox(
              width: 80,
              child: TextField(
                controller: _fdControllers[bank]![period],
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                  border: OutlineInputBorder(),
                  suffixText: '%',
                  suffixStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          )),
        ])).toList(),
      ),
    );
  }

  Widget _buildTaxTable() {
    return Column(children: [
      Row(children: [
        const Text('Tax-Free Allowance (LKR): ', style: TextStyle(color: Colors.white70)),
        SizedBox(
          width: 150,
          child: TextField(
            controller: _taxFreeAllowanceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A2E)),
          dataRowColor: WidgetStateProperty.all(const Color(0xFF0B0C10)),
          border: TableBorder.all(color: Colors.white.withOpacity(0.1), width: 1),
          columns: const [
            DataColumn(label: Text('Label', style: TextStyle(color: Color(0xFF66FCF1)))),
            DataColumn(label: Text('Min', style: TextStyle(color: Color(0xFF66FCF1)))),
            DataColumn(label: Text('Max', style: TextStyle(color: Color(0xFF66FCF1)))),
            DataColumn(label: Text('Rate %', style: TextStyle(color: Color(0xFF66FCF1)))),
          ],
          rows: _taxBrackets.map((b) => DataRow(cells: [
            DataCell(SizedBox(width: 200, child: TextField(controller: TextEditingController(text: b['label']), onChanged: (v) => b['label'] = v, style: const TextStyle(color: Colors.white, fontSize: 11), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
            DataCell(SizedBox(width: 100, child: TextField(controller: TextEditingController(text: b['min']), onChanged: (v) => b['min'] = v, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 11), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
            DataCell(SizedBox(width: 100, child: TextField(controller: TextEditingController(text: b['max']), onChanged: (v) => b['max'] = v, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 11), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
            DataCell(SizedBox(width: 80, child: TextField(controller: TextEditingController(text: b['rate']), onChanged: (v) => b['rate'] = v, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 11), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), suffixText: '%')))),])).toList(),
        ),
      ),
    ]);
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveAndPublish,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Publish to Firebase'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}