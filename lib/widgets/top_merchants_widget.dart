// File: lib/widgets/top_merchants_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopMerchantsWidget extends StatelessWidget {
  final List<MapEntry<String, double>> merchants;
  final double totalSpending;

  const TopMerchantsWidget({
    super.key,
    required this.merchants,
    required this.totalSpending,
  });

  IconData _getMerchantIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('keells') || lower.contains('cargills') || lower.contains('food city')) return Icons.shopping_cart_rounded;
    if (lower.contains('pickme') || lower.contains('uber') || lower.contains('kangaroo')) return Icons.local_taxi_rounded;
    if (lower.contains('pizza') || lower.contains('kfc') || lower.contains('restaurant')) return Icons.restaurant_rounded;
    if (lower.contains('dialog') || lower.contains('mobitel') || lower.contains('slt')) return Icons.phone_android_rounded;
    if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('youtube')) return Icons.subscriptions_rounded;
    return Icons.store_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final top5 = merchants.take(5).toList();
    if (top5.isEmpty) return const SizedBox();

    final maxAmount = top5.first.value;

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
          Row(children: [
            const Icon(Icons.store_rounded, color: Color(0xFF66FCF1), size: 20),
            const SizedBox(width: 8),
            const Text('Top Merchants', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final merchant = entry.value;
            final pct = maxAmount > 0 ? (merchant.value / maxAmount) : 0.0;
            final share = totalSpending > 0 ? (merchant.value / totalSpending * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66FCF1).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(_getMerchantIcon(merchant.key), color: const Color(0xFF66FCF1), size: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('${index + 1}.', style: TextStyle(color: Colors.white.withValues(alpha:0.3), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(merchant.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withValues(alpha:0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66FCF1)),
                        minHeight: 4,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('LKR ${NumberFormat('#,##0').format(merchant.value)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${share.toStringAsFixed(1)}%', style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 10)),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
  }
}