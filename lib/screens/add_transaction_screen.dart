import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final Function(AppTransaction) onTransactionExtracted;
  final Map<String, String> learningRules;

  const AddTransactionScreen({super.key, required this.onTransactionExtracted, required this.learningRules});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final String _apiKey = 'AIzaSyAbC5HMYjlfpaKlgAnmlKMrldMfvcSwKgA';
  final TextEditingController _smsController = TextEditingController();
  bool _isLoadingSms = false;
  String _extractedJsonSms = '';
  final String _sampleSms = "Acct 4432 debited LKR 3,450.00 at UBER EATS on 24-MAY. Bal: LKR 12,700.00. ComBank.";
  
  bool _isScanningReceipt = false;
  final ImagePicker _picker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _manualAmountController = TextEditingController();
  final _manualMerchantController = TextEditingController();
  final _manualDateController = TextEditingController();
  final _manualAccountMaskController = TextEditingController();
  
  String _selectedBank = 'Commercial Bank';
  String _selectedCategory = 'Dining'; // Updated default
  String _selectedType = 'Debit';
  String _selectedAccountType = 'Debit/Account';

  final List<String> _banks = ['Commercial Bank', 'BOC', 'Sampath Bank', 'HNB', 'NDB', 'HSBC', 'NTB', 'Cash/Other'];
  // The Strict Category List!
  final List<String> _categories = ['Groceries', 'Transport', 'Dining', 'Bills & Utilities', 'Recurring Payments', 'Shopping', 'Transfers', 'Income', 'General'];
  final List<String> _accountTypes = ['Debit/Account', 'Credit Card'];

  @override
  void dispose() {
    _smsController.dispose(); _manualAmountController.dispose(); _manualMerchantController.dispose(); _manualDateController.dispose(); _manualAccountMaskController.dispose();
    super.dispose();
  }

  Future<void> _extractSmsData() async {
    if (_smsController.text.trim().isEmpty) return;
    setState(() { _isLoadingSms = true; _extractedJsonSms = 'Connecting to Gemini AI...'; });
    
    String rawText = ''; 
    try {
      String rulesPrompt = widget.learningRules.isEmpty ? "" : 
          "\nUser's learned category preferences (use strictly if matched): ${jsonEncode(widget.learningRules)}";

      final systemInstruction = Content.system(
        'You are a financial data extraction bot for a Sri Lankan finance app. '
        'Analyze the SMS text and extract the information into a strict JSON object (NOT an array). '
        '\n\nCRITICAL RULES:\n'
        '1. The "category" field MUST be chosen exactly from this list, and no other words: '
        '["Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"].\n'
        '2. Use "Recurring Payments" ONLY if it represents a regular subscription or scheduled bill (e.g., Netflix, Spotify, Dialog postpaid, SLT, CEB, Water Board).\n'
        '3. Keys must exactly match: "bank", "amount" (number), "merchant", "category", "type" (Debit/Credit), "date" (string DD-MMM), "account_type", "account_mask". $rulesPrompt'
      );
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey, systemInstruction: systemInstruction, generationConfig: GenerationConfig(responseMimeType: 'application/json', temperature: 0.1));
      final response = await model.generateContent([Content.text(_smsController.text)]);
      
      if (!mounted) return;
      rawText = response.text ?? '{}';
      
      final String tripleTicks = String.fromCharCode(96) * 3;
      rawText = rawText.replaceAll('$tripleTicks json', '').replaceAll(tripleTicks, '').trim();
      if (rawText.startsWith('[')) rawText = rawText.substring(1, rawText.length - 1).trim();
      int startIndex = rawText.indexOf('{'); int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        rawText = rawText.substring(startIndex, endIndex + 1);
      } else {
        throw FormatException('No JSON object found.');
      }
      
      final parsedJson = jsonDecode(rawText);
      double extractedAmount = 0.0;
      if (parsedJson['amount'] != null) extractedAmount = double.tryParse(parsedJson['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final newTransaction = AppTransaction(
        bank: parsedJson['bank']?.toString() ?? 'Unknown',
        bankName: parsedJson['bankName']?.toString() ?? parsedJson['bank']?.toString() ?? 'Unknown',
        amount: extractedAmount,
        merchant: parsedJson['merchant']?.toString() ?? 'Unknown',
        type: parsedJson['type']?.toString() ?? 'Debit',
        date: parsedJson['date']?.toString() ?? 'Unknown Date',
        category: parsedJson['category']?.toString() ?? 'General',
        accountType: parsedJson['account_type']?.toString() ?? 'Unknown',
        accountMask: parsedJson['account_mask']?.toString() ?? '',
        availableBalance: parsedJson['availableBalance'] != null ? double.tryParse(parsedJson['availableBalance'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) : null,
      );
      
      widget.onTransactionExtracted(newTransaction);
      setState(() => _extractedJsonSms = const JsonEncoder.withIndent('  ').convert(parsedJson));
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ SMS Transaction Extracted & Saved!'), backgroundColor: Colors.green));
      Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
    } catch (e) {
      if (mounted) setState(() => _extractedJsonSms = 'Error extracting data:\n$e\n\n---\nRaw AI Response:\n$rawText');
    } finally {
      if (mounted) setState(() => _isLoadingSms = false);
    }
  }

  Future<void> _processReceiptImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isScanningReceipt = true);

    try {
      final bytes = await image.readAsBytes();
      
      String rulesPrompt = widget.learningRules.isEmpty ? "" : 
          "\nUser's learned category preferences (use strictly if matched): ${jsonEncode(widget.learningRules)}";

      final systemInstruction = Content.system(
        'You are a receipt data extraction bot. Analyze the image and extract the receipt information into a strict JSON object (NOT an array). '
        '\n\nCRITICAL RULES:\n'
        '1. The "category" field MUST be chosen exactly from this list, and no other words: '
        '["Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"].\n'
        '2. Keys must exactly match: "bank" (default to "Cash/Other" if not clear), "amount" (number), "merchant", "category", "type" (usually "Debit"), "date" (string DD-MMM), "account_type" (Unknown), "account_mask". $rulesPrompt'
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: _apiKey, 
        systemInstruction: systemInstruction, 
        generationConfig: GenerationConfig(responseMimeType: 'application/json', temperature: 0.1)
      );

      final prompt = TextPart("Extract the transaction details from this receipt.");
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (!mounted) return;
      String rawText = response.text ?? '{}';
      
      final String tripleTicks = String.fromCharCode(96) * 3;
      rawText = rawText.replaceAll('$tripleTicks json', '').replaceAll(tripleTicks, '').trim();
      if (rawText.startsWith('[')) rawText = rawText.substring(1, rawText.length - 1).trim();
      int startIndex = rawText.indexOf('{'); int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        rawText = rawText.substring(startIndex, endIndex + 1);
      } else {
        throw FormatException('No JSON object found.');
      }
      
      final parsedJson = jsonDecode(rawText);
      
      double extractedAmount = 0.0;
      if (parsedJson['amount'] != null) extractedAmount = double.tryParse(parsedJson['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final newTransaction = AppTransaction(
        bank: parsedJson['bank']?.toString() ?? 'Cash/Other',
        bankName: parsedJson['bankName']?.toString() ?? parsedJson['bank']?.toString() ?? 'Cash/Other',
        amount: extractedAmount,
        merchant: parsedJson['merchant']?.toString() ?? 'Unknown',
        type: parsedJson['type']?.toString() ?? 'Debit',
        date: parsedJson['date']?.toString() ?? 'Today',
        category: parsedJson['category']?.toString() ?? 'General',
        accountType: parsedJson['account_type']?.toString() ?? 'Unknown',
        accountMask: parsedJson['account_mask']?.toString() ?? '',
        availableBalance: parsedJson['availableBalance'] != null ? double.tryParse(parsedJson['availableBalance'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) : null,
      );
      
      widget.onTransactionExtracted(newTransaction);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Receipt Extracted: LKR $extractedAmount at ${newTransaction.merchant}'), backgroundColor: Colors.green));
      Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error reading receipt: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isScanningReceipt = false);
    }
  }

  void _submitManualForm() {
    if (_formKey.currentState!.validate()) {
      double amount = double.tryParse(_manualAmountController.text) ?? 0.0;
      widget.onTransactionExtracted(AppTransaction(
        bank: _selectedBank,
        bankName: _selectedBank,
        amount: amount,
        merchant: _manualMerchantController.text,
        type: _selectedType,
        date: _manualDateController.text.isNotEmpty ? _manualDateController.text : 'Today',
        category: _selectedCategory,
        accountType: _selectedAccountType,
        accountMask: _manualAccountMaskController.text,
        availableBalance: null,
      ));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📝 Manual transaction added!'), backgroundColor: Colors.green));
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Transaction'), backgroundColor: Theme.of(context).colorScheme.inversePrimary, bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.sms), text: "Paste SMS"), Tab(icon: Icon(Icons.document_scanner), text: "Scan Receipt"), Tab(icon: Icon(Icons.edit_note), text: "Manual")])),
        body: TabBarView(children: [_buildSmsTab(), _buildReceiptTab(), _buildManualTab()]),
      ),
    );
  }

  Widget _buildSmsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Paste a Bank SMS below:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _smsController, maxLines: 4, decoration: InputDecoration(hintText: 'e.g., $_sampleSms', border: const OutlineInputBorder(), filled: true)),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _smsController.text = _sampleSms, child: const Text('Use Sample SMS'))),
          const SizedBox(height: 8),
          ElevatedButton.icon(icon: _isLoadingSms ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(_isLoadingSms ? 'Extracting...' : 'Extract & Save with AI'), onPressed: _isLoadingSms ? null : _extractSmsData, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16))),
          const SizedBox(height: 24), const Text('AI Output:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.withValues(alpha: 0.3))), child: SingleChildScrollView(child: Text(_extractedJsonSms.isEmpty ? 'Waiting for input...' : _extractedJsonSms, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 14))))),
        ],
      ),
    );
  }

  Widget _buildReceiptTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 100, color: Colors.teal), const SizedBox(height: 24), const Text('Smart Receipt Scanner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          const Text('Take a picture of your physical receipt. Gemini Vision AI will automatically extract the vendor, total amount, and categorize the expense.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)), const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt), 
                label: const Text('Take Photo'), 
                onPressed: _isScanningReceipt ? null : () => _processReceiptImage(ImageSource.camera), 
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.image), 
                label: const Text('Upload'), 
                onPressed: _isScanningReceipt ? null : () => _processReceiptImage(ImageSource.gallery), 
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))
              ),
          ]),
          const SizedBox(height: 30), if (_isScanningReceipt) const Column(children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Gemini AI is reading receipt...', style: TextStyle(color: Colors.tealAccent))])
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
            const Text('Enter Details Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
            TextFormField(controller: _manualAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (LKR)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money)), validator: (value) => value == null || value.isEmpty ? 'Please enter an amount' : null), const SizedBox(height: 16),
            TextFormField(controller: _manualMerchantController, decoration: const InputDecoration(labelText: 'Merchant / Vendor Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store)), validator: (value) => value == null || value.isEmpty ? 'Please enter the merchant name' : null), const SizedBox(height: 16),
            Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedType, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()), items: ['Debit', 'Credit'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(), onChanged: (val) => setState(() => _selectedType = val!))), const SizedBox(width: 16), Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedBank, decoration: const InputDecoration(labelText: 'Bank', border: OutlineInputBorder()), items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (val) => setState(() => _selectedBank = val!)))]), const SizedBox(height: 16),
            Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedAccountType, decoration: const InputDecoration(labelText: 'Account Type', border: OutlineInputBorder()), items: _accountTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(), onChanged: (val) => setState(() => _selectedAccountType = val!))), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _manualAccountMaskController, decoration: const InputDecoration(labelText: 'Last 4 Digits (Opt)', border: OutlineInputBorder())))]), const SizedBox(height: 16),
            Row(children: [Expanded(flex: 2, child: DropdownButtonFormField<String>(initialValue: _selectedCategory, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setState(() => _selectedCategory = val!))), const SizedBox(width: 16), Expanded(flex: 2, child: TextFormField(controller: _manualDateController, decoration: const InputDecoration(labelText: 'Date (e.g. 28-May)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today))))]), const SizedBox(height: 32),
            ElevatedButton(onPressed: _submitManualForm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.teal), child: const Text('Save Transaction', style: TextStyle(fontSize: 16, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
