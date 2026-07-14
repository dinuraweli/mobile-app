// File: lib/services/receipt_scanner_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();
  
  // Cache for merchant categories
  static final Map<String, String> _merchantCategoryCache = {};

  // ==================== IMAGE CAPTURE METHODS ====================
  
  /// Capture image from camera
  Future<File?> captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85, // Good quality but reasonable size
      );
      
      if (image != null) {
        return await _optimizeImage(File(image.path));
      }
      return null;
    } catch (e) {
      debugPrint('Camera capture error: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _optimizeImage(File(image.path));
      }
      return null;
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  // ==================== IMAGE OPTIMIZATION ====================
  
  /// Optimize image for Gemini API (reduce size, improve quality)
  Future<File> _optimizeImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      debugPrint('📸 Original image size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      // If image is too large (>4MB), compress it
      if (fileSize > 4 * 1024 * 1024) {
        debugPrint('⚠️ Image too large, compressing...');
        // For now, return as-is (Gemini handles up to 4MB)
        // In production, you'd resize here
      }
      
      return imageFile;
    } catch (e) {
      debugPrint('Image optimization error: $e');
      return imageFile;
    }
  }

  // ==================== RECEIPT PARSING ====================
  
  /// Main method to scan and parse a receipt
  Future<ReceiptScanResult> scanReceipt(File imageFile, {required int userId}) async {
    try {
      debugPrint('🔍 Scanning receipt...');
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Call Gemini Vision API
      final result = await _parseWithGeminiVision(bytes);
      
      // Post-process results
      return _postProcessResult(result, imageFile);
      
    } catch (e) {
      debugPrint('❌ Receipt scan error: $e');
      return ReceiptScanResult(
        success: false,
        errorMessage: 'Failed to scan receipt: ${e.toString()}',
      );
    }
  }

  // ==================== GEMINI VISION API ====================
  
  Future<Map<String, dynamic>> _parseWithGeminiVision(Uint8List imageBytes) async {
    if (!ApiConfig.isGeminiConfigured) {
      throw Exception('Gemini API key not configured');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // Use Flash for faster, cheaper vision
      apiKey: ApiConfig.geminiApiKey,
      systemInstruction: Content.system('''
You are a Sri Lankan receipt scanner. Extract purchase details from receipt images with HIGH accuracy.

IMPORTANT: 
- Look for the STORE/VENDOR name (usually at the top)
- Find the TOTAL amount (usually at the bottom)
- Extract the DATE of purchase (NOT today's date)
- Identify the LOCATION/branch if visible
- Categorize the purchase

CATEGORIES (choose ONE):
"Groceries" - Supermarkets, food items (Keells, Cargills, Food City, Arpico)
"Transport" - Fuel, vehicle expenses (Fuel stations, IOC, Lanka IOC)
"Dining" - Restaurants, cafes, food courts
"Bills & Utilities" - Utility payments, phone bills
"Recurring Payments" - Subscriptions
"Shopping" - Retail, clothing, electronics
"Transfers" - Money transfers
"Income" - Salary, deposits
"General" - Other

EXTRACTION RULES:
1. "vendor" - Clean store name (e.g., "Keells Super", not "KEELS SUPER (PVT) LTD")
2. "amount" - Total bill amount as a NUMBER (not string)
3. "date" - Receipt date in DD-MMM-YYYY format (e.g., "13-JUL-2026")
4. "location" - Branch/city if visible, otherwise null
5. "category" - One of the categories above
6. "items" - List of main items purchased (top 3-5 items)
7. "payment_method" - "Cash", "Card", or null if not visible
8. "tax_amount" - VAT/tax if shown separately, otherwise null

Return ONLY a JSON object (no markdown):
{
  "vendor": "Keells Super",
  "amount": 3450.00,
  "date": "13-JUL-2026",
  "location": "Colombo 03",
  "category": "Groceries",
  "items": ["Rice 5kg", "Dhal 1kg", "Coconut Oil", "Bread"],
  "payment_method": "Card",
  "tax_amount": 450.00
}

If the image is NOT a receipt, return:
{"error": "not_a_receipt", "reason": "This appears to be a [description]"}

If the receipt is unreadable, return:
{"error": "unreadable", "reason": "The receipt is too blurry/faded to read"}
'''),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.0,
        maxOutputTokens: 1000,
      ),
    );

    final prompt = TextPart('Extract all purchase details from this Sri Lankan receipt.');
    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    String rawJson = response.text ?? '{}';
    
    // Clean the response
    rawJson = rawJson
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    
    if (rawJson.startsWith('[')) {
      rawJson = rawJson.substring(1, rawJson.length - 1).trim();
    }

    return jsonDecode(rawJson);
  }

  // ==================== POST-PROCESSING ====================
  
  ReceiptScanResult _postProcessResult(Map<String, dynamic> data, File imageFile) {
    // Check for errors
    if (data.containsKey('error')) {
      return ReceiptScanResult(
        success: false,
        errorMessage: data['reason'] ?? 'Could not read receipt',
        imageFile: imageFile,
      );
    }

    // Extract and validate amount
    double amount = 0.0;
    if (data['amount'] != null) {
      amount = double.tryParse(data['amount'].toString()) ?? 0.0;
    }

    if (amount <= 0) {
      return ReceiptScanResult(
        success: false,
        errorMessage: 'Could not detect total amount on receipt',
        imageFile: imageFile,
      );
    }

    // Extract vendor
    String vendor = data['vendor']?.toString() ?? 'Unknown Merchant';
    vendor = _cleanVendorName(vendor);

    // Extract and validate category
    String category = data['category']?.toString() ?? 'General';
    category = _validateCategory(category, vendor);

    // Cache the category for this vendor
    _merchantCategoryCache[vendor.toLowerCase()] = category;

    // Parse date
    String date = 'Today';
    if (data['date'] != null) {
      date = _normalizeDate(data['date'].toString());
    }

    // Extract location
    String? location = data['location']?.toString();

    // Extract payment method
    String paymentMethod = 'Unknown';
    if (data['payment_method'] != null) {
      paymentMethod = data['payment_method'].toString();
    }

    // Extract items
    List<String> items = [];
    if (data['items'] != null && data['items'] is List) {
      items = List<String>.from(data['items']);
    }

    // Extract tax
    double? taxAmount;
    if (data['tax_amount'] != null) {
      taxAmount = double.tryParse(data['tax_amount'].toString());
    }

    return ReceiptScanResult(
      success: true,
      vendor: vendor,
      amount: amount,
      date: date,
      location: location,
      category: category,
      paymentMethod: paymentMethod,
      items: items,
      taxAmount: taxAmount,
      imageFile: imageFile,
    );
  }

  // ==================== HELPER METHODS ====================
  
  String _cleanVendorName(String name) {
    // Remove common suffixes and clean up
    return name
        .replaceAll(RegExp(r'\b(PVT|LTD|PVT LTD|PRIVATE LIMITED|COMPANY)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _validateCategory(String category, String vendor) {
    // Check cache first
    final vendorLower = vendor.toLowerCase();
    if (_merchantCategoryCache.containsKey(vendorLower)) {
      return _merchantCategoryCache[vendorLower]!;
    }

    // Validate against allowed categories
    const allowedCategories = [
      'Groceries', 'Transport', 'Dining', 'Bills & Utilities',
      'Recurring Payments', 'Shopping', 'Transfers', 'Income', 'General'
    ];

    if (allowedCategories.contains(category)) {
      return category;
    }

    // Smart categorization based on vendor
    if (RegExp(r'keells|cargills|food city|arpico|glomark|supermarket', caseSensitive: false).hasMatch(vendor)) {
      return 'Groceries';
    }
    if (RegExp(r'fuel|petrol|ioc|lanka ioc|shed', caseSensitive: false).hasMatch(vendor)) {
      return 'Transport';
    }
    if (RegExp(r'restaurant|hotel|cafe|bake|food|kitchen', caseSensitive: false).hasMatch(vendor)) {
      return 'Dining';
    }
    if (RegExp(r'dialog|mobitel|hutch|slt|ceb|water|utility', caseSensitive: false).hasMatch(vendor)) {
      return 'Bills & Utilities';
    }

    return 'General';
  }

  String _normalizeDate(String dateStr) {
    try {
      // Try parsing various date formats
      final formats = [
        'dd-MMM-yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'dd MMM yyyy',
        'dd MMM, yyyy',
      ];

      for (var format in formats) {
        try {
          final parsed = DateFormat(format).parse(dateStr);
          return DateFormat('dd-MMM-yyyy').format(parsed).toUpperCase();
        } catch (_) {}
      }

      // If already in correct format
      if (RegExp(r'\d{2}-[A-Z]{3}-\d{4}').hasMatch(dateStr)) {
        return dateStr;
      }

      return 'Today';
    } catch (e) {
      return 'Today';
    }
  }

  // ==================== BATCH SCANNING ====================
  
  /// Scan multiple receipts at once
  Future<List<ReceiptScanResult>> scanMultipleReceipts(List<File> images) async {
    final List<ReceiptScanResult> results = [];
    
    for (var image in images) {
      final result = await scanReceipt(image, userId: 0); // Default userId for batch
      results.add(result);
    }
    
    return results;
  }
}

// ==================== RESULT CLASS ====================

class ReceiptScanResult {
  final bool success;
  final String? errorMessage;
  final String? vendor;
  final double? amount;
  final String? date;
  final String? location;
  final String? category;
  final String? paymentMethod;
  final List<String>? items;
  final double? taxAmount;
  final File? imageFile;

  ReceiptScanResult({
    required this.success,
    this.errorMessage,
    this.vendor,
    this.amount,
    this.date,
    this.location,
    this.category,
    this.paymentMethod,
    this.items,
    this.taxAmount,
    this.imageFile,
  });

  /// Convert to AppTransaction for saving
  AppTransaction? toTransaction(int userId) {
    if (!success || amount == null || vendor == null) return null;

    return AppTransaction.create(
      userId: userId,
      bank: 'Cash/Other',
      bankName: paymentMethod == 'Card' ? 'Card Payment' : 'Cash/Other',
      amount: amount!,
      merchant: vendor!,
      type: 'debit',
      date: date ?? 'Today',
      category: category ?? 'General',
      source: 'receipt',
      aiConfidence: 0.85,
    );
  }
}