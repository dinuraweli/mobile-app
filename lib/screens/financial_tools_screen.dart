// File: lib/screens/financial_tools_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sl_financial_data.dart';
import 'dart:math' as math;
import 'tax_calculator_screen.dart' as tax_screens;

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Tools',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sri Lanka-specific calculators',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Tax Calculator
            SliverToBoxAdapter(
              child: _ToolCard(
                icon: Icons.account_balance_rounded,
                title: 'APIT / PAYE Tax Calculator',
                subtitle: 'Calculate your monthly income tax deductions',
                color: const Color(0xFFEF5350),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const tax_screens.TaxCalculatorScreen()),
                ),
              ),
            ),

            // EPF/ETF Calculator
            SliverToBoxAdapter(
              child: _ToolCard(
                icon: Icons.savings_rounded,
                title: 'EPF / ETF Calculator',
                subtitle: 'Project your retirement fund growth',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EPFCalculatorScreen()),
                ),
              ),
            ),

            // Leasing Calculator
            SliverToBoxAdapter(
              child: _ToolCard(
                icon: Icons.directions_car_rounded,
                title: 'Vehicle Leasing Calculator',
                subtitle: 'Calculate monthly rentals for vehicles',
                color: const Color(0xFFFFA726),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeasingCalculatorScreen()),
                ),
              ),
            ),

            // FD Calculator
            SliverToBoxAdapter(
              child: _ToolCard(
                icon: Icons.trending_up_rounded,
                title: 'Fixed Deposit Calculator',
                subtitle: 'Compare FD rates across Sri Lankan banks',
                color: const Color(0xFF42A5F5),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FDCalculatorScreen()),
                ),
              ),
            ),

            // Loan Calculator
            SliverToBoxAdapter(
              child: _ToolCard(
                icon: Icons.monetization_on_rounded,
                title: 'Loan Calculator',
                subtitle: 'Personal & business loan EMI calculations',
                color: const Color(0xFFAB47BC),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanCalculatorScreen()),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ==================== TOOL CARD WIDGET ====================

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TAX CALCULATOR ====================

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _salaryController = TextEditingController();
  String _result = '';
  bool _calculated = false;

  void _calculate() {
    double salary = double.tryParse(_salaryController.text) ?? 0;
    if (salary <= 0) return;

    double monthlyTax = SLFinancialData.calculateMonthlyTax(salary);
    double annualTax = monthlyTax * 12;
    double effectiveRate = salary > 0 ? (annualTax / (salary * 12)) * 100 : 0;

    setState(() {
      _result = '''
Monthly Salary: LKR ${NumberFormat('#,##0.00').format(salary)}
Tax-Free Allowance: LKR ${NumberFormat('#,##0').format(SLFinancialData.taxFreeAllowance)}/year
Monthly Tax (APIT): LKR ${NumberFormat('#,##0.00').format(monthlyTax)}
Annual Tax: LKR ${NumberFormat('#,##0.00').format(annualTax)}
Take-Home Pay: LKR ${NumberFormat('#,##0.00').format(salary - monthlyTax)}
Effective Tax Rate: ${effectiveRate.toStringAsFixed(1)}%

Tax Brackets Applied:
${SLFinancialData.apitBrackets.map((b) {
  double max = b.maxAmount == double.infinity ? double.infinity : b.maxAmount;
  return '• LKR ${NumberFormat('#,##0').format(b.minAmount)} - ${max == double.infinity ? 'Above' : 'LKR ${NumberFormat('#,##0').format(max)}'}: ${(b.rate * 100).toStringAsFixed(0)}%';
}).join('\n')}
''';
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('APIT/PAYE Tax Calculator'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput('Monthly Gross Salary (LKR)', _salaryController, Icons.money),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66FCF1),
                foregroundColor: const Color(0xFF0B0C10),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Calculate Tax', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (_calculated) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF66FCF1)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

// ==================== EPF CALCULATOR ====================

class EPFCalculatorScreen extends StatefulWidget {
  const EPFCalculatorScreen({super.key});

  @override
  State<EPFCalculatorScreen> createState() => _EPFCalculatorScreenState();
}

class _EPFCalculatorScreenState extends State<EPFCalculatorScreen> {
  final _salaryController = TextEditingController();
  final _yearsController = TextEditingController(text: '30');
  String _result = '';
  bool _calculated = false;

  void _calculate() {
    double salary = double.tryParse(_salaryController.text) ?? 0;
    int years = int.tryParse(_yearsController.text) ?? 30;
    if (salary <= 0) return;

    var epf = SLFinancialData.calculateEPF(salary);
    double etf = SLFinancialData.calculateETF(salary);
    double projected = SLFinancialData.projectEPFBalance(salary, years);

    setState(() {
      _result = '''
Monthly Salary: LKR ${NumberFormat('#,##0.00').format(salary)}

EPF Contributions:
• Employee (8%): LKR ${NumberFormat('#,##0.00').format(epf['employee']!)}
• Employer (12%): LKR ${NumberFormat('#,##0.00').format(epf['employer']!)}
• Total Monthly: LKR ${NumberFormat('#,##0.00').format(epf['totalMonthly']!)}
• Total Yearly: LKR ${NumberFormat('#,##0.00').format(epf['totalYearly']!)}

ETF Contribution:
• Employer (3%): LKR ${NumberFormat('#,##0.00').format(etf)}/month

Projected EPF Balance after $years years:
LKR ${NumberFormat('#,##0.00').format(projected)}

(Assuming ${(SLFinancialData.epfInterestRate * 100).toStringAsFixed(0)}% annual interest)
''';
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: const Text('EPF/ETF Calculator'), backgroundColor: const Color(0xFF1A1A2E)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput('Monthly Gross Salary (LKR)', _salaryController, Icons.money),
            const SizedBox(height: 16),
            _buildInput('Years to Project', _yearsController, Icons.calendar_today),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66FCF1),
                foregroundColor: const Color(0xFF0B0C10),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Calculate EPF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (_calculated) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
                child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF66FCF1)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

// ==================== ENHANCED LEASING CALCULATOR ====================

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
  
  double _downPayment = 0;
  double _monthlyRental = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;
  double _loanAmount = 0;
  double _interestRate = 0;
  double _ltvRatio = 0;
  
  bool _isCalculated = false;

  @override
  void dispose() {
    _vehicleValueController.dispose();
    _lumpSumController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    double vehicleValue = double.tryParse(_vehicleValueController.text) ?? 0;
    double lumpSum = double.tryParse(_lumpSumController.text) ?? 0;
    
    if (vehicleValue <= 0) return;

    // Get LTV ratio
    final ltvData = SLFinancialData.ltvRatios[_selectedVehicle];
    _ltvRatio = ltvData?.ltv ?? 0.40;
    
    // Calculate maximum loan amount based on LTV
    double maxLoan = vehicleValue * _ltvRatio;
    
    // Calculate down payment (minimum required)
    _downPayment = vehicleValue - maxLoan;
    
    // Get interest rate from selected bank and tenure
    _interestRate = SLFinancialData.bankLeasingRates[_selectedBank]?[_selectedTenure] ?? 0.14;
    
    // Calculate loan amount after lump sum
    _loanAmount = maxLoan - lumpSum;
    if (_loanAmount < 0) _loanAmount = 0;
    
    // Calculate EMI
    double monthlyRate = _interestRate / 12;
    if (_loanAmount > 0 && monthlyRate > 0 && _selectedTenure > 0) {
      double factor = math.pow(1 + monthlyRate, _selectedTenure).toDouble();
      _monthlyRental = _loanAmount * monthlyRate * factor / (factor - 1);
    } else {
      _monthlyRental = 0;
    }
    
    _totalPayment = _monthlyRental * _selectedTenure + lumpSum;
    _totalInterest = _totalPayment - _loanAmount;
    
    setState(() => _isCalculated = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Vehicle Leasing Calculator'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CBSL Notice Banner
            _buildCBSLNotice(),
            const SizedBox(height: 20),

            // Input Section
            _buildInputSection(),
            const SizedBox(height: 24),

            // Calculate Button
            _buildCalculateButton(),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              // Payment Breakdown Chart
              _buildPaymentChart(),
              const SizedBox(height: 24),
              // Results Cards
              _buildResultsCards(),
              const SizedBox(height: 24),
              // Summary
              _buildSummary(),
              const SizedBox(height: 24),
              // CBSL LTV Info
              _buildLTVInfo(),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildCBSLNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel, color: Color(0xFFFFA726), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CBSL Regulation Update', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'New LTV ratios effective May 25, 2026. Unregistered vehicles: 40% LTV. Registered vehicles: 70% LTV.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle & Loan Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Vehicle Type
          _buildDropdown(
            label: 'Vehicle Type',
            value: _selectedVehicle,
            items: SLFinancialData.vehicleCategories,
            onChanged: (val) {
              setState(() => _selectedVehicle = val!);
              _updateCalculations();
            },
          ),
          const SizedBox(height: 14),

          // Vehicle Value
          _buildInputField('Vehicle Value (LKR)', _vehicleValueController, onChanged: (_) => _updateCalculations()),
          const SizedBox(height: 14),

          // LTV Info
          if (double.tryParse(_vehicleValueController.text) != null && double.tryParse(_vehicleValueController.text)! > 0)
            _buildLTVDisplay(),
          const SizedBox(height: 14),

          // Bank Selection
          _buildDropdown(
            label: 'Bank / Financial Institution',
            value: _selectedBank,
            items: SLFinancialData.leasingBanks,
            onChanged: (val) {
              setState(() => _selectedBank = val!);
              _updateCalculations();
            },
          ),
          const SizedBox(height: 14),

          // Tenure
          _buildTenureSelector(),
          const SizedBox(height: 14),

          // Interest Rate Display
          _buildInterestRateDisplay(),
          const SizedBox(height: 14),

          // Lump Sum
          _buildInputField('Additional Lump Sum Payment (LKR)', _lumpSumController, hint: 'Optional - reduces monthly rental', onChanged: (_) => _updateCalculations()),
        ],
      ),
    );
  }

  Widget _buildLTVDisplay() {
    double value = double.tryParse(_vehicleValueController.text) ?? 0;
    if (value <= 0) return const SizedBox();

    final ltvData = SLFinancialData.ltvRatios[_selectedVehicle];
    double ltv = ltvData?.ltv ?? 0.40;
    double maxLoan = value * ltv;
    double minDownPayment = value - maxLoan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF66FCF1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF66FCF1).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LTV Ratio (${ltvData?.category ?? 'Standard'})', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              Text('${(ltv * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min. Down Payment Required', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              Text('LKR ${NumberFormat('#,##0').format(minDownPayment)}', style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Loan Amount', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              Text('LKR ${NumberFormat('#,##0').format(maxLoan)}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestRateDisplay() {
    double rate = SLFinancialData.bankLeasingRates[_selectedBank]?[_selectedTenure] ?? 0.14;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF66FCF1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Interest Rate ($_selectedBank)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          Text('${(rate * 100).toStringAsFixed(1)}% p.a.', style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTenureSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tenure: $_selectedTenure months', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SLFinancialData.tenureOptions.map((t) {
            bool isSelected = _selectedTenure == t;
            return ChoiceChip(
              label: Text('${t}mo', style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF0B0C10) : Colors.white70)),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedTenure = t);
                _updateCalculations();
              },
              selectedColor: const Color(0xFF66FCF1),
              backgroundColor: const Color(0xFF0B0C10),
              side: BorderSide(color: isSelected ? const Color(0xFF66FCF1) : Colors.white.withOpacity(0.1)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1A1A2E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF0B0C10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
      onPressed: () {
        if (double.tryParse(_vehicleValueController.text) == null || (double.tryParse(_vehicleValueController.text) ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid vehicle value'), backgroundColor: Colors.redAccent),
          );
          return;
        }
        _updateCalculations();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66FCF1),
        foregroundColor: const Color(0xFF0B0C10),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Calculate Leasing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // ==================== PAYMENT BREAKDOWN CHART ====================

  Widget _buildPaymentChart() {
    double totalWithDown = _downPayment + _totalPayment;
    double downPct = totalWithDown > 0 ? (_downPayment / totalWithDown) * 100 : 0;
    double loanPct = totalWithDown > 0 ? ((_totalPayment - _totalInterest) / totalWithDown) * 100 : 0;
    double interestPct = totalWithDown > 0 ? (_totalInterest / totalWithDown) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Cost: LKR ${NumberFormat('#,##0.00').format(totalWithDown)}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  if (downPct > 0) Expanded(flex: downPct.round().clamp(1, 100), child: Container(color: const Color(0xFF42A5F5))),
                  if (loanPct > 0) Expanded(flex: loanPct.round().clamp(1, 100), child: Container(color: const Color(0xFF4CAF50))),
                  if (interestPct > 0) Expanded(flex: interestPct.round().clamp(1, 100), child: Container(color: const Color(0xFFEF5350))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildLegend('Down Payment', const Color(0xFF42A5F5), _downPayment, '${downPct.toStringAsFixed(1)}%'),
            _buildLegend('Principal', const Color(0xFF4CAF50), _totalPayment - _totalInterest, '${loanPct.toStringAsFixed(1)}%'),
            _buildLegend('Interest', const Color(0xFFEF5350), _totalInterest, '${interestPct.toStringAsFixed(1)}%'),
          ]),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, double amount, String pct) {
    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
      const SizedBox(height: 2),
      Text('LKR ${NumberFormat.compact().format(amount)} ($pct)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
    ]);
  }

  // ==================== RESULTS CARDS ====================

  Widget _buildResultsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leasing Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _buildResultCard('Monthly Rental', 'LKR ${NumberFormat('#,##0').format(_monthlyRental)}', const Color(0xFF66FCF1), Icons.payments),
          const SizedBox(width: 12),
          _buildResultCard('Down Payment', 'LKR ${NumberFormat('#,##0').format(_downPayment)}', const Color(0xFF42A5F5), Icons.download),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildResultCard('Total Interest', 'LKR ${NumberFormat('#,##0').format(_totalInterest)}', const Color(0xFFEF5350), Icons.trending_up),
          const SizedBox(width: 12),
          _buildResultCard('Loan Amount', 'LKR ${NumberFormat('#,##0').format(_loanAmount)}', const Color(0xFF4CAF50), Icons.account_balance),
        ]),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ==================== SUMMARY ====================

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF66FCF1).withOpacity(0.1), const Color(0xFF45A29E).withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF66FCF1).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.description, color: Color(0xFF66FCF1), size: 20),
            SizedBox(width: 8),
            Text('Loan Details', style: TextStyle(color: Color(0xFF66FCF1), fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _buildSummaryRow('Vehicle', _selectedVehicle),
          _buildSummaryRow('Bank', _selectedBank),
          _buildSummaryRow('Tenure', '$_selectedTenure months'),
          _buildSummaryRow('Interest Rate', '${(_interestRate * 100).toStringAsFixed(1)}% p.a.'),
          _buildSummaryRow('LTV Ratio', '${(_ltvRatio * 100).toStringAsFixed(0)}%'),
          _buildSummaryRow('Monthly Rental', 'LKR ${NumberFormat('#,##0.00').format(_monthlyRental)}', isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        Text(value, style: TextStyle(color: isHighlighted ? const Color(0xFF66FCF1) : Colors.white, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ]),
    );
  }

  // ==================== LTV INFO ====================

  Widget _buildLTVInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFFFA726), size: 18),
            SizedBox(width: 8),
            Text('CBSL LTV Regulations', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          _buildLTVRow('Unregistered Vehicles', '40% LTV'),
          _buildLTVRow('Registered Vehicles (>1 year)', '70% LTV'),
          _buildLTVRow('Electric Vehicles', '60% LTV'),
          _buildLTVRow('Commercial Vehicles', '60% LTV'),
          const SizedBox(height: 8),
          Text('Effective from May 25, 2026 per CBSL directive.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLTVRow(String type, String ltv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(type, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        Text(ltv, style: const TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
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
  String _selectedBank = 'Commercial Bank';
  String _selectedPeriod = '1 Year';
  String _result = '';
  bool _calculated = false;

  void _calculate() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    double rate = SLFinancialData.fdRates[_selectedBank]?[_selectedPeriod] ?? 0.10;
    int months = _getMonths(_selectedPeriod);
    double maturity = amount * (1 + rate * months / 12);
    double interest = maturity - amount;

    setState(() {
      _result = '''
Bank: $_selectedBank
Period: $_selectedPeriod
Interest Rate: ${(rate * 100).toStringAsFixed(2)}% p.a.

Investment: LKR ${NumberFormat('#,##0.00').format(amount)}
Interest Earned: LKR ${NumberFormat('#,##0.00').format(interest)}
Maturity Amount: LKR ${NumberFormat('#,##0.00').format(maturity)}
''';
      _calculated = true;
    });
  }

  int _getMonths(String period) {
    switch (period) {
      case '3 Months': return 3;
      case '6 Months': return 6;
      case '1 Year': return 12;
      case '2 Years': return 24;
      case '3 Years': return 36;
      case '5 Years': return 60;
      default: return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    var periods = SLFinancialData.fdRates[_selectedBank]?.keys.toList() ?? ['1 Year'];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: const Text('Fixed Deposit Calculator'), backgroundColor: const Color(0xFF1A1A2E)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput('Deposit Amount (LKR)', _amountController),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBank,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Bank',
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: SLFinancialData.fdRates.keys.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBank = val!;
                  _selectedPeriod = SLFinancialData.fdRates[_selectedBank]?.keys.first ?? '1 Year';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Period',
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => _selectedPeriod = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66FCF1),
                foregroundColor: const Color(0xFF0B0C10),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Calculate Returns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (_calculated) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
                child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.money, color: Color(0xFF66FCF1)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

// ==================== LOAN CALCULATOR ====================

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '13');
  final _tenureController = TextEditingController(text: '36');
  String _selectedBank = 'Commercial Bank';
  String _result = '';
  bool _calculated = false;

  void _calculate() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double rate = (double.tryParse(_rateController.text) ?? 13) / 100;
    int tenure = int.tryParse(_tenureController.text) ?? 36;
    
    if (amount <= 0) return;

    double monthlyRate = rate / 12;
    double monthlyFactor = math.pow(1 + monthlyRate, tenure).toDouble();
    double emi = amount * monthlyRate * monthlyFactor / (monthlyFactor - 1);
    double totalPayment = emi * tenure;
    double totalInterest = totalPayment - amount;

    setState(() {
      _result = '''
Loan Amount: LKR ${NumberFormat('#,##0.00').format(amount)}
Interest Rate: ${(rate * 100).toStringAsFixed(1)}% p.a.
Tenure: $tenure months (${(tenure / 12).toStringAsFixed(1)} years)

Monthly EMI: LKR ${NumberFormat('#,##0.00').format(emi)}
Total Payment: LKR ${NumberFormat('#,##0.00').format(totalPayment)}
Total Interest: LKR ${NumberFormat('#,##0.00').format(totalInterest)}
''';
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: const Text('Loan Calculator'), backgroundColor: const Color(0xFF1A1A2E)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedBank,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Bank (for reference rate)',
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: SLFinancialData.personalLoanRates.keys.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text('$b (${(SLFinancialData.personalLoanRates[b]! * 100).toStringAsFixed(1)}%)'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBank = val!;
                  _rateController.text = (SLFinancialData.personalLoanRates[val]! * 100).toStringAsFixed(1);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildInput('Loan Amount (LKR)', _amountController),
            const SizedBox(height: 16),
            _buildInput('Interest Rate (% p.a.)', _rateController),
            const SizedBox(height: 16),
            _buildInput('Tenure (months)', _tenureController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66FCF1),
                foregroundColor: const Color(0xFF0B0C10),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Calculate EMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (_calculated) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
                child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}