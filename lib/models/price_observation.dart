/// A recorded price for a specific item/category at a place.
///
/// Populated by the user tagging "I paid X here" after a transaction, or
/// automatically extracted from transaction amounts at known locations.
class PriceObservation {
  final String id;
  final String placeVisitId;
  final String category; // e.g. "Makanan", "Bensin"
  final double price;
  final String currency;
  final DateTime observedAt;
  final String source; // "self_reported" | "auto_extracted"
  final String? transactionId;
  final DateTime createdAt;

  PriceObservation({
    required this.id,
    required this.placeVisitId,
    required this.category,
    required this.price,
    this.currency = 'IDR',
    required this.observedAt,
    this.source = 'auto_extracted',
    this.transactionId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'place_visit_id': placeVisitId,
    'category': category,
    'price': price,
    'currency': currency,
    'observed_at': observedAt.toIso8601String().split('T')[0],
    'source': source,
    'transaction_id': transactionId,
    'created_at': createdAt.toIso8601String(),
  };

  factory PriceObservation.fromMap(Map<String, dynamic> map) {
    final id = map['price_observation_id_232143'] ?? map['id'] ?? '';
    return PriceObservation(
      id: id.toString(),
      placeVisitId: map['place_visit_id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'IDR',
      observedAt: _parseDate(map['observed_at']),
      source: map['source']?.toString() ?? 'auto_extracted',
      transactionId: map['transaction_id']?.toString(),
      createdAt: _parseDate(map['created_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
