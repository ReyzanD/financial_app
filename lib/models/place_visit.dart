/// A place the user has visited, derived from transaction location data.
///
/// Deduplicated by (osm_node_id) or (place_name, latitude, longitude) so
/// multiple transactions at the same location share one PlaceVisit record.
class PlaceVisit {
  final String id;
  final String? osmNodeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final String? address;
  final String category; // e.g. "Makanan", "Transportasi"
  final String? osmTag; // e.g. "amenity=restaurant"
  final int visitCount;
  final double totalSpent;
  final DateTime firstVisit;
  final DateTime lastVisit;
  final DateTime createdAt;

  PlaceVisit({
    required this.id,
    this.osmNodeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.category,
    this.osmTag,
    this.visitCount = 1,
    this.totalSpent = 0.0,
    required this.firstVisit,
    required this.lastVisit,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'osm_node_id': osmNodeId,
    'place_name': placeName,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'category': category,
    'osm_tag': osmTag,
    'visit_count': visitCount,
    'total_spent': totalSpent,
    'first_visit': firstVisit.toIso8601String().split('T')[0],
    'last_visit': lastVisit.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
  };

  factory PlaceVisit.fromMap(Map<String, dynamic> map) {
    final id = map['place_visit_id_232143'] ?? map['id'] ?? '';
    return PlaceVisit(
      id: id.toString(),
      osmNodeId: map['osm_node_id']?.toString(),
      placeName: map['place_name']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address']?.toString(),
      category: map['category']?.toString() ?? '',
      osmTag: map['osm_tag']?.toString(),
      visitCount: (map['visit_count'] as num?)?.toInt() ?? 1,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      firstVisit: _parseDate(map['first_visit']),
      lastVisit: _parseDate(map['last_visit']),
      createdAt: _parseDate(map['created_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
