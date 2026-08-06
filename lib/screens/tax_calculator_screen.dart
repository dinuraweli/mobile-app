// File: lib/screens/tax_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tax_calculator_service.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _basicSalaryController = TextEditingController();
  final _bonusController = TextEditingController(text: '0');
  final _commissionController = TextEditingController(text: '0');
  final _allowancesController = TextEditingController(text: '0');
  
  TaxCalculationResult? _result;
  bool _isCalculated = false;

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _bonusController.dispose();
    _commissionController.dispose();
    _allowancesController.dispose();
    super.dispose();
  }

  void _calculate() {
    double basicSalary = double.tryParse(_basicSalaryController.text) ?? 0;
    if (basicSalary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your basic salary'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _result = TaxCalculatorService.calculate(
        monthlyBasicSalary: basicSalary,
        monthlyBonus: double.tryParse(_bonusController.text) ?? 0,
        monthlyCommission: double.tryParse(_commissionController.text) ?? 0,
        monthlyAllowances: double.tryParse(_allowancesController.text) ?? 0,
      );
      _isCalculated = true;
    });
  }

  void _reset() {
    setState(() {
      _basicSalaryController.clear();
      _bonusController.text = '0';
      _commissionController.text = '0';
      _allowancesController.text = '0';
      _result = null;
      _isCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('APIT, EPF & ETF Calculator'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (_isCalculated)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _reset, tooltip: 'Reset'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tax Year Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66FCF1).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF66FCF1).withValues(alpha:0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF66FCF1), size: 16),
                    SizedBox(width: 8),
                    Text('Updated for 2025/2026 Tax Year', style: TextStyle(color: Color(0xFF66FCF1), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Section
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildCalculateButton(),

            if (_isCalculated && _result != null) ...[
              const SizedBox(height: 28),
              _buildSalaryChart(),
              const SizedBox(height: 24),
              _buildMonthlySummary(),
              const SizedBox(height: 24),
              _buildTaxBreakdown(),
              const SizedBox(height: 24),
              _buildAnnualSummary(),
              const SizedBox(height: 24),
              _buildEpfEtfInfo(),
              const SizedBox(height: 24),
              _buildDisclaimer(),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ==================== INPUT SECTION ====================

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF66FCF1).withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF66FCF1), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Enter Your Monthly Earnings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField('Basic Salary (LKR)', _basicSalaryController, 'e.g., 250,000'),
          const SizedBox(height: 14),
          _buildInputField('Monthly Bonus (LKR)', _bonusController, 'Optional'),
          const SizedBox(height: 14),
          _buildInputField('Commission (LKR)', _commissionController, 'Optional'),
          const SizedBox(height: 14),
          _buildInputField('Other Allowances (LKR)', _allowancesController, 'Optional'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF66FCF1).withValues(alpha:0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF66FCF1), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Tax-free allowance: Rs. 1,800,000/year (Rs. 150,000/month)', style: TextStyle(color: Colors.white.withValues(alpha:0.6), fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.25)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
        filled: true,
        fillColor: const Color(0xFF0B0C10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF66FCF1), width: 1)),
        prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFF66FCF1), size: 20),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66FCF1),
        foregroundColor: const Color(0xFF0B0C10),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Calculate My Tax & Deductions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // ==================== SALARY BREAKDOWN CHART ====================

  Widget _buildSalaryChart() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha:0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salary Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Monthly Earnings: LKR ${NumberFormat('#,##0.00').format(result.totalMonthlyEarnings)}', style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 13)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  if (result.takeHomePercentage > 0)
                    Expanded(flex: result.takeHomePercentage.round().clamp(1, 100), child: Container(color: const Color(0xFF4CAF50))),
                  if (result.epfPercentage > 0)
                    Expanded(flex: result.epfPercentage.round().clamp(1, 100), child: Container(color: const Color(0xFF42A5F5))),
                  if (result.taxPercentage > 0)
                    Expanded(flex: result.taxPercentage.round().clamp(1, 100), child: Container(color: const Color(0xFFEF5350))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('Take Home', const Color(0xFF4CAF50), result.monthlyTakeHome, '${result.takeHomePercentage.toStringAsFixed(1)}%'),
              _buildLegend('EPF (8%)', const Color(0xFF42A5F5), result.monthlyEpfEmployee, '${result.epfPercentage.toStringAsFixed(1)}%'),
              _buildLegend('APIT Tax', const Color(0xFFEF5350), result.monthlyTax, '${result.taxPercentage.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, double amount, String percentage) {
    return Column(
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 4),
        Text('LKR ${NumberFormat.compact().format(amount)} ($percentage)', style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 11)),
      ],
    );
  }

  // ==================== MONTHLY SUMMARY ====================

  Widget _buildMonthlySummary() {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatCard('PAYE Tax', 'LKR ${NumberFormat('#,##0').format(result.monthlyTax)}', const Color(0xFFEF5350), Icons.account_balance),
          const SizedBox(width: 12),
          _buildStatCard('Employee EPF', 'LKR ${NumberFormat('#,##0').format(result.monthlyEpfEmployee)}', const Color(0xFF42A5F5), Icons.savings),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatCard('Take Home Pay', 'LKR ${NumberFormat('#,##0').format(result.monthlyTakeHome)}', const Color(0xFF4CAF50), Icons.wallet),
          const SizedBox(width: 12),
          _buildStatCard('Eff. Tax Rate', '${result.effectiveTaxRate.toStringAsFixed(1)}%', const Color(0xFFFFA726), Icons.trending_up),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF66FCF1).withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF66FCF1).withValues(alpha:0.1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.business, color: Color(0xFF66FCF1), size: 18),
                SizedBox(width: 8),
                Text('Employer Contributions (Monthly)', style: TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildEmployerItem('EPF (12%)', result.monthlyEpfEmployer),
                _buildEmployerItem('ETF (3%)', result.monthlyEtfEmployer),
                _buildEmployerItem('Total', result.totalMonthlyEmployerContribution, isTotal: true),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha:0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployerItem(String label, double amount, {bool isTotal = false}) {
    return Column(children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha:isTotal ? 1 : 0.5), fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      const SizedBox(height: 2),
      Text('LKR ${NumberFormat('#,##0').format(amount)}', style: TextStyle(color: const Color(0xFF66FCF1), fontWeight: FontWeight.bold, fontSize: isTotal ? 15 : 13)),
    ]);
  }

  // ==================== TAX BREAKDOWN ====================

  Widget _buildTaxBreakdown() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha:0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tax Calculation Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Based on IRD rates effective April 2025', style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 11)),
          const SizedBox(height: 16),
          _buildInfoRow('Annual Gross Salary', 'LKR ${NumberFormat('#,##0.00').format(result.annualGrossSalary)}'),
          _buildInfoRow('Less: EPF Contribution (8%)', 'LKR ${NumberFormat('#,##0.00').format(result.annualEpfEmployee)}'),
          _buildInfoRow('Less: Tax-Free Allowance', 'LKR ${NumberFormat('#,##0').format(TaxCalculatorService.annualTaxFreeAllowance)}'),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Annual Taxable Income', 'LKR ${NumberFormat('#,##0.00').format(result.annualTaxableIncome)}', isHighlighted: true),
          const SizedBox(height: 16),
          const Text('Tax Brackets Applied:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...result.bracketBreakdowns.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(flex: 3, child: Text(b.label, style: const TextStyle(color: Colors.white, fontSize: 12))),
              Text('${(b.rate * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF66FCF1), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('LKR ${NumberFormat('#,##0').format(b.taxAmount)}', style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          )),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Annual Tax Payable', 'LKR ${NumberFormat('#,##0.00').format(result.annualTax)}', isHighlighted: true, color: const Color(0xFFEF5350)),
          _buildInfoRow('Monthly Tax (PAYE)', 'LKR ${NumberFormat('#,##0.00').format(result.monthlyTax)}', isHighlighted: true, color: const Color(0xFFEF5350)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(flex: 3, child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha:isHighlighted ? 1 : 0.6), fontSize: 13, fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal))),
        Text(value, style: TextStyle(color: color ?? (isHighlighted ? const Color(0xFF66FCF1) : Colors.white), fontSize: 13, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }

  // ==================== ANNUAL SUMMARY ====================

  Widget _buildAnnualSummary() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF66FCF1).withValues(alpha:0.1), const Color(0xFF45A29E).withValues(alpha:0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF66FCF1).withValues(alpha:0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.calendar_today, color: Color(0xFF66FCF1), size: 20),
            SizedBox(width: 8),
            Text('Annual Summary', style: TextStyle(color: Color(0xFF66FCF1), fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _buildAnnualRow('Total Annual Income', result.annualGrossSalary),
          _buildAnnualRow('Annual Tax (APIT)', result.annualTax, isDeduction: true),
          _buildAnnualRow('Annual EPF (Employee)', result.annualEpfEmployee, isDeduction: true),
          _buildAnnualRow('Annual Net Salary', result.annualNetSalary, isTotal: true),
          const Divider(color: Colors.white10, height: 24),
          _buildAnnualRow('Employer EPF (12%)', result.annualEpfEmployer),
          _buildAnnualRow('Employer ETF (3%)', result.annualEtfEmployer),
          _buildAnnualRow('Total Employer Contribution', result.annualEpfEmployer + result.annualEtfEmployer, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildAnnualRow(String label, double amount, {bool isDeduction = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha:isTotal ? 1 : 0.7), fontSize: 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text('LKR ${NumberFormat('#,##0.00').format(amount)}', style: TextStyle(color: isDeduction ? const Color(0xFFEF5350) : (isTotal ? const Color(0xFF66FCF1) : Colors.white), fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  // ==================== EPF/ETF INFO ====================

  Widget _buildEpfEtfInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha:0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF66FCF1).withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, color: Color(0xFF66FCF1), size: 18)),
            const SizedBox(width: 10),
            const Text('About EPF & ETF', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Text('The Employees\' Provident Fund (EPF) and Employees\' Trust Fund (ETF) are mandatory social security schemes established by the Government of Sri Lanka. They provide financial security and retirement benefits to employees in the formal sector.', style: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 13, height: 1.6)),
          const SizedBox(height: 16),
          _buildInfoPoint('Employee EPF Contribution', '8% of your total monthly earnings is deducted and contributed to your EPF account. This is a compulsory savings mechanism for your retirement.'),
          const SizedBox(height: 12),
          _buildInfoPoint('Employer EPF Contribution', 'Your employer contributes an additional 12% of your monthly salary to your EPF account, effectively growing your retirement fund faster.'),
          const SizedBox(height: 12),
          _buildInfoPoint('Employer ETF Contribution', 'An additional 3% of your salary is contributed by your employer to the ETF, a separate fund that provides additional benefits upon retirement or resignation.'),
          const SizedBox(height: 12),
          _buildInfoPoint('Total Employer Contribution', 'Your employer contributes a total of 15% (12% EPF + 3% ETF) of your monthly salary towards your future. This is in addition to your take-home pay.'),
          const SizedBox(height: 12),
          _buildInfoPoint('Net Salary After EPF', 'After the 8% EPF deduction, your net salary before tax is 92% of your gross earnings. Income tax is then calculated after applying the tax-free allowance of Rs. 1,800,000 per year.'),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String title, String description) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF66FCF1), shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        TextSpan(text: description, style: TextStyle(color: Colors.white.withValues(alpha:0.65), fontSize: 13, height: 1.5)),
      ]))),
    ]);
  }

  // ==================== DISCLAIMER ====================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFA726).withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withValues(alpha:0.15))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Disclaimer', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('This calculator is based on the Sri Lanka Inland Revenue Department regulations for the 2025/2026 year of assessment. While every effort has been made to ensure accuracy, this tool is for informational purposes only. For professional tax advice tailored to your situation, please consult a qualified tax professional.', style: TextStyle(color: Colors.white.withValues(alpha:0.6), fontSize: 11, height: 1.5)),
        ])),
      ]),
    );
  }
}