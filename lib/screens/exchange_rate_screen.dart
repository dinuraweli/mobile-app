// File: lib/screens/exchange_rate_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';
import '../services/financial_config_service.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  String _selectedCurrency = 'USD';
  ExchangeRateData? _rateData;
  bool _isLoading = true;
  String? _lastUpdated;
  ExchangeRateData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_cachedData != null) {
      setState(() {
        _rateData = _cachedData;
        _isLoading = false;
      });
      _refreshInBackground();
      return;
    }

    setState(() => _isLoading = true);
    try {
      _rateData = await ExchangeRateService.getRates(_selectedCurrency);
      _cachedData = _rateData;
      _lastUpdated = FinancialConfigService().getExchangeRatesLastUpdated();
    } catch (e) {
      debugPrint('Error loading rates: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshInBackground() async {
    try {
      final data = await ExchangeRateService.getRates(_selectedCurrency);
      if (mounted) {
        setState(() {
          _rateData = data;
          _cachedData = data;
          _lastUpdated = FinancialConfigService().getExchangeRatesLastUpdated();
        });
      }
    } catch (e) {
      debugPrint('Background refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Exchange Rate Tracker'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              _cachedData = null;
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrencySelector(),
                  if (_rateData != null) ...[
                    const SizedBox(height: 16),
                    _buildDataSourceBanner(),
                    const SizedBox(height: 20),
                    _buildTodayRates(),
                    const SizedBox(height: 24),
                    _buildBestRates(),
                    const SizedBox(height: 24),
                    _buildDisclaimer(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ExchangeRateService.currencies.map((currency) {
            final isSelected = _selectedCurrency == currency;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCurrency = currency;
                  _cachedData = null;
                });
                _loadData();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF66FCF1).withValues(alpha:0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF66FCF1) : Colors.white.withValues(alpha:0.1),
                  ),
                ),
                child: Text(
                  currency,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF66FCF1) : Colors.white.withValues(alpha:0.6),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataSourceBanner() {
    final isFallback = _rateData?.isFallback ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFallback
            ? const Color(0xFFFFA726).withValues(alpha:0.08)
            : const Color(0xFF4CAF50).withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFallback
              ? const Color(0xFFFFA726).withValues(alpha:0.2)
              : const Color(0xFF4CAF50).withValues(alpha:0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFallback ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isFallback ? const Color(0xFFFFA726) : const Color(0xFF4CAF50),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFallback
                  ? 'Showing approximate rates. Connect to internet for live rates.'
                  : 'Live rates from Sri Lankan banks',
              style: TextStyle(
                color: isFallback ? const Color(0xFFFFA726) : const Color(0xFF4CAF50),
                fontSize: 12,
              ),
            ),
          ),
          if (_lastUpdated != null && !isFallback)
            Text(
              'Updated: ${_formatTimestamp(_lastUpdated!)}',
              style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 10),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) {
      return iso;
    }
  }

  Widget _buildTodayRates() {
    if (_rateData == null) return const SizedBox();
    final bankRates = _rateData!.bankRates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedCurrency / LKR Rates',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF66FCF1).withValues(alpha:0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Bank', style: TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(flex: 2, child: Text('Buying', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Selling', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Column(
            children: bankRates.entries.map((entry) {
              final bank = entry.key;
              final rate = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha:0.03))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(bank, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                    Expanded(flex: 2, child: Text(rate.buying.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text(rate.selling.toStringAsFixed(2), style: const TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBestRates() {
    if (_rateData == null) return const SizedBox();
    final bankRates = _rateData!.bankRates;
    if (bankRates.isEmpty) return const SizedBox();

    final bestBuy = bankRates.entries.reduce((a, b) => a.value.buying > b.value.buying ? a : b);
    final bestSell = bankRates.entries.reduce((a, b) => a.value.selling < b.value.selling ? a : b);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha:0.2))),
            child: Column(children: [
              const Text('Best to Sell Currency', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              Text(bestBuy.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(bestBuy.value.buying.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 2),
              const Text('Highest buying rate', style: TextStyle(color: Colors.white30, fontSize: 10)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEF5350).withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEF5350).withValues(alpha:0.2))),
            child: Column(children: [
              const Text('Best to Buy Currency', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              Text(bestSell.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(bestSell.value.selling.toStringAsFixed(2), style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 2),
              const Text('Lowest selling rate', style: TextStyle(color: Colors.white30, fontSize: 10)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFA726).withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726).withValues(alpha:0.15))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20),
        SizedBox(width: 10),
        Expanded(child: Text('Exchange rates are indicative and updated periodically. Actual transaction rates may vary based on amount and bank policies. Always confirm with the bank before making foreign currency transactions.', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5))),
      ]),
    );
  }
}