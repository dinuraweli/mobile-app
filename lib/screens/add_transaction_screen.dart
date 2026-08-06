// File: lib/screens/add_transaction_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/transaction.dart';
import '../services/receipt_scanner_service.dart';
import 'package:image_picker/image_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  final Function(AppTransaction) onTransactionExtracted;
  final Map<String, String> learningRules;
  final int userId;

  const AddTransactionScreen({
    super.key,
    required this.onTransactionExtracted,
    required this.learningRules,
    required this.userId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // ==================== SMS TAB CONTROLLERS ====================
  final TextEditingController _smsController = TextEditingController();
  bool _isLoadingSms = false;
  String _extractedJsonSms = '';
  final String _sampleSms =
      "Acct 4432 debited LKR 3,450.00 at UBER EATS on 24-MAY. Bal: LKR 12,700.00. ComBank.";

  // ==================== RECEIPT TAB CONTROLLERS ====================
  final ReceiptScannerService _receiptScanner = ReceiptScannerService();
  bool _isScanningReceipt = false;
  ReceiptScanResult? _scanResult;
  File? _selectedImage;

  // ==================== MANUAL TAB CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _manualAmountController = TextEditingController();
  final _manualMerchantController = TextEditingController();
  final _manualDateController = TextEditingController();
  final _manualAccountMaskController = TextEditingController();
  final _manualLocationController = TextEditingController();

  String _selectedBank = 'Commercial Bank';
  String _selectedCategory = 'Dining';
  String _selectedType = 'Debit';
  String _selectedAccountType = 'Debit/Account';
  final List<String> _banks = [
    'Commercial Bank', 'BOC', 'Sampath Bank', 'HNB', 
    'NDB', 'HSBC', 'NTB', 'Seylan Bank', 'Cash/Other'
  ];
  
  final List<String> _categories = [
    'Groceries', 'Transport', 'Dining', 'Bills & Utilities',
    'Recurring Payments', 'Shopping', 'Transfers', 'Income', 'General'
  ];
  
  final List<String> _accountTypes = ['Debit/Account', 'Credit Card'];

  @override
  void dispose() {
    _smsController.dispose();
    _manualAmountController.dispose();
    _manualMerchantController.dispose();
    _manualDateController.dispose();
    _manualAccountMaskController.dispose();
    _manualLocationController.dispose();
    super.dispose();
  }

  // ==================== SMS EXTRACTION ====================

  Future<void> _extractSmsData() async {
    if (_smsController.text.trim().isEmpty) return;
    setState(() {
      _isLoadingSms = true;
      _extractedJsonSms = 'Connecting to Gemini AI...';
    });

    String rawText = '';
    try {
      String rulesPrompt = widget.learningRules.isEmpty
          ? ""
          : "\nUser's learned category preferences (use strictly if matched): ${jsonEncode(widget.learningRules)}";

      final systemInstruction = Content.system(
        'You are a financial data extraction bot for a Sri Lankan finance app. '
        'Analyze the SMS text and extract the information into a strict JSON object (NOT an array). '
        '\n\nCRITICAL RULES:\n'
        '1. The "category" field MUST be chosen exactly from this list: '
        '["Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"].\n'
        '2. Use "Recurring Payments" ONLY for regular subscriptions or scheduled bills.\n'
        '3. Keys: "bank", "amount" (number), "merchant", "category", "type" (Debit/Credit), "date" (DD-MMM), "account_type", "account_mask". $rulesPrompt'
      );
      
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiConfig.geminiApiKey,
        systemInstruction: systemInstruction,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1,
        ),
      );
      
      final response = await model.generateContent([Content.text(_smsController.text)]);

      if (!mounted) return;
      rawText = response.text ?? '{}';

      // Clean JSON
      const tripleTicks = '```';
      rawText = rawText.replaceAll('$tripleTicks json', '').replaceAll(tripleTicks, '').trim();
      if (rawText.startsWith('[')) {
        rawText = rawText.substring(1, rawText.length - 1).trim();
      }
      int startIndex = rawText.indexOf('{');
      int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        rawText = rawText.substring(startIndex, endIndex + 1);
      } else {
        throw FormatException('No JSON object found.');
      }

      final parsedJson = jsonDecode(rawText);
      double extractedAmount = 0.0;
      if (parsedJson['amount'] != null) {
        extractedAmount = double.tryParse(
          parsedJson['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')
        ) ?? 0.0;
      }

      final newTransaction = AppTransaction.create(
        userId: widget.userId,
        bank: parsedJson['bank']?.toString() ?? 'Unknown',
        bankName: parsedJson['bankName']?.toString() ?? parsedJson['bank']?.toString() ?? 'Unknown',
        amount: extractedAmount,
        merchant: parsedJson['merchant']?.toString() ?? 'Unknown',
        type: parsedJson['type']?.toString() ?? 'Debit',
        date: parsedJson['date']?.toString() ?? 'Unknown Date',
        category: parsedJson['category']?.toString() ?? 'General',
        accountType: parsedJson['account_type']?.toString() ?? 'Unknown',
        accountMask: parsedJson['account_mask']?.toString() ?? '',
        availableBalance: parsedJson['availableBalance'] != null
            ? double.tryParse(parsedJson['availableBalance'].toString().replaceAll(RegExp(r'[^0-9.]'), ''))
            : null,
        source: 'sms',
        smsRawText: _smsController.text,
      );

      widget.onTransactionExtracted(newTransaction);
      setState(() => _extractedJsonSms = const JsonEncoder.withIndent('  ').convert(parsedJson));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SMS Transaction Extracted & Saved!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _extractedJsonSms = 'Error extracting data:\n$e\n\n---\nRaw AI Response:\n$rawText');
      }
    } finally {
      if (mounted) setState(() => _isLoadingSms = false);
    }
  }

  // ==================== RECEIPT SCANNING ====================

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() {
      _isScanningReceipt = true;
      _scanResult = null;
    });

    try {
      // Capture/pick image
      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await _receiptScanner.captureFromCamera();
      } else {
        imageFile = await _receiptScanner.pickFromGallery();
      }

      if (imageFile == null) {
        setState(() => _isScanningReceipt = false);
        return;
      }

      setState(() => _selectedImage = imageFile);

      // Scan the receipt
      final result = await _receiptScanner.scanReceipt(imageFile, userId: widget.userId);

      if (!mounted) return;

      setState(() {
        _scanResult = result;
        _isScanningReceipt = false;
      });

      if (result.success) {
        // Auto-fill the transaction
        final transaction = result.toTransaction(widget.userId);
        if (transaction != null) {
          widget.onTransactionExtracted(transaction);
          _showScanSuccessDialog(result);
        }
      } else {
        _showScanErrorDialog(result.errorMessage ?? 'Could not read receipt');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanningReceipt = false);
        _showScanErrorDialog('Error: ${e.toString()}');
      }
    }
  }

  void _showScanSuccessDialog(ReceiptScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Receipt Scanned!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Vendor', result.vendor ?? 'Unknown'),
            _buildDetailRow('Amount', 'LKR ${result.amount?.toStringAsFixed(2) ?? '0.00'}'),
            _buildDetailRow('Date', result.date ?? 'Today'),
            if (result.location != null)
              _buildDetailRow('Location', result.location!),
            _buildDetailRow('Category', result.category ?? 'General'),
            if (result.paymentMethod != null)
              _buildDetailRow('Payment', result.paymentMethod!),
            if (result.taxAmount != null)
              _buildDetailRow('Tax', 'LKR ${result.taxAmount!.toStringAsFixed(2)}'),
            if (result.items != null && result.items!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.items!.map((item) => Text('  • $item')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close add screen
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Stay on scan screen for another scan
            },
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  void _showScanErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Scan Issue'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ==================== MANUAL ENTRY ====================

  void _submitManualForm() {
    if (_formKey.currentState!.validate()) {
      double amount = double.tryParse(_manualAmountController.text) ?? 0.0;
      
      // Build merchant name with location
      String merchant = _manualMerchantController.text;
      if (_manualLocationController.text.isNotEmpty) {
        merchant += ' (${_manualLocationController.text})';
      }

      widget.onTransactionExtracted(AppTransaction.create(
        userId: widget.userId,
        bank: _selectedBank,
        bankName: _selectedBank,
        amount: amount,
        merchant: merchant,
        type: _selectedType,
        date: _manualDateController.text.isNotEmpty ? _manualDateController.text : 'Today',
        category: _selectedCategory,
        accountType: _selectedAccountType,
        accountMask: _manualAccountMaskController.text,
        availableBalance: null,
        source: 'manual',
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 Manual transaction added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Transaction'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sms), text: "Paste SMS"),
              Tab(icon: Icon(Icons.document_scanner), text: "Scan Receipt"),
              Tab(icon: Icon(Icons.edit_note), text: "Manual"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSmsTab(),
            _buildReceiptTab(),
            _buildManualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Paste a Bank SMS below:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _smsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g., $_sampleSms',
              border: const OutlineInputBorder(),
              filled: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _smsController.text = _sampleSms,
              child: const Text('Use Sample SMS'),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: _isLoadingSms
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoadingSms ? 'Extracting...' : 'Extract & Save with AI'),
            onPressed: _isLoadingSms ? null : _extractSmsData,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 24),
          const Text('AI Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _extractedJsonSms.isEmpty ? 'Waiting for input...' : _extractedJsonSms,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.teal),
          const SizedBox(height: 24),
          const Text(
            'Smart Receipt Scanner',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Take a clear photo of your receipt. Gemini AI will automatically extract vendor, amount, date, category, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Ensure good lighting and a flat surface for best results',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Scan buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScanButton(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onPressed: _isScanningReceipt ? null : () => _scanReceipt(ImageSource.camera),
              ),
              _buildScanButton(
                icon: Icons.photo_library,
                label: 'Upload',
                onPressed: _isScanningReceipt ? null : () => _scanReceipt(ImageSource.gallery),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Scanning indicator
          if (_isScanningReceipt) ...[
            const CircularProgressIndicator(color: Colors.tealAccent),
            const SizedBox(height: 16),
            const Text(
              'Gemini AI is reading your receipt...',
              style: TextStyle(color: Colors.tealAccent, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Extracting vendor, amount, date, and category',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],

          // Preview scanned image
          if (_selectedImage != null && !_isScanningReceipt) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Scan Again'),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _scanResult = null;
                });
              },
            ),
          ],

          // Scan result summary
          if (_scanResult != null && _scanResult!.success) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha:0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Receipt Scanned Successfully!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResultRow('Vendor', _scanResult!.vendor),
                  _buildResultRow('Amount', 'LKR ${_scanResult!.amount?.toStringAsFixed(2)}'),
                  _buildResultRow('Date', _scanResult!.date),
                  _buildResultRow('Category', _scanResult!.category),
                  if (_scanResult!.location != null)
                    _buildResultRow('Location', _scanResult!.location),
                  if (_scanResult!.paymentMethod != null)
                    _buildResultRow('Payment', _scanResult!.paymentMethod),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildScanButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResultRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter Details Manually',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _manualAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter an amount' : null,
            ),
            const SizedBox(height: 16),

            // Merchant
            TextFormField(
              controller: _manualMerchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant / Vendor Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter the merchant name' : null,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _manualLocationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Type and Bank
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Debit', 'Credit']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                      border: OutlineInputBorder(),
                    ),
                    items: _banks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBank = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Account Type and Mask
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAccountType,
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _accountTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedAccountType = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _manualAccountMaskController,
                    decoration: const InputDecoration(
                      labelText: 'Last 4 Digits (Opt)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category and Date
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _manualDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date (e.g. 28-May)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _submitManualForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}