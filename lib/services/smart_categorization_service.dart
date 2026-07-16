import 'package:financial_app/services/logger_service.dart';

class SmartCategorizationService {
  static const Map<String, List<String>> _keywordMap = {
    'makanan': [
      'makan',
      'makanan',
      'minum',
      'minuman',
      'warung',
      'resto',
      'restaurant',
      'cafe',
      'kopi',
      'bakso',
      'nasi',
      'mie',
      'ayam',
      'mie ayam',
      'gado',
      'sate',
      'bakmi',
      'pizza',
      'burger',
      'kfc',
      'mc',
      'mcd',
      'indomaret',
      'alfamart',
      'supermarket',
      'swalayan',
      'toko roti',
      'bakery',
      'grabfood',
      'gofood',
      'shopeefood',
      'tokopedia food',
    ],
    'transportasi': [
      'gojek',
      'grab',
      'ojek',
      'taxi',
      'taxsi',
      'bengkel',
      'bensin',
      'bbm',
      'pertamax',
      'tol',
      'parkir',
      'kereta',
      'bus',
      'damri',
      'travel',
      'ojol',
      'transport',
      'trans',
      'jaklingko',
      'krl',
      'lrt',
      'mrt',
      'kendaraan',
      'ban',
      'oli',
      'service',
      'cuci mobil',
      'cuci motor',
    ],
    'hiburan': [
      'netflix',
      'spotify',
      'youtube',
      'bios',
      'cinema',
      'xxi',
      'game',
      'steam',
      'playstation',
      'xbox',
      'nintendo',
      'film',
      'konser',
      'tiket',
      'hiburan',
      'entertainment',
      'rekreasi',
      'wisata',
      'traveling',
      'hotel',
      'resort',
      'taman',
      'mall',
      'bioskop',
    ],
    'belanja': [
      'shopee',
      'tokopedia',
      'bukalapak',
      'lazada',
      'blibli',
      'amazon',
      'belanja',
      'shopping',
      'pakaian',
      'baju',
      'celana',
      'sepatu',
      'tas',
      'fashion',
      'online',
      'order',
      'paket',
      'barang',
      'elektronik',
      'hp',
      'handphone',
      'gadget',
    ],
    'tagihan': [
      'listrik',
      'pln',
      'air',
      'pdam',
      'internet',
      'wifi',
      'telkom',
      'indihome',
      'tri',
      'telkomsel',
      'xl',
      'im3',
      'smartfren',
      'bpjs',
      'asuransi',
      'asuransi',
      'kredit',
      'cicilan',
      'tagihan',
      'bill',
      'listrik bulanan',
    ],
    'kesehatan': [
      'apotek',
      'obat',
      'dokter',
      'rumah sakit',
      'rs',
      'klinik',
      'apotik',
      'farmasi',
      'vitamin',
      'suplemen',
      'sikat gigi',
      'sabun',
      'shampoo',
      'masker',
      'hand sanitizer',
      'medical',
      'health',
    ],
    'pendidikan': [
      'sekolah',
      'kuliah',
      'universitas',
      'kursus',
      'bimbel',
      'les',
      'buku',
      'tugas',
      'uang sekolah',
      'spp',
      'pendidikan',
      'education',
      'training',
      'seminar',
      'workshop',
    ],
    'rumah': [
      'kos',
      'sewa',
      'kontrakan',
      'cicilan rumah',
      'renovasi',
      'cat rumah',
      'perabot',
      'furniture',
      'lampu',
      'air',
      'kebersihan',
      'cleaning',
      'taman',
      'kebun',
      'listrik rumah',
    ],
  };

  Future<List<Map<String, dynamic>>> suggestCategory({
    required String description,
    double? amount,
    String? merchant,
  }) async {
    try {
      final suggestions = <Map<String, dynamic>>[];
      final text = '$description $merchant'.toLowerCase();

      for (final entry in _keywordMap.entries) {
        double score = 0.0;
        int matchCount = 0;

        for (final keyword in entry.value) {
          if (text.contains(keyword)) {
            matchCount++;
            score += 1.0;

            if (keyword.length > 6) {
              score += 0.5;
            }

            if (text.startsWith(keyword)) {
              score += 1.0;
            }
          }
        }

        if (matchCount > 0) {
          suggestions.add({
            'category': entry.key,
            'score': score,
            'matches': matchCount,
            'confidence': (score / 3.0).clamp(0.0, 1.0),
          });
        }
      }

      suggestions.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return suggestions.take(3).toList();
    } catch (e) {
      LoggerService.error('Error suggesting category', error: e);
      return [];
    }
  }

  Future<String?> predictBestCategory({required String description, double? amount, String? merchant}) async {
    final suggestions = await suggestCategory(description: description, amount: amount, merchant: merchant);

    if (suggestions.isNotEmpty && (suggestions.first['confidence'] as double) > 0.4) {
      return suggestions.first['category'];
    }

    return null;
  }
}
