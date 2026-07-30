// File: lib/screens/financial_tools_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sl_financial_data.dart';
import 'dart:math' as math;
import 'tax_calculator_screen.dart' as tax_screens;
import 'exchange_rate_screen.dart';
import 'admin_panel_screen.dart';
import '../services/financial_config_service.dart';

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('Financial Tools', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Sri Lanka-specific calculators & market data', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              // Admin quick link (small, low-visibility)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                  child: Text('Admin', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text('CALCULATORS', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ),
              Row(children: [
                Expanded(child: _ToolCard(icon: Icons.account_balance_rounded, title: 'Income Tax', subtitle: 'APIT, EPF & ETF', color: const Color(0xFFEF5350), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const tax_screens.TaxCalculatorScreen())))),
                const SizedBox(width: 12),
                Expanded(child: _ToolCard(icon: Icons.directions_car_rounded, title: 'Vehicle Leasing', subtitle: 'CBSL LTV rates', color: const Color(0xFFFFA726), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeasingCalculatorScreen())))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _ToolCard(icon: Icons.savings_rounded, title: 'Fixed Deposit', subtitle: 'Compare bank rates', color: const Color(0xFF42A5F5), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FDCalculatorScreen())))),
                const SizedBox(width: 12),
                Expanded(child: _ToolCard(icon: Icons.credit_card_rounded, title: 'Loan Calculator', subtitle: '6 loan types', color: const Color(0xFFAB47BC), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanCalculatorScreen())))),
              ]),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('MARKET DATA', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ),
              _ToolCard(icon: Icons.currency_exchange_rounded, title: 'Exchange Rate Tracker', subtitle: 'Daily rates across all major banks', color: const Color(0xFF26C6DA), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExchangeRateScreen())), isFullWidth: true),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: isFullWidth
            ? Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 3), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12))])),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.25), size: 16),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
      ),
    );
  }
}

// ==================== FD CALCULATOR ====================

class FDCalculatorScreen extends StatefulWidget {
  const FDCalculatorScreen({super.key});
  @override
  State<FDCalculatorScreen> createState() => _FDCalculatorScreenState();
}

class _FDCalculatorScreenState extends State<FDCalculatorScreen> {
  final _amountController = TextEditingController();
  String _selectedPeriod = '1 Year';
  double _amount = 0;
  bool _isCalculated = false;
  Map<String, BankFDResult> _bankResults = {};
  String? _bestBank;
  double _bestReturn = 0;
  String? _selectedDetailBank;
  final List<String> _periods = ['3 Months', '6 Months', '1 Year', '2 Years', '3 Years', '5 Years'];

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  void _calculate() async {
  _amount = double.tryParse(_amountController.text) ?? 0;
  if (_amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid deposit amount'), backgroundColor: Colors.redAccent));
    return;
  }

  Map<String, Map<String, double>> fdRates;
  try {
    // Force refresh from Firebase before calculating
    final configService = FinancialConfigService();
    await configService.forceRefresh();
    final config = await configService.getActiveConfig();
    fdRates = config.fdRates;
  } catch (e) {
    fdRates = SLFinancialData.fdRates;
  }


    _bankResults = {};
    _bestReturn = 0;
    _bestBank = null;

    for (var bank in fdRates.keys) {
      double rate = fdRates[bank]?[_selectedPeriod] ?? 0.10;
      int months = _getMonths(_selectedPeriod);
      double interest = _amount * rate * (months / 12);
      double maturity = _amount + interest;
      double effectiveAnnualRate = rate;
      if (months < 12) effectiveAnnualRate = rate * (12 / months);
      _bankResults[bank] = BankFDResult(bankName: bank, rate: rate, interest: interest, maturity: maturity, months: months, effectiveAnnualRate: effectiveAnnualRate);
      if (maturity > _bestReturn) { _bestReturn = maturity; _bestBank = bank; }
    }
    setState(() => _isCalculated = true);
  }

  int _getMonths(String p) {
    switch (p) { case '3 Months': return 3; case '6 Months': return 6; case '1 Year': return 12; case '2 Years': return 24; case '3 Years': return 36; case '5 Years': return 60; default: return 12; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF0B0C10), appBar: AppBar(title: const Text('Fixed Deposit Calculator'), backgroundColor: const Color(0xFF1A1A2E), elevation: 0), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildInputSection(), const SizedBox(height: 24), _buildCalculateButton(),
      if (_isCalculated) ...[const SizedBox(height: 28), _buildBestBankCard(), const SizedBox(height: 24), _buildComparisonChart(), const SizedBox(height: 24), _buildAllBanksList(), const SizedBox(height: 24), if (_selectedDetailBank != null) _buildBankDetailCard(), const SizedBox(height: 24), _buildHowItWorks(), const SizedBox(height: 24), _buildCalculationFormula(), const SizedBox(height: 24), _buildDisclaimer()],
      const SizedBox(height: 120),
    ])));
  }

  Widget _buildInputSection() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.savings_rounded, color: Color(0xFF42A5F5), size: 22)), const SizedBox(width: 12), const Text('FD Investment Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 20),
      TextField(controller: _amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Deposit Amount (LKR)', hintText: 'e.g., 500,000', hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)), labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1)), prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFF42A5F5)))),
      const SizedBox(height: 16), const Text('Select Deposit Period:', style: TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _periods.map((period) { bool isSelected = _selectedPeriod == period; return ChoiceChip(label: Text(period, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF0B0C10) : Colors.white70)), selected: isSelected, onSelected: (_) => setState(() => _selectedPeriod = period), selectedColor: const Color(0xFF42A5F5), backgroundColor: const Color(0xFF0B0C10), side: BorderSide(color: isSelected ? const Color(0xFF42A5F5) : Colors.white.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))); }).toList()),
    ]));
  }

  Widget _buildCalculateButton() => ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF42A5F5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text('Compare FD Rates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildBestBankCard() {
    if (_bestBank == null) return const SizedBox();
    final best = _bankResults[_bestBank]!;
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF4CAF50).withOpacity(0.2), const Color(0xFF4CAF50).withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3))), child: Column(children: [
      Row(children: [const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28), const SizedBox(width: 10), const Text('Best Return', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 20, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 16), Text(best.bankName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text('${(best.rate * 100).toStringAsFixed(2)}% p.a.', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildBestStat('Investment', 'LKR ${NumberFormat('#,##0').format(_amount)}'), Container(width: 1, height: 40, color: Colors.white10),
        _buildBestStat('Interest', 'LKR ${NumberFormat('#,##0').format(best.interest)}'), Container(width: 1, height: 40, color: Colors.white10),
        _buildBestStat('Maturity', 'LKR ${NumberFormat('#,##0').format(best.maturity)}'),
      ]),
    ]));
  }
  Widget _buildBestStat(String l, String v) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 2), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))]);

  Widget _buildComparisonChart() {
    if (_bankResults.isEmpty) return const SizedBox();
    var sorted = _bankResults.entries.toList()..sort((a, b) => b.value.maturity.compareTo(a.value.maturity));
    double maxMaturity = sorted.first.value.maturity;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bank Comparison', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text('$_selectedPeriod deposit of LKR ${NumberFormat('#,##0').format(_amount)}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)), const SizedBox(height: 20),
      ...sorted.map((entry) { double pct = (entry.value.maturity / maxMaturity * 100); bool isBest = entry.key == _bestBank; return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [if (isBest) const Icon(Icons.star, color: Color(0xFFFFD700), size: 16), if (isBest) const SizedBox(width: 4), Text(entry.key, style: TextStyle(color: isBest ? const Color(0xFFFFD700) : Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]), Text('LKR ${NumberFormat('#,##0').format(entry.value.maturity)}', style: TextStyle(color: isBest ? const Color(0xFFFFD700) : const Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 13))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(isBest ? const Color(0xFFFFD700) : const Color(0xFF42A5F5)), minHeight: 6))])); }),
    ]));
  }

  Widget _buildAllBanksList() {
    var sorted = _bankResults.entries.toList()..sort((a, b) => b.value.maturity.compareTo(a.value.maturity));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('All Bank Rates', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('Tap a bank for full details', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)), const SizedBox(height: 12), ...sorted.map((entry) { bool isSel = _selectedDetailBank == entry.key; bool isBest = entry.key == _bestBank; return GestureDetector(onTap: () => setState(() => _selectedDetailBank = isSel ? null : entry.key), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSel ? const Color(0xFF42A5F5) : Colors.white.withOpacity(0.05), width: isSel ? 1.5 : 1)), child: Row(children: [if (isBest) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Text('Best', style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold))), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 2), Text('${(entry.value.rate * 100).toStringAsFixed(2)}% p.a. • $_selectedPeriod', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('LKR ${NumberFormat('#,##0').format(entry.value.maturity)}', style: const TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 2), Text('+LKR ${NumberFormat('#,##0').format(entry.value.interest)}', style: TextStyle(color: const Color(0xFF4CAF50).withOpacity(0.7), fontSize: 11))])]))); })]);
  }

  Widget _buildBankDetailCard() {
    final d = _bankResults[_selectedDetailBank]; if (d == null) return const SizedBox();
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.account_balance, color: Color(0xFF42A5F5), size: 20), const SizedBox(width: 8), Text(d.bankName, style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), _buildDRow('Investment Amount', 'LKR ${NumberFormat('#,##0.00').format(_amount)}'), _buildDRow('Interest Rate', '${(d.rate * 100).toStringAsFixed(2)}% p.a.'), _buildDRow('Deposit Period', _selectedPeriod), _buildDRow('Effective Annual Rate', '${(d.effectiveAnnualRate * 100).toStringAsFixed(2)}%'), const Divider(color: Colors.white10, height: 20), _buildDRow('Interest Earned', 'LKR ${NumberFormat('#,##0.00').format(d.interest)}', hl: true, c: const Color(0xFF4CAF50)), _buildDRow('Maturity Amount', 'LKR ${NumberFormat('#,##0.00').format(d.maturity)}', hl: true, c: const Color(0xFF42A5F5))]));
  }
  Widget _buildDRow(String l, String v, {bool hl = false, Color? c}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)), Text(v, style: TextStyle(color: c ?? Colors.white, fontWeight: hl ? FontWeight.bold : FontWeight.normal, fontSize: 13))]));

  Widget _buildHowItWorks() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lightbulb_outline, color: Color(0xFF42A5F5), size: 18)), const SizedBox(width: 10), const Text('How Fixed Deposits Work', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Text('A Fixed Deposit (FD) is a savings instrument where you deposit a lump sum for a fixed period at a guaranteed interest rate.', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.6)), const SizedBox(height: 16), _buildStep('1', 'Choose Your Deposit', 'Decide how much to invest and for how long.'), _buildStep('2', 'Select a Bank', 'Compare rates across banks.'), _buildStep('3', 'Earn Guaranteed Returns', 'Your interest rate is locked.'), _buildStep('4', 'Receive Maturity Amount', 'Get principal plus interest at end of term.')]));
  }
  Widget _buildStep(String n, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(n, style: const TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 13)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 2), Text(d, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4))]))]));

  Widget _buildCalculationFormula() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF42A5F5).withOpacity(0.1), const Color(0xFF42A5F5).withOpacity(0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.calculate, color: Color(0xFF42A5F5), size: 20), const SizedBox(width: 8), const Text('How We Calculate Returns', style: TextStyle(color: Color(0xFF42A5F5), fontSize: 17, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0B0C10), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Text('Simple Interest Formula', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text('Interest = Principal x Rate x (Months/12)', style: TextStyle(color: const Color(0xFF42A5F5).withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')), const SizedBox(height: 8), Text('Maturity = Principal + Interest', style: TextStyle(color: const Color(0xFF42A5F5).withOpacity(0.7), fontSize: 13, fontFamily: 'monospace'))])), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0B0C10), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Example: LKR 100,000 at 10% for 1 Year', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(height: 6), Text('Interest = 100,000 x 0.10 x 1 = LKR 10,000', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)), Text('Maturity = LKR 110,000', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w600))]))]));
  }

  Widget _buildDisclaimer() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Important Notice', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text('Rates are indicative. Please contact your bank for exact rates. FDs insured up to Rs. 1,100,000 under Sri Lanka Deposit Insurance Scheme.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.5))]))]));
  }
}

// ==================== LEASING CALCULATOR ====================

class LeasingCalculatorScreen extends StatefulWidget {
  const LeasingCalculatorScreen({super.key});
  @override
  State<LeasingCalculatorScreen> createState() => _LeasingCalculatorScreenState();
}

class _LeasingCalculatorScreenState extends State<LeasingCalculatorScreen> {
  final _vehicleValueController = TextEditingController();
  final _lumpSumController = TextEditingController(text: '0');
  String _selectedVehicle = 'Car (Unregistered)';
  String _selectedBank = 'Commercial Bank';
  int _selectedTenure = 60;
  double _downPayment = 0, _monthlyRental = 0, _totalPayment = 0, _totalInterest = 0, _loanAmount = 0, _interestRate = 0, _ltvRatio = 0;
  bool _isCalculated = false;

  @override
  void dispose() { _vehicleValueController.dispose(); _lumpSumController.dispose(); super.dispose(); }

  void _updateCalculations() async {
  double vehicleValue = double.tryParse(_vehicleValueController.text) ?? 0;
  double lumpSum = double.tryParse(_lumpSumController.text) ?? 0;
  if (vehicleValue <= 0) return;

  // Try Firebase config first
  Map<String, VehicleLTV> ltvData;
  Map<String, Map<int, double>> leasingRates;
  try {
    final configService = FinancialConfigService();
    await configService.forceRefresh();
    final config = await configService.getActiveConfig();
    ltvData = config.ltvRatios.map((k, v) => MapEntry(k, VehicleLTV(category: v.category, ltv: v.ltv, description: v.description)));
    leasingRates = config.bankLeasingRates;
  } catch (e) {
    ltvData = SLFinancialData.ltvRatios;
    leasingRates = SLFinancialData.bankLeasingRates;
  }

  final ltvInfo = ltvData[_selectedVehicle];
  _ltvRatio = ltvInfo?.ltv ?? 0.40;
  // ... rest of calculation using leasingRates
    double maxLoan = vehicleValue * _ltvRatio;
    _downPayment = vehicleValue - maxLoan;
    _interestRate = SLFinancialData.bankLeasingRates[_selectedBank]?[_selectedTenure] ?? 0.14;
    _loanAmount = (maxLoan - lumpSum).clamp(0, double.infinity);
    double monthlyRate = _interestRate / 12;
    if (_loanAmount > 0 && monthlyRate > 0 && _selectedTenure > 0) {
      double factor = math.pow(1 + monthlyRate, _selectedTenure).toDouble();
      _monthlyRental = _loanAmount * monthlyRate * factor / (factor - 1);
    } else { _monthlyRental = 0; }
    _totalPayment = _monthlyRental * _selectedTenure + lumpSum;
    _totalInterest = _totalPayment - _loanAmount;
    setState(() => _isCalculated = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF0B0C10), appBar: AppBar(title: const Text('Vehicle Leasing Calculator'), backgroundColor: const Color(0xFF1A1A2E), elevation: 0), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildCBSLNotice(), const SizedBox(height: 20), _buildInputSection(), const SizedBox(height: 24), _buildCalculateButton(),
      if (_isCalculated) ...[const SizedBox(height: 24), _buildPaymentChart(), const SizedBox(height: 24), _buildResultsCards(), const SizedBox(height: 24), _buildSummary(), const SizedBox(height: 24), _buildLTVInfo()],
      const SizedBox(height: 120),
    ])));
  }

  Widget _buildCBSLNotice() {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.2))), child: Row(children: [const Icon(Icons.gavel, color: Color(0xFFFFA726), size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CBSL Regulation Update', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 2), Text('New LTV ratios effective May 25, 2026. Unregistered vehicles: 40% LTV. Registered vehicles: 70% LTV.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4))]))]));
  }

  Widget _buildInputSection() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Vehicle & Loan Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      _buildDropdown(label: 'Vehicle Type', value: _selectedVehicle, items: SLFinancialData.vehicleCategories, onChanged: (val) { setState(() => _selectedVehicle = val!); _updateCalculations(); }), const SizedBox(height: 14),
      _buildInputField('Vehicle Value (LKR)', _vehicleValueController, onChanged: (_) => _updateCalculations()), const SizedBox(height: 14),
      if (double.tryParse(_vehicleValueController.text) != null && double.tryParse(_vehicleValueController.text)! > 0) _buildLTVDisplay(), const SizedBox(height: 14),
      _buildDropdown(label: 'Bank / Financial Institution', value: _selectedBank, items: SLFinancialData.leasingBanks, onChanged: (val) { setState(() => _selectedBank = val!); _updateCalculations(); }), const SizedBox(height: 14),
      _buildTenureSelector(), const SizedBox(height: 14), _buildInterestRateDisplay(), const SizedBox(height: 14),
      _buildInputField('Additional Lump Sum Payment (LKR)', _lumpSumController, hint: 'Optional - reduces monthly rental', onChanged: (_) => _updateCalculations()),
    ]));
  }

  Widget _buildLTVDisplay() {
    double value = double.tryParse(_vehicleValueController.text) ?? 0;
    if (value <= 0) return const SizedBox();
    final ltvData = SLFinancialData.ltvRatios[_selectedVehicle];
    double ltv = ltvData?.ltv ?? 0.40;
    double maxLoan = value * ltv;
    double minDownPayment = value - maxLoan;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF66FCF1).withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF66FCF1).withOpacity(0.1))), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LTV Ratio (${ltvData?.category ?? 'Standard'})', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), Text('${(ltv * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold, fontSize: 14))]),
      const SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min. Down Payment Required', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), Text('LKR ${NumberFormat('#,##0').format(minDownPayment)}', style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14))]),
      const SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max Loan Amount', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), Text('LKR ${NumberFormat('#,##0').format(maxLoan)}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 14))]),
    ]));
  }

  Widget _buildInterestRateDisplay() {
    double rate = SLFinancialData.bankLeasingRates[_selectedBank]?[_selectedTenure] ?? 0.14;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF66FCF1).withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Interest Rate ($_selectedBank)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), Text('${(rate * 100).toStringAsFixed(1)}% p.a.', style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold, fontSize: 14))]));
  }

  Widget _buildTenureSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tenure: $_selectedTenure months', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), const SizedBox(height: 8), Wrap(spacing: 8, children: SLFinancialData.tenureOptions.map((t) { bool isSelected = _selectedTenure == t; return ChoiceChip(label: Text('${t}mo', style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF0B0C10) : Colors.white70)), selected: isSelected, onSelected: (_) { setState(() => _selectedTenure = t); _updateCalculations(); }, selectedColor: const Color(0xFF66FCF1), backgroundColor: const Color(0xFF0B0C10), side: BorderSide(color: isSelected ? const Color(0xFF66FCF1) : Colors.white.withOpacity(0.1))); }).toList())]);
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(initialValue: value, dropdownColor: const Color(0xFF1A1A2E), style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(), onChanged: onChanged);
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, Function(String)? onChanged}) {
    return TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 16), onChanged: onChanged, decoration: InputDecoration(labelText: label, hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)), labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF66FCF1), width: 1)), prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFF66FCF1), size: 20)));
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(onPressed: () { if (double.tryParse(_vehicleValueController.text) == null || (double.tryParse(_vehicleValueController.text) ?? 0) <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid vehicle value'), backgroundColor: Colors.redAccent)); return; } _updateCalculations(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF66FCF1), foregroundColor: const Color(0xFF0B0C10), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text('Calculate Leasing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
  }

  Widget _buildPaymentChart() {
    double totalWithDown = _downPayment + _totalPayment;
    double downPct = totalWithDown > 0 ? (_downPayment / totalWithDown) * 100 : 0;
    double loanPct = totalWithDown > 0 ? ((_totalPayment - _totalInterest) / totalWithDown) * 100 : 0;
    double interestPct = totalWithDown > 0 ? (_totalInterest / totalWithDown) * 100 : 0;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Total Cost: LKR ${NumberFormat('#,##0.00').format(totalWithDown)}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)), const SizedBox(height: 20), ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 32, child: Row(children: [if (downPct > 0) Expanded(flex: downPct.round().clamp(1, 100), child: Container(color: const Color(0xFF42A5F5))), if (loanPct > 0) Expanded(flex: loanPct.round().clamp(1, 100), child: Container(color: const Color(0xFF4CAF50))), if (interestPct > 0) Expanded(flex: interestPct.round().clamp(1, 100), child: Container(color: const Color(0xFFEF5350)))]))), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildLegend('Down Payment', const Color(0xFF42A5F5), _downPayment, '${downPct.toStringAsFixed(1)}%'), _buildLegend('Principal', const Color(0xFF4CAF50), _totalPayment - _totalInterest, '${loanPct.toStringAsFixed(1)}%'), _buildLegend('Interest', const Color(0xFFEF5350), _totalInterest, '${interestPct.toStringAsFixed(1)}%')])]));
  }

  Widget _buildLegend(String label, Color color, double amount, String pct) => Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))]), const SizedBox(height: 2), Text('LKR ${NumberFormat.compact().format(amount)} ($pct)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10))]);

  Widget _buildResultsCards() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Leasing Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Row(children: [_buildResultCard('Monthly Rental', 'LKR ${NumberFormat('#,##0').format(_monthlyRental)}', const Color(0xFF66FCF1), Icons.payments), const SizedBox(width: 12), _buildResultCard('Down Payment', 'LKR ${NumberFormat('#,##0').format(_downPayment)}', const Color(0xFF42A5F5), Icons.download)]), const SizedBox(height: 12), Row(children: [_buildResultCard('Total Interest', 'LKR ${NumberFormat('#,##0').format(_totalInterest)}', const Color(0xFFEF5350), Icons.trending_up), const SizedBox(width: 12), _buildResultCard('Loan Amount', 'LKR ${NumberFormat('#,##0').format(_loanAmount)}', const Color(0xFF4CAF50), Icons.account_balance)])]);

  Widget _buildResultCard(String label, String value, Color color, IconData icon) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)), const SizedBox(height: 12), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 2), Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))])));

  Widget _buildSummary() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF66FCF1).withOpacity(0.1), const Color(0xFF45A29E).withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF66FCF1).withOpacity(0.15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.description, color: Color(0xFF66FCF1), size: 20), SizedBox(width: 8), Text('Loan Details', style: TextStyle(color: Color(0xFF66FCF1), fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), _buildSummaryRow('Vehicle', _selectedVehicle), _buildSummaryRow('Bank', _selectedBank), _buildSummaryRow('Tenure', '$_selectedTenure months'), _buildSummaryRow('Interest Rate', '${(_interestRate * 100).toStringAsFixed(1)}% p.a.'), _buildSummaryRow('LTV Ratio', '${(_ltvRatio * 100).toStringAsFixed(0)}%'), _buildSummaryRow('Monthly Rental', 'LKR ${NumberFormat('#,##0.00').format(_monthlyRental)}', hl: true)]));

  Widget _buildSummaryRow(String l, String v, {bool hl = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)), Text(v, style: TextStyle(color: hl ? const Color(0xFF66FCF1) : Colors.white, fontWeight: hl ? FontWeight.bold : FontWeight.normal, fontSize: 13))]));

  Widget _buildLTVInfo() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.info_outline, color: Color(0xFFFFA726), size: 18), SizedBox(width: 8), Text('CBSL LTV Regulations', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 14))]), const SizedBox(height: 8), _buildLTVRow('Unregistered Vehicles', '40% LTV'), _buildLTVRow('Registered Vehicles (>1 year)', '70% LTV'), _buildLTVRow('Electric Vehicles', '60% LTV'), _buildLTVRow('Commercial Vehicles', '60% LTV'), const SizedBox(height: 8), Text('Effective from May 25, 2026 per CBSL directive.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))]));
  Widget _buildLTVRow(String t, String l) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)), Text(l, style: const TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 12))]));
}

// ==================== LOAN CALCULATOR ====================

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});
  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _amountController = TextEditingController();
  final _lumpSumController = TextEditingController(text: '0');
  final _recurringLumpSumController = TextEditingController(text: '0');
  String _selectedLoanType = 'Personal Loan';
  String _selectedBank = 'Commercial Bank';
  int _selectedTenure = 36;
  double _interestRate = 0.12;
  double _monthlyEMI = 0, _totalPayment = 0, _totalInterest = 0;
  List<AmortizationEntry> _schedule = [];
  Map<String, BankLoanResult> _bankResults = {};
  String? _bestBank;
  bool _isCalculated = false, _showSchedule = false;

  @override
  void dispose() { _amountController.dispose(); _lumpSumController.dispose(); _recurringLumpSumController.dispose(); super.dispose(); }

  void _onLoanTypeChanged(String? type) {
    if (type != null) { setState(() { _selectedLoanType = type; final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == type); _interestRate = loanType.typicalRates[_selectedBank] ?? loanType.minRate; if (_selectedTenure > loanType.maxTenure) _selectedTenure = loanType.maxTenure; }); }
  }

  void _onBankChanged(String? bank) {
    if (bank != null) { setState(() { _selectedBank = bank; final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType); _interestRate = loanType.typicalRates[bank] ?? loanType.minRate; }); }
  }

  void _calculate() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid loan amount'), backgroundColor: Colors.redAccent)); return; }
    double lumpSum = double.tryParse(_lumpSumController.text) ?? 0;
    double recurringLumpSum = double.tryParse(_recurringLumpSumController.text) ?? 0;
    double monthlyRate = _interestRate / 12;
    double effectiveLoan = amount - lumpSum;
    double monthlyFactor = math.pow(1 + monthlyRate, _selectedTenure).toDouble();
    _monthlyEMI = effectiveLoan > 0 ? effectiveLoan * monthlyRate * monthlyFactor / (monthlyFactor - 1) : 0;
    double totalMonthly = _monthlyEMI + recurringLumpSum;
    _schedule = []; double balance = effectiveLoan;
    for (int i = 1; i <= _selectedTenure && balance > 0; i++) { double interestPayment = balance * monthlyRate; double principalPayment = totalMonthly - interestPayment; if (principalPayment > balance) { principalPayment = balance; totalMonthly = principalPayment + interestPayment; } balance -= principalPayment; _schedule.add(AmortizationEntry(month: i, emi: totalMonthly, principal: principalPayment, interest: interestPayment, balance: balance.clamp(0, double.infinity))); }
    _totalPayment = _schedule.fold(0.0, (sum, e) => sum + e.emi) + lumpSum;
    _totalInterest = _schedule.fold(0.0, (sum, e) => sum + e.interest);
    _bankResults = {}; double bestEMI = double.infinity; _bestBank = null;
    final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType);
    for (var bank in loanType.typicalRates.keys) { double rate = loanType.typicalRates[bank] ?? 0.12; double bMonthlyRate = rate / 12; double bFactor = math.pow(1 + bMonthlyRate, _selectedTenure).toDouble(); double bEMI = effectiveLoan > 0 ? effectiveLoan * bMonthlyRate * bFactor / (bFactor - 1) : 0; double bTotal = bEMI * _selectedTenure + lumpSum; double bInterest = bTotal - effectiveLoan; _bankResults[bank] = BankLoanResult(bankName: bank, rate: rate, emi: bEMI + recurringLumpSum, totalPayment: bTotal + (recurringLumpSum * _selectedTenure), totalInterest: bInterest); if (bEMI < bestEMI) { bestEMI = bEMI; _bestBank = bank; } }
    setState(() { _isCalculated = true; _showSchedule = false; });
  }

  IconData _getLoanIcon(String type) { switch (type) { case 'Housing Loan': return Icons.home_rounded; case 'Vehicle Loan': return Icons.directions_car_rounded; case 'Education Loan': return Icons.school_rounded; case 'Solar Loan': return Icons.solar_power_rounded; case 'Business Loan': return Icons.business_rounded; default: return Icons.person_rounded; } }

  @override
  Widget build(BuildContext context) {
    final currentLoanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType);
    final filteredTenures = SLFinancialData.loanTenureOptions.where((t) => t <= currentLoanType.maxTenure).toList();
    return Scaffold(backgroundColor: const Color(0xFF0B0C10), appBar: AppBar(title: const Text('Loan Calculator'), backgroundColor: const Color(0xFF1A1A2E), elevation: 0), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildInputSection(currentLoanType, filteredTenures), const SizedBox(height: 24), _buildCalculateButton(),
      if (_isCalculated) ...[const SizedBox(height: 28), _buildResultsCards(), const SizedBox(height: 24), _buildPaymentChart(), const SizedBox(height: 24), _buildBankComparison(), const SizedBox(height: 24), _buildAmortizationSection(), const SizedBox(height: 24), _buildHowItWorks(), const SizedBox(height: 24), _buildDisclaimer()],
      const SizedBox(height: 120),
    ])));
  }

  Widget _buildInputSection(LoanType loanType, List<int> tenures) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFAB47BC), size: 22)), const SizedBox(width: 12), const Text('Loan Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 20), const Text('Loan Type:', style: TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: SLFinancialData.loanTypes.map((type) { bool isSelected = _selectedLoanType == type.name; return ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_getLoanIcon(type.name), size: 16, color: isSelected ? Colors.white : Colors.white60), const SizedBox(width: 6), Text(type.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70))]), selected: isSelected, onSelected: (_) => _onLoanTypeChanged(type.name), selectedColor: const Color(0xFFAB47BC), backgroundColor: const Color(0xFF0B0C10), side: BorderSide(color: isSelected ? const Color(0xFFAB47BC) : Colors.white.withOpacity(0.1))); }).toList()), const SizedBox(height: 8), Text(loanType.description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)), const SizedBox(height: 16), _buildDropdown('Bank', _selectedBank, SLFinancialData.loanBanks, _onBankChanged), const SizedBox(height: 14), _buildTextField('Loan Amount (LKR)', _amountController, hint: 'e.g., 1,000,000'), const SizedBox(height: 14), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Interest Rate ($_selectedBank)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)), Text('${(_interestRate * 100).toStringAsFixed(1)}% p.a.', style: const TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.bold, fontSize: 14))])), const SizedBox(height: 14), const Text('Tenure:', style: TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 8), Wrap(spacing: 8, children: tenures.map((t) { bool isSelected = _selectedTenure == t; String label = t >= 12 ? '${t ~/ 12}Y' : '${t}M'; return ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)), selected: isSelected, onSelected: (_) => setState(() => _selectedTenure = t), selectedColor: const Color(0xFFAB47BC), backgroundColor: const Color(0xFF0B0C10), side: BorderSide(color: isSelected ? const Color(0xFFAB47BC) : Colors.white.withOpacity(0.1))); }).toList()), const SizedBox(height: 14), _buildTextField('Initial Lump Sum Payment (LKR)', _lumpSumController, hint: 'Optional'), const SizedBox(height: 14), _buildTextField('Additional Monthly Payment (LKR)', _recurringLumpSumController, hint: 'Optional - reduces tenure')]));

  Widget _buildDropdown(String l, String v, List<String> items, Function(String?) oc) => DropdownButtonFormField<String>(initialValue: v, dropdownColor: const Color(0xFF1A1A2E), style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: oc);
  Widget _buildTextField(String l, TextEditingController c, {String? hint}) => TextField(controller: c, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: InputDecoration(labelText: l, hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)), labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFAB47BC), width: 1)), prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFFAB47BC), size: 20)));
  Widget _buildCalculateButton() => ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text('Calculate Loan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildResultsCards() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Loan Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Row(children: [_buildResultCard('Monthly EMI', 'LKR ${NumberFormat('#,##0').format(_monthlyEMI + (double.tryParse(_recurringLumpSumController.text) ?? 0))}', const Color(0xFFAB47BC), Icons.payments), const SizedBox(width: 12), _buildResultCard('Total Interest', 'LKR ${NumberFormat('#,##0').format(_totalInterest)}', const Color(0xFFEF5350), Icons.trending_up)]), const SizedBox(height: 12), Row(children: [_buildResultCard('Total Payment', 'LKR ${NumberFormat('#,##0').format(_totalPayment)}', const Color(0xFFFFA726), Icons.receipt_long), const SizedBox(width: 12), _buildResultCard('Best Bank', _bestBank ?? 'N/A', const Color(0xFF4CAF50), Icons.star)])]);
  Widget _buildResultCard(String l, String v, Color c, IconData i) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: c, size: 16)), const SizedBox(height: 12), Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 2), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))])));

  Widget _buildPaymentChart() {
    double principal = _totalPayment - _totalInterest;
    double totalWithDown = principal + _totalInterest + (double.tryParse(_lumpSumController.text) ?? 0);
    double pp = totalWithDown > 0 ? (principal / totalWithDown) * 100 : 0, ip = totalWithDown > 0 ? (_totalInterest / totalWithDown) * 100 : 0, lp = totalWithDown > 0 ? ((double.tryParse(_lumpSumController.text) ?? 0) / totalWithDown) * 100 : 0;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 32, child: Row(children: [if (lp > 0) Expanded(flex: lp.round().clamp(1, 100), child: Container(color: const Color(0xFF42A5F5))), if (pp > 0) Expanded(flex: pp.round().clamp(1, 100), child: Container(color: const Color(0xFF4CAF50))), if (ip > 0) Expanded(flex: ip.round().clamp(1, 100), child: Container(color: const Color(0xFFEF5350)))]))), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildLegend('Lump Sum', const Color(0xFF42A5F5), double.tryParse(_lumpSumController.text) ?? 0, '${lp.toStringAsFixed(1)}%'), _buildLegend('Principal', const Color(0xFF4CAF50), principal, '${pp.toStringAsFixed(1)}%'), _buildLegend('Interest', const Color(0xFFEF5350), _totalInterest, '${ip.toStringAsFixed(1)}%')])]));
  }
  Widget _buildLegend(String l, Color c, double a, String p) => Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(l, style: const TextStyle(color: Colors.white, fontSize: 11))]), const SizedBox(height: 2), Text('LKR ${NumberFormat.compact().format(a)} ($p)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10))]);

  Widget _buildBankComparison() {
    if (_bankResults.isEmpty) return const SizedBox();

    final sorted = _bankResults.entries.toList()
      ..sort((a, b) => a.value.emi.compareTo(b.value.emi));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Comparison (Lowest EMI First)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sorted.map((e) {
            final isBest = e.key == _bestBank;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBest ? const Color(0xFF4CAF50).withOpacity(0.05) : const Color(0xFF0B0C10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBest ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  if (isBest)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                            color: isBest ? const Color(0xFFFFD700) : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(e.value.rate * 100).toStringAsFixed(1)}% p.a.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LKR ${NumberFormat('#,##0').format(e.value.emi)}/mo',
                        style: TextStyle(
                          color: isBest ? const Color(0xFF4CAF50) : const Color(0xFFAB47BC),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Total: LKR ${NumberFormat('#,##0').format(e.value.totalPayment)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAmortizationSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Payment Schedule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), TextButton.icon(icon: Icon(_showSchedule ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFAB47BC)), label: Text(_showSchedule ? 'Hide' : 'Show Full Schedule', style: const TextStyle(color: Color(0xFFAB47BC))), onPressed: () => setState(() => _showSchedule = !_showSchedule))]), if (_showSchedule) ...[const SizedBox(height: 8), SizedBox(height: 120, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [...List.generate(_schedule.length.clamp(0, 24), (i) { if (i % (_schedule.length ~/ 12).clamp(1, 100) != 0 && i != 0 && i != _schedule.length - 1) return const SizedBox.shrink(); double mv = _schedule.map((e) => e.emi).reduce((a, b) => a > b ? a : b); double pct = mv > 0 ? _schedule[i].emi / mv : 0; return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(height: 90 * pct, decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.6), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))), const SizedBox(height: 4), Text('${_schedule[i].month}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 7))]))); })])), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [SizedBox(width: 35, child: Text('#', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))), Expanded(flex: 2, child: Text('Principal', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))), Expanded(flex: 2, child: Text('Interest', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))), Expanded(flex: 2, child: Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)))])), ..._schedule.take(24).map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))), child: Row(children: [SizedBox(width: 35, child: Text('${e.month}', style: const TextStyle(color: Colors.white54, fontSize: 11))), Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.principal), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11))), Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.interest), style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11))), Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.balance), style: const TextStyle(color: Colors.white54, fontSize: 11)))]))), if (_schedule.length > 24) Padding(padding: const EdgeInsets.all(12), child: Text('+ ${_schedule.length - 24} more payments...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)))], const SizedBox(height: 12), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildMiniStat('Total Payments', '${_schedule.length}'), _buildMiniStat('Avg Monthly', 'LKR ${NumberFormat.compact().format(_totalPayment / _schedule.length)}'), _buildMiniStat('Interest Share', '${(_totalInterest / _totalPayment * 100).toStringAsFixed(1)}%')]))]);
  Widget _buildMiniStat(String l, String v) => Column(children: [Text(v, style: const TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.bold, fontSize: 14)), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10))]);

  Widget _buildHowItWorks() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, color: Color(0xFFAB47BC), size: 18)), const SizedBox(width: 10), const Text('Understanding Your Loan', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), _buildIP('EMI', 'Equated Monthly Installment - fixed monthly payment covering principal and interest.'), _buildIP('Principal', 'The original loan amount. Each EMI reduces outstanding principal.'), _buildIP('Interest', 'Calculated monthly on reducing balance. Early payments have higher interest.'), _buildIP('Lump Sum', 'Optional upfront payment reducing loan amount and EMI.'), _buildIP('Recurring Extra', 'Additional monthly payments reduce tenure and total interest.')]));
  Widget _buildIP(String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFAB47BC), shape: BoxShape.circle)), const SizedBox(width: 10), Expanded(child: RichText(text: TextSpan(children: [TextSpan(text: '$t: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), TextSpan(text: d, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5))])))]));

  Widget _buildDisclaimer() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Disclaimer', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text('Rates are indicative. Actual rates depend on credit score, income, and bank relationship. Contact the bank for exact rates and terms.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.5))]))]));
}

// ==================== MODELS ====================

class BankFDResult {
  final String bankName; final double rate, interest, maturity, effectiveAnnualRate; final int months;
  BankFDResult({required this.bankName, required this.rate, required this.interest, required this.maturity, required this.months, required this.effectiveAnnualRate});
}

class BankLoanResult {
  final String bankName; final double rate, emi, totalPayment, totalInterest;
  BankLoanResult({required this.bankName, required this.rate, required this.emi, required this.totalPayment, required this.totalInterest});
}