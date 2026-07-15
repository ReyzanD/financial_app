/// Maps financial transaction categories to OpenStreetMap Overpass QL tags.
///
/// Each category name (e.g. "Makanan & Minuman") is mapped to one or more
/// OSM key=value pairs that the Overpass API uses to find nearby places of
/// the same type.
///
/// The mapping also supports keyword-based fallback for custom/user-created
/// categories that don't match a known default name exactly.
class OsmCategoryMappingService {
  /// Canonical mappings: app category name → list of OSM [key, value] pairs.
  static const Map<String, List<List<String>>> _categoryToOsmTags = {
    // Food & Drink
    'Makanan & Minuman': [
      ['amenity', 'restaurant'],
      ['amenity', 'cafe'],
      ['amenity', 'fast_food'],
      ['shop', 'bakery'],
      ['shop', 'convenience'],
    ],

    // Transport
    'Transportasi': [
      ['amenity', 'fuel'],
      ['amenity', 'parking'],
      ['amenity', 'bus_station'],
      ['highway', 'bus_stop'],
      ['shop', 'car_repair'],
    ],

    // Shopping
    'Belanja': [
      ['shop', 'supermarket'],
      ['shop', 'convenience'],
      ['shop', 'mall'],
      ['shop', 'clothes'],
      ['shop', 'electronics'],
    ],

    // Entertainment
    'Hiburan': [
      ['amenity', 'cinema'],
      ['amenity', 'theatre'],
      ['leisure', 'park'],
      ['leisure', 'sports_centre'],
      ['tourism', 'attraction'],
    ],

    // Health
    'Kesehatan': [
      ['amenity', 'pharmacy'],
      ['amenity', 'hospital'],
      ['amenity', 'clinic'],
      ['amenity', 'dentist'],
      ['amenity', 'veterinary'],
    ],

    // Education
    'Pendidikan': [
      ['amenity', 'school'],
      ['amenity', 'university'],
      ['amenity', 'college'],
      ['amenity', 'library'],
      ['amenity', 'language_school'],
    ],

    // Bills & Utilities — mostly online; minimal OSM mapping
    'Tagihan & Utilitas': [
      ['office', 'government'],
      ['amenity', 'post_office'],
      ['shop', 'mobile_phone'],
    ],

    // Savings — not a physical place; minimal fallback
    'Tabungan': [
      ['amenity', 'bank'],
      ['amenity', 'atm'],
    ],
  };

  /// Keyword-based overrides for custom/user categories.
  /// Keys are lowercase substrings; values are OSM tag pairs.
  /// Matched in order (first match wins).
  static const List<_KeywordMapping> _keywordMappings = [
    // Food keywords
    _KeywordMapping('makan', [['amenity', 'restaurant'], ['amenity', 'cafe'], ['amenity', 'fast_food']]),
    _KeywordMapping('restoran', [['amenity', 'restaurant']]),
    _KeywordMapping('kopi', [['amenity', 'cafe']]),
    _KeywordMapping('cafe', [['amenity', 'cafe']]),
    _KeywordMapping('warung', [['amenity', 'restaurant'], ['shop', 'convenience']]),
    _KeywordMapping('jajan', [['amenity', 'cafe'], ['amenity', 'fast_food']]),

    // Transport keywords
    _KeywordMapping('bensin', [['amenity', 'fuel']]),
    _KeywordMapping('bbm', [['amenity', 'fuel']]),
    _KeywordMapping('parkir', [['amenity', 'parking']]),
    _KeywordMapping('transport', [['amenity', 'fuel'], ['amenity', 'bus_station']]),
    _KeywordMapping('gojek', [['amenity', 'fuel']]),
    _KeywordMapping('grab', [['amenity', 'fuel']]),

    // Shopping keywords
    _KeywordMapping('belanja', [['shop', 'supermarket'], ['shop', 'convenience'], ['shop', 'mall']]),
    _KeywordMapping('toko', [['shop', 'convenience'], ['shop', 'mall']]),
    _KeywordMapping('supermarket', [['shop', 'supermarket']]),
    _KeywordMapping('pasar', [['shop', 'supermarket'], ['shop', 'convenience']]),

    // Health keywords
    _KeywordMapping('obat', [['amenity', 'pharmacy']]),
    _KeywordMapping('apotek', [['amenity', 'pharmacy']]),
    _KeywordMapping('dokter', [['amenity', 'clinic']]),
    _KeywordMapping('rumah sakit', [['amenity', 'hospital']]),
    _KeywordMapping('sehat', [['amenity', 'pharmacy'], ['amenity', 'clinic']]),

    // Education
    _KeywordMapping('sekolah', [['amenity', 'school']]),
    _KeywordMapping('kuliah', [['amenity', 'university'], ['amenity', 'college']]),
    _KeywordMapping('kursus', [['amenity', 'language_school']]),
    _KeywordMapping('belajar', [['amenity', 'school'], ['amenity', 'library']]),

    // Entertainment
    _KeywordMapping('nonton', [['amenity', 'cinema']]),
    _KeywordMapping('film', [['amenity', 'cinema']]),
    _KeywordMapping('game', [['leisure', 'sports_centre']]),
    _KeywordMapping('olahraga', [['leisure', 'sports_centre']]),
    _KeywordMapping('liburan', [['tourism', 'attraction']]),

    // General/bills
    _KeywordMapping('tagihan', [['office', 'government']]),
    _KeywordMapping('listrik', [['office', 'government']]),
    _KeywordMapping('air', [['office', 'government']]),
    _KeywordMapping('pulsa', [['shop', 'mobile_phone']]),
    _KeywordMapping('bank', [['amenity', 'bank'], ['amenity', 'atm']]),
  ];

  /// Get OSM Overpass QL tag filters for a given category name.
  ///
  /// Returns a list of [key, value] pairs that can be converted to
  /// Overpass QL `["key"="value"]` filters.
  List<List<String>> getTagsForCategory(String categoryName) {
    // 1. Try exact match against canonical categories
    final exact = _categoryToOsmTags[categoryName];
    if (exact != null) return exact;

    // 2. Try case-insensitive exact match
    final lowerName = categoryName.toLowerCase();
    for (final entry in _categoryToOsmTags.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }

    // 3. Try keyword-based match (first match wins)
    for (final kw in _keywordMappings) {
      if (lowerName.contains(kw.keyword)) {
        return kw.tags;
      }
    }

    // 4. Fallback: return a broad set of common amenity tags
    return [
      ['amenity', 'restaurant'],
      ['amenity', 'cafe'],
      ['shop', 'convenience'],
      ['shop', 'supermarket'],
    ];
  }

  /// Build an Overpass QL "[key=value]" filter string for a category.
  /// Returns a list of filter strings, one per tag pair, joined with `,`.
  String buildOverpassFilter(String categoryName) {
    final tags = getTagsForCategory(categoryName);
    return tags.map((t) => '["${t[0]}"="${t[1]}"]').join(',');
  }
}

/// Internal helper for keyword-based mappings.
class _KeywordMapping {
  final String keyword;
  final List<List<String>> tags;

  const _KeywordMapping(this.keyword, this.tags);
}
