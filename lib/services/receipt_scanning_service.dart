import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/local_data_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReceiptScanningService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final LocalDataService _localData = LocalDataService();
  final _uuid = const Uuid();

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

  Future<Map<String, dynamic>?> scanReceipt(
    File imageFile, {
    bool saveImage = true,
    bool createTransaction = false,
  }) async {
    try {
      String? savedImagePath;
      if (saveImage) {
        savedImagePath = await _saveReceiptImage(imageFile);
      }

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        LoggerService.warning('No text found in receipt image');
        return null;
      }

      final parsedData = _parseReceiptText(recognizedText.text);
      parsedData['image_path'] = savedImagePath;

      await _localData.saveReceiptScan({
        'merchant': parsedData['merchant'],
        'total_amount': parsedData['total'],
        'receipt_date': parsedData['date'],
        'raw_text': recognizedText.text,
        'items': parsedData['items'],
        'image_path': savedImagePath,
        'is_processed': createTransaction ? 1 : 0,
        'confidence': _calculateConfidence(recognizedText),
      });

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

  Future<String?> _saveReceiptImage(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptDir = Directory('${appDir.path}/receipts');
      if (!await receiptDir.exists()) {
        await receiptDir.create(recursive: true);
      }

      final filename = 'receipt_${_uuid.v4()}.jpg';
      final destFile = File('${receiptDir.path}/$filename');
      await sourceFile.copy(destFile.path);

      LoggerService.info('Receipt image saved: ${destFile.path}');
      return destFile.path;
    } catch (e) {
      LoggerService.error('Error saving receipt image', error: e);
      return null;
    }
  }

  Map<String, dynamic> _parseReceiptText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final parsed = <String, dynamic>{
      'merchant': '',
      'date': '',
      'total': 0.0,
      'items': <Map<String, dynamic>>[],
    };

    for (var line in lines) {
      final upperLine = line.toUpperCase();
      if (upperLine.contains('TOKO') ||
          upperLine.contains('WARUNG') ||
          upperLine.contains('RESTORAN') ||
          upperLine.contains('RESTAURANT') ||
          upperLine.contains('CAFE') ||
          upperLine.contains('SUPERMARKET') ||
          upperLine.contains('MINIMARKET') ||
          upperLine.contains('INDOMARET') ||
          upperLine.contains('ALFAMART') ||
          upperLine.contains('ALFAMIDI') ||
          upperLine.contains('MALL') ||
          upperLine.contains('SHOP') ||
          upperLine.contains('STORE') ||
          upperLine.contains('KEDAI')) {
        parsed['merchant'] = line.trim();
        break;
      }
    }

    if (parsed['merchant'].isEmpty && lines.isNotEmpty) {
      parsed['merchant'] = lines[0].trim();
    }

    for (var line in lines) {
      final upperLine = line.toUpperCase();
      if (upperLine.contains('TOTAL') ||
          upperLine.contains('GRAND TOTAL') ||
          upperLine.contains('JUMLAH') ||
          upperLine.contains('BAYAR') ||
          upperLine.contains('TOTAL HARGA')) {
        final amount = _extractAmount(line);
        if (amount > 0) {
          parsed['total'] = amount;
        }
      }

      final dateMatch = RegExp(
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|(\d{4}[/-]\d{1,2}[/-]\d{1,2})',
      ).firstMatch(line);
      if (dateMatch != null) {
        final dateStr = dateMatch.group(0) ?? '';
        parsed['date'] = _normalizeDate(dateStr);
      }

      final timeMatch = RegExp(r'\d{1,2}:\d{2}').firstMatch(line);
      if (timeMatch != null) {
        parsed['time'] = timeMatch.group(0);
      }
    }

    if (parsed['total'] == 0.0) {
      double maxAmount = 0.0;
      for (var line in lines) {
        final amount = _extractAmount(line);
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
      if (maxAmount > 0) {
        parsed['total'] = maxAmount;
      }
    }

    for (var line in lines) {
      final upperLine = line.toUpperCase();
      if (upperLine.contains('TOTAL') ||
          upperLine.contains('GRAND') ||
          upperLine.contains('JUMLAH') ||
          upperLine.contains('BAYAR')) {
        continue;
      }

      final amount = _extractAmount(line);
      if (amount > 0 && amount < parsed['total']) {
        final description = line
            .replaceAll(RegExp(r'[\d.,Rp]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (description.isNotEmpty && description.length > 1) {
          parsed['items'].add({
            'description': description,
            'amount': amount,
          });
        }
      }
    }

    return parsed;
  }

  String _normalizeDate(String dateStr) {
    try {
      dateStr = dateStr.replaceAll('/', '-');
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        if (year < 100) {
          year += year < 50 ? 2000 : 1900;
        }

        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      LoggerService.warning('Error normalizing date: $dateStr', error: e);
    }
    return dateStr;
  }

  double _extractAmount(String text) {
    final rupiahPattern = RegExp(
      r'Rp\s*[\d.,]+|[\d]{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|[\d]{1,3}(?:[.,]\d{3})+',
    );
    final match = rupiahPattern.firstMatch(text);

    if (match != null) {
      var amountStr = match.group(0)!
          .replaceAll('Rp', '')
          .replaceAll(' ', '');

      if (amountStr.contains('.') && amountStr.contains(',')) {
        if (amountStr.lastIndexOf(',') > amountStr.lastIndexOf('.')) {
          amountStr = amountStr.replaceAll('.', '').replaceAll(',', '.');
        } else {
          amountStr = amountStr.replaceAll(',', '');
        }
      } else if (amountStr.contains(',')) {
        final commaIndex = amountStr.indexOf(',');
        final afterComma = amountStr.substring(commaIndex + 1);
        if (afterComma.length == 3 && amountStr.split(',').length == 2) {
          amountStr = amountStr.replaceAll(',', '');
        } else if (afterComma.length <= 2) {
          amountStr = amountStr.replaceAll(',', '.');
        } else {
          amountStr = amountStr.replaceAll(',', '');
        }
      }

      return double.tryParse(amountStr) ?? 0.0;
    }

    return 0.0;
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int blockCount = 0;

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        for (var element in line.elements) {
          if (element.text.trim().isNotEmpty) {
            totalConfidence += 0.8;
            blockCount++;
          }
        }
      }
    }

    return blockCount > 0 ? totalConfidence / blockCount : 0.0;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
