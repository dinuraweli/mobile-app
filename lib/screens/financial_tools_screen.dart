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

// ==================== LEASING CALCULATOR ====================

class LeasingCalculatorScreen extends StatefulWidget {
  const LeasingCalculatorScreen({super.key});

  @override
  State<LeasingCalculatorScreen> createState() => _LeasingCalculatorScreenState();
}

class _LeasingCalculatorScreenState extends State<LeasingCalculatorScreen> {
  final _vehicleValueController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _interestRateController = TextEditingController(text: '14');
  final _tenureController = TextEditingController(text: '60');
  String _selectedVehicle = 'Brand New Car';
  String _result = '';
  bool _calculated = false;

  void _calculate() {
    double value = double.tryParse(_vehicleValueController.text) ?? 0;
    double downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    double rate = (double.tryParse(_interestRateController.text) ?? 14) / 100;
    int tenure = int.tryParse(_tenureController.text) ?? 60;
    
    if (value <= 0) return;

    double loanAmount = value - downPayment;
    double monthlyRate = rate / 12;
    double monthlyFactor = math.pow(1 + monthlyRate, tenure).toDouble();
    double emi = loanAmount * monthlyRate * monthlyFactor / (monthlyFactor - 1);
    double totalPayment = emi * tenure;
    double totalInterest = totalPayment - loanAmount;

    setState(() {
      _result = '''
Vehicle Value: LKR ${NumberFormat('#,##0.00').format(value)}
Down Payment: LKR ${NumberFormat('#,##0.00').format(downPayment)}
Loan Amount: LKR ${NumberFormat('#,##0.00').format(loanAmount)}
Interest Rate: ${(rate * 100).toStringAsFixed(1)}% p.a.
Tenure: $tenure months (${(tenure / 12).toStringAsFixed(1)} years)

Monthly Rental: LKR ${NumberFormat('#,##0.00').format(emi)}
Total Payment: LKR ${NumberFormat('#,##0.00').format(totalPayment)}
Total Interest: LKR ${NumberFormat('#,##0.00').format(totalInterest)}
''';
      _calculated = true;
    });
  }

  void _onVehicleSelected(String? vehicle) {
    if (vehicle != null) {
      setState(() => _selectedVehicle = vehicle);
      var rate = SLFinancialData.leasingRates[vehicle];
      if (rate != null) {
        _interestRateController.text = ((rate.minRate + rate.maxRate) / 2 * 100).toStringAsFixed(1);
        _tenureController.text = rate.maxTenure.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: const Text('Vehicle Leasing Calculator'), backgroundColor: const Color(0xFF1A1A2E)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicle,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: SLFinancialData.leasingRates.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _onVehicleSelected,
            ),
            const SizedBox(height: 16),
            _buildInput('Vehicle Value (LKR)', _vehicleValueController),
            const SizedBox(height: 16),
            _buildInput('Down Payment (LKR)', _downPaymentController),
            const SizedBox(height: 16),
            _buildInput('Interest Rate (% p.a.)', _interestRateController),
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
              child: const Text('Calculate Leasing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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