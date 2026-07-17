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
      initialValue: value,
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

// ==================== ENHANCED FD CALCULATOR ====================

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
  
  // Results per bank
  Map<String, BankFDResult> _bankResults = {};
  String? _bestBank;
  double _bestReturn = 0;
  
  // Selected bank for detail view
  String? _selectedDetailBank;

  final List<String> _periods = ['3 Months', '6 Months', '1 Year', '2 Years', '3 Years', '5 Years'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculate() {
    _amount = double.tryParse(_amountController.text) ?? 0;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Calculate for all banks
    _bankResults = {};
    _bestReturn = 0;
    _bestBank = null;

    final fdRates = SLFinancialData.fdRates;
    for (var bank in fdRates.keys) {
      double rate = fdRates[bank]?[_selectedPeriod] ?? 0.10;
      int months = _getMonths(_selectedPeriod);
      
      // Simple interest FD calculation
      double interest = _amount * rate * (months / 12);
      double maturity = _amount + interest;
      double effectiveAnnualRate = rate;
      
      // For periods less than 1 year, annualize the rate
      if (months < 12) {
        effectiveAnnualRate = rate * (12 / months);
      }
      
      _bankResults[bank] = BankFDResult(
        bankName: bank,
        rate: rate,
        interest: interest,
        maturity: maturity,
        months: months,
        effectiveAnnualRate: effectiveAnnualRate,
      );
      
      if (maturity > _bestReturn) {
        _bestReturn = maturity;
        _bestBank = bank;
      }
    }

    setState(() => _isCalculated = true);
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Fixed Deposit Calculator'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            _buildInputSection(),
            const SizedBox(height: 24),
            
            // Calculate Button
            _buildCalculateButton(),

            if (_isCalculated) ...[
              const SizedBox(height: 28),
              
              // Best Bank Highlight
              _buildBestBankCard(),
              const SizedBox(height: 24),
              
              // Bank Comparison Chart
              _buildComparisonChart(),
              const SizedBox(height: 24),
              
              // All Banks Detail
              _buildAllBanksList(),
              const SizedBox(height: 24),
              
              // Selected Bank Detail
              if (_selectedDetailBank != null)
                _buildBankDetailCard(),
              const SizedBox(height: 24),
              
              // How FD Works
              _buildHowItWorks(),
              const SizedBox(height: 24),
              
              // Calculation Formula
              _buildCalculationFormula(),
              const SizedBox(height: 24),
              
              // Disclaimer
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.savings_rounded, color: Color(0xFF42A5F5), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('FD Investment Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          
          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Deposit Amount (LKR)',
              hintText: 'e.g., 500,000',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF0B0C10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1)),
              prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFF42A5F5)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Period Selector
          const Text('Select Deposit Period:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _periods.map((period) {
              bool isSelected = _selectedPeriod == period;
              return ChoiceChip(
                label: Text(period, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF0B0C10) : Colors.white70)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedPeriod = period),
                selectedColor: const Color(0xFF42A5F5),
                backgroundColor: const Color(0xFF0B0C10),
                side: BorderSide(color: isSelected ? const Color(0xFF42A5F5) : Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Compare FD Rates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // ==================== BEST BANK CARD ====================

  Widget _buildBestBankCard() {
    if (_bestBank == null) return const SizedBox();
    final best = _bankResults[_bestBank]!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4CAF50).withOpacity(0.2), const Color(0xFF4CAF50).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 10),
            const Text('Best Return', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Text(best.bankName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${(best.rate * 100).toStringAsFixed(2)}% p.a.', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildBestStat('Investment', 'LKR ${NumberFormat('#,##0').format(_amount)}'),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildBestStat('Interest', 'LKR ${NumberFormat('#,##0').format(best.interest)}'),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildBestStat('Maturity', 'LKR ${NumberFormat('#,##0').format(best.maturity)}'),
          ]),
        ],
      ),
    );
  }

  Widget _buildBestStat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    ]);
  }

  // ==================== COMPARISON CHART ====================

  Widget _buildComparisonChart() {
    if (_bankResults.isEmpty) return const SizedBox();
    
    // Sort banks by maturity amount
    var sorted = _bankResults.entries.toList()
      ..sort((a, b) => b.value.maturity.compareTo(a.value.maturity));
    
    double maxMaturity = sorted.first.value.maturity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Comparison', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$_selectedPeriod deposit of LKR ${NumberFormat('#,##0').format(_amount)}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),
          ...sorted.map((entry) {
            double pct = (entry.value.maturity / maxMaturity * 100);
            bool isBest = entry.key == _bestBank;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      if (isBest) const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                      if (isBest) const SizedBox(width: 4),
                      Text(entry.key, style: TextStyle(color: isBest ? const Color(0xFFFFD700) : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    Text('LKR ${NumberFormat('#,##0').format(entry.value.maturity)}', style: TextStyle(color: isBest ? const Color(0xFFFFD700) : const Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(isBest ? const Color(0xFFFFD700) : const Color(0xFF42A5F5)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== ALL BANKS LIST ====================

  Widget _buildAllBanksList() {
    var sorted = _bankResults.entries.toList()
      ..sort((a, b) => b.value.maturity.compareTo(a.value.maturity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All Bank Rates', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Tap a bank for full details', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        const SizedBox(height: 12),
        ...sorted.map((entry) {
          bool isSelected = _selectedDetailBank == entry.key;
          bool isBest = entry.key == _bestBank;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDetailBank = isSelected ? null : entry.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? const Color(0xFF42A5F5) : Colors.white.withOpacity(0.05), width: isSelected ? 1.5 : 1),
              ),
              child: Row(children: [
                if (isBest)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Best', style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${(entry.value.rate * 100).toStringAsFixed(2)}% p.a. • $_selectedPeriod', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('LKR ${NumberFormat('#,##0').format(entry.value.maturity)}', style: const TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('+LKR ${NumberFormat('#,##0').format(entry.value.interest)}', style: TextStyle(color: const Color(0xFF4CAF50).withOpacity(0.7), fontSize: 11)),
                ]),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ==================== BANK DETAIL CARD ====================

  Widget _buildBankDetailCard() {
    final detail = _bankResults[_selectedDetailBank];
    if (detail == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance, color: Color(0xFF42A5F5), size: 20),
            const SizedBox(width: 8),
            Text(detail.bankName, style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _buildDetailRow('Investment Amount', 'LKR ${NumberFormat('#,##0.00').format(_amount)}'),
          _buildDetailRow('Interest Rate', '${(detail.rate * 100).toStringAsFixed(2)}% p.a.'),
          _buildDetailRow('Deposit Period', _selectedPeriod),
          _buildDetailRow('Effective Annual Rate', '${(detail.effectiveAnnualRate * 100).toStringAsFixed(2)}%'),
          const Divider(color: Colors.white10, height: 20),
          _buildDetailRow('Interest Earned', 'LKR ${NumberFormat('#,##0.00').format(detail.interest)}', isHighlighted: true, color: const Color(0xFF4CAF50)),
          _buildDetailRow('Maturity Amount', 'LKR ${NumberFormat('#,##0.00').format(detail.maturity)}', isHighlighted: true, color: const Color(0xFF42A5F5)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ]),
    );
  }

  // ==================== HOW FD WORKS ====================

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lightbulb_outline, color: Color(0xFF42A5F5), size: 18)),
            const SizedBox(width: 10),
            const Text('How Fixed Deposits Work', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Text('A Fixed Deposit (FD) is a savings instrument offered by banks where you deposit a lump sum for a fixed period at a guaranteed interest rate. Your money grows safely, and you receive the principal plus interest at maturity.', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.6)),
          const SizedBox(height: 16),
          _buildInfoStep('1', 'Choose Your Deposit', 'Decide how much to invest and for how long. Longer periods typically offer higher interest rates.'),
          _buildInfoStep('2', 'Select a Bank', 'Compare rates across banks. In Sri Lanka, rates can vary significantly between institutions for the same period.'),
          _buildInfoStep('3', 'Earn Guaranteed Returns', 'Your interest rate is locked for the entire period. Unlike stock market investments, FD returns are guaranteed.'),
          _buildInfoStep('4', 'Receive Maturity Amount', 'At the end of the term, you receive your original deposit plus all earned interest. You can withdraw or reinvest.'),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(number, style: const TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }

  // ==================== CALCULATION FORMULA ====================

  Widget _buildCalculationFormula() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF42A5F5).withOpacity(0.1), const Color(0xFF42A5F5).withOpacity(0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calculate, color: Color(0xFF42A5F5), size: 20),
            const SizedBox(width: 8),
            const Text('How We Calculate Returns', style: TextStyle(color: Color(0xFF42A5F5), fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          
          // Formula card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0B0C10), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              const Text('Simple Interest Formula', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Interest = Principal × Rate × (Months / 12)',
                style: TextStyle(color: const Color(0xFF42A5F5).withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              Text(
                'Maturity = Principal + Interest',
                style: TextStyle(color: const Color(0xFF42A5F5).withOpacity(0.7), fontSize: 13, fontFamily: 'monospace'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          
          // Example
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0B0C10), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Example:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              Text('Deposit: LKR 100,000', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              Text('Rate: 10% p.a. for 1 Year', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const SizedBox(height: 4),
              Text('Interest = 100,000 × 0.10 × (12/12) = LKR 10,000', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Maturity = 100,000 + 10,000 = LKR 110,000', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  // ==================== DISCLAIMER ====================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Important Notice', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Interest rates shown are indicative and may vary based on the deposit amount, customer relationship, and prevailing market conditions. '
            'Rates are updated periodically but may not reflect real-time changes. '
            'Please contact your bank\'s branch manager or relationship officer for the most current rates, special promotions, and terms applicable to your specific deposit. '
            'Past rates do not guarantee future returns. Fixed Deposits in Sri Lanka are insured up to Rs. 1,100,000 per depositor per bank under the Sri Lanka Deposit Insurance Scheme.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.5),
          ),
        ])),
      ]),
    );
  }
}

// ==================== BANK FD RESULT MODEL ====================

class BankFDResult {
  final String bankName;
  final double rate;
  final double interest;
  final double maturity;
  final int months;
  final double effectiveAnnualRate;

  BankFDResult({
    required this.bankName,
    required this.rate,
    required this.interest,
    required this.maturity,
    required this.months,
    required this.effectiveAnnualRate,
  });
}

// ==================== ENHANCED LOAN CALCULATOR ====================

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
  
  // Results
  double _monthlyEMI = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;
  List<AmortizationEntry> _schedule = [];
  Map<String, BankLoanResult> _bankResults = {};
  String? _bestBank;
  
  bool _isCalculated = false;
  bool _showSchedule = false;

  @override
  void dispose() {
    _amountController.dispose();
    _lumpSumController.dispose();
    _recurringLumpSumController.dispose();
    super.dispose();
  }

  void _onLoanTypeChanged(String? type) {
    if (type != null) {
      setState(() {
        _selectedLoanType = type;
        // Update rate from selected bank for this loan type
        final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == type);
        _interestRate = loanType.typicalRates[_selectedBank] ?? loanType.minRate;
        // Reset tenure if exceeds max
        final maxTenure = loanType.maxTenure;
        if (_selectedTenure > maxTenure) {
          _selectedTenure = maxTenure;
        }
      });
    }
  }

  void _onBankChanged(String? bank) {
    if (bank != null) {
      setState(() {
        _selectedBank = bank;
        final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType);
        _interestRate = loanType.typicalRates[bank] ?? loanType.minRate;
      });
    }
  }

  void _calculate() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid loan amount'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    double lumpSum = double.tryParse(_lumpSumController.text) ?? 0;
    double recurringLumpSum = double.tryParse(_recurringLumpSumController.text) ?? 0;
    double monthlyRate = _interestRate / 12;

    // Calculate EMI with optional recurring lump sum
    double effectiveLoan = amount - lumpSum;
    double monthlyFactor = math.pow(1 + monthlyRate, _selectedTenure).toDouble();
    _monthlyEMI = effectiveLoan > 0 
        ? effectiveLoan * monthlyRate * monthlyFactor / (monthlyFactor - 1) 
        : 0;

    // Add recurring lump sum to monthly payment
    double totalMonthly = _monthlyEMI + recurringLumpSum;

    // Generate amortization schedule
    _schedule = [];
    double balance = effectiveLoan;
    for (int i = 1; i <= _selectedTenure && balance > 0; i++) {
      double interestPayment = balance * monthlyRate;
      double principalPayment = totalMonthly - interestPayment;
      if (principalPayment > balance) {
        principalPayment = balance;
        totalMonthly = principalPayment + interestPayment;
      }
      balance -= principalPayment;
      _schedule.add(AmortizationEntry(
        month: i,
        emi: totalMonthly,
        principal: principalPayment,
        interest: interestPayment,
        balance: balance.clamp(0, double.infinity),
      ));
    }

    _totalPayment = _schedule.fold(0.0, (sum, e) => sum + e.emi) + lumpSum;
    _totalInterest = _schedule.fold(0.0, (sum, e) => sum + e.interest);

    // Compare banks
    _bankResults = {};
    double bestEMI = double.infinity;
    _bestBank = null;
    final loanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType);
    
    for (var bank in loanType.typicalRates.keys) {
      double rate = loanType.typicalRates[bank] ?? 0.12;
      double bMonthlyRate = rate / 12;
      double bFactor = math.pow(1 + bMonthlyRate, _selectedTenure).toDouble();
      double bEMI = effectiveLoan > 0 
          ? effectiveLoan * bMonthlyRate * bFactor / (bFactor - 1) 
          : 0;
      double bTotal = bEMI * _selectedTenure + lumpSum;
      double bInterest = bTotal - effectiveLoan;
      
      _bankResults[bank] = BankLoanResult(
        bankName: bank,
        rate: rate,
        emi: bEMI + recurringLumpSum,
        totalPayment: bTotal + (recurringLumpSum * _selectedTenure),
        totalInterest: bInterest,
      );
      
      if (bEMI < bestEMI) {
        bestEMI = bEMI;
        _bestBank = bank;
      }
    }

    setState(() {
      _isCalculated = true;
      _showSchedule = false;
    });
  }

  IconData _getLoanIcon(String type) {
    switch (type) {
      case 'Housing Loan': return Icons.home_rounded;
      case 'Vehicle Loan': return Icons.directions_car_rounded;
      case 'Education Loan': return Icons.school_rounded;
      case 'Solar Loan': return Icons.solar_power_rounded;
      case 'Business Loan': return Icons.business_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLoanType = SLFinancialData.loanTypes.firstWhere((lt) => lt.name == _selectedLoanType);
    final filteredTenures = SLFinancialData.loanTenureOptions
        .where((t) => t <= currentLoanType.maxTenure)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            _buildInputSection(currentLoanType, filteredTenures),
            const SizedBox(height: 24),
            _buildCalculateButton(),

            if (_isCalculated) ...[
              const SizedBox(height: 28),
              _buildResultsCards(),
              const SizedBox(height: 24),
              _buildPaymentChart(),
              const SizedBox(height: 24),
              _buildBankComparison(),
              const SizedBox(height: 24),
              _buildAmortizationSection(),
              const SizedBox(height: 24),
              _buildHowItWorks(),
              const SizedBox(height: 24),
              _buildDisclaimer(),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(LoanType loanType, List<int> tenures) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFAB47BC), size: 22)),
          const SizedBox(width: 12),
          const Text('Loan Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),

        // Loan Type Chips
        const Text('Loan Type:', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: SLFinancialData.loanTypes.map((type) {
          bool isSelected = _selectedLoanType == type.name;
          return ChoiceChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_getLoanIcon(type.name), size: 16, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 6),
              Text(type.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
            ]),
            selected: isSelected,
            onSelected: (_) => _onLoanTypeChanged(type.name),
            selectedColor: const Color(0xFFAB47BC),
            backgroundColor: const Color(0xFF0B0C10),
            side: BorderSide(color: isSelected ? const Color(0xFFAB47BC) : Colors.white.withOpacity(0.1)),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text(loanType.description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 16),

        // Bank
        _buildDropdown('Bank', _selectedBank, SLFinancialData.loanBanks, _onBankChanged),
        const SizedBox(height: 14),

        // Amount
        _buildTextField('Loan Amount (LKR)', _amountController, hint: 'e.g., 1,000,000'),
        const SizedBox(height: 14),

        // Interest Rate Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Interest Rate ($_selectedBank)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            Text('${(_interestRate * 100).toStringAsFixed(1)}% p.a.', style: const TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 14),

        // Tenure
        const Text('Tenure:', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: tenures.map((t) {
          bool isSelected = _selectedTenure == t;
          String label = t >= 12 ? '${t ~/ 12}Y' : '${t}M';
          return ChoiceChip(
            label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedTenure = t),
            selectedColor: const Color(0xFFAB47BC),
            backgroundColor: const Color(0xFF0B0C10),
            side: BorderSide(color: isSelected ? const Color(0xFFAB47BC) : Colors.white.withOpacity(0.1)),
          );
        }).toList()),
        const SizedBox(height: 14),

        // Lump Sum
        _buildTextField('Initial Lump Sum Payment (LKR)', _lumpSumController, hint: 'Optional'),
        const SizedBox(height: 14),
        _buildTextField('Additional Monthly Payment (LKR)', _recurringLumpSumController, hint: 'Optional - reduces tenure'),
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1A1A2E),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(labelText: label, hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)), labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)), filled: true, fillColor: const Color(0xFF0B0C10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFAB47BC), width: 1)), prefixIcon: const Icon(Icons.money_outlined, color: Color(0xFFAB47BC), size: 20)),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculate,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      child: const Text('Calculate Loan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // ==================== RESULTS ====================

  Widget _buildResultsCards() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Loan Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        _buildResultCard('Monthly EMI', 'LKR ${NumberFormat('#,##0').format(_monthlyEMI + (double.tryParse(_recurringLumpSumController.text) ?? 0))}', const Color(0xFFAB47BC), Icons.payments),
        const SizedBox(width: 12),
        _buildResultCard('Total Interest', 'LKR ${NumberFormat('#,##0').format(_totalInterest)}', const Color(0xFFEF5350), Icons.trending_up),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _buildResultCard('Total Payment', 'LKR ${NumberFormat('#,##0').format(_totalPayment)}', const Color(0xFFFFA726), Icons.receipt_long),
        const SizedBox(width: 12),
        _buildResultCard('Best Bank', _bestBank ?? 'N/A', const Color(0xFF4CAF50), Icons.star),
      ]),
    ]);
  }

  Widget _buildResultCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ]),
      ),
    );
  }

  // ==================== PAYMENT CHART ====================

  Widget _buildPaymentChart() {
    double principal = _totalPayment - _totalInterest;
    double totalWithDown = principal + _totalInterest + (double.tryParse(_lumpSumController.text) ?? 0);
    double principalPct = totalWithDown > 0 ? (principal / totalWithDown) * 100 : 0;
    double interestPct = totalWithDown > 0 ? (_totalInterest / totalWithDown) * 100 : 0;
    double lumpPct = totalWithDown > 0 ? ((double.tryParse(_lumpSumController.text) ?? 0) / totalWithDown) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 32, child: Row(children: [
          if (lumpPct > 0) Expanded(flex: lumpPct.round().clamp(1, 100), child: Container(color: const Color(0xFF42A5F5))),
          if (principalPct > 0) Expanded(flex: principalPct.round().clamp(1, 100), child: Container(color: const Color(0xFF4CAF50))),
          if (interestPct > 0) Expanded(flex: interestPct.round().clamp(1, 100), child: Container(color: const Color(0xFFEF5350))),
        ]))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildLegend('Lump Sum', const Color(0xFF42A5F5), double.tryParse(_lumpSumController.text) ?? 0, '${lumpPct.toStringAsFixed(1)}%'),
          _buildLegend('Principal', const Color(0xFF4CAF50), principal, '${principalPct.toStringAsFixed(1)}%'),
          _buildLegend('Interest', const Color(0xFFEF5350), _totalInterest, '${interestPct.toStringAsFixed(1)}%'),
        ]),
      ]),
    );
  }

  Widget _buildLegend(String label, Color color, double amount, String pct) {
    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))]),
      const SizedBox(height: 2),
      Text('LKR ${NumberFormat.compact().format(amount)} ($pct)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
    ]);
  }

  // ==================== BANK COMPARISON ====================

  Widget _buildBankComparison() {
    if (_bankResults.isEmpty) return const SizedBox();
    var sorted = _bankResults.entries.toList()..sort((a, b) => a.value.emi.compareTo(b.value.emi));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bank Comparison (Lowest EMI First)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...sorted.map((entry) {
          bool isBest = entry.key == _bestBank;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isBest ? const Color(0xFF4CAF50).withOpacity(0.05) : const Color(0xFF0B0C10), borderRadius: BorderRadius.circular(12), border: Border.all(color: isBest ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.white.withOpacity(0.05))),
            child: Row(children: [
              if (isBest) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.star, color: Color(0xFFFFD700), size: 18)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key, style: TextStyle(color: isBest ? const Color(0xFFFFD700) : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${(entry.value.rate * 100).toStringAsFixed(1)}% p.a.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('LKR ${NumberFormat('#,##0').format(entry.value.emi)}/mo', style: TextStyle(color: isBest ? const Color(0xFF4CAF50) : const Color(0xFFAB47BC), fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Total: LKR ${NumberFormat('#,##0').format(entry.value.totalPayment)}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  // ==================== AMORTIZATION SCHEDULE ====================

  Widget _buildAmortizationSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Payment Schedule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(
          icon: Icon(_showSchedule ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFAB47BC)),
          label: Text(_showSchedule ? 'Hide' : 'Show Full Schedule', style: const TextStyle(color: Color(0xFFAB47BC))),
          onPressed: () => setState(() => _showSchedule = !_showSchedule),
        ),
      ]),
      if (_showSchedule) ...[
        const SizedBox(height: 8),
        // Chart
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ...List.generate(_schedule.length.clamp(0, 24), (i) {
              if (i % (_schedule.length ~/ 12).clamp(1, 100) != 0 && i != 0 && i != _schedule.length - 1) return const SizedBox.shrink();
              double maxVal = _schedule.map((e) => e.emi).reduce((a, b) => a > b ? a : b);
              double pct = maxVal > 0 ? _schedule[i].emi / maxVal : 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(height: 90 * pct, decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.6), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
                    const SizedBox(height: 4),
                    Text('${_schedule[i].month}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 7)),
                  ]),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 12),
        // Schedule table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
  SizedBox(width: 35, child: Text('#', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))),
  Expanded(flex: 2, child: Text('Principal', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))),
  Expanded(flex: 2, child: Text('Interest', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))),
  Expanded(flex: 2, child: Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600))),
]),
        ),
        // Schedule rows
        ..._schedule.take(24).map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
          child: Row(children: [
            SizedBox(width: 35, child: Text('${e.month}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
            Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.principal), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11))),
            Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.interest), style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11))),
            Expanded(flex: 2, child: Text(NumberFormat.compact().format(e.balance), style: const TextStyle(color: Colors.white54, fontSize: 11))),
          ]),
        )),
        if (_schedule.length > 24)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('+ ${_schedule.length - 24} more payments...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ),
      ],
      const SizedBox(height: 12),
      // Quick stats
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildMiniStat('Total Payments', '${_schedule.length}'),
          _buildMiniStat('Avg Monthly', 'LKR ${NumberFormat.compact().format(_totalPayment / _schedule.length)}'),
          _buildMiniStat('Interest Share', '${(_totalInterest / _totalPayment * 100).toStringAsFixed(1)}%'),
        ]),
      ),
    ]);
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
    ]);
  }

  // ==================== HOW IT WORKS ====================

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, color: Color(0xFFAB47BC), size: 18)),
          const SizedBox(width: 10),
          const Text('Understanding Your Loan', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        _buildInfoPoint('EMI', 'Equated Monthly Installment - your fixed monthly payment covering both principal and interest.'),
        _buildInfoPoint('Principal', 'The original loan amount you borrow. Each EMI payment reduces the outstanding principal.'),
        _buildInfoPoint('Interest', 'Calculated monthly on the reducing balance. Early payments have higher interest components.'),
        _buildInfoPoint('Lump Sum', 'An optional upfront payment that reduces the loan amount and your monthly EMI.'),
        _buildInfoPoint('Recurring Extra', 'Additional monthly payments that reduce your loan tenure and total interest paid.'),
      ]),
    );
  }

  Widget _buildInfoPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFAB47BC), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(children: [
          TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          TextSpan(text: description, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5)),
        ]))),
      ]),
    );
  }

  // ==================== DISCLAIMER ====================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.15))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Disclaimer', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Interest rates are indicative and subject to change. Actual rates depend on your credit score, income, relationship with the bank, and prevailing market conditions. This calculator provides estimates only. Please contact the respective bank for exact rates, processing fees, and terms applicable to your profile.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.5)),
        ])),
      ]),
    );
  }
}

// ==================== BANK LOAN RESULT ====================

class BankLoanResult {
  final String bankName;
  final double rate;
  final double emi;
  final double totalPayment;
  final double totalInterest;

  BankLoanResult({
    required this.bankName,
    required this.rate,
    required this.emi,
    required this.totalPayment,
    required this.totalInterest,
  });
}