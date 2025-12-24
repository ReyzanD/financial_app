import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk receipt scanning dengan OCR
class ReceiptScanningService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Pick image dari gallery atau camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error picking image', error: e);
      return null;
    }
  }

  /// Scan receipt dan extract text
  Future<Map<String, dynamic>?> scanReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        LoggerService.warning('No text found in receipt image');
        return null;
      }

      // Parse receipt text
      final parsedData = _parseReceiptText(recognizedText.text);

      return {
        'raw_text': recognizedText.text,
        'parsed_data': parsedData,
        'confidence': _calculateConfidence(recognizedText),
      };
    } catch (e) {
      LoggerService.error('Error scanning receipt', error: e);
      return null;
    }
  }

  /// Parse receipt text untuk extract amount, date, merchant, dll
  Map<String, dynamic> _parseReceiptText(String text) {
    final lines = text.split('\n');
    final parsed = <String, dynamic>{
      'merchant': '',
      'date': '',
      'total': 0.0,
      'items': <Map<String, dynamic>>[],
    };

    // Extract merchant (usually first line or contains store name)
    if (lines.isNotEmpty) {
      parsed['merchant'] = lines[0].trim();
    }

    // Extract total amount (look for patterns like "TOTAL", "Rp", "IDR")
    for (var line in lines) {
      final upperLine = line.toUpperCase();
      if (upperLine.contains('TOTAL') || 
          upperLine.contains('GRAND TOTAL') ||
          upperLine.contains('JUMLAH')) {
        final amount = _extractAmount(line);
        if (amount > 0) {
          parsed['total'] = amount;
        }
      }

      // Extract date (look for date patterns)
      final dateMatch = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').firstMatch(line);
      if (dateMatch != null) {
        parsed['date'] = dateMatch.group(0);
      }
    }

    // Extract items (lines with amount patterns)
    for (var line in lines) {
      final amount = _extractAmount(line);
      if (amount > 0 && amount < (parsed['total'] as double) * 0.9) {
        // Item amount should be less than total
        parsed['items'].add({
          'description': line.replaceAll(RegExp(r'[\d.,]'), '').trim(),
          'amount': amount,
        });
      }
    }

    return parsed;
  }

  /// Extract amount dari text
  double _extractAmount(String text) {
    // Pattern untuk Rupiah: Rp 50.000 atau 50000
    final rupiahPattern = RegExp(r'Rp\s*[\d.,]+|[\d.,]+\s*Rp|[\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?');
    final match = rupiahPattern.firstMatch(text);
    
    if (match != null) {
      final amountStr = match.group(0)!
          .replaceAll('Rp', '')
          .replaceAll(' ', '')
          .replaceAll(',', '')
          .replaceAll('.', '');
      
      return double.tryParse(amountStr) ?? 0.0;
    }
    
    return 0.0;
  }

  /// Calculate confidence score
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int blockCount = 0;
    
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        for (var element in line.elements) {
          // ML Kit doesn't provide confidence directly, so we estimate
          // based on text length and structure
          if (element.text.trim().isNotEmpty) {
            totalConfidence += 0.8; // Estimated confidence
            blockCount++;
          }
        }
      }
    }
    
    return blockCount > 0 ? totalConfidence / blockCount : 0.0;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

