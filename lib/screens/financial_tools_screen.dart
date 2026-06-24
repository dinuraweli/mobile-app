import 'package:flutter/material.dart';

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Tools'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.calculate, color: Colors.tealAccent), title: Text('APIT / PAYE Tax Calculator'), subtitle: Text('Estimate your monthly corporate tax deductions.')), Divider(),
          ListTile(leading: Icon(Icons.real_estate_agent, color: Colors.tealAccent), title: Text('Leasing Calculator'), subtitle: Text('Calculate monthly rentals for vehicles.')), Divider(),
          ListTile(leading: Icon(Icons.account_balance, color: Colors.tealAccent), title: Text('Fixed Deposit Returns'), subtitle: Text('Compare local bank FD rates and returns.')),
        ],
      ),
    );
  }
}
