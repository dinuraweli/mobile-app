import 'package:flutter/material.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Hub'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildArticleCard('How to register for a TIN in Sri Lanka', 'Step-by-step visual guide for 2026.'),
          _buildArticleCard('Central Bank Policy Rates Update', 'What the latest CBSL decisions mean for your loans.'),
          _buildArticleCard('Understanding the EPF / ETF', 'How to check your balance and claim benefits.'),
        ],
      ),
    );
  }
  
  Widget _buildArticleCard(String title, String subtitle) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const Icon(Icons.article, color: Colors.teal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.arrow_forward_ios, size: 16)));
}
